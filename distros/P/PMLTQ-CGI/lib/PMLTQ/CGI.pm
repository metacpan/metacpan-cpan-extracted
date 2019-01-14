package PMLTQ::CGI;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::CGI::VERSION = '2.0.1';
# ABSTRACT: [DEPRECATED] This is html fronted for SQLEvaluator and is currently being replaced by PMLTQ::Server

use 5.006;
use strict;
use warnings;
use Treex::PML;
use Treex::PML::Instance;
use Treex::PML::Schema;
use Encode;
use PMLTQ::Common ':tredmacro';
use PMLTQ::SQLEvaluator;
use Benchmark;
use URI;
use File::Spec;
use File::Glob qw(:glob);
use Digest::MD5 qw(md5_hex);
use Carp;
use UNIVERSAL::DOES;

use MIME::Types;
use LWP::UserAgent;
use HTTP::Request;
use File::Temp;
use JSON;
use YAML ();

my $ua = LWP::UserAgent->new;
$ua->agent("Tree_Query_CGI/1.0 ");

my $conf;
my $URL_BASE = '';
my $APP_PREFIX = 'app';
my $DEBUG=0;
our $HELP_URI = q{http://ufal.mff.cuni.cz/pmltq/doc/pmltq_doc.html};
our $PMLTQ_PROJECT_URI = q{http://ufal.mff.cuni.cz/pmltq/index.html};
my $log_dir='.pmltq_cgi_log';
my $tmp_dir;

my $static_dir = undef;

# print STDERR "XHTML: $CGI::XHTML\n";
# $CGI::XHTML=0;

my $tree_print_service;
my $nodes_to_query_service;
my $pid_file;
my $pid_dir;
my $title = "PML Tree-Query Engine";
my $desc=Treex::PML::Factory->createStructure;
my $auth_file;
my $service_id;
my $use_google_translate;
my $use_ms_translate;

my $ga_tracking_code;
my $ga_tracking_domain;

use vars qw($PAST_QUERIES_SCRIPT);



sub Configure {
  my ($opts)=@_;
  croak("Usage: Configure({...})\n") unless ref($opts) eq 'HASH';

  if ($opts->{debug}) {
    print STDERR "Reading configuration from $opts->{'config-file'}\n";
  }

  if ($opts->{'method-prefix'}) {
    $URL_BASE = $opts->{'method-prefix'};
    $URL_BASE .= '/' unless $URL_BASE=~m{/$};
  }
  if ($opts->{'app-prefix'}) {
    $APP_PREFIX = $opts->{'app-prefix'};
    $APP_PREFIX=~s{/$}{};
  }

  # directory for static content
  $static_dir = $opts->{'static-dir'};
  if (! $static_dir) {
    die "Static content directory not given!\nUse $0 --static-dir <dir-name>\n"
  } elsif (! -d $static_dir) {
    die "Static content directory '$static_dir' does not exist!\n";
  }

  # configuration
  my $cfg_root = Treex::PML::Instance->load({ filename=>$opts->{'config-file'} })->get_root;
  my $configs = $cfg_root->{configurations};
  $tree_print_service = $cfg_root->{tree_print_service};
  $nodes_to_query_service = $cfg_root->{nodes_to_query_service};

  # configuration id
  my $id = $service_id  = $opts->{'server'} || 'cgi-default';
  $conf = first { $_->{id} eq $id } map $_->value, grep $_->name eq 'dbi', SeqV($configs);
  die "Didn't find server configuration named '$id' in $opts->{'config-file'}!\nUse $0 --list-servers and then $0 --server <name>\n"
    unless $conf;
  $DEBUG=1 if $opts->{debug};

  if (defined($conf->{resources})) {
    Treex::PML::AddResourcePath($conf->{resources}->values);
  }

  # query log dir
  if ($opts->{'query-log-dir'}) {
    $log_dir=$opts->{'query-log-dir'};
  }

  if ($opts->{'tmp-dir'}) {
    $tmp_dir=$opts->{'tmp-dir'};
  } else {
    $tmp_dir=File::Temp::tempdir()
  }

  $pid_dir = $opts->{'pid-dir'};
  $desc = $conf->{'description'} || Treex::PML::Factory->createStructure();
  if ($pid_dir and -d $pid_dir) {
    $pid_file = File::Spec->catfile($pid_dir, "pmltq_cgi_$$.$id");
    my $fh;
    if (open ($fh, '>:utf8', $pid_file)) {
      if ($conf->{public}) {
        print $fh ($opts->{'port'}."\n");
        for my $k (qw(title abstract moreinfo)) {
          my $v = $desc->{$k} || '';
          $v=~tr{\n}{ };
          print $fh "$v\n";
        }
        print $fh ($conf->{'featured'}."\n");
  print $fh ($conf->{'anonymous_access'}||''."\n");
        close($fh);
      }
    }
  }

  $auth_file = $opts->{'auth-file'};
  update_auth_info() if $auth_file;

  $use_google_translate = $opts->{'google-translate'};
  $use_ms_translate = $opts->{'ms-translate'};

  $ga_tracking_code = $opts->{'ga-tracking-code'};
  $ga_tracking_domain = $opts->{'ga-tracking-domain'};

}

sub configuration {
    $conf || {};
}


# read authorization data from the auth-file

my %auth_data;
my $last_auth_file_mtime;
sub update_auth_info {
  my $mtime = [stat $auth_file]->[9];
  if (!defined($last_auth_file_mtime) or
      $mtime != $last_auth_file_mtime) {
    %auth_data=();
    print STDERR scalar(localtime).": (Re)loading AUTH information\n";
    $last_auth_file_mtime=$mtime;
    if (open my $af, '<', $auth_file) {
      local $_;
      while (<$af>) {
        chomp if defined($_);
        s{^\s*|\s*$|#.*}{}g;
        next unless length;
        my ($user,$passwd,$selection)=split m{\s*:\s+},$_,3;
        next unless length($user) and length($passwd);
        my $data = $auth_data{$user}={};
        if ($selection) {
          my %s; my $bool = $1 if $selection=~s{^\s*([-+])}{};
          @s{ split m{\s*,\s*}, $selection } = ();
          if (defined($bool) and $bool eq '-') {
            $data->{deny}=\%s;
            next if exists $s{ $service_id }
          } else {
            $data->{allow}=\%s;
            next if !exists $s{ $service_id }
          }
        } else {
          # complete access
          $data->{deny}={};
        }
        $data->{passwd}=$passwd;
      }
      close $af;
    } else {
      print STDERR "Failed to read AUTH information!\n";
    }
  }
}


# this method returns (401,"") for unknown user
# and (200,$password) for a known user.
sub auth {
  my ($url,$user)=@_;
  update_auth_info();
  my $data=$auth_data{$user};
  my $passwd = $data && $data->{passwd};
  unless (defined $passwd) {
    print STDERR scalar(localtime).": denied AUTH to $user for $url: code 401.\n";
    return ("401", "");
  }
  print STDERR scalar(localtime).": accepted AUTH from $user for $url\n";
  return ("200",$passwd);
}

# check if the current HTTP user is authorized for a given service
sub user_authorized {
  my ($cgi,$id)=@_;
  return 1 unless $auth_file;
  my $user = _user_name($cgi);
  my $data = $auth_data{$user};
  return 0 unless ref $data;
  if (ref($data->{allow})) {
    return exists($data->{allow}{$id}) ? 1 : 0;
  }
  if (ref $data->{deny}) {
    return exists($data->{deny}{$id}) ? 0 : 1;
  }
  return 1;
}

# auxiliary method used to generate a HTML description of a given list
# of services
sub _print_service_info {
  my ($cgi,$services)=@_;
  my $format = $cgi->param('format');
  my $current;
  my $uri = URI->new($cgi->url(-base=>1));
  update_auth_info();
  unless ($services) {
    $services=[{
      id => $service_id,
      access => user_authorized($cgi,$service_id)||$conf->{anonymous_access}||0,
      service => $uri,
      title => $desc->{title},
      abstract => $desc->{abstract},
      moreinfo => $desc->{moreinfo},
      featured => $conf->{featured},
      anonymous_access => $conf->{anonymous_access}||0,
    }];
    $current = 1;
  }

  # use current host, but change the port number
  for (@$services) {
    next if $_->{service};
    my $u = URI->new($uri);
    $u->port(delete $_->{port});
    $_->{service} = $u;
  }
  if ($format eq 'html') {
    my $i=0;
    print(
      $cgi->header(-charset => 'UTF-8'),
      $cgi->start_html({-title=>($current ? 'About This PML-TQ Service' : 'Available PML-TQ Services'),
                        -encoding => 'UTF-8',
                        -style => {
                          -type => 'text/css',
                          -src => $URL_BASE.'static/css/query.css'
                         },

                      }),
      _title($cgi,$current ? 'about' : 'other'),
      $cgi->div({-class => 'content'},
                (map {
                  $i++;
                  $cgi->div({-class => 'service'},
                            $cgi->div({ -class => 'hh', id=>"hh$i" },
                            $cgi->h3(
                            (($current or !$_->{access}) ? () :
                               $cgi->a({href=>"javascript:document.qf.action='$_->{service}';document.qf.submit()"},
                                                 'Select')),
                              $_->{title},
                                     $cgi->a({class=>"show",
                                               onClick=>"document.getElementById('hh$i').setAttribute('class','hs'); return false;"
                                             },"&raquo;"),
                            $cgi->a({class=>"hide",
                                               onClick=>"document.getElementById('hh$i').setAttribute('class','hh'); return false;"
                                             },"&laquo;")),
                                      $cgi->div({ -class => 'hbody' },
                                                $cgi->div({ -class => 'abstract' },
                                                          $cgi->p($_->{abstract}),
                                                          ($_->{moreinfo}
                                                             ? $cgi->p($cgi->a({href=>"$_->{moreinfo}", target=>"_blank"},
                                                                               'More info ...'))
                                                               : ()),
                                                         )
                                               ),
                            )
                           )
                }  @$services)),
      $cgi->end_html()
     );
  } elsif ($format eq 'json') {
    print $cgi->header(-type => 'text/x-json',
                       -charset=>'UTF-8'
                      );
    print(qq{[},
          join(",", map {
            my $s=$_;
            qq[\n  {]
            .join(",", map {
              qq{\n    \"}
                ._js_escape_string($_)
                .q{" : "}
                ._js_escape_string($s->{$_})
              .q{"}
            } sort keys %$s)
            .qq[\n  }]
          } @$services),
          qq{\n]\n});
  } else {
    print($cgi->header(-type=>'text/plain',
                       -charset=>'UTF-8'));
    my ($v,$s);
    print(map {
            $s=$_;
            join("\t", map {
              $v=$s->{$_};
              $v=~s{\s+}{ }g;
              qq{$_:$v}
            } sort keys %$s)
            .qq[\n]
          } @$services);
  }
}

sub _dump_all_info {
    my ($cgi)=@_;
    my $format = $cgi->param('format')||'text';
    $format = 'text' if $format eq 'html';
    my $ev = eval { init_evaluator() };
    if ($@) {
      print STDERR "INIT: $@\n";
      return $@;
    }
    my %dump;
    my $schema_names = $ev->get_schema_names();
    my $node_types = $ev->get_node_types();
    $dump{schema_names} = $schema_names;
    my %node_types = map { $_ => $ev->get_node_types($_) } @$schema_names;
    $dump{node_types} = \%node_types;

    $dump{relations} = {
        standard => \@{PMLTQ::Common::standard_relations()},
        pml => { },
        user => { },
    };
    foreach my $type (@$node_types) {
        my $types = $ev->get_pmlrf_relations($type);
        if (@$types) {
            $dump{relations}->{pml}->{$type} = $types;
        }
    }
    foreach my $type (@$node_types) {
        my $types = $ev->get_user_defined_relations($type);
        if (@$types) {
            $dump{relations}->{user}->{$type} = $types;
        }
    }

    my %attributes = map {
        my @res;
        my $type = $_;
        my $decl = $ev->get_decl_for($_);
        if ($decl) {
            @res = map { my $t = $_; $t=~s{#content}{content()}g; $t } $decl->get_paths_to_atoms({ no_childnodes => 1});
            if (@{PMLTQ::Common::GetElementNamesForDecl($decl)}) {
                unshift @res, 'name()';
            }
        }
        @res?($type => \@res):()
    } @$node_types;
    $dump{attributes} = \%attributes;

    $dump{doc} = generate_doc($ev);

    if ($format eq 'json') {
        print $cgi->header(-type => 'text/x-json',
                           -charset=>'UTF-8'
                       );
        my $json = JSON->new->allow_nonref;
        print $json->pretty->encode(\%dump);
    } else { ## dump text for everything else
        print($cgi->header(-type=>'text/plain',
                           -charset=>'UTF-8'));
        print YAML::Dump(\%dump);
    }
}

# logout a given user
sub logout_user {
  my ($user)=@_;
  print STDERR "logging out $user\n";
  if (-d $pid_dir) {
    for my $session_file (glob(File::Spec->catfile($pid_dir,'session_'.$user.'-*'))) {
      unlink $session_file
    }
  }
}

# generate a new session ID for a given user
sub generate_session_id {
  my $session_id = '';
  $session_id.=sprintf("%02x",int(rand(256))) for 0..15;
  return $session_id;
}

# generate a HTML redirect response to a given URL with URL params
sub redirect {
  my ($cgi,$to,$params)=@_;
  my $url = URI->new($to);
  $params = {
    (map {
      my $val = $cgi->param($_);
      defined($val) ? ($_ => $val) : ()
    } $cgi->param()),
    %{$params||{}}
   };
  $url->query_form($params);
  print STDERR "Redirecting to $url\n";
  print $cgi->header(-Location => $url->as_string);
  return 303;
}


sub app {
  my $callback=shift;
  my $cgi=shift;
  if (!defined $callback) {
    return 404;
  }
  if (session_ok($cgi) or $conf->{anonymous_access}) {
    return $callback->($cgi);
  } else {
    print STDERR "No or invalid session\n";
    return redirect($cgi,qq{login});
  }
}


sub resp_login {
  my ($cgi)=@_;
  my $user = _user_name($cgi);
  return 403 unless user_name_string_ok($user);
  return 403 unless -d $pid_dir;

  my $session_file_base = File::Spec->catfile($pid_dir,'session_'.$user.'-');
  print STDERR "logging in $user\n";
  print STDERR $session_file_base,"\n";

  my @session_files = glob($session_file_base.'*');
  my $session_id;
  if (@session_files) {
    $session_id=$session_files[0];
    $session_id=~s{^.*-}{}g;
    unless (session_id_string_ok($session_id)) {
      logout_user($user);
      undef $session_id;
    }
  }
  unless ($session_id) {
    $session_id = generate_session_id();
    my $session_file = $session_file_base.$session_id;
    print STDERR "Creating session file $session_file\n";
    open(my $fh, '>', $session_file) || return 403;
    print $fh ("$$\t$user\t".localtime()."\n");
    close $fh;
  }
  return redirect($cgi,qq{form},{u=>$user,s => $session_id});
}

sub session_id_string_ok {
  my ($id)=@_;
  return (($id =~/^[a-z0-9]+$/) ? 1 : 0);
}
sub user_name_string_ok {
  my ($user)=@_;
  return 0 if $user eq 'unknown';
  return (($user=~/^[a-zA-Z0-9_.]+$/) ? 1 : 0);
}

# check if the session ID provided in the s and u arguments
# is vallid (backed by a session file in the pid-dir and not expired)
sub session_ok {
    my ($cgi)=@_;
    #  return 1 unless $auth_file;
    my ($session_id,$user)=($cgi->param('s'), $cgi->param('u'));
    if ($session_id and $user and session_id_string_ok($session_id)
            and user_name_string_ok($user) and (-d $pid_dir)) {
        my $session_file = File::Spec->catfile($pid_dir,'session_'.$user.'-'.$session_id);
        if (-f $session_file) {
            update_auth_info();
            if (user_authorized($cgi,$service_id)) {
                my $now = time();
                if (($now-(stat($session_file))[9])<259_200) { # two days
                    print STDERR "Session ok.\n";
                    utime $now, $now, $session_file;
                    return 1;
                } else {
                    print STDERR "Session expired.\n";
                    logout_user($user);
                }
            }
        }
    }

    return 0;
}

# faster form of session_ok... just doesn't check session expiration
sub logged_in {
    my ($cgi)=@_;
    my ($session_id,$user)=($cgi->param('s'), $cgi->param('u'));
    if ($session_id and $user and session_id_string_ok($session_id)
            and user_name_string_ok($user) and (-d $pid_dir)) {
        return 1;
    }
    return 0;
}

sub is_anonymous {
    my ($cgi)=@_;
    return !logged_in($cgi) && $conf->{anonymous_access};
}

sub resp_root {
  my ($cgi)=@_;
  if (session_ok($cgi) or $conf->{anonymous_access}) {
    return redirect($cgi,qq{$APP_PREFIX/${URL_BASE}form});
  } else {
    return redirect($cgi,qq{$APP_PREFIX/${URL_BASE}login});
  }
}

sub resp_about {
  my ($cgi)=@_;
  my $ext = $cgi->param('extended')?1:0;
  _print_service_info($cgi) unless $ext;
  _dump_all_info($cgi) if $ext;
  return 200;
}

sub resp_other_services {
    my ($cgi)=@_;
    my @services;

    # read all pid filesa
    update_auth_info();
    if (-d $pid_dir) {
        for my $file (glob(File::Spec->catfile($pid_dir,"pmltq_cgi_*.*"))) {
            open(my $fh, '<', $file) or next;
            my $port = <$fh>;
            next unless defined $port;
            chomp $port;
            next unless $port;
            my $title = <$fh>;
            $title=~s{\s+}{ }g;
            $title=~s{^ | $}{}g;
            my $abstract = <$fh>;
            $abstract=~s{\s+}{ }g;
            $abstract=~s{^ | $}{}g;
            my $moreinfo = <$fh>; chomp $moreinfo;
            my $featured = <$fh>; chomp $featured;
            my $anonymous_access = <$fh>; chomp $anonymous_access;
            if ($port) {
                my (undef, $id) = split m{\.}, $file,2;
                push @services, {
                    id => $id,
                    port => $port,
                    title => $title,
                    abstract => $abstract,
                    moreinfo => $moreinfo,
                    featured => $featured,
                    access => user_authorized($cgi,$id)||$anonymous_access||0,
                    anonymous_access => $anonymous_access||0,
                    service => undef,
                };
            }
        }
    }
    @services = sort {
        $b->{access} <=> $a->{access} or
            ($a->{featured}||10000) <=> ($b->{featured}||10000) or
                ($a->{title}||'') cmp ($b->{title}||'') or
                    $a->{port} <=> $b->{port} } @services;
    _print_service_info($cgi,\@services);
    return 200;
}

sub _user_name {
  my ($cgi)=@_;
  my $user = $cgi->remote_user || $cgi->param('u') || 'unknown';
  $user=~y{/!#'"*~$^&()[]\{\}\.\+\|}{_}; # sanity
  return $user;
}

sub log_query {
  my ($cgi,$query)=@_;
  $query=~s{^\s+|\s+$}{}g;
  my $md5 = md5_hex($query);
  my $user = _user_name($cgi);
  my $log_string = sprintf("query: time='%s' remote_user='%s' auth='%s' remote_host='%s' port='%s' srv_version='%s'\n",
                           scalar(localtime()), $user, $cgi->auth_type||'',
                           $cgi->remote_host, $cgi->server_port, $PMLTQ::SQLEvaluator::VERSION );
  print STDERR $log_string;
  return unless $log_dir and logged_in($cgi);
  if (!(-d $log_dir) and !(mkdir($log_dir))) {
    warn "Failed to create query log dir: $log_dir: $!\n";
    return;
  }
  my $user_log_dir = File::Spec->catdir($log_dir,$user);
  if (!(-d $user_log_dir) and !(mkdir($user_log_dir))) {
    warn "Failed to create query user log dir: $user_log_dir: $!\n";
    return;
  }
  my $log_file = File::Spec->catfile($user_log_dir,$md5.".txt");
  if (!-f $log_file) {
    if (open my $log, '>', $log_file) {
      print STDERR "query_log_file:", $log_file,"\n";
      print $log "# log: ".$log_string;
      print $log $query;
      close $log;
    } else {
      warn "Failed to create query log file: $log_file: $!\n";
    }
  } else {
    my $now = time;
    utime $now, $now, $log_file;
  }
}

sub _js_escape_string {
  my $str=join '',@_;
  $str=~s{([\\'"])}{\\$1}g;
  $str=~s{\n}{\\n}g;
  return $str;
}


sub resp_past_queries {
  my ($cgi)=@_;
  my $format = $cgi->param('format');
  my $callback = $cgi->param('cb');
  my $max = $cgi->param('max');
  my $first = $cgi->param('first');
  if ($format eq 'html') {
    print
      $cgi->header(-charset => 'UTF-8'),
      $cgi->start_html(-title => $title,
                       -encoding => 'UTF-8',
                       -style => {
                         -type => 'text/css',
                         -src => $URL_BASE.'static/css/query.css'
                        },
                       -script => [
                         {
                           -type => 'text/javascript',
                           -src => $URL_BASE.'static/js/common.js',
                         },
                         {
                           -type => 'text/javascript',
                           -code => $PAST_QUERIES_SCRIPT,
                         },
                        ],
                      ),
      _title($cgi,'past_queries');
  } elsif ($format eq 'json') {
    print $cgi->header(
      -type => ($callback ? 'text/javascript' : 'text/x-json'),
      -charset => 'UTF-8',
     );
    print $callback ? $callback.'([' : '[';
  } else {
    print $cgi->header(
      -type => 'text/plain',
      -charset => 'UTF-8'
     );
  }
  return 200 unless logged_in($cgi); # ignore past queries for anonymous users

  my $user = _user_name($cgi);
  my $user_log_dir = File::Spec->catdir($log_dir,$user);
  if ($log_dir and (-d $user_log_dir)) {
    my $id = 0;
    print $cgi->start_div({-class => 'content'});
    my @queries = map { $_->[0] } sort { $b->[1]<=>$a->[1] } map { [$_, ((stat($_))[9])] } glob(File::Spec->catfile($user_log_dir,'*.txt'));
    my $count = scalar(@queries);
    $max ||= ($format eq 'html' ? 50 : $count);
    $first||=1;
    my $last = ($first+$max-1>$count ? $count-1 : $first+$max-2);
    for my $f (@queries[($first-1)..$last]) {
      $id++;
      open my $fh, '<', $f;
      scalar( <$fh> ); # skip 1st line
      local $/;
      if ($format eq 'html') {
        print $cgi->div(
          {-class => 'past_queries'},
          $cgi->div({-class => 'past_queries_head'},scalar localtime(((stat($fh))[9])),
                    $cgi->a({href=>"javascript:edit('q$id')"},'Edit'),
                    $cgi->a({href=>"javascript:run('q$id')"},'Run'),
                   ),
          $cgi->pre({id=>"q$id"},$cgi->escapeHTML(<$fh>)));
      } elsif ($format eq 'json') {
        print '[',((stat($fh))[9]),",'",_js_escape_string(<$fh>),"'],\n";
      } else {
        print <$fh>,"\n\n";
      }
      close $fh;
    }
    if ($first>1 or @queries>$max) {
      print $cgi->div('Past querires from ', ($first-1),' to ',$last);
      print $cgi->div(_generate_range_index($cgi,scalar(@queries),$first,$max,"javascript:goto(%d)",{}));
    }
    print $cgi->end_div();
  }
  if ($format eq 'html') {
    print $cgi->end_html;
  } elsif ($format eq 'json') {
    print ($callback ? ']);' : ']');
  }
  return 200;
}

sub _generate_range_index {
  my ($cgi, $count, $first, $max, $href_format,$a_opts)=@_;
  $a_opts||={};
  my $i=1;
  my @ret;
  push @ret, $cgi->a({href=>sprintf($href_format,1),%$a_opts},'<<'),' ';
  push @ret, $cgi->a({href=>sprintf($href_format,$first-1),%$a_opts},'<'),' ' if $first>1;
  if ($first > 5*$max) {
    $i=$first-5*$max;
    push @ret,' ... ';
  }
  for (1..10) {
    last if $i>$count;
    if ($i <= $first and $first < $i+$max) {
      push @ret, $cgi->b( $i ),' ';
    } else {
      push @ret, $cgi->a({href=>sprintf($href_format,$i),%$a_opts},$i),' ';
    }
    $i+=$max;
  }
  if ($i<$count) {
    push @ret,' ... ';
  }
  push @ret, $cgi->a({href=>sprintf($href_format,$first+$max),%$a_opts},'>'),' ' if $first+$max<=$count;
  push @ret, $cgi->a({href=>sprintf($href_format,$count-$max+1),%$a_opts},'>>'),' ';
  return @ret;
}

sub _param_form {
  my ($cgi,$type)=@_;
  return (
    $cgi->start_form(
      { -method => 'POST',
        -name => 'qf',
        -action => $URL_BASE.'form'}),
    $cgi->input({name=>'format',value=>'html',type=>'hidden'}),
    $cgi->input({name=>'back_to',value=>$type,type=>'hidden'}),
    ($type eq 'past_queries'
       ? $cgi->input({name=>'first',value=>scalar($cgi->param('first')),type=>'hidden'})
       : ()
    ),
    (map {
        $cgi->input({
          name => $_,
          value => scalar($cgi->param($_)),
          type => 'hidden',
        })
      } grep {
        !/^(query_submit|back_to|_.*|first|format)$/
      } $cgi->param()),
    $cgi->end_form,
   );
}

sub _start_query_form {
  my ($cgi)=@_;
  return (
    $cgi->start_form(-method => 'POST',
                     -name => 'qf',
                     -onSubmit=>"show_loading(); return true",
                     -action => $URL_BASE.'query'),
    $cgi->input({name=>'format',value=>'html',type=>'hidden'}),
    $cgi->input({name=>'row_limit',value=>'limit',type=>'hidden'}),
    $cgi->input({name=>'back_to',value=>'form',type=>'hidden'}),
    (map {
      $cgi->input({
        name => $_,
        value => scalar($cgi->param($_)),
        type => 'hidden',
       })
    } grep {!/^(query|back_to|first|format|limit|timeout|_.*|query_submit)$/} $cgi->param()),
    $cgi->start_div({-class => 'query'}),
   );
}

sub _query_textarea {
  my ($cgi)=@_;
  return
    $cgi->div({-style=>'width:99%', -class=>'qmenubar'},
              $cgi->div(
                {-style=>'float:right'},
                'Limit: '.$cgi->popup_menu(-name=>"limit",
                                           -default=>(scalar($cgi->param('limit'))||100),
                                           -values => [1,10,100,1000,10000]),
                'Timeout: '.$cgi->popup_menu(-name=>"timeout",
                                             -default=>(scalar($cgi->param('timeout'))||30),
                                             -values => [20,30,45,60,90,120,200,300])
               ).
              $cgi->start_div({-id => 'qm'}).$cgi->end_div()
             ).
    # $cgi->pre({-id => 'qp', -style=>'width:99%'},'foo').
    $cgi->fieldset({style=>'clear:both'},
    $cgi->div({-class => 'query-area'},
    $cgi->textarea(
      -id => 'queryTA',
      -name => 'query',
      -default => "# Enter your query here\n",
      -style => 'font-size: 7pt',
      -rows => 2,
      -accesskey => 'e',
      -onFocus => 'this.rows=12;this.style.fontSize="10pt"; return true;',
      -onBlur => <<'EOJS',
var t=this;
setTimeout(
  function(){
    if (t) {
      if (isMenuButtonActive()) {
        setOnDeactivate( function(inserting){ if (t && !inserting) t.rows=2; t.style.fontSize="7pt"; } )
      } else { t.rows=2; t.style.fontSize="7pt"; }
    }
  } ,200);
return true;
EOJS
      # -columns => 80,
     )));
}

sub _end_query_form {
  my ($cgi)=@_;
  return (
#   $cgi->end_div(),
   $cgi->endform(),
  );
}

sub _query_form {
  my ($cgi,$text)=@_;
  return (
    _start_query_form($cgi),
    _toolbar_text($cgi,$text),
    _end_query_form($cgi),
   )
}
{
  my $evaluator;
  sub init_evaluator {
    unless ($evaluator) {
      $evaluator = PMLTQ::SQLEvaluator->new(undef,{
        connect => $conf,
        debug=>$DEBUG,
      });
      $evaluator->connect();
    }
    return $evaluator;
  }
}

sub search {
  my ($query,%opts)=@_;
  my $evaluator;
  my $sth;
  my $no_distinct = ($opts{node_limit} and abs($opts{node_limit})<=10_000) ? 1 : 0;
  eval {
    $evaluator = init_evaluator();
    my $qt = $evaluator->prepare_query($query,{
      node_limit => $opts{node_limit},
      row_limit => $opts{row_limit},
      select_first => $opts{select_first},
      node_IDs => ($tree_print_service ? 1 : 0),
      no_filters => $opts{no_filters},
      use_cursor => $opts{use_cursor},
      no_distinct => $no_distinct,
      timeout => $opts{timeout},
      debug_sql => $opts{debug},
    }); # count=>1
#    if ($opts{display_tree}) {
#      undef $qt;
#    } else {
      undef $qt;
#    }
    if ($DEBUG) {
      print STDERR "[BEGIN_SQL]=================================================\n";
      my $sql = $evaluator->get_sql;
      Encode::_utf8_off($sql);
      print STDERR $sql,"\n";
      print STDERR "[END_SQL]=================================================\n";
    }
    $sth = $evaluator->run({
      node_limit => $opts{node_limit},
      row_limit => $opts{row_limit},
      timeout => $opts{timeout},
      use_cursor => $opts{use_cursor},
      return_sth=>1,
    });
  };
  my $err = $@;
  if ($err) {
    print STDERR "[BEGIN_SQL]=================================================\n";
    my $sql = $evaluator->get_sql;
    Encode::_utf8_off($sql);
    print STDERR $sql,"\n";
    print STDERR "[END_SQL]=================================================\n";

    if ($opts{use_cursor}) {
      $evaluator->close_cursor();
    }
    print STDERR "ERROR [ $err ]\n";
    if ($err =~ /\tTIMEOUT\t/) {
      return "Evaluation of query exceeded specified maximum time limit of $opts{timeout} seconds\n";
    }
    $err =~ s{\bat \S+ line \d+.*}{}s;
    return "$err";
  } else {
    return ($sth,$evaluator->{returns_nodes},$evaluator->get_query_nodes,$evaluator);
  }
}

sub _html_editor_menu {
  my $ret = "
   var menu = [\n";
  my $evaluator = eval { init_evaluator() };
  if ($evaluator) {
    my $node_types = $evaluator->get_node_types();
    $ret .=
      "['Relations',0,[\n";
    $ret .= "  ['Standard',0,[\n"
      . join(',', map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\"$v \");']" }
             @{PMLTQ::Common::standard_relations()})
      . "  ]],\n";

    $ret .= "  ['PML Reference',0,[\n";
    foreach my $type (@$node_types) {
      my $types = $evaluator->get_pmlrf_relations($type);
      if (@$types) {
        $ret .= "    ['$type',0,[\n".
          join (',', map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\"$v \");']" } @$types)
        . "    ]],\n";
      }
    }
    $ret .= "  ]],\n";

    $ret .= "  ['Other',0,[\n";
    foreach my $type (@$node_types) {
      my $types = $evaluator->get_user_defined_relations($type);
      if (@$types) {
        $ret .= "    ['$type',0,[\n".
          join (',',map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\"$v \");']" } @$types)
        . "    ]],\n";
      }
    }
    $ret .= "  ]],\n";
    $ret .= "]],\n";

    my $schema_names = $evaluator->get_schema_names;
    $ret .=
      "['Node Types',0,[\n"
      . join(',',
             map {
               my $nt = $evaluator->get_node_types($_);
               my $l = $_; $l=~s/'/\\'/g;
               (
                 qq{['',2,'<small>Layer $l</small>']},
                 (map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\"$v [ ]\");']" }
                    @$nt, (@$schema_names == 1 ? '*' : $l.':*')),
               )
             } @$schema_names
            )
      . "]],\n";

    $ret .=
      "['Attributes',0,[\n";
    foreach my $type (@$node_types) {
      my @res;
      my $decl = $evaluator->get_decl_for($type);
      if ($decl) {
        @res = map { my $t = $_; $t=~s{#content}{content()}g; $t } $decl->get_paths_to_atoms({ no_childnodes => 1 });
        if (@{PMLTQ::Common::GetElementNamesForDecl($decl)}) {
          unshift @res, 'name()';
        }
      }
      if (@res) {
        $ret .= "    ['of $type',0,[\n".
          join (',',map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\"$v \");']" } @res)
        . "    ]],\n";
      }
    }
    $ret .= "]],\n";

    my %operators = (
      Logical => [qw{and or !}, ','],
      Comparison => [qw{= ~ ~* < > >= <= != !~ !~* },'in {..., ...}'],
      Arithmetical => [qw{+ - * div mod}],
      String => [qw{&}],
      Misc => [qw{() [] := >> . '...' "..."}],
     );
    $ret .=
      "['Operators',0,[\n";
    for my $type (sort keys %operators) {
      $ret .= "    ['$type',0,[\n".
        join (',',map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\" $v \");']" } @{$operators{$type}})
          . "    ]],\n";
    }
    $ret .= "]],\n";


    my %functions = (
      Strings => [
      'lower(STR)',
      'upper(STR)',
      'length(STR)',
      'substr(STR,OFFSET,LEN?),',
      'tr(STR,CHARS_TO_REPLACE,REPLACEMENT_CHARS)',
      'replace(STR,SUBSTR,REPLACEMENT)',
      'substitute(STR,REGEXP,REPLACEMENT,FLAGS?)',
      'match(STR,REGEXP,FLAGS?)',
      ],
      Numeric => [
      'ciel(NUM)',
      'floor(NUM)',
      'round(NUM,PLACES?)',
      'trunc(NUM,PLACES?)',
      'percnt(NUM)',
      'abs(NUM)',
      'sqrt(NUM)',
      'exp(NUM)',
      'ln(NUM)',
      'power(BASE?,NUM)',
      'log(BASE?,NUM)',
      ],
      'Node Properties' => [
        'descendants(NODE?)',
        'lbrothers(NODE?)',
        'rbrothers(NODE?)',
        'sons(NODE?)',
        'depth_first_order(NODE?)',
        'depth(NODE?)',
        'name(NODE?)',
        'type_of(NODE?)',
        'file(NODE?)',
        'tree_no(NODE?)',
        'address(NODE?)',
       ],
      'Conditional' => [
        'first_defined(VALUE2,VALUE2,...)',
        'if(CONDITION,VALUE_IF_TRUE,VALUE_IF_FALSE)',
       ],
      Group => [
        'avg(EXP? [over COLUMNS...])',
        'count([over COLUMNS...])',
        'min(EXP? [over COLUMNS...])',
        'max(EXP? [over COLUMNS...])',
        'sum(EXP? [over COLUMNS...])',
        'concat(EXP, SEPARATOR [over COLUMNS... sort by COLUMNS...])',
        'ratio(EXP? [over COLUMNS...])',
        'rank([over COLUMNS... sort by COLUMNS...])',
        'dense_rank([over COLUMNS... sort by COLUMNS...])',
        'row_number([over COLUMNS... sort by COLUMNS...])',
      ],
     );

    $ret .=
      "['Functions',0,[\n";
    for my $type (sort keys %functions) {
      $ret .= "    ['$type',0,[\n".
        join (',',map { my $v=$_; $v=~s/'/\\'/g; "    ['$v',1,'javascript:ins(\"$v\");']" } @{$functions{$type}})
          . "    ]],\n";
    }
    $ret .= "]],\n";

  }
  $ret .= "];\n";
  $ret .= <<'EOF';
function m_init () {
  document.getElementById('qm').innerHTML = build_menu(menu, 'menu', 'menuBar');
}
EOF

  return $ret;
}


sub resp_form {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  print(
    $cgi->header(-charset=>'UTF-8'),
    $cgi->start_html(-title => $title,
                     -encoding => 'UTF-8',
                     -style => [{
                       -type => 'text/css',
                       -src => $URL_BASE.'static/css/query.css'
                      },{
                       -type => 'text/css',
                       -src => $URL_BASE.'static/menubar/menu.css'
                      }],
                     -script => [{
                         -type => 'text/javascript',
                         -src => $URL_BASE.'static/js/common.js',
                       },{
                         -type => 'text/javascript',
                         -src => $URL_BASE.'static/menubar/menu.js',
                       },{
                         -type => 'text/javascript',
                         -code => eval { _html_editor_menu() } || '',
                       }],
                     -onLoad => "m_init();hide_loading();"
                    ),
    _title($cgi,'form'),
    _query_form($cgi),
    intro($cgi),
    $cgi->end_html
   );
  return 200;
}

sub _error_form {
  my ($cgi)=@_;
  return (_query_form($cgi),_error_html(@_));
}
sub _error_html {
  my ($cgi,$head,$message)=@_;
  warn($message);
  $message=~s/\(DBD ERROR:.*//s;
  $message = $cgi->escapeHTML($message);
  $message=~s/\n/<br>\n/g;
  $cgi->div({-class=>'error', id=>'error'},
            $cgi->h2($head), $cgi->font({-size => -1}, $message));
}


sub resp_query {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $query = decode_utf8($cgi->param('query'));
  my ($format,$limit,$row_limit,$timeout, $query_submit) =
    map scalar($cgi->param($_)), qw(format limit row_limit timeout query_submit);
  my $no_filters = $query_submit =~ m{w/o} ? 1 : 0;
  $format = 'html' unless (defined($format) and length($format));
  unless (defined($query) and length($query)) {
    if ($format eq 'html') {
      return resp_form($cgi);
    } else {
      print $cgi->header(-type=>'text/plain',
                         -charset=>'UTF-8',
                        );
      print "ERROR\n";
      print "Query was empty!\n";
      return 400;
    }
  }

  log_query($cgi,$cgi->param('query')); # DON'T USE $query here, we need non-UTF8-decoded form
  print STDERR "CGI: TIMEOUT ".(defined($timeout) ? $timeout : '')
    .", NODE LIMIT  ".(defined($limit) ? $limit : '')
    ." ROW LIMIT ".(defined($row_limit) ? $row_limit : '')."\n"
      if $DEBUG;
  $limit = 100 unless (defined($limit) and length($limit));
  $limit=int($limit);
  if ($row_limit eq 'limit') {
    $row_limit = $limit
  }
  $row_limit = 1000 unless (defined($row_limit) and length($row_limit));
  $row_limit=int($row_limit);
  $timeout = 30 unless (defined($timeout) and length($timeout));
  $timeout=int($timeout);
  $timeout = 300 if $timeout>300;
  print STDERR "USING: TIMEOUT $timeout, NODE LIMIT $limit, ROW LIMIT $row_limit\n"
    if $DEBUG;
  unless ($format=~/^(html|text)$/) {
    resp_error($cgi,"Wrong format requested!\n");
    return 400;
  }
  my ($sth,$returns_nodes,$query_nodes,$evaluator) = search(
    $query,
    node_limit => $limit,
    row_limit  => $row_limit,
    timeout    => $timeout,
    no_filters => $no_filters,
    use_cursor => 1,
    debug_sql => ($DEBUG && ($query =~ /^#\s*DEBUG=1\s/) ? 1 : 0),
  );

  $limit=abs($limit);
  $row_limit=abs($row_limit);
#  $format='text';
  if ($format eq 'html') {
    my $have_trees = ($returns_nodes and
       $tree_print_service
         and
           ref($sth) and !$sth->err) ? 1 : 0;
    my $js_code = eval {
      _html_editor_menu()
    };
    my $err = $@;
    if ($returns_nodes) {
      $js_code .= "\n result_nodes=".(eval{node_ids_js($cgi,$evaluator)})."\n";
      if ($@) {
        $err.="\n" if $err;
        $err.=$@;
      }
    }
    # warn $err if $err;
    print(
      $cgi->header(-charset=>'UTF-8'),
      $cgi->start_html(-title => $title,
                       -encoding => 'UTF-8',
                     -style => [{
                       -type => 'text/css',
                       -src => $URL_BASE.'static/css/query.css'
                      },{
                       -type => 'text/css',
                       -src => $URL_BASE.'static/menubar/menu.css'
                      }],
                     -script => [{
                         -type => 'text/javascript',
                         -src => $URL_BASE.'static/js/common.js',
                       },{
                         -type => 'text/javascript',
                         -src => $URL_BASE.'static/js/results.js',
                        },
                        {
                          -type => 'text/javascript',
                          -src => $URL_BASE.'static/menubar/menu.js',
                        },
                        ($use_google_translate && $have_trees ?
                           ({
                             -type => 'text/javascript',
                             -src => 'http://www.google.com/jsapi',
                           },
                            {
                              -type => 'text/javascript',
                              -code => 'google.load("language", "1");',
                            }
                           ) : ()),
                        ($use_ms_translate && $have_trees ?
                           ({
                             -type => 'text/javascript',
                             -src => "http://api.microsofttranslator.com/v1/Ajax.svc/Embed?appId=$use_ms_translate",
                           },
                           ) : ()),
                        {
                          -type => 'text/javascript',
                          -code => $js_code,
                        },],
                       (($have_trees) ?
                          (
                            -class=>"tree-results",
                            -onLoad => "m_init();init('".$URL_BASE."', result_nodes,"
                              .'['.join(',',map { $_->{name} ? qq{'$_->{name}'} : qq{''} } @$query_nodes).'])'
                          )
                            : (
                              -class=>"tabular-results",
                              -onLoad => "m_init(); hide_loading();"
                             ))
                      ),
      _title($cgi,'query')
     );
    if (!ref $sth) {
      print (_error_form($cgi,"ERROR",$sth));
    } elsif ($err) {
      print (_error_form($cgi,"INTERNAL SERVER ERROR",$err));
    } elsif ($sth->err) {
      print (_error_form($cgi,"INTERNAL SERVER ERROR", $sth->errstr));
    } else {
      my $count=0;
      if ($returns_nodes and $tree_print_service) {
        print(_start_query_form($cgi),
               _toolbar_trees($cgi),
               _result_tree_div($cgi),
               _end_query_form($cgi));

      } else {
        print _query_form($cgi,"RESULTS (first $row_limit rows)"),
          $cgi->start_center(),
          $cgi->start_div({-class => 'results'}),
          $cgi->start_table({-border => '1px',
                             -rules=>"all",
                             -cellpadding=>"4pt",
                             -class=> 'result-table',
                            });
        my $row;
        while ($row = $evaluator->cursor_next()) {
          Encode::_utf8_off($_) for @$row;
          print $cgi->Tr({-align => 'LEFT', -valign => 'TOP', ($count%2==0 ? (-class=>'odd-row') : ())},
                         $returns_nodes
                           ? $cgi->td([map $cgi->a({href=>$URL_BASE."node?idx=$_"}, $_), @$row])
                             : $cgi->td($row)
                            );
          $count++;
        }

        print $cgi->end_table(),
              $cgi->p("$count ".($returns_nodes ? "OCCURRENCE(S)" : "ROW(S)")),
              $cgi->end_div(),
              $cgi->end_center();
      }
      if ($sth->err) {
        print _error_html($cgi,"ERROR", $sth->errstr);
      }
    }
    print($cgi->end_html);
  } elsif ($format eq 'text') {
    if (!ref $sth) {
      print $cgi->header(-type=>'text/plain',
                         -charset=>'UTF-8',
                        );
      print($sth);
      return 500;
    } elsif ($sth->err) {
      print $cgi->header(-type=>'text/plain',
                         -charset=>'UTF-8',
                        );
      print $sth->errstr;
      return 400;
    } else {
      print $cgi->header(-type=>'text/plain',
                         -charset=>'UTF-8',
                         -pmltq_returns_nodes => $returns_nodes,
                        );
      my $t0 = new Benchmark;
      my $count=0;
      my $row;
      while ($row = $evaluator->cursor_next()) {
        $_ = join("\t",@$row)."\n";
        Encode::_utf8_off($_);
        print;
        $count++;
      }
      my $t1 = new Benchmark;
      print STDERR "Sending $count results took ",timestr(timediff($t1,$t0)),"\n";
      if ($sth->err) {
        print "ERROR\n";
        print $sth->errstr;
        return 400;
      }
    }
  }
  return 200;
}

sub node_ids_js {
  my ($cgi,$evaluator)=@_;
  my $row;
  my @ret;
  eval {
    while ($row = $evaluator->cursor_next()) {
      Encode::_utf8_off($_) for @$row;
      push @ret,('['.join(',',map qq{'$_'}, @$row).']');
    }
  };
  return '['.join(',',@ret).']';
}

sub _report_error {
  my ($err) = @_;
  print STDERR $err;
  $err =~ s{\bat \S+ line \d+.*}{}s;
  print "$err";
  return 500;
}


sub resp_query_svg {
  my ($cgi)=@_;
  my $evaluator;
  my $query = decode_utf8($cgi->param('query'));
  my $tree;
  eval {
    $evaluator = init_evaluator();
    $tree = PMLTQ::Common::parse_query($query,{
      pmlrf_relations => $evaluator->get_pmlrf_relations,
      user_defined_relations => $evaluator->get_user_defined_relations,
    });
    Treex::PML::Document->determine_node_type($_) for ($tree->descendants);
    PMLTQ::Common::CompleteMissingNodeTypes($evaluator,$tree);
  };
  print STDERR $@ if $@;
  my $fh = File::Temp->new(UNLINK=>0, SUFFIX=>'.query.pml', DIR => $tmp_dir);
  my $path = $fh->filename;
  my $pml = PMLTQ::Common::NewQueryFileInstance($path);
  $pml->{'_trees'} = Treex::PML::Factory->createList;
  $pml->get_trees->append($tree);
  $pml->save({ fh => $fh, filename => $path });
  $fh->flush;

  my $url = URI->new($tree_print_service);
  $url->query_form(file => $path, tree_no=>1, sentence=>0, fileinfo=>0, dt=>0, no_cache=>1);
  my $res = $ua->request( HTTP::Request->new(GET => $url) );
  print $cgi->header(
    -type => 'image/svg+xml',# $res->header('Content-Type'),
    -Content_length => $res->header('Content-Length'),
  );
  print $res->content;
  unlink $path;
  return $res->code;
}


sub resp_svg {
  my ($cgi)=@_;
  my @nodes = split(/\|/,$cgi->param('nodes'));
  unless (@nodes) {
    resp_error($cgi,"Error: no nodes requested!\n");
    return 500;
  }
  my $evaluator;
  my ($f) = eval {
    $evaluator = init_evaluator();
    $evaluator->idx_to_pos([$nodes[0]])
  };
  return _report_error($@) if $@;
  my $path;
  my $tree_no=$cgi->param('tree_no');
  print STDERR "Treeno: $tree_no\n";
  if ($f) {
    Encode::_utf8_off($f);
    $tree_no=$1 if ($f=~s{##(\d+)(?:\.\d+)?}{} and $tree_no<=0);
    $path = resolve_data_path($f);
  }
  print STDERR "Treeno: ($f / $path) $tree_no\n";
  if (!defined $path) {
    resp_error($cgi,"Error: $f not found!\n");
    return 404;
  }
  my $url = URI->new($tree_print_service);
  $url->query_form(file => $path,tree_no=>$tree_no,sentence=>1,fileinfo=>1,dt=>1);
#  print STDERR "$url\n";
  my $res = $ua->request( HTTP::Request->new(GET => $url) );
  if ($res->is_success) {
    my $length = $res->header('Content-Length');
    print $cgi->header(
      -type => 'image/svg+xml',# $res->header('Content-Type'),
      -charset => 'UTF-8',
      ($length ? (-Content_length => $length ) : ()),
     );
  } else {
    print $cgi->header(
      -type => $res->header('Content-Type'),
      -charset => 'UTF-8',
     );
  }
  print $res->content;
  return $res->code;
}



sub resp_n2q {
  my ($cgi)=@_;
  my $format = $cgi->param('format');
  my $callback = $cgi->param('cb');
  my @ids = split(/\|/,$cgi->param('ids'));
  my $vars = $cgi->param('vars');
  unless ($nodes_to_query_service) {
    resp_error($cgi,"n2q service not configured!\n");
    return 500;
  }
  unless (@ids) {
    resp_error($cgi,"Error: no IDs requested!\n");
    return 500;
  }
  my $evaluator;
  my @f = eval {
    $evaluator = init_evaluator();
    $evaluator->ids_to_pos(\@ids,1);
  };
  return _report_error($@) if $@;
  foreach my $f (@f) {
    my $path;
    my $goto=$1 if $f=~s{(#.*$)}{};
    if ($f) {
      Encode::_utf8_off($f);
      $path = resolve_data_path($f);
    }
    if (!defined $path) {
      resp_error($cgi,"Error: $f not found!\n");
      return 404;
    }
    $f = $path.$goto;
    print STDERR "Node: $f\n";
  }
  my $url = URI->new($nodes_to_query_service);
  $url->query_form(p=>join('|', @f), ($vars ? (r => $vars) : ()) );
  my $res = $ua->request( HTTP::Request->new(GET => $url) );
  if (!$res->is_success) {
    print $cgi->header(
      -type => $res->header('Content-Type')
     );
    my $content = $res->content;
    print STDERR "n2p: ",$res->code,"\n";
    print STDERR $content,"\n";
    print $content;
  } elsif ($format eq 'json') {
    print $cgi->header(
      -type => ($callback ? 'text/javascript' : 'text/x-json'),
      -charset => 'UTF-8',
     );
    my $js = q{'}._js_escape_string($res->content).q{'};
    $js = $callback.'('.$js.');' if $callback;
    print STDERR $js;
    print $js;
  } else {
    print $cgi->header(
      -type => 'text/plain',
      -charset => 'UTF-8',
     );
    print $res->content;
  }
  return $res->code;
}


sub resp_error {
  my ($cgi,$msg)=@_;
  return 500 if !ref $cgi;
  print STDERR $msg,"\n";
  print(
    $cgi->header(-charset=>'UTF-8'),
    $msg
   );
  return 200;
}

sub locate_file {
  my ($f)=@_;
  my $evaluator = init_evaluator();
  my $schemas = $evaluator->run_sql_query(qq{SELECT "root","data_dir","schema_file" FROM "#PML"},{ RaiseError=>1 });
  for my $schema (@$schemas) {
    for my $what ('__#files','__#references') {
      my $n = $schema->[0].$what;
      next if $n=~/"/;          # just for sure
      print STDERR "testing: $what $n $f\n";
      my $count = $evaluator->run_sql_query(qq{SELECT count(1) FROM "$n" WHERE "file"=?},
                                            {
                                              RaiseError=>1,
                                              Bind=>[ $f ],
                                            }
                                           );
      if ($count->[0][0]) {
        return ($schema->[0], $schema->[1]);
      }
    }
  }
  my $basename = $f; $basename =~ s{.*/}{};
  for my $schema (@$schemas) {
    my $schema_filename = $schema->[2];
    if ($schema_filename eq $f or
        $schema_filename eq $basename or
        ($schema_filename =~ s{.*/}{} and ($schema_filename eq $basename or $schema_filename eq $f))) {
      # assume it is a schema file and return it:
      return ($schema->[0],$schema->[1],$schema->[2]);
    }
  }
  return;
}

sub resolve_data_path {
  my ($f)=@_;
  my ($schema_name,$data_dir,$new_filename) = locate_file($f);
  my $path;
  if (defined($schema_name) and defined($data_dir)) {
    $f = $new_filename if defined $new_filename;
    # print STDERR "SOURCES: $conf->{sources}\n";
    my ($sources) =
      map $_->{'#content'},
      grep { $_->{schema} eq $schema_name }
      grep ref, (UNIVERSAL::DOES::does($conf->{sources},'Treex::PML::Alt') ? @{$conf->{sources}} : $conf->{sources});
    if ($sources) {
      $path = URI::file->new($f)->abs(URI::file->new($sources.'/'))->file;
      print STDERR "F: schema '$schema_name', file: $f, located: $path in configured sources\n";
    } else {
      $path = URI::file->new($f)->abs(URI::file->new($data_dir.'/'))->file;
      print STDERR "F: schema '$schema_name', file: $f, located: $path in data-dir\n";
    }
  } else {
    print STDERR "did not find $f in the database\n";
    my $uri = URI->new($f);
    if (!$uri->scheme) { # it must be a relative URI
      $uri->scheme('file'); # convert it to file URI
      my $file = $uri->file;
      unless (File::Spec->file_name_is_absolute($file) and $file ne 'treebase.conf') { # must be a relative path
        ($path) = Treex::PML::FindInResources($file, {strict=>1});
        if (!defined($path) or $path eq $file) {  # must be in resource dir
          (undef,undef,$file)=File::Spec->splitpath($file);
          ($path) = Treex::PML::FindInResources($file, {strict=>1});
          undef $path if $path and $path eq $file; # must be in resource dir
        }
      }
    }
  }
  return $path;
}



sub resp_data {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $f = $cgi->url(-absolute=>1,-path_info=>1);
  print STDERR "URL: ",$cgi->url(-path_info=>1),"\n";
  $f=~s{^/*(\Q$APP_PREFIX\E/+)?\Q${URL_BASE}\Edata/+}{};
  my $path = resolve_data_path($f);
#  my $path;
#  if ($conf->{sources}) {
#    $f = File::Spec->abs2rel($f,$conf->{sources});
#  }
#  $path = $conf->{sources} ? File::Spec->rel2abs($f,$conf->{sources}) : $f;
#  print STDERR "$path [$f]\t",_have_file($f),"\n";
#  my $have = (_have_file($f) or _have_file($path));
  if (!defined $path) {
    print STDERR "ERROR: $f not found in the database!\n";
    resp_error($cgi,"Object $f not found!");
    return 404;
  } elsif (! (-r $path) ) {
    print STDERR "ERROR: '$path' not readable!\n";
    resp_error($cgi,"Error: object $f not readable!\nPlease notify PML-TQ Engine administrator!");
    return 404;
  } elsif (serve_static_data($cgi,$path,{-type => 'application/octet-stream'})) {
    print STDERR "OK\n";
    return 200;
  } else {
    print STDERR "FAIL: error opening $path: $!\n";
    resp_error($cgi,"Error: could not open $f for reading!\nPlease notify PML-TQ Engine administrator!");
    return 404;
  }
}

sub serve_static_data {
  my ($cgi,$path,$header)=@_;
  $header||={};
  open(my $fh, '<:bytes',$path) or return 0;
  my $content_length = (stat($fh))[7];
  # print "HTTP/1.1 200 OK\015\012";
  print $cgi->header(
#    -charset => 'UTF-8',
    -Content_length => $content_length,
    %$header,
   );
  my $buffer;
  print $buffer while read $fh, $buffer, 16*1024;
  return 1;
}

sub resp_favicon {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $path = URI::file->new('favicon.ico')->abs(URI::file->new($static_dir.'/icons/'))->file;
  if (serve_static_data($cgi,$path,{ -type => 'image/vnd.microsoft.icon' })) {
    return 200;
  } else {
    return 404;
  }
}


my $mt = MIME::Types->new;
sub resp_static {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $f = $cgi->url(-absolute=>1,-path_info=>1);
  print STDERR "STATIC URL: ",$f,"\n";
  $f=~s{^/*(\Q$APP_PREFIX\E/+)?\Q${URL_BASE}\Estatic/}{};
  my $path = URI::file->new($f)->abs(URI::file->new($static_dir.'/'))->file;
  my ($mimetype) = $mt->mimeTypeOf($path);
  if (serve_static_data($cgi,$path,{ -type => $mimetype })) {
    print STDERR "SERVED STATIC: $path as $mimetype\n";
    return 200;
  } else {
    resp_error($cgi,"Static object $f not found!");
    return 404;
  }
}


sub resp_node {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my ($idx,$format) = map $cgi->param($_), qw(idx format);
  my $evaluator;
  my ($f) = eval {
    $evaluator = init_evaluator();
    $evaluator->idx_to_pos([$idx])
  };
  return _report_error($@) if $@;
  Encode::_utf8_off($f);
  $format = 'text' unless (defined($format) and length($format));
  if ($f) {
    if ($format eq 'html') {
      print $cgi->header(-charset=>'UTF-8'),
        $cgi->start_html("Type"),
        $cgi->a({href=>$URL_BASE.'data/'.$f},"$idx"),
        $cgi->end_html();
    } else {
      print($cgi->header(-type=>'text/plain',
                         -charset=>'UTF-8'),
            $f."\r\n");
    }
    return 200;
  } else {
    # resp_error($cgi,"Error resolving $type $idx: $@");
    return 404;
  }
}


sub resp_schema {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $name = $cgi->param('name');
  my ($evaluator,$results);
  eval {
    $evaluator = init_evaluator();
    $results = $evaluator->run_sql_query(
      qq(SELECT "schema" FROM "#PML" WHERE "root" = ? ),
      {
        MaxRows => 1,
        RaiseError => 1,
        LongReadLen => 512*1024,
        Bind => [$name]
       });
  };
  return _report_error($@) if $@;
  my $mimetype='application/octet-stream';
  if (ref($results) and ref($results->[0]) and $results->[0][0]) {
    Encode::_utf8_off($results->[0][0]);
    my $content_length = length($results->[0][0]);
    print $cgi->header(
      -type => $mimetype,
      -Content_length => $content_length
    );
    print $results->[0][0];
    return 200;
  } else {
    print $cgi->header(
      -type => $mimetype,
      -Content_length => 0,
    );
    return 404;
  }
}


sub resp_type {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $type = $cgi->param('type');
  my $format = $cgi->param('format');
  my $evaluator;
  my $name = eval {
    $evaluator = init_evaluator();
    $evaluator->get_schema_name_for($type)
  };
  return _report_error($@) if $@;
  $name ||= '';
  Encode::_utf8_off($name);
  if ($format eq 'html') {
    print
      $cgi->header(-charset=>'UTF-8'),
        $cgi->start_html("Type"),
          $name,
            $cgi->end_html();
  } else {
    print($cgi->header(-type=>'text/plain',
                       -charset=>'UTF-8'),
          $name."\r\n");
  }
  return 200;
}


sub resp_nodetypes {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $format = $cgi->param('format') || 'text';
  my $layer = $cgi->param('layer');
  my $evaluator;
  my $types = eval{
    $evaluator = init_evaluator();
    $evaluator->get_node_types($layer || ());
  };
  return _report_error($@) if $@;
  Encode::_utf8_off($_) for @$types;
  if ($format eq 'text') {
    print($cgi->header(-type=>'text/plain',
                       -charset=>'UTF-8'),
          map "$_\r\n", @$types);
  } else {
    print
      $cgi->header(-charset=>'UTF-8'),
      $cgi->start_html("Node Types"),
        $cgi->table({-border => undef},
                      $cgi->Tr({-align => 'LEFT', -valign => 'TOP'},
                               [ map $cgi->td($_), @$types ])),
            $cgi->end_html();
  }
  return 200;
}


sub resp_relations {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $format = $cgi->param('format') || 'text';
  my $type = $cgi->param('type');
  my $rel_cat = $cgi->param('category');
  my $evaluator = eval { init_evaluator() };
  return _report_error($@) if $@;
  my $relations;
  if ($rel_cat eq 'implementation') {
    $relations = $evaluator->get_user_defined_relations($type);
  } elsif ($rel_cat eq 'pmlrf') {
    $relations = $evaluator->get_pmlrf_relations($type);
  } else {
    $relations = $evaluator->get_specific_relations($type);
  }
  Encode::_utf8_off($_) for @$relations;
  if ($format eq 'html') {
    print
      $cgi->header(-charset=>'UTF-8'),
      $cgi->start_html("Specific relations"),
        $cgi->table({-border => undef},
                      $cgi->Tr({-align => 'LEFT', -valign => 'TOP'},
                               [ map $cgi->td($_), @$relations ])),
            $cgi->end_html();
  } else {
    print($cgi->header(-type=>'text/plain',
                       -charset=>'UTF-8'),
          map "$_\r\n", @$relations);
  }
  return 200;
}


sub resp_relation_target_types {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $format = $cgi->param('format') || 'text';
  my $type = $cgi->param('type');
  my $category = $cgi->param('category');
  my $evaluator = eval{ init_evaluator() };
  return _report_error($@) if $@;
  my @map;
  my %map;
  if ($type) {
    my @maps;
    if (!$category or $category eq 'pmlrf') {
      push @maps, $evaluator->get_pmlrf_relation_map_for_type($type);
    }
    if (!$category or $category eq 'implementation') {
      push @maps, $evaluator->get_user_defined_relation_map_for_type($type);
    }
    for my $map (@maps) {
      for my $rel (sort keys %$map) {
        my $target = $map->{$rel};
        if (defined $target) {
          push @map,[$type,$rel,$target->[2]];
        }
      }
    }
  } else {
    my @maps;
    if (!$category or $category eq 'pmlrf') {
      push @maps, $evaluator->get_pmlrf_relation_map();
    }
    if (!$category or $category eq 'implementation') {
      push @maps, $evaluator->get_user_defined_relation_map();
    }
    for my $map (@maps) {
      for my $node_type (sort keys %$map) {
        my $map2 = $map->{$node_type};
        if ($map2) {
          for my $rel (sort keys %$map2) {
            my $target = $map2->{$rel};
            if (defined $target) {
              push @map,[$node_type,$rel,$target->[2]];
            }
          }
        }
      }
    }
  }
  Encode::_utf8_off($_) for @map;
  if ($format eq 'html') {
    print
      $cgi->header(-charset=>'UTF-8'),
      $cgi->start_html("Target-node types for specific relations"),
        $cgi->table({-border => undef},
                    $cgi->Tr({-align => 'LEFT', -valign => 'TOP'},
                             $cgi->th([qw(node-type relation target-type)])),
                      $cgi->Tr({-align => 'LEFT', -valign => 'TOP'},
                               [ map $cgi->td($_), @map ])),
            $cgi->end_html();
  } else {
    print($cgi->header(-type=>'text/plain',
                       -charset=>'UTF-8'),
          map {join(':',@$_)."\r\n" } @map);
  }
  return 200;
}



sub resp_version {
  my $cgi  = shift;             # CGI.pm object
  return 500 if !ref $cgi;
  my $format = $cgi->param('format') || 'html';
  my $version = $cgi->param('client_version') || '';
  my $evaluator = eval { init_evaluator() };
  return _report_error($@) if $@;
  my $ok = $evaluator->check_client_version($version) ? 'COMPATIBLE' : 'INCOMPATIBLE';
  if ($format eq 'text') {
    print($cgi->header(-type=>'text/plain',
                       -charset=>'UTF-8'),
          $ok."\r\n".$PMLTQ::SQLEvaluator::VERSION
         );
  } else {
    print
      $cgi->header(-charset=>'UTF-8'),
        $cgi->start_html("VERSION"),
        $cgi->p("CLIENT VERSION $version IS $ok"),
        $cgi->p($PMLTQ::SQLEvaluator::VERSION),
        $cgi->end_html();
  }
  return 200;
}

BEGIN {

$PAST_QUERIES_SCRIPT = <<"EOF";
function goto (first) {
   document.qf.first.value = first;
   document.qf.action = 'past_queries';
   document.qf.submit();
}
function edit (id) {
   var el = document.getElementById(id);
   if (el == null) return;
   var query = el.textContent;
   if (query==null) query=el.innerText;
   document.qf.query.value = query;
   document.qf.action = 'form';
   document.qf.submit();
}
function run (id) {
   var el = document.getElementById(id);
   if (el == null) return;
   show_loading();
   var query = el.textContent;
   if (query==null) query = el.innerText;
   document.qf.query.value = query;
   document.qf.action = 'query';
   document.qf.submit();
}
EOF

}

sub _query_tree_div{
  return <<EOF
  <div id="query_tree" style="visibility:hidden">
    <div class="handle">
      <a href="javascript:document.getElementById('query_tree').setAttribute('style','visibility:hidden');">x</a>
    </div>
    <object width="100%" type="image/svg+xml"
            id="query_tree_img" title="Visualization of the Query" alt="query image"></object>
    </div>
  </div>
EOF
}

sub _toolbar_text {
  my ($cgi,$title)=@_;
  $title||='';
  my $query_field = _query_textarea($cgi) || '';
  return <<"EOF" . _query_tree_div();
  <center>
  <div class="toolbar">
  $query_field
  <table rules="none" border="0pt">
    <tr>
      <td align="left" width="40%">
        <input type="submit" accesskey="q" value="&#x21e9; Query" name="query_submit" title="Execute the query (including output filters)" />
        <input type="submit" accesskey="w" value="&#x21e9; w/o Filters" name="query_submit" title="Execute the query, excluding possible output filters" />
        <input type="button" accesskey="v" onclick="show_query_svg()" value="&#x263C; Visualize" name="view_submit" title="Display graphical visualization of the query" />
        <input type="button" accesskey="c" onclick="document.qf.query.value=''; return false;" title="Empty the query form" value="&#x2715; Clear" name="clear" />
      </td>
      <td align="center"><span id="title">$title</span></td>
      <td align="right" width="40%"></td>
    </tr>
  </table>
  </div>
  </center>
EOF
}
sub _toolbar_trees {
  my ($cgi)=@_;
  my $query_field = _query_textarea($cgi);
  my $size = length(int($cgi->param('limit') || 100)) || 4;
  return <<"EOF" . _query_tree_div();
  <center>
  <div class="toolbar">
  $query_field
  <div class="toolbar-controls">
    <span style="float:left">
        <input type="submit" value="&#x21e9; Query" name="query_submit" title="Execute the query (including output filters)" accesskey="q" />
        <input type="submit" value="&#x21e9; w/o Filters " name="query_submit" title="Execute the query, excluding possible output filters" accesskey="w" />
        <input type="button" onclick="node2pmltq()" value="&#x21e7; Suggest" title="Suggest query based on nodes marked by user" name="extract" disabled="disabled" accesskey="s" />
        <input type="button" onclick="show_query_svg()" value="&#x263C; Visualize" name="view_submit" title="Display graphical visualization of the query" accesskey="v" />
        <input type="button" onclick="document.qf.query.value=''; return false;" title="Empty the query form" value="&#x2715; Clear" name="clear" accesskey="c"/>
    </span>
    <span style="float:right; margin-right: 10px;">Result:
        <button type="button" accesskey="p" title="Previous match" onclick="next_tree(-1)">&lt;</button>
        <input type="text" size="$size" maxlength="$size" id="cur_tree" name="_ct" onkeypress="return tree_no_keypress(event, this.value)" value="0" /> of <span id="tree_count">0</span>
        <button type="button" accesskey="n" title="Next match" onclick="next_tree(1)">&gt;</button>
    </span>
    <span class="qnodes" id="q_nodes"></span>
  </div>
  <div style="clear: both; height: 0pt;" ></div>
  <div id="n2p-dlg">
<div id="n2p-hint">
<p>This is a PML-TQ query generated from the marked nodes.  Use the checkboxes
to include/exclude parts of the query.</p>
<p>
Then insert the result to the current query or replace it.
</p>
</div>
<div id="n2p-buttons">
    <button type="button" accesskey="i" title="Insert into query at cursor position" onclick="n2p_insert()">Insert</button>
    <button type="button" accesskey="r" title="Replace current query" onclick="n2p_replace()">Replace</button>
    <button type="button" accesskey="u" title="Clean up disabled parts of the query" onclick="n2p_cleanup()">Clean Up</button>
    <button type="button" accesskey="m" title="Clear marks" onclick="n2p_clear()">Clear Marks</button>
    <button type="button" accesskey="l" title="Close" onclick="n2p_cancel()">Close</button>
</div>
<div id="n2p-query"><table id="n2p-body"></table></div>
  </div>
  </div>
  </center>
EOF
#   return <<"EOF";
#   <center>
#   <div class="toolbar">
#   $query_field
#   <table rules="none" border="0pt">
#     <tr>
#       <td align="left" width="40%">
#         <input type="submit" value="Submit New Query &#x21e9;" name="query_submit" />
#         <small><input type="checkbox" value="1" $no_filters_checked name="no_filters" />  Without filters</small>
#       </td>
#       <td align="center">
#         <span class="qnodes" id="q_nodes"></span>
#       </td>
#       <td align="right" width="40%">
#         Result: <input type="button" accesskey="p" title="Previous match" value="&lt;" onclick="next_tree(-1)" />
#         <span id="cur_tree">0</span> of <span id="tree_count">0</span>
#         <input type="button" accesskey="n" title="Next match" value="&gt;" onclick="next_tree(1)" />
#       </td>
#     </tr>
#   </table>
#   </div>
#   </center>
# EOF
}


sub _result_tree_div {
  my ($cgi)=@_;
  my $tools="";
  return <<"EOF";
  <div class="result-info">
   <span class="zoom-buttons" style="float: right">
        <span id="tools-menu"></span>
        <button class="zoom-button" accesskey="+" title="Zoom in" type="button" onclick="zoom_inc(0.1)">+</button>
        <button class="zoom-button" accesskey="-" title="Zoom out" type="button" onclick="zoom_inc(-0.1)">-</button>
   </span>
   <div id="result-text">
   <span id="context">
     <a class="svg-title" accesskey="9" id="context-tree-before" title="Context (Tree Before)" type="button" href="javascript:next_context_tree(-1)">&lt;</a>
     <span id="tree_offset" class="svg-title">-</span>
     <a class="svg-title" accesskey="0" id="context-tree-after" title="Context (Tree After)" type="button" href="javascript:next_context_tree(1)">&gt;</a>
   </span>
   <span id="title" class="svg-title">Searching...</span>
   <span id="desc" class="desc"></span>
   </div>
 </div>
 <div><div id="tooltip"></div><div id="tree" class="tree" style="width:100%; height:60%; overflow:auto;">
    <object id="svg-tree" width="100%" height="100%" type="image/svg+xml"></object>
 </div>
 </div>
EOF
}

sub _ga_track_code {
    my ($cgi) = @_;
    return <<"EOF";
<script>
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

ga('create', '$ga_tracking_code', '$ga_tracking_domain');
ga('send', 'pageview');
</script>
EOF
}

sub _title {
    my ($cgi,$type)=@_;
    $type ||= 'default';

    return (
        ($ga_tracking_code ? _ga_track_code($cgi) : ()),
        ($cgi->user_agent =~ /MSIE/ ? ($cgi->p({-style=>'color:red; font-weight:bold; font-size:9pt'},"Warning: Internet Explorer detected; your browser may not work correctly, try Mozilla FireFox, Google Chrome, Opera, or Safari")) : ()),
        $cgi->div($cgi->a({href=>'javascript:document.qf.action="form";document.qf.submit()'},
                          $cgi->img({-src=>$URL_BASE."static/icons/pmltq_small.png",
                                     -alt=>"PML Tree-Query Engine",
                                     -style=>"float: left; margin: -5px 5px 0px 5px;",
                                 })),
                  $cgi->img({-src=>$URL_BASE."static/icons/loading_bar.gif", -id => "loading", -class=>"loading-bar",
                             -style => "visibility: ".($type =~ /^(query|form)$/ ? 'visible' : 'hidden'),
                         })),
        $cgi->div({-class=>'top'},
                  $cgi->div(
                      {-class => 'subtitle', -style=>'text-align: right; padding: 5pt;'},
                      $type eq 'past_queries' ?
                          "Previous Queries"
                              : $type eq 'other' ?
                                  "Available Treebanks"
                                      : $type eq 'about' ?
                                          "About This Treebank"
                                              : $cgi->a({href=>'javascript:document.qf.action="about";document.qf.submit()'}, ($desc->{title}||''))),
                  $cgi->span({-style=>'float: right'},
                             (($type eq 'past_queries' or $type eq 'other' or $type eq 'about')
                                  ? (
                                      _param_form($cgi,$type),
                                      $cgi->a({href=>'javascript:document.qf.action="'.($cgi->param('back_to')||'form').'";document.qf.submit()'},"Back")," ")
                                      : ()
                                  ),
                             ((!is_anonymous($cgi) and $type ne 'past_queries') ?
                                  ($cgi->a({href=>'javascript:document.qf.action="past_queries";document.qf.submit()'},"Previous Queries"), " ") : ()),
                             (($type ne 'other') ?
                                  ($cgi->a({href=>'javascript:document.qf.action="other";document.qf.submit()'},"Select Treebank")," ") : ()),
                             $cgi->a({href=>$HELP_URI, target=>"_blank"},"Documentation"),
                             " ",
                             $cgi->a({href=>$PMLTQ_PROJECT_URI, target=>"_blank"},"Project Page"),
                             (!session_ok($cgi) ? $cgi->a({href=>qq{/$APP_PREFIX/${URL_BASE}login}},"Login") : ())
                         ),
                  $cgi->div({-style=>'clear:both;'},''),
              ),
    );
}

my $INTRO;
sub intro {
  my ($cgi)=@_;
  unless ($INTRO) {
    $INTRO = INTRO();

    my $ev = eval { init_evaluator() };
    if ($@) {
      print STDERR "INIT: $@\n";
      return $@;
    }
    my $schema_names = $ev->get_schema_names;
    my $layers = '<ul>'.join('',map { '<li style="padding-bottom: 6pt;">Layer <b><tt>'.$_.'</tt></b> consists of node types:<br />'.
                                        join(', ',map qq{<b><tt>$_</tt></b>},@{$ev->get_node_types($_)})
                                          .' (wildcard <b><tt>'.(@$schema_names == 1 ? '*' : $_.':*' ).'</b></tt>)'
                                            .'</li>' } @$schema_names).'</ul>';
    $INTRO =~ s/\%layers\%/$layers/g;
    my $title = $desc->{title};
    $title=~s{\(.*?\)}{}g;
    $title=~s{,?\s*(?:Oracle|PostgreSQL|Postgres|DB2)\s*$}{};
    $INTRO =~ s/\%title\%/$title/g;

    my $doc = generate_doc($ev);

    $INTRO =~ s/\%node\%/$doc->{type}/g;
    $INTRO =~ s/\%layer\%/$doc->{layer}/g;
    $INTRO =~ s/\%attr\%/$doc->{attr}/g;
    $INTRO =~ s/\%value\%/$doc->{value}/g;

    $INTRO =~ s{\%try\%}{<button style="float:right" class="try-button" title="Try" type="button" onclick="try_example(this.parentNode)">Try</button>}g;
  }

  my $copy = $INTRO;
  my $user = _user_name($cgi);

  if ($user ne 'unknown') {
      $user=~s{([[:lower:]])([[:upper:]])}{$1 $2}g;
      $copy =~ s/\%user\%/ $user/g;
  } else {
      $copy =~ s/\%user\%//g;
  }
  return $copy;
}

sub generate_doc {
    my ($ev) = @_;
    my @aux;
    my %doc;
 SCHEMA:
    for my $layer (@{$ev->get_schema_names}) {
        for my $type (@{$ev->get_node_types($layer)}) {
            my $decl = $ev->get_decl_for($type) || next;
            for my $attr (map { my $t = $_; $t=~s{#content}{content()}g; $t }
                              map $_->[0],
                          sort { $a->[1]<=>$b->[1] or $a->[0] cmp $b->[0] }
                              map [$_,scalar(@aux = m{/}g) ],
                          $decl->get_paths_to_atoms({ no_childnodes => 1 })) {
                my $mdecl = $decl->find($attr,1);
                next if $mdecl->get_role();
                $mdecl=$mdecl->get_knit_content_decl unless $mdecl->is_atomic;
                next if ($mdecl->get_decl_type == PML_CDATA_DECL and $mdecl->get_format eq 'PMLREF');

                $doc{layer} = $layer;
                $doc{type} = $type;
                $doc{attr} = $attr;
                $doc{value} = '...some value...';

                my ($sth) =
                    search(qq{$type \$n:=[ $attr=$attr ]>>\$n.$attr}, select_first => 1);
                if (ref($sth) and !$sth->err) {
                    my $row = $sth->fetch;
                    Encode::_utf8_off($row->[0]);
                    $doc{value} = $row->[0];
                }
                last SCHEMA;
            }
        }
    }

    return \%doc;
}


sub INTRO {
q@
<div id="quick_intro">
    <h2>Welcome%user%!</h2>
    <div class="note">This quick introduction to PML-TQ is semi-automatically generated
    and covers the most basic topics only. See the <a target="_blank" href="http://ufal.mff.cuni.cz/~pajas/pmltq/doc/pmltq_doc.html">Documentation</a> for full reference. You can always return to this help
by clicking the logo.
    </div>
    <h3>Using This Interface</h3>
    <p>Type your query into the text box above. The menus allow you to insert
       special strings into the query, such as node types, attribute names,
       node relations, operators, and functions.
       <span class="guibutton">&#x21e9; Query</span> sends the query to the server and displays the results.
       Complex or low-selective queries may take a few seconds to evaluate; the <b>Timeout</b> option
       specifies maximum time the server should spend trying to evaluate the query.
       The <span class="guibutton">&#x21e9; w/o Filters</span> button submits the query without
       any <a href="#output-filters">output filters</a> (see below).
       The <span class="guibutton">&#x263C; Visualize</span> button
       shows visualization of the query.
    </p>
    <p>It is also possible to add result nodes to the query:
         run some simple query to display a tree from the treebank. Then
         mark (by clicking) one or more related nodes in the result tree
         and press <span class="guibutton">&#x21e7; Suggest</span>; a PML-TQ query based
         on the marked nodes will be suggested and displayed in
         a dialog where you can exclude/include its parts and then
         paste it directly to the query text box.</p>
       <p>The button <span class="guibutton">&#x2715; Clear</span> empties the query form.</p>
    <h3>Annotation Schema of %title%</h3>
    <p><b>This treebank</b>, consists of the following <b>annotation layer(s)</b> and <b>node type(s)</b>:
    </p>
    %layers%
    <h3>Query Language</h3>
    <p>A basic <b>query</b> for nodes of the type, say <tt>%node%</tt>, looks like this:</p>
    <pre class="programlisting" id="example-1">%try%%node% [ ]</pre>
    <p>Similarly for other node types and node-type wildcards.</p>
    <p><b>Contstraints</b> on the node go between the square brackets [...].
    Basic constraints on <b>attribute</b> values have the following forms:</p>
    <table>
      <tr><td><tt><i>attribute</i> = '<i>value</i>'</tt></td>
          <td>string comparison</td>
      </tr>
      <tr><td><tt><i>attribute</i> ~ '<i>reg-exp</i>'</tt></td>
          <td>regular expression match</td>
      <tr><td><tt><i>attribute</i> &lt; number</tt></td>
          <td>number comparison, same for >, &lt;=, >=, =</td>
      <tr><td><tt><i>attribute</i> in {'<i>value1</i>', '<i>value2</i>', ...}</tt></td>
        <td>membership in an enumeration</td>
    </table>
    <p>For example:</p>
    <pre class="programlisting" id="example-2">%try%%node% [ %attr%='%value%' ]</pre>
    <p>
      See the <span class="guimenu">Attributes</span> menu for the list of attributes for each node type.
    </p>
    <p>Other <b>node properties</b>, such as number of sons, descendants, siblings, etc.
    can be obtained using functions (see <span class="guimenu">Funcions</span> &raquo; <span class="guimenuitem">Node Properties</span>).
    In fact, <b>complex expressions</b> can be used on left and right hand side of
    the comparison operators in constraints; see the menus
    <span class="guimenu">Operators</span> and
    <span class="guimenu">Funcions</span> for available arithmetic and string operators
    and functions.</p>
    <p>The constraints can be combined using commas (<tt>and</tt>)
    or the logical operators
    <tt>!</tt> (not), <tt>and</tt>, <tt>or</tt> (see also the <span class="guimenu">Operators</span> menu). For example:
    </p>
    <pre class="programlisting" id="example-3">%try%%node% [ %attr%='%value%', sons()=0 or lbrothers()+rbrothers()=0  ]</pre>
    <p>searches for any  %node% with %attr%='%value%' that is either
     a leaf node (has no sons) or an only child (has no left nor right siblings).</p>
    <p>To introduce another node into the query, include it among the constrains and
     specify its <b>relation</b> to the existing node.
     The <span class="guimenu">Relation</span> menu contains a list list of available relations.
     Here a is an example using the relation 'child':
    </p>
    <pre class="programlisting" id="example-4">%try%%node% [
  %attr%='%value%',
  child %node% [ ]
]</pre>
  <p><b>Additional relations</b> between a pair of nodes can be specified by assigning <b>symbolic names</b>
     to the query nodes. The names can be used also to refer to
     other node's attributes, e.g.</p>
     <pre class="programlisting"  id="example-5">%try%%node% $a := [
  sibling %node% [
     depth-first-follows $a,
     %attr%=$a.%attr%,
  ]
]</pre>
<p>searches for any %node% $a with a sibling %node% having the same value of %attr%
and following the node $a. We may also search for any %node% with no such sibling, using a so called <b>subquery</b>
by quantifying the number of occurrences:</p>
     <pre class="programlisting" id="example-6">%try%%node% $a := [
  0x sibling %node% [
     depth-first-follows $a,
     %attr%=$a.%attr%,
  ]
]</pre>
<p>The symbol <literal>0x</literal>, stands for `zero times'.
Similarly, <literal>1x</literal> stands for `exactly one', <literal>3+x</literal> for `three and more',
<literal>2-x</literal> for `at most two', or <literal>1..10x</literal> for `one to ten'.</p>
    <h3>Output Filters</h3>
  <a name="output-filters" ></a>
  <p>To count number of all matches of a query, append an output filter, e.g.</p>
      <pre class="programlisting" id="example-7">%try%%node% [ ]
>> count()</pre>
  <p>Be careful when counting matches for queries with more than one node,
     To count only distinct occurrences of a particular node, say <tt>$a</tt>, regardless of the other nodes
     in the query, use these output filters instead:</p>
     <pre class="programlisting">
>> distinct $a
>> count()</pre>
      <p>Output filters are used to extract data and generate a tabular output from a query.
      For example, the following query lists all values of the attribute %attr%
      and counts their occurrences:
      <pre class="programlisting" id="example-7">%try%%node% $a:= [ ]
>> for $a.%attr% give $1, count()</pre>
     </p>

    See the <a target="_blank" href="http://ufal.mff.cuni.cz/~pajas/pmltq/doc/pmltq_doc.html">Documentation</a> for more on output-filters.</p>
<div>
@
}

1; # End of PMLTQ::CGI

__END__

=pod

=encoding UTF-8

=head1 SYNOPSIS

    use PMLTQ::CGI;
    PMLTQ::CGI::Configure({
     # options
    });

    my $cgi = CGI->new();
    ...
    if ($request eq 'query') {
     resp_query($cgi);
    } elsif ($request eq 'svg') {
     resp_svg($cgi);
    } elsif ...

=head1 DESCRIPTION

This module is intended to be used in a FastCGI or Net::HTTPServer
environment (see pmltq_http). It implements a REST web service and a
web application to the PML-TQ engine driven by an SQL database
(PMLTQ::SQLEvaluator).

=head1 WEB SERVICE

Individual types of request are implemented by the resp_* family of
functions, which all assume a CGI-like object as their first and only
argument.

The web service uses URLs of the form

  http(s)://<host>:<port>/<method_prefix><method_name>?<arguments>

or

  http(s)://<host>:<port>/<method_prefix><method_name>/<resource-path>?<arguments>

where method_prefix is an optional path prefix, typically empty (see
method-prefix configuration option).

It is up to the HTTP server to do both user authentication and
authorization to the individual web service methods.

=head1 WEB APPLICATION

Individual types of request are implemented by a wrapper app() function,
whose first argument is a reference to a corresponding resp_* function
(see L</WEB SERVICE>) and the second argument is a CGI-like object.

The web service uses URLs of the form

  http(s)://<host>:<port>/<app_prefix>/<method_prefix><method_name>?<arguments>

or

  http(s)://<host>:<port>/<app_prefix>/<method_prefix><method_name>/<resource-path>?<arguments>

where <app_prefix> is 'app' by default.

=head1 AUTHENTICATION AND AUTHORIZATION

The authorization to the web application depends on the HTTP server to
do both autentication and authorization for all the web service
requests and also the <app_prefix>/<method_prefix>login web application request.  It
is not required to do authorization for other <app_prefix>/<method_prefix>* requests.

The autentication and authorization data are stored in the <auth-file>
configuration file, which contains user names, unencrypted passwords
(optional), and server-ID based access lists for each user.

The HTTP server may use the auth() method provided by this module in
order to obtain a password stored in the <auth-file> (this is what
pmltq_http does). Alternatively, the passwords can be stored
in the server's configuration, e,g. the .htaccess file, and the
<auth-file> can be used just for authorization.

Each web application method (<app_prefix>/<method_prefix>*) first checks the user and
session ID arguments (u and s) for validity and consults <auth-file>
in order to determine if the user is authorized for the running
instance.  If the session is valid and the user authorized, the
request is performed. Otherwise the client is redirected to the
<app_prefix>/<method_prefix>login request.

The HTTP server should be configured so as to require HTTP password
authentication for the <app_prefix>/<method_prefix>login request. If the HTTP server
authorizes the client for the <app_prefix>/<method_prefix>login request, a new
session is created for the user and the client is redirected to the
web application start page (<app_prefix>/<method_prefix>form).

Updates to the <auth-file> apply immediately without needing to
restart the service.

Each line in the <auth-file> may have one the following forms (empty and invalid lines are ignored):

# <comment>
<username> : : <authorization>
<username>: <password>
<username>: <password> : <authorization>

where <authorization> is a comma-separated list of server IDs (see the
C<server> configuration option). If the list is preceded by the minus
(-) sign, the user is authorized this service unless the server ID is
present in the list.  If this list is preceded by the plus (+) sign or
no sign at all, the user is authorized to connect to this service, if
and only if the server ID is present in the list. If the list
<authorization> list is not present, the user is authorized to connect
to any service.

The information about other services is also used when responding to
the method L<"/other">, which returns basic information about other
running instances (sharing the same <pid-dir> and <auth-file>, but
typically running on different ports or using different prefixes) and
whether the current user is authorized to use them or not.

=head1 INITIALIZATION

The module is initialized using a call to the Configure() function:

  PMLTQ::CGI::Configure({...options...});

In a forking FastCGI or Net::HTTPServer implementation, this
configuration is typically called just once prior to forking, so as
only one PID file is created for this service (even if the service is
handled by several forked instances).

The configuration options are:

=over 5

=item static-dir => $dirname

Directory from which static content is to be served.

=item config-file => $filename

PML-TQ configuration file (in the PML format described by the pmltq_cgi_conf_schema.xml schema.

=item server => $conf_id

ID of the server configuration in the configuration file (see above).

=item pid-dir => $dirname

Directory where to store a PID file containing basic information about
this running instance (to be used by other instances in order to
provide a list of available services).

This directory is also used to create user session files which may be
reused by other running services as well to provide a single-login
access to a family of related PML-TQ services.

=item port => $port_number

Port number of this instance. This information is stored into a PID
file and can be used by other running instances in order to determine
the correct URL for the service provided by this instance.

=item query-log-dir => $dirname

Directory where individual user's queries are logged. The content of
this directory is also used to retrieve previous user's queries.

=item auth-file => $filename

Path to a file containing user access configuration (note that
cooperation with the HTTP server is required), see L<"AUTHENTICATION AND AUTHORIZATION">.

=item tmp-dir => $dirname

A directory to use for temporary files.

=item google-translate => $bool

Add Google Translator service to the Toolbar of the sentence displayed
with the result tree.

=item ms-translate => $api_key

Add Microsoft Bing Translator service to the Toolbar of the sentence
displayed with the result tree. The argument must be a valid API key
issued from Microsoft for the host that runs this HTTP service.

=item method-prefix => $path_prefix

Optional path to be used as a prefix to all method parts in the
URLs. It is not recommended to use this parameter. If you must, make
sure you add a trailing /. If set to foo/, the path part of the URL
for the web service method 'query' (for example), will have the form of
'foo/query'. The corresponding web application path will be
'app/foo/query'.

=item debug => $bool

If true, the service logs some extra debugging information into the error log (STDERR).

=back

=head1 FUNCTIONS

=over 5

=item auth($unused,$user)

This helper function is designed for use with the RegisterAuth method
of Net::HTTPServer. It retrieves password for a given user from the
<auth-file> and returns ("401","") if user not found or not authorized
to access this service instance (server ID), and
("200",$unencrypted_password) otherwise.

=item app($resp_sub, $cgi)

This function is intended as a wrapper for the requests handlers when
called from the L<WEB APPLICATION>. It calls $resp_sub if valid
authorized username and session-id were passed in the s and u
parameters of the request, otherwise redirects the client to the URL
of the login request.

Requests handled by this function accept the following additional
parameters:

  s - sessionID
  u - username

=item resp_login($cgi)

This method implements response to the
<app_prefix>/<method_prefix>login request. The request is assumed to
be be protected by a HTTP authorization and should only be used in
connection with the WEB APPLICATION.

It checks that a valid session file exists for the user exists in the
pid_dir and creates a new one (pruning all invalid or expired session
files for the user). Then it redirects the user to the L<"/form"> method
(providing a user name and session-id in the u and s arguments).

Note: this function does not implement authorization or
authentication. It just creates a session for any user to which the
HTTP server granted access to the login request; the HTTP server is
responsible for granting access to authenticated users only and
session validity checking mechanisms used by the app() function
implementing the WEB APPLICATION are responsible for particular
instance authorization based on the <auth-file> data.

=item resp_root($cgi)

This function is used to implement a request to the base URL (/).
It redirects to <app-prefix>/form if a valid username and session-id is
passed in the s and u URL parameters, otherwise redirects to <app-prefix>/login.

=item resp_<method>($cgi)

This family of functions implements individual types of WEB SERVICE
requests described below.  For the WEB APPLICATION, they should be
called through the app() function documented above.

=back

=head1 WEB APPLICATION API

The web application API is the same as that for the web service,
described below, except that

  s - sessionID
  u - username

=head1 WEB SERVICE API

All methods of the web service accept both GET and POST requests; in
the latter case, parameters can be passed both as URL parameters or as
data.  In both cases, the parameters must be encoded using th
C<application/x-www-form-urlencoded> format.

NOTE: we write method names as C</METHOD>, omitting any
<method_prefix> specified in the configuration and adding a leading
slash (to indicate that we are describing the REST web service API
rather than Perl API).  However, if a request method A returns
(possibly embedded in some HTML code) an URL to a method B on this
instance, the returned URL has the form of a relative ( C<B> ) rather
than absolute URL ( C</B> ), so if the original method was invoked
e.g. as http://foo.bar:8082/app/A, the browser will reslove the
returned URL to http://foo.bar:8082/app/B.

=over 5

=item /about

Parameters:

        format - html|json|text
  extended - 0|1

Returns information about this instance:

        id       - ID
        service  - base URL (hostname)
        title    - full name
        abstract - short description
        moreinfo - a web URL with more information about the treebank database
        featured - popularity index

=item /other

Parameters:

        format - html|json|text

Returns information about other known PML-TQ services (sharing the same
<pid-dir> and <auth-file>, but typically running on different ports or
using different app or method prefixes):

        id       - ID
        service  - base URL (hostname)
        port     - port
        title    - full name
        abstract - short description
        moreinfo - a web URL with more information about the treebank database
        access   - true if the user is authorized to use the instance
        featured - popularity index

=item /past_queries

Parameters:

  format - html|json|text
  cb     - a string (typically JavaScript function name)
  first  - first query to return
  max    - max number of queries to return

Returns a list of users past queries. If format='json', the result is
an array of arrays (pairs), each of which consists of the time they
were last run (in seconds since UNIX epoch) and the query. If C<cb> is
passed, the JSON array is wrapped into a Javacript function whose name
was passed in C<cb>.

If format='text' the queries are returned as plain text, separated
only by two empty lines.

The options C<first> and C<max> can be used to obtain only partial
lists. For format='html', max defaults to 50.

=item /form

Parameters: none

Returns HTML with an empty PML-TQ query form, introduction and a few
query examples generated for the actual treebank.

=item /query

Parameters:

        format          - html|text
        query           - string query in the PML-TQ syntax
        limit           - maximum number of results to return for node queries
        row_limit       - maximum number of results for filter queries
        timeout         - timeout in seconds
        query_submit    - name of the submit button (if contains the substring 'w/o',
                          the query is evaluated ignoring output filters, if any)

For queries returning nodes the output contains for each match a tuple
of so called node handles of the matching nodes is returned.  The
tuple is ordered in the depth-first order of nesting of node selectors
in the query. The handles can be passed to methods such as /node and
/svg.

If format=text, the output consists of zero or more lines, each line
consisting of TAB-separated columns. For queries with output filter,
the columns are the values computed by the last filter, for queries
returning nodes they are the node handles (so each line encodes the
tuple of node handles as described above).  In this case, the header
'Pmltq-returns-nodes' indicates whether the query returned nodes
(value 1) or output filter results (value 0).

If format=html, the output is a web application page showing the query
and the results. The web page depends on CSS styleheets and JavaScript
code from the /static folder (i.e. it generates /static callbacks to
this service). Most of the web-page functionality is implemented in
the JavaScript file C<static/js/results.js>. Tree results are encoded
as node indexes in a JavaScript variable of the output web page and
the browser performs callback /svg requests to this service in order
to obtain a SVG rendering of the mathing tree.

[Node handles: For ordinary nodes, the handle has the form X/T or
X/T@I where X is an integer (internal database index of the
corresponding record), T is the name of the PML type of the node and
the optional I value is the PML ID of the matched node (if
available). For member objects (matching the member relation) the
handle has the form X//T.]

=item /query_svg

Parameters:

        query           - string query in the PML-TQ syntax

Returns an SVG document with the mime-type C<image/svg+xml> rendering
a graphical representation of the input PML-TQ query.

=item /svg

Parameters:

        nodes           - a node handle (or a |-separated list of node handles)
        tree_no         - tree number

Returns an SVG document with the mime-type C<image/svg+xml> rendering
a tree.

If C<tree_no> is less or equal 0 or not specified, the rendered tree
is the tree containing the node corresponding to the given node handle.

If C<tree_no> is a positive integer N, the returned SVG is a rendering
of Nth tree in the document containing the node corresponding to the
given node handle.

Currently, if C<nodes> contains a |-separated list of node handles,
only the first handle in the list is used.

=item /n2q

Parameters:

        format          - json|text
        ids             - a |-separated list of PML node IDs
        cb              - a string (typically JavaScript function name)
        vars            - comma separated list of reserved selector names

Locates given nodes by their IDs in the database and suggests a PML-TQ
query that cover this set of nodes as one of its matches (the query
restricts the nodes based on most of their attributes and their mutual
relationships). The returned query is formatted and indented so that
there is e.g. at most one attribute test per line, tests for technical
attributes (such as ID or order) are commented out, etc.  The query
also does not use any variable listed in the vars list.

The output for the text format is simply the query. For the json
format it is either a JavaScript string literal with the 'text/x-json'
mime-type, or, if the C<cb> parameter was set, the output has the
'text/javascript' mime-type and consists of the string literal wrapped
into a function call to the function whose name was passed in
C<cb>. For example, if the resulting query was 'a-node $a:= []' and
'show' was passed in C<cb>, the the JavaScript code show('a-node $a:=
[]').

=item /data/<path>

Parameters: none

Verifies that <path> is a (relative) path of a PML document in the
database (or related, e.g. a PML schema) and if so, returns the
document indicating 'application/octet-stream' as mime-type.

=item /static/<path>

Parameters: none

Returns the content of <static-dir>/<path> guessing the mime-type
based on the file extension, where <static-dir> is a pre-configured
directory for static content.

=item /node

Parameters:

        idx - a node handle
        format - html|text

Resolves a given node handle (see L<"/query">) into a relative URL which
points to the /data/<path> method and can be used to retrieve the
document containing a given node. Usually, a fragment identifier is
appended to the URL consisting either of the ID of the node or has the
form N.M where N is the tree number and M is the depth-first order of
the node in the tree.

=item /schema

Parameters:

        name - name of the annotation layer (root element)

Returns a PML schema for the particular annotation layer. The schema
(layer) is identified by the root name.

=item /type

Parameters:

        type    - PML type name
        format  - html|text

Returns a PML schema of the annotation layer which declares nodes of a
given type.

=item /nodetypes

Parameters:

        format  - html|text
        layer   - name of the annotation layer (root element)

Returns a list of node types available the given annotation layer or
on all layers if C<layer> is not given. In 'text' format the types are
returned one per line.

=item /relations

Parameters:

        format   - html|text
        type     - node type
        category - implementation|pmlrf|both

Returns a list of specific (i.e. implementation-defined or PMLREF-based or both)
PML-TQ relations that can start at a node of the given type (or any node if type not given).

=item /relation_target_types

Parameters:

        format   - html|text
        type     - node type
        category - implementation|pmlrf|both

Returns target-node types for specific (implementation-defined or
PMLREF-based or both) PML-TQ relations that can start at a node of the
given type (or any node if type is not given).

The output for format='text' is one or more line, each consisting of a
TAB-separated triplet C<ST>, C<REL>, C<TT> where C<ST> is the source
node type (same as C<type> if specified), C<REL> is the name of the
PML-TQ relation, and C<TT> is a possible PML node type of a target node
that can be in the relation C<R> with nodes of type C<ST>.

=item /version

Parameters:

        format           - html|text
        client_version   - version string

Checks compatibility of this version to the client version.

For format=text, returns the string COMPATIBLE (in cases that
compatible client version string was passed) or INCOMPATIBLE
(otherwise) and on the next line the version of the underlying
PMLTQ::SQLEvaluator.

For format=html, returns the same information in a small HTML
document.

=back

=cut
