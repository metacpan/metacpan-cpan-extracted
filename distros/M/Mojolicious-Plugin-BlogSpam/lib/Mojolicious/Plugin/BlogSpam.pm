package Mojolicious::Plugin::BlogSpam;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::URL;
use Mojo::JSON;
use Mojo::Log;
use Mojo::UserAgent;
use Mojo::IOLoop;
use Scalar::Util 'weaken';

our $VERSION = '0.11';

# TODO: X-Forwarded-For in Config per index steuern
# TODO: - Check for blacklist/whitelist/max words etc. yourself.
#       - Create a route condition for posts.
#         -> $r->post('/comment')->over('blogspam')->to('#');

our @OPTION_ARRAY =
  qw/blacklist exclude whitelist mandatory
     max-links max-size min-size min-words/;
     # 'fail' is special, as it is boolean


# Register plugin
sub register {
  my ($plugin, $mojo, $params) = @_;

  $params ||= {};

  # Load parameters from Config file
  if (my $config_param = $mojo->config('BlogSpam')) {
    $params = { %$config_param, %$params };
  };

  # Set server url of BlogSpam instance
  my $url = Mojo::URL->new(
    delete $params->{url} || 'http://test.blogspam.net/'
  );

  # Set port of BlogSpam instance
  $url->port(delete $params->{port} || '8888');

  # Site name
  my $site = delete $params->{site};

  # Add Log
  my $log;
  if (my $log_path = delete $params->{log}) {
    $log = Mojo::Log->new(
      path  => $log_path,
      level => delete $params->{log_level} || 'info'
    );
  };

  my $app_log_clone = $mojo->log;
  weaken $app_log_clone;

  # Get option defaults
  my (%options, $base_options);
  foreach ('fail', @OPTION_ARRAY) {
    $options{$_} = delete $params->{$_} if $params->{$_};
  };
  $base_options = \%options if %options;


  # Add 'blogspam' helper
  $mojo->helper(
    blogspam => sub {
      my $c = shift;

      # Create new BlogSpam::Comment object
      my $obj = Mojolicious::Plugin::BlogSpam::Comment->new(
        url     => $url->to_string,
        log     => $log,
        site    => $site,
        app_log => $app_log_clone,
        client  => __PACKAGE__ . ' v' . $VERSION,
        base_options => $base_options,
        @_
      );

      # Get request headers
      my $headers = $c->req->headers;

      # Set user-agent if not given
      $obj->agent($headers->user_agent) unless $obj->agent;

      # No ip manually given
      unless ($obj->ip) {

        # Get forwarded ip
        if (my $ip = $headers->to_hash->{'X-Forwarded-For'}) {
          $obj->ip( split(/\s*,\s*/, $ip) );
        };

        # Get host ip, because X-Forwarded-For wasn't set
        unless ($obj->ip) {
          $obj->ip( split(/\s*:\s*/, ($headers->host || '')) );
        };
      };

      # Return blogspam object
      return $obj;
    }
  );
};


# BlogSpam object class
package Mojolicious::Plugin::BlogSpam::Comment;
use Mojo::Base -base;


# Attributes
has [qw/comment ip email link name subject agent/];


# Test comment for spam
sub test_comment {
  my $self = shift;

  # Callback for async
  my $cb = pop if $_[-1] && ref $_[-1] && ref $_[-1] eq 'CODE';

  # No IP or comment text defined
  unless ($self->ip && $self->comment) {
    $self->{app_log}->debug('You have to specify ip and comment');
    return;
  };

  # Create option string
  my $option_string = $self->_options(@_);

  # Check for mandatory parameters
  while ($option_string &&
     $option_string =~ m/(?:^|,)mandatory=([^,]+?)(?:,|$)/g) {
    return unless $self->{$1};
  };

  # Create option array if set
  my @options = (options => $option_string) if $option_string;

  # Push site to array if set
  push(@options, site => $self->{site}) if $self->{site};

  # Make xml-rpc call
  if ($cb) {

    # Make call non-blocking
    $self->_xml_rpc_call(
      testComment => (
        %{$self->hash},
        @options
      ) => sub {

        # Analyze response
        return $cb->( $self->_handle_test_response( shift ) );
      }
    );

    # Do not use this value
    return -1;
  };

  # Make call blocking
  my $res = $self->_xml_rpc_call(
    testComment => (
      %{$self->hash},
      @options
    )
  );

  # Analyze response
  return $self->_handle_test_response($res);
};


# Classify a comment as spam or ham
sub classify_comment {
  my $self = shift;
  my $train = lc shift;

  # Callback for async
  my $cb = pop if $_[-1] && ref $_[-1] && ref $_[-1] eq 'CODE';

  # Missing comment and valid train option
  unless ($self->comment && $train && $train =~ /^(?:ok|spam)$/) {
    $self->{app_log}->debug('You have to specify comment and train value');
    return;
  };

  # Create site array if set
  my @site = (site => $self->{site}) if $self->{site};

  # Send xml-rpc call
  if ($cb) {

    # Non-blocking request
    $self->_xml_rpc_call(classifyComment => (
      %{$self->hash},
      train => $train,
      @site,
      sub {
        my $res = shift;
        $cb->($res ? 1 : 0);
      }
    ));

    return;
  };

  # Blocking request
  return 1 if $self->_xml_rpc_call(classifyComment => (
    %{$self->hash},
    train => $train,
    @site
  ));

  return;
};


# Get a list of plugins installed at the BlogSpam instance
sub get_plugins {
  my $self = shift;

  # Callback for async
  my $cb = pop if $_[-1] && ref $_[-1] && ref $_[-1] eq 'CODE';

  # Response of xml-rpc call
  if ($cb) {

    # Non-blocking request
    $self->_xml_rpc_call(
      getPlugins => sub {
        my $res = shift;

        # Analyze response in callback
        return $cb->($self->_handle_plugins_response($res));
      });

    return ();
  };

  # Blocking request
  my $res = $self->_xml_rpc_call('getPlugins');

  # Analyze response
  return $self->_handle_plugins_response($res);
};


# Get statistics of your site from the BlogSpam instance
sub get_stats {
  my $self = shift;

  # Callback for async
  my $cb = pop if $_[-1] && ref $_[-1] && ref $_[-1] eq 'CODE';

  my $site = shift || $self->{site};

  # No site is given
  return unless $site;

  # Send xml-rpc call
  if ($cb) {

    # Send non-blocking request
    my $res = $self->_xml_rpc_call(
      'getStats', $site => sub {
        my $res = shift;
        return $cb->($self->_handle_stats_response($res));
      });

    return;
  };

  # Send blocking request
  my $res = $self->_xml_rpc_call('getStats', $site);
  return $self->_handle_stats_response($res);
};


# Get a hash representation of the comment
sub hash {
  my $self = shift;
  my %hash = %$self;

  # Delete non-comment info
  delete @hash{qw/site app_log url log client base_options/};

  # Delete empty values
  return { map {$_ => $hash{$_} } grep { $hash{$_} } keys %hash };
};


# Handle test_comment response
sub _handle_test_response {
  my ($self, $res)  = @_;

  # No response
  return -1 unless $res;

  # Get response element
  my $response =
    $res->dom->at('methodResponse > params > param > value > string');

  # Unexpected response format
  return -1 unless $response;

  # Get response tag
  $response = $response->all_text;

  # Response string is malformed
  return -1 unless $response =~ /^(OK|ERROR|SPAM)(?:\:\s*(.+?))?$/;

  # Comment is no spam
  return 1 if $1 eq 'OK';

  # Log is defined
  if (my $log = $self->{log}) {

    # Serialize comment
    my $msg = "[$1]: " . ($2 || '') . ' ' .
      Mojo::JSON->new->encode($self->hash);

    # Log error
    if ($1 eq 'ERROR') {
      $log->error($msg);
    }

    # Log spam
    else {
      $log->info($msg);
    };
  };

  # An error occured
  return -1 if $1 eq 'ERROR';

  # The comment is considered spam
  return 0;
};


# Handle get_plugins response
sub _handle_plugins_response {
  my ($self, $res) = @_;

  # Retrieve result
  my $array =
    $res->dom->at('methodResponse > params > param > value > array > data');

  # No plugins installed
  return () unless $array;

  # Convert data to array
  return @{$array->find('string')->map(sub { $_->text })};
};


# Handle get_stats response
sub _handle_stats_response {
  my ($self, $res) = @_;

  # Get response struct
  my $hash =
    $res->dom->at('methodResponse > params > param > value > struct');

  # No response struct defined
  return +{} unless $hash;

  # Convert struct to hash
  return {@{$hash->find('member')->map(
    sub {
      return ($_->at('name')->text, $_->at('value > int')->text);
    })}};
};


# Get options string
sub _options {
  my $self = shift;
  my %options = @_;

  # Create option string
  my @options;
  if (%options || $self->{base_options}) {

    # Get base options from plugin registration
    my $base = $self->{base_options};

    # Check for fail flag
    if (exists $options{fail}) {
      push(@options, 'fail') if $options{fail};
    }

    # Check for fail flag in plugin defaults
    elsif ($base->{fail}) {
      push(@options, 'fail');
    };

    # Check for valid option parameters
    foreach my $n (@Mojolicious::Plugin::BlogSpam::OPTION_ARRAY) {

      # Option flag is not set
      next unless $options{$n} || $base->{$n};

      # Base options
      my $opt = [
        $base->{$n} ? (ref $base->{$n} ? @{$base->{$n}} : $base->{$n}) : ()
      ];

      # Push new options
      push(
        @$opt,
        $options{$n} ? (ref $options{$n} ? @{$options{$_}} : $options{$n}) : ()
      );

      # Option flag is set as an array
      push(@options, "$n=$_") foreach @$opt};
  };

  # return option string
  return join(',', @options) if @options;

  return;
};


# Send xml-rpc call
sub _xml_rpc_call {
  my $self = shift;

  # Callback for async
  my $cb = pop if ref $_[-1] && ref $_[-1] eq 'CODE';

  my ($method_name, $param) = @_;

  # Create user agent
  my $ua = Mojo::UserAgent->new(
    max_redirects => 3,
    name => $self->{client}
  );

  # Start xml document
  my $xml = '<?xml version="1.0"?>' .
    "\n<methodCall><methodName>$method_name</methodName>";

  # Send with params
  if ($param) {
    $xml .= '<params><param><value>';

    # Param is a struct
    if (ref $param) {
      $xml .= '<struct>';

      # Create struct object
      foreach (keys %$param) {
        $xml .= "<member><name>$_</name><value>" .
          '<string>' . $param->{$_} . '</string>' .
          "</value></member>\n" if $param->{$_};
      };

      # End struct
      $xml .= '</struct>';
    }

    # Param is a string
    else {
      $xml .= "<string>$param</string>";
    };

    # End parameter list
    $xml .= '</value></param></params>';
  };

  # End method call
  $xml .= '</methodCall>';

  # Post method call to BlogSpam instance
  if ($cb) {

    # Create delay object
    my $delay = Mojo::IOLoop->delay(
      sub {
        my $tx = pop;

        my $res = $tx->success;

        # Connection failure - accept comment
        unless ($res) {
          # Maybe there needs something to be weakened
          $self->_log_error($tx);
          return;
        };

        # Send response to callback
        $cb->($res);
      }
    );

    # Post non-blocking
    $ua->post($self->{url} => +{} => $xml => $delay->begin);

    # Start IOLoop if not started already
    $delay->wait unless Mojo::IOLoop->is_running;

    return;
  };

  # Post blocking
  my $tx = $ua->post($self->{url} => +{} => $xml);
  my $res = $tx->success;

  # Connection failure - accept comment
  unless ($res) {
    $self->_log_error($tx);
    return;
  };

  # Return response
  return $res;
};


# Log connection_error
sub _log_error {
  my ($self, $tx) = @_;

  my ($err, $code) = $tx->error;
  $code ||= '*';

  $self->{app_log}->warn(
    "Connection error: [$code] $err for " .
      $self->{url}
    );

  return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::BlogSpam - Check your Comments using BlogSpam


=head1 SYNOPSIS

  # In Mojolicious
  $app->plugin('BlogSpam');

  # In Mojolicious::Lite
  plugin 'BlogSpam';

  # In Controller
  my $blogspam = $c->blogspam(
    comment => 'I just want to test the system!'
  );

  # Check for spam
  if ($blogspam->test_comment) {
    print "Your comment is no spam!\n";
  };

  # Even non-blocking
  $blogspam->test_comment(sub {
    print "Your comment is no spam!\n" if shift;
  });

  # Train the system
  $blogspam->classify_comment('ok');


=head1 DESCRIPTION

L<Mojolicious::Plugin::BlogSpam> is a plugin
for L<Mojolicious> to test
comments or posts for spam against a
L<BlogSpam|http://blogspam.net/> instance
(see L<Blog::Spam::API> for the codebase).
It supports blocking as well as non-blocking requests.


=head1 METHODS

L<Mojolicious::Plugin::BlogSpam> inherits all methods
from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  # Mojolicious
  $app->plugin(Blogspam => {
    url  => 'blogspam.sojolicio.us',
    port => '8888',
    site => 'http://grimms-abenteuer.de/',
    log  => '/spam.log',
    log_level => 'debug',
    exclude   => 'badip',
    mandatory => [qw/name subject/]
  });

  # Mojolicious::Lite
  plugin 'BlogSpam' => {
    site => 'http://grimms-abenteuer.de/'
  };

  # Or in your config file
  {
    BlogSpam => {
      url => 'blogspam.sojolicio.us',
      site => 'http://grimms-abenteuer.de/',
      port => '8888'
    }
  }

Called when registering the plugin.
Accepts the following optional parameters:

=over 2

=item C<url>

URL of your BlogSpam instance.
Defaults to C<http://test.blogspam.net/>.

=item C<port>

Port of your BlogSpam instance.
Defaults to C<8888>.

=item C<site>

The name of your site to monitor.

=item C<log>

A path to a log file.

=item C<log_level>

The level of logging, based on L<Mojo::Log>.
Spam is logged as C<info>, errors are logged as C<error>.

=back

In addition to these parameters, additional optional parameters
are allowed as defined in the
L<BlogSpam API|http://blogspam.net/api>.
See L</"test_comment"> method below.


=head1 HELPERS

=head2 blogspam

  # In controller:
  my $bs = $c->blogspam(
    comment => 'This is a comment to test the system',
    name => 'Akron'
  );

Returns a new blogspam object, based on the given attributes.


=head1 OBJECT ATTRIBUTES

These attributes are primarily based on
the L<BlogSpam API|http://blogspam.net/api>.

=head2 agent

  $bs->agent('Mozilla/5.0 (X11; Linux x86_64; rv:12.0) ...');
  my $agent = $bs->agent;

The user-agent sending the comment.
Defaults to the user-agent of the request.


=head2 comment

  $bs->comment('This is just a test comment');
  my $comment_text = $bs->comment;

The comment text.


=head2 email

  $bs->email('spammer@sojolicio.us');
  my $email = $bs->email;

The email address of the commenter.


=head2 hash

  my $hash = $bs->hash;

Returns a hash representation of the comment.


=head2 ip

  $bs->ip('192.168.0.1');
  my $ip = $bs->ip;

The ip address of the commenter.
Defaults to the ip address of the request.
Supports C<X-Forwarded-For> proxy information.


=head2 link

  $bs->link('http://grimms-abenteuer.de/');
  my $link = $bs->link;

Homepage link given by the commenter.


=head2 name

  $bs->name('Akron');
  my $name = $bs->name;

Name given by the commenter.


=head2 subject

  $bs->subject('Fun');
  my $subject = $bs->subject;

Subject given by the commenter.


=head1 OBJECT METHODS

These methods are based on the L<BlogSpam API|http://blogspam.net/api>.

=head2 test_comment

  # Blocking
  if ($bs->test_comment(
         mandatory => 'name',
         blacklist => ['192.168.0.1']
      )) {
    print 'Probably ham!';
  } else {
    print 'Spam!';
  };

  # Non-blocking
  $bs->test_comment(
    mandatory => 'name',
    blacklist => ['192.168.0.1'],
    sub {
      my $result = shift;
      print ($result ? 'Probably ham!' : 'Spam!');
    }
  );

Test the comment of the blogspam object for spam or ham.
It's necessary to have a defined comment text and an IP address.
The method returns nothing in case the comment is detected
as spam, C<1> if the comment is detected as ham and C<-1>
if something went horribly, horribly wrong.
Accepts additional option parameters as defined in the
L<BlogSpam API|http://blogspam.net/api>.

=over 2

=item C<blacklist>

Blacklist an IP or an array reference of IPs.
This can be either a literal IP address ("192.168.0.1")
or a CIDR range ("192.168.0.1/8").

=item C<exclude>

Exclude a plugin or an array reference of plugins from testing.
See L</"get_plugins"> for installed plugins of the BlogSpam instance.

=item C<fail>

Boolean flag that will, if set, return every comment as C<spam>.

=item C<mandatory>

Define an attribute (or an array reference of attributes)
of the blogspam object, that should be treated as mandatory
(e.g. "name" or "subject").

=item C<max-links>

The maximum number of links allowed in the comment.
This defaults to 10.

=item C<max-size>

The maximum size of the comment text allowed, given as a
byte expression (e.g. "2k").

=item C<min-size>

The minimum size of the comment text needed, given as a
byte expression (e.g. "2k").

=item C<min-words>

The minimum number of words of the comment text needed.
Defaults to 4.

=item C<whitelist>

Whitelist an IP or an array reference of IPs.
This can be either a literal IP address ("192.168.0.1")
or a CIDR range ("192.168.0.1/8").

=back

For a non-blocking request, append a callback function.
The parameters of the callback are identical to the method's
return values in blocking requests.


=head2 classify_comment

  $bs->classify_comment('ok');
  $bs->classify_comment(ok => sub {
    print 'Done!';
  });


Train the BlogSpam instance based on your
comment definition as C<ok> or C<spam>.
This may help to improve the spam detection.
Expects a defined C<comment> attribute and
a single parameter, either C<ok> or C<spam>.

For a non-blocking request, append a callback function.
The parameters of the callback are identical to the method's
return values in blocking requests.


=head2 get_plugins

  my @plugins = $bs->get_plugins;
  $bs->get_plugins(sub {
    print join ', ', @_;
  });

Requests a list of plugins installed at the BlogSpam instance.

For a non-blocking request, append a callback function.
The parameters of the callback are identical to the method's
return values in blocking requests.

=head2 get_stats

  my $stats = $bs->get_stats;
  my $stats = $bs->get_stats('http://sojolicio.us/');
  $bs->get_stats(sub {
    my $stats = shift;
    ...
  });

Requests a hash reference of statistics for your site
regarding the number of comments detected as C<ok> or C<spam>.
If no C<site> attribute is given (whether as a parameter or when
registering the plugin), this will return nothing.

For a non-blocking request, append a callback function.
The parameters of the callback are identical to the method's
return values in blocking requests.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 SEE ALSO

L<Blog::Spam::API>,
L<http://blogspam.net/>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-BlogSpam


=head1 PRIVACY NOTE

Be aware that information of your users may be send
to a third party.
This may need to be noted in your privacy policy if you
use a foreign BlogSpam instance, especially if you
are located in the European Union.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

The API definition as well as the BlogSpam API code were
written and defined by Steve Kemp.

=cut
