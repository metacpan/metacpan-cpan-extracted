#
# $Id: Api.pm,v d8b98095b893 2023/08/30 05:24:07 gomor $
#
package Onyphe::Api;
use strict;
use warnings;

our $VERSION = '4.10';

use experimental qw(signatures);

use base qw(Onyphe);

our @AS = qw(endpoint apikey username password);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildIndices;

use utf8;
use File::Temp qw(tempfile);
use File::Slurp qw(read_file);
use Mojo::URL;
use JSON::XS qw(encode_json);
use Mojo::UserAgent;
use Mojo::Util qw(b64_encode url_escape);

#
# Common functions:
#
sub _ua ($self) {
   my $ua = Mojo::UserAgent->new(
      connect_timeout => 5,
      max_response_size => 0,
      inactivity_timeout => 0,
   );

   $ua->transactor->name('Onyphe::Api-v'.$VERSION);
   $ua->proxy->detect;

   return $ua;
}

sub _headers ($self, $apikey, $ct = undef) {
   my $headers = {
      'Authorization' => 'Bearer '.$apikey,
      'X-Api-Key' => $apikey,  # Ready for APIv3
      'Content-Type' => 'application/json',
      'Accept' => '*/*',
   };
   if (defined($ct)) {
      $headers->{'Content-Type'} = $ct;
   }
   my $global = $self->config->{''};
   my $username = $global->{api_unrated_email} || $self->username;
   if ($global->{api_unrated_endpoint} && $username) {
      print STDERR "VERBOSE: Using Unrated API endpoint: ".$global->{api_unrated_endpoint}.
         ", with username: $username\n" if $self->verbose;
      if (!defined($username) || !defined($apikey)) {
         print STDERR "ERROR: need api_unrated_email & api_key settings\n"
            unless $self->silent;
         return;
      }
      $username =~ s{\@}{_};
      my $auth = b64_encode($username.':'.$apikey, '');
      $headers->{Authorization} = 'Basic '.$auth;
   }
   return $headers;
}

sub get_maxpage ($self, $json) {
   my $maxpage = $json->{max_page};
   return defined($maxpage) && $maxpage ? $maxpage : 0;
}

sub get_results ($self, $json) {
   my $results = $json->{results};
   return defined($results) && @$results ? $results : [];
}

sub encode ($self, $result) {
   return '' unless $result;
   my $encode;
   eval {
      $encode = encode_json($result);
   };
   if ($@) {
      chomp($@);
      print STDERR "ERROR: encode failed: $@\n" unless $self->silent;
      return '';
   }
   return $encode;
}

#
# Request-based APIs
#
sub _cb_request ($self, $results = undef, $cb_args = undef) {
   return sub ($results, $cb_args) {
      $results = ref($results) eq 'ARRAY' ? $results : [ $results ];
      for (@$results) {
         next if defined($_->{'@category'}) && $_->{'@category'} eq 'none';
         print $self->encode($_)."\n";
      }
   };
}

sub _params ($self, $params) {
   my $first = 1;
   my $args = '';
   for my $p (@$params) {
      my $op = '?';
      $op = '&' unless $first;
      $args .= $op.$p->{k}.'='.$p->{v};
      $first = 0;
   }
   return $args;
}

# $self->request('/search', 'protocol:ssh', 1, 10);
# $self->request('/simple/datascan', '8.8.8.8');
sub request ($self, $api, $input = undef, $page = undef, $maxpage = undef, $params = undef, $cb = undef, $cb_args = undef) {
   my $global = $self->config->{''};
   my $endpoint = $global->{api_unrated_endpoint} || $global->{api_endpoint}
      || $self->endpoint;
   my $apikey = $global->{api_key} || $self->apikey;

   # Use default callback when none given:
   $cb ||= $self->_cb_request;

   $page ||= 1;
   $maxpage ||= $global->{api_maxpage} || 1;

   my $ua = $self->_ua();
   my $headers = $self->_headers($apikey);

   $api =~ s{^/*}{/}g;
   my $this_max_page;
   while (1) {
      my $path = $endpoint.$api;
      $path .= '/'.url_escape($input) if defined $input;
      my $p = [];
      push @$p, { k => 'k', v => $apikey };
      push @$p, { k => 'page', v => $page } if defined $page;
      push @$p, { k => 'trackquery', v => 'true' } if $global->{api_trackquery};
      push @$p, { k => 'calculated', v => 'true' } if $global->{api_calculated};
      push @$p, { k => 'keepalive', v => 'true' } if $global->{api_keepalive};
      if (defined($params) && ref($params) eq 'HASH' && keys %$params) {
         for my $this (qw(size trackquery calculated keepalive)) {
            next unless defined($params->{$this}) || defined($params->{'api_'.$this});
            push @$p, { k => $this, v => $params->{$this} || $global->{'api_'.$this} };
         }
      }
      my $args = $self->_params($p);
      $path .= $args if $args;
      my $url = Mojo::URL->new($path);

      print STDERR "VERBOSE: Calling API: $path\n" if $self->verbose;

   RETRY:
      my $res;
      eval {
         $res = $ua->get($url => $headers)->result;
      };
      if ($@) {
         chomp($@);
         print STDERR "WARNING: Request API call failed: [$@], retrying...\n" unless $self->silent;
         goto RETRY;
      }
      unless ($res->is_success) {
         my $code = $res->code;
         my $text = $res->json->{text};
         # If code 429, retry with some sleep:
         if ($code == 429) {
            print STDERR "WARNING: Too fast, sleeping before retry...\n" unless $self->silent;
            sleep 1;
            goto RETRY;
         }
         # Otherwise, stops and display error:
         print STDERR "ERROR: Request API call failed: $code, $text\n" unless $self->silent;
         return;
      }

      my $json = $res->json;
      # Fetch max_page value so we can iterate:
      $this_max_page = $self->get_maxpage($json) unless defined $this_max_page;
      if (defined($input) && !$this_max_page) {
         print STDERR "ERROR: Request API call failed, no max_page found\n"
            unless $self->silent;
         print STDERR "VERBOSE: ".Data::Dumper::Dumper($json)."\n" if $self->verbose;
         return;
      }

      my $results = $self->get_results($json);
      if (defined($input) && !@$results) {
         print STDERR "ERROR: Request API call failed, no results found\n"
            unless $self->silent;
         print STDERR "VERBOSE: ".Data::Dumper::Dumper($json)."\n" if $self->verbose;
         return;
      }
      $cb->($results, $cb_args);

      last unless (defined($page) && defined($maxpage));

      last if ($page == $maxpage || $page >= $this_max_page);
      $page++;
   }

   return 1;
}

# $self->post_request('/search', 'protocol:ssh', 1, 10);
# $self->post_request('/simple/datascan', '8.8.8.8');
sub post_request ($self, $api, $input = undef, $page = undef, $maxpage = undef, $params = undef, $cb = undef, $cb_args = undef) {
   my $global = $self->config->{''};
   my $endpoint = $global->{api_unrated_endpoint} || $global->{api_endpoint}
      || $self->endpoint;
   my $apikey = $global->{api_key} || $self->apikey;

   # Use default callback when none given:
   $cb ||= $self->_cb_request;

   $page ||= 1;
   $maxpage ||= $global->{api_maxpage} || 1;

   my $ua = $self->_ua();
   my $headers = $self->_headers($apikey, 'application/x-www-form-urlencoded');

   $api =~ s{^/*}{/}g;
   my $this_max_page;
   while (1) {
      my $path = $endpoint.$api;
      my $p = [];
      push @$p, { k => 'k', v => $apikey };
      push @$p, { k => 'page', v => $page } if defined $page;
      push @$p, { k => 'trackquery', v => 'true' } if $global->{api_trackquery};
      push @$p, { k => 'calculated', v => 'true' } if $global->{api_calculated};
      push @$p, { k => 'keepalive', v => 'true' } if $global->{api_keepalive};
      if (defined($params) && ref($params) eq 'HASH' && keys %$params) {
         for my $this (qw(size trackquery calculated keepalive)) {
            next unless defined($params->{$this}) || defined($params->{'api_'.$this});
            push @$p, { k => $this, v => $params->{$this} || $global->{'api_'.$this} };
         }
      }
      my $args = $self->_params($p);
      $path .= $args if $args;
      my $url = Mojo::URL->new($path);

      print STDERR "VERBOSE: Calling API: $path\n" if $self->verbose;

      $input = url_escape($input) if defined $input;

   RETRY:
      my $res;
      eval {
         $res = $ua->post($url => $headers => form => { query => $input })->result;
      };
      if ($@) {
         chomp($@);
         print STDERR "WARNING: Request API call failed: [$@], retrying...\n" unless $self->silent;
         goto RETRY;
      }
      unless ($res->is_success) {
         my $code = $res->code;
         my $text = $res->json->{text};
         # If code 429, retry with some sleep:
         if ($code == 429) {
            print STDERR "WARNING: Too fast, sleeping before retry...\n" unless $self->silent;
            sleep 1;
            goto RETRY;
         }
         # Otherwise, stops and display error:
         print STDERR "ERROR: Request API call failed: $code, $text\n" unless $self->silent;
         return;
      }

      my $json = $res->json;
      # Fetch max_page value so we can iterate:
      $this_max_page = $self->get_maxpage($json) unless defined $this_max_page;
      if (defined($input) && !$this_max_page) {
         print STDERR "ERROR: Request API call failed, no max_page found\n"
            unless $self->silent;
         print STDERR "VERBOSE: ".Data::Dumper::Dumper($json)."\n" if $self->verbose;
         return;
      }

      my $results = $self->get_results($json);
      if (defined($input) && !@$results) {
         print STDERR "ERROR: Request API call failed, no results found\n"
            unless $self->silent;
         print STDERR "VERBOSE: ".Data::Dumper::Dumper($json)."\n" if $self->verbose;
         return;
      }
      $cb->($results, $cb_args);

      last unless (defined($page) && defined($maxpage));

      last if ($page == $maxpage || $page >= $this_max_page);
      $page++;
   }

   return 1;
}

# $self->user();
sub user ($self, $cb = undef, $cb_args = undef) {
   return $self->request('/user', undef, undef, undef, undef, $cb, $cb_args);
}

# $self->summary('ip', '8.8.8.8');
# $self->summary('domain', 'example.com');
# $self->summary('hostname', 'www.example.com');
sub summary ($self, $api, $oql, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->request('/summary/'.$api, $oql, undef, undef, $params, $cb, $cb_args);
}

# $self->simple('datascan', 'Server: Apache');
# $self->simple('synscan', '8.8.8.8');
sub simple ($self, $api, $oql, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->request('/simple/'.$api, $oql, undef, undef, $params, $cb, $cb_args);
}

# $self->simple_best('geoloc', '8.8.8.8');
# $self->simple_best('inetnum', '8.8.8.8');
# $self->simple_best('threatlist', '8.8.8.8');
# $self->simple_best('whois', '8.8.8.8');
sub simple_best ($self, $api, $oql, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->request('/simple/'.$api.'/best', $oql, undef, undef, $params, $cb, $cb_args);
}

# $self->search('protocol:ssh', 1, 1000);
sub search ($self, $oql, $page = 1, $maxpage = 1, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->request('/search', $oql, $page, $maxpage, $params, $cb, $cb_args);
}

sub post_search ($self, $oql, $page = 1, $maxpage = 1, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->post_request('/search', $oql, $page, $maxpage, $params, $cb, $cb_args);
}

#
# Stream-based APIs
#
sub _cb_stream ($self, $results = undef, $cb_args = undef) {
   return sub ($results, $cb_args) {
      $results = ref($results) eq 'ARRAY' ? $results : [ $results ];
      for (@$results) {
         next if m{.\@category.\s*:\s*.none.};
         print "$_\n";
      }
   };
}

sub _on_read ($self, $cb = undef, $cb_args = undef, $buf = \'') {
   # XXX: handle is_success and render ERROR
   return sub {
      my ($content, $bytes) = @_;
      $bytes = $$buf.$bytes;  # Complete from previously incomplete lines
      my ($this, $tail) = $bytes =~ m/^(.*\n)(.*)$/s;
      # One line is not complete, add to buf and go to next:
      if (!defined($this)) {
         $buf = \$bytes;
      }
      else {  # Lines complete, process them
         $buf = defined($tail) ? \$tail : \'';
         my $results = [ split(/\n/, $this) ];
         return $cb->($results, $cb_args);
      }
   };
}

# $self->stream('GET', '/export', 'protocol:ssh');
# $self->stream('POST', '/bulk/whois/best/ip', '/tmp/ip.txt');
sub stream ($self, $method, $api, $input, $params = undef, $cb = undef, $cb_args = undef) {
   my $global = $self->config->{''};
   my $endpoint = $global->{api_unrated_endpoint} || $global->{api_endpoint}
      || $self->endpoint;
   my $apikey = $global->{api_key} || $self->apikey;

   # Use default callback when none given:
   $cb ||= $self->_cb_stream;

   my $ua = $self->_ua();
   my $headers = $self->_headers($apikey);

   my $path = $endpoint.$api;
   unless (-f $input) {
      $path .= '/'.url_escape($input);   # Build with OQL string
   }

   my $p= [];
   push @$p, { k => 'k', v => $apikey };
   push @$p, { k => 'trackquery', v => 'true' } if $global->{api_trackquery};
   push @$p, { k => 'calculated', v => 'true' } if $global->{api_calculated};
   push @$p, { k => 'keepalive', v => 'true' } if $global->{api_keepalive};
   if (defined($params) && ref($params) eq 'HASH' && keys %$params) {
      for my $this (qw(size trackquery calculated keepalive)) {
         next unless defined($params->{$this}) || defined($params->{'api_'.$this});
         push @$p, { k => $this, v => $params->{$this} || $global->{'api_'.$this} };
      }
   }
   my $args = $self->_params($p);
   $path .= $args if $args;

   print STDERR "VERBOSE: Calling API: $path\n" if $self->verbose;

   my $url = Mojo::URL->new($path);

   my $buf = '';  # Will store incomplete lines for later processing
   my $tx = $ua->build_tx($method => $url => $headers);
   # Replace "read" events to disable default content parser:
   $tx->res->content->unsubscribe('read')->on(read => $self->_on_read($cb, $cb_args, \$buf));

   if (-f $input) {  # POST file content
      print STDERR "VERBOSE: Reading file: $input\n" if $self->verbose;
      $tx->req->content->asset(Mojo::Asset::File->new(path => $input));
   }

   # Process transaction:
   return $ua->start($tx);
}

sub post_stream ($self, $method, $api, $input, $params = undef, $cb = undef, $cb_args = undef) {
   my $global = $self->config->{''};
   my $endpoint = $global->{api_unrated_endpoint} || $global->{api_endpoint}
      || $self->endpoint;
   my $apikey = $global->{api_key} || $self->apikey;

   # Use default callback when none given:
   $cb ||= $self->_cb_stream;

   my $ua = $self->_ua();
   my $headers = $self->_headers($apikey, 'application/x-www-form-urlencoded');

   my $path = $endpoint.$api;
   $input = url_escape($input);   # Build with OQL string

   my $p= [];
   push @$p, { k => 'k', v => $apikey };
   push @$p, { k => 'trackquery', v => 'true' } if $global->{api_trackquery};
   push @$p, { k => 'calculated', v => 'true' } if $global->{api_calculated};
   push @$p, { k => 'keepalive', v => 'true' } if $global->{api_keepalive};
   if (defined($params) && ref($params) eq 'HASH' && keys %$params) {
      for my $this (qw(size trackquery calculated keepalive)) {
         next unless defined($params->{$this}) || defined($params->{'api_'.$this});
         push @$p, { k => $this, v => $params->{$this} || $global->{'api_'.$this} };
      }
   }
   my $args = $self->_params($p);
   $path .= $args if $args;

   print STDERR "VERBOSE: Calling API: $path\n" if $self->verbose;

   my $url = Mojo::URL->new($path);

   my $buf = '';  # Will store incomplete lines for later processing
   my $tx = $ua->build_tx($method => $url => $headers => form => { query => $input });
   # Replace "read" events to disable default content parser:
   $tx->res->content->unsubscribe('read')->on(read => $self->_on_read($cb, $cb_args, \$buf));

   if (-f $input) {  # POST file content
      print STDERR "VERBOSE: Reading file: $input\n" if $self->verbose;
      $tx->req->content->asset(Mojo::Asset::File->new(path => $input));
   }

   # Process transaction:
   return $ua->start($tx);
}

sub _check_file ($self, $file) {
   unless (-f $file) {
      print STDERR "ERROR: file not found: $file\n" unless $self->silent;
      return;
   }
   return $file;
}

# $self->bulk_summary('ip', '/tmp/ip.txt');
# $self->bulk_summary('domain', '/tmp/domain.txt');
# $self->bulk_summary('hostname', '/tmp/hostname.txt');
sub bulk_summary ($self, $api, $file, $params = undef, $cb = undef, $cb_args = undef) {
   return unless $self->_check_file($file);
   $api =~ s{^/*}{/}g;
   return $self->stream('POST', '/bulk/summary'.$api, $file, $params, $cb, $cb_args);
}

# $self->bulk_simple('ctl', '/tmp/ip.txt');
# $self->bulk_simple('resolver', '/tmp/ip.txt');
sub bulk_simple ($self, $api, $file, $params = undef, $cb = undef, $cb_args = undef) {
   return unless $self->_check_file($file);
   $api =~ s{^/*}{/}g;
   return $self->stream('POST', '/bulk/simple'.$api.'/ip', $file, $params, $cb, $cb_args);
}

# $self->bulk_simple_best('threatlist', '/tmp/ip.txt');
# $self->bulk_simple_best('whois', '/tmp/ip.txt');
sub bulk_simple_best ($self, $api, $file, $params = undef, $cb = undef, $cb_args = undef) {
   return unless $self->_check_file($file);
   $api =~ s{^/*}{/}g;
   return $self->stream('POST', '/bulk/simple'.$api.'/best/ip', $file, $params, $cb, $cb_args);
}

# $self->bulk_discovery('datascan', '/tmp/oql.txt');
# $self->bulk_discovery('domain', '/tmp/oql.txt');
# $self->bulk_discovery('domain', '/tmp/oql.txt', $oql);
sub bulk_discovery ($self, $api, $file, $oql = undef, $params = undef, $cb = undef, $cb_args = undef) {
   return unless $self->_check_file($file);
   $api =~ s{^/*}{/}g;
   my $input = $file;
   # Rewrite to another file when oql is given:
   my ($fh, $filename);
   if (defined($oql)) {
      my @lines = read_file($file);
      ($fh, $filename) = tempfile();
      $input = $filename;
      for (@lines) {
         chomp;
         my $line = "$_ $oql";
         utf8::encode($line);
         print $fh "$line\n";
      }
      close($fh);
   }
   $self->stream('POST', '/bulk/discovery'.$api.'/asset', $input, $params, $cb, $cb_args);
   unlink($filename) if defined($filename) && -f $filename;
   return 1;
}

# $self->export('protocol:ssh');
sub export ($self, $oql, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->stream('GET', '/export', $oql, $params, $cb, $cb_args);
}

sub post_export ($self, $oql, $params = undef, $cb = undef, $cb_args = undef) {
   return $self->stream('POST', '/export', $oql, $params, $cb, $cb_args);
}

#
# Alert API
#
sub _cb_alert ($self, $results = undef, $cb_args = undef) {
   return sub ($results, $cb_args) {
      $results = ref($results) eq 'ARRAY' ? $results : [ $results ];
      for (@$results) {
         print $self->encode($_)."\n";
      }
   };
}

sub alert ($self, $method, $api, $name, $oql, $email, $threshold = 0, $cb = undef, $cb_args = undef) {
   my $global = $self->config->{''};
   my $endpoint = $global->{api_unrated_endpoint} || $global->{api_endpoint}
      || $self->endpoint;
   my $apikey = $global->{api_key} || $self->apikey;

   # Use default callback when none given:
   $cb ||= $self->_cb_alert;

   my $ua = $self->_ua();
   my $headers = $self->_headers($apikey);

   $api =~ s{^/*}{/}g;

   my $path = $endpoint.$api;
   $path .= '?k='.$apikey;

   print STDERR "VERBOSE: Calling API: $path\n" if $self->verbose;

   my $url = Mojo::URL->new($path);

   my $post;
   $post->{name} = $name if defined $name;
   $post->{query} = $oql if defined $oql;
   $post->{email} = $email if defined $email;
   $post->{threshold} = $threshold if defined $threshold;

   my @args = ( $url => $headers );
   @args = ( $url => $headers => json => $post ) if defined $post;

   #print STDERR "DEBUG: args: ".Data::Dumper::Dumper(\@args)."\n";

RETRY:
   my $res;
   eval {
      $res = $ua->$method(@args)->result;
   };
   if ($@) {
      chomp($@);
      print STDERR "WARNING: Alert API call failed: [$@], retrying...\n" unless $self->silent;
      goto RETRY;
   }
   unless ($res->is_success) {
      my $code = $res->code;
      my $text = $res->json->{text};
      # If code 429, retry with some sleep:
      if ($code == 429) {
         print STDERR "WARNING: Too fast, sleeping before retry...\n" unless $self->silent;
         sleep 1;
         goto RETRY;
      }
      # Otherwise, stops and display error:
      print STDERR "ERROR: Alert API call failed: $code, $text\n" unless $self->silent;
      return;
   }

   my $json = $res->json;
   $cb->($json, $cb_args);

   return 1;
}

# $self->alert_list();
sub alert_list ($self, $cb = undef, $cb_args = undef) {
   return $self->alert('get', '/alert/list', undef, undef, undef, undef, $cb, $cb_args);
}

# $self->alert_add('test', 'category:datascan protocol:ssh', 'email@example.com', '>1000');
sub alert_add ($self, $name, $oql, $email, $threshold = undef, $cb = undef, $cb_args = undef) {
   if ($self->verbose) {
      print STDERR "VERBOSE: name: [$name]\n";
      print STDERR "VERBOSE: oql: [$oql]\n";
      print STDERR "VERBOSE: email: [$email]\n";
      print STDERR "VERBOSE: threshold: [$threshold]\n" if defined $threshold;
   }
   return $self->alert('post', '/alert/add', $name, $oql, $email, $threshold, $cb, $cb_args);
}

# $self->alert_del(0);
sub alert_del ($self, $id, $cb = undef, $cb_args = undef) {
   return $self->alert('post', '/alert/del/'.$id, undef, undef, undef, undef, $cb, $cb_args);
}

#
# On-demand APIs:
#
sub _cb_ondemand ($self, $results = undef, $cb_args = undef) {
   return sub ($results, $cb_args) {
      $results = ref($results) eq 'ARRAY' ? $results : [ $results ];
      for (@$results) {
         print $self->encode($_)."\n";
      }
   };
}

sub ondemand ($self, $method, $api, $param, $post, $cb = undef, $cb_args = undef) {
   my $global = $self->config->{''};
   my $endpoint = $global->{api_ondemand_endpoint} || $self->endpoint;
   my $apikey = $global->{api_ondemand_key} || $self->apikey;

   # Use default callback when none given:
   $cb ||= $self->_cb_ondemand;

   my $ua = $self->_ua();
   my $headers = $self->_headers($apikey);

   $api =~ s{^/*}{/}g;

   my $path = $endpoint.$api;
   $path .= '?k='.$apikey;

   if (defined($param)) {
      $post->{maxscantime} = $param->{maxscantime} if defined $param->{maxscantime};
      $post->{urlscan} = $param->{urlscan} ? 'true' : 'false' if defined $param->{urlscan};
      $post->{vulnscan} = $param->{vulnscan} ? 'true' : 'false' if defined $param->{vulnscan};
      $post->{import} = $param->{import} ? 'true' : 'false' if defined $param->{import};
   }

   print STDERR "VERBOSE: Calling API: $path\n" if $self->verbose;

   my $url = Mojo::URL->new($path);

   my @args = ( $url => $headers );
   @args = ( $url => $headers => json => $post ) if defined $post;

   #print STDERR "DEBUG: args: ".Data::Dumper::Dumper(\@args)."\n";

RETRY:
   my $res;
   eval {
      $res = $ua->$method(@args)->result;
   };
   if ($@) {
      chomp($@);
      print STDERR "WARNING: Ondemand API call failed: [$@], retrying...\n" unless $self->silent;
      goto RETRY;
   }
   unless ($res->is_success) {
      my $code = $res->code;
      #print Data::Dumper::Dumper($res->body)."\n";
      my $text = $res->json->{text};
      # If code 429, retry with some sleep:
      if ($code == 429) {
         print STDERR "WARNING: Too fast, sleeping before retry...\n" unless $self->silent;
         sleep 1;
         goto RETRY;
      }
      # Otherwise, stops and display error:
      print STDERR "ERROR: Ondemand API call failed: $code, $text\n" unless $self->silent;
      return;
   }

   my $json = $res->json;
   $cb->($json, $cb_args);

   return 1;
}

sub ondemand_scope_ip ($self, $target, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('post', '/ondemand/scope/ip/single', $param, { ip => $target }, $cb, $cb_args);
}

sub ondemand_scope_domain ($self, $target, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('post', '/ondemand/scope/domain/single', $param, { domain => $target }, $cb, $cb_args);
}

sub ondemand_scope_ip_bulk ($self, $file, $param = undef, $cb = undef, $cb_args = undef) {
   if (! -f $file) {
      print STDERR "ERROR: Ondemand Scope Ip Bulk needs a file as input\n"
         unless $self->silent;
   }

   my @lines = read_file($file);
   for (@lines) { chomp };
   unless (@lines) {
      print STDERR "ERROR: Ondemand Scope Ip Bulk needs a file with content\n"
         unless $self->silent;
   }

   my $target = join(',', @lines);

   return $self->ondemand('post', '/ondemand/scope/ip/bulk', $param, { ip => $target }, $cb, $cb_args);
}

sub ondemand_scope_domain_bulk ($self, $file, $param = undef, $cb = undef, $cb_args = undef) {
   if (! -f $file) {
      print STDERR "ERROR: Ondemand Scope Domain Bulk needs a file as input\n"
         unless $self->silent;
   }

   my @lines = read_file($file);
   for (@lines) { chomp };
   unless (@lines) {
      print STDERR "ERROR: Ondemand Scope Domain Bulk needs a file with content\n"
         unless $self->silent;
   }

   my $target = join(',', @lines);

   return $self->ondemand('post', '/ondemand/scope/domain/bulk', $param, { domain => $target }, $cb, $cb_args);
}

sub ondemand_scope_result ($self, $scan_id, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('get', '/ondemand/scope/result/'.$scan_id, $param, undef, $cb, $cb_args);
}

sub ondemand_resolver_ip ($self, $target, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('post', '/ondemand/resolver/ip/single', $param, { ip => $target }, $cb, $cb_args);
}

sub ondemand_resolver_domain ($self, $target, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('post', '/ondemand/resolver/domain/single', $param, { domain => $target }, $cb, $cb_args);
}

sub ondemand_resolver_hostname ($self, $target, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('post', '/ondemand/resolver/hostname/single', $param, { hostname => $target }, $cb, $cb_args);
}

sub ondemand_resolver_result ($self, $scan_id, $param = undef, $cb = undef, $cb_args = undef) {
   return $self->ondemand('get', '/ondemand/resolver/result/'.$scan_id, $param, undef, $cb, $cb_args);
}

1;

__END__

=head1 NAME

Onyphe::Api - ONYPHE API

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, ONYPHE

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
