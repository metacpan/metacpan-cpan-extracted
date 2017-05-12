package Protocol::Notifo;
BEGIN {
  $Protocol::Notifo::VERSION = '0.004';
}

# ABSTRACT: utilities to build requests for the notifo.com service

use strict;
use warnings;
use Carp 'confess';
use JSON 'decode_json';
use MIME::Base64 'encode_base64';
use File::HomeDir;
use File::Spec::Functions qw( catfile );
use URI ();
use namespace::clean;

sub new {
  my ($class, %args) = @_;
  my $self = bless $class->_read_config_file, $class;

  for my $f (qw( user api_key )) {
    $self->{$f} = $args{$f} if exists $args{$f};
    confess("Missing required parameter '$f' to new(), ") unless $self->{$f};
  }

  $self->{base_url} = 'https://api.notifo.com/v1';
  $self->{auth_hdr} = encode_base64(join(':', @$self{qw(user api_key)}), '');

  return $self;
}


sub parse_response {
  my ($self, %args) = @_;

  my $res = {};
  eval { $res = decode_json(delete $args{http_body}) };
  if ($@) {
    $res->{status}           = 'error';
    $res->{response_code}    = -1;
    $res->{response_message} = $args{http_status_line};
  }

  for my $k (qw( http_response_code http_status_line)) {
    $res->{$k} = delete $args{$k};
  }
  $res->{other} = \%args;

  return $res;
}


sub send_notification {
  my ($self, %args) = @_;

  my %call = (
    url     => "$self->{base_url}/send_notification",
    method  => 'POST',
    headers => [Authorization => "Basic $self->{auth_hdr}"],
    args    => {},
  );

  for my $f (qw( to msg label title uri )) {
    my $v = $args{$f};
    next unless defined $v;

    $call{args}{$f} = $v;
  }

  confess("Missing required argument 'msg', ") unless $call{args}{msg};

  _build_http_request(\%call);

  return \%call;
}

sub config_file {
  my ($self) = @_;

  return $ENV{NOTIFO_CFG} || catfile(File::HomeDir->my_home, '.notifo.rc');
}


sub _read_config_file {
  my ($self) = @_;
  my %opts;

  my $fn = $self->config_file;
  return \%opts unless -r $fn;

  open(my $fh, '<', $fn) || confess("Could not open file '$fn': $!, ");

  while (my $l = <$fh>) {
    chomp($l);
    $l =~ s/^\s*(#.*)?|\s*$//g;
    next unless $l;

    my ($k, $v) = $l =~ m/(\S+)\s*[=:]\s*(.*)/;
    confess("Could not parse line $. of $fn ('$l'), ") unless $k;

    $opts{$k} = $v;
  }

  return \%opts;
}

sub _build_http_request {
  my ($req) = @_;
  my ($meth, $url, $args, $hdrs) = @$req{qw(method url args headers)};

  my $uri = $req->{url} = URI->new($url);
  $uri->query_form($args);

  $req->{body} = $uri->query;
  push @$hdrs, 'Content-Type'   => 'application/x-www-form-urlencoded';
  push @$hdrs, 'Content-Length' => length($req->{body});

  $uri->query_form([]);
}

1;



=pod

=head1 NAME

Protocol::Notifo - utilities to build requests for the notifo.com service

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    ## Reads user and api_key from configuration file
    my $pn = Protocol::Notifo->new;
    
    ## Use a particular user and api_key, overrides configuration file
    my $pn = Protocol::Notifo->new(user => 'me', api_key => 'my_key');
    
    my $req = $pn->send_notification(msg => 'Hi!');
    
    .... send $req, get a response back ....
    
    my $res = $pn->parse_response($response_http_code, $response_body);
    
    .... do stuff with $res ....

=head1 DESCRIPTION

This module provides an API to prepare requests to the
L<http://notifo.com/> service.

The module doesn't actually execute the HTTP request. It only prepares
all the information required for such request to be performed. As such
this module is not to be used by end users, but by writters of
notifo.com API clients.

If you are an end-user and want to call the API, you should look into
the modules L<WebService::Notifo> and L<AnyEvent::WebService::Notifo>.

This module supports both the User API and the Service API.
Differences between the behaviour of the two are noted in this
documentation where relevant.

You need a notifo.com account to be able to use this module. The account
will give you access to an API username, and an API key. Both are required
arguments of our L<constructors|/CONSTRUCTORS>.

The module also supports a configuration file. See
L<config_file()|/config_file> to learn which configuration file will
be loaded automatically, if found.

For all the details of the notifo.com API, check out the site
L<https://api.notifo.com/>.

=head1 CONSTRUCTORS

=head2 new

Creates new C<Protocol::Notifo> object.

It first tries to load default values from a configuration file. If you
set the environment variable C<NOTIFO_CFG>, it will try that. If not, it
will default to L<< File::HomeDir->my_home()|File::HomeDir/my_home >>. See
section L</"CONFIGURATION FILE"> for the format of those files.

You can also pass a hash of options, that will override the defaults set
by the configuration file. The following options are accepted:

=over 4

=item user

The API username.

=item api_key

The API key.

=back

Values for this two options can be found in the
L<user settings page|http://notifo.com/user/settings>
of the L<notifo site|http://notifo.com/>.

=head1 METHODS

=head2 parse_response

Accepts a hash with response information. The following fields must be present:

=over 4

=item http_response_code

The HTTP code of the response message.

=item http_status_line

The HTTP status line of the response message.

=item http_body

The response content.

=back

Other fields might be passed, they will be ignored and returned in the
C<other> field of the return value.

This method parses the content, adds the HTTP response code and returns a hashref
with all the fields.

The following fields are present on all responses:

=over 4

=item status

A string, either C<success> or C<error>.

=item http_response_code

The HTTP code of the response message.

=item http_status_line

The HTTP status line of the response message.

=item response_code

A notifo.com integer response code.

=item response_message

A text description of the response. Specially useful when C<status>
is C<error>.

=item other

All C<parse_response()> other parameters.

=back

=head2 send_notification

Prepares a request for the
L<send_notification|https://api.notifo.com/docs/notifications#send_notification>
API.

Accepts a hash with options. The following options are supported:

=over 4

=item msg

The notification message. This parameter is B<required>.

=item to

The destination user. If the API username/key pair used is of a User
account, then this parameter is ignored and can be safelly ommited.

A User account can only send notifications to itself. A Service account
can send notifications to all his subscribed users.

=item label

A label describing the application that is sending the
notification. With Service accounts, this option is ignored and the
Service Name is used.

=item title

The title or subject of the notification.

=item uri

The URL for the event. On some clients you can click the notification and jump to this URL.

=back

The return value is a hashref with all the relevant information to
perform the HTTP request: the url and the method to use, the
Authorization header, and the query form fields.

An example:

    url    => URI->new("https://api.notifo.com/v1/send_notification"),
    method => "POST",
    args   => {
      label => "l",
      msg   => "hello",
      title => "t",
      to    => "to"
    },
    headers => [
      "Authorization"  => "Basic bWU6bXlfa2V5",
      "Content-Type"   => "application/x-www-form-urlencoded",
      "Content-Length" => 31,
    ],
    body => "msg=hello&to=to&title=t&label=l",

The following keys are always present in the hashref:

=over 4

=item url

The L<URI> object representing the URL where the HTTP request should
be sent to.

=item method

The HTTP method to use.

=item args

A hashref with all the URL query form fields and values.

=item headers

A hashref with all the headers to include in the HTTP request.

=item body

The C<args> in C<application/x-www-form-urlencoded> form, can be used as
the body of the HTTP request.

=back

=head2 config_file

Returns the configuration file that this module will attempt to use.

=head1 CONFIGURATION FILE

The configuration file is line based. Empty lines os just spaces/tabs,
or lines starting with # are ignored.

All other lines are parsed for commands, in the form
C<command separator value>. The C<separator> can be a C<=> or a C<:>.

See the L<new() constructor|/new> for the commands you can use,
they are the same ones as the accepted options.

=head1 TODO

Future versions of this module will implement the other APIs:

=over 4

=item subscribe_user

=item send_message

=back

Patches welcome.

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

