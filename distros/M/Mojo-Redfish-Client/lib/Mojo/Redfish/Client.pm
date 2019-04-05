package Mojo::Redfish::Client;

use Mojo::Base -base;

use Carp ();
use Mojo::Collection;
use Mojo::Redfish::Client::Result;
use Scalar::Util ();

our $VERSION = '0.02';
$VERSION = eval $VERSION;

has ssl  => 1;
has [qw/host password token username/];

has ua => sub {
  my $self = shift;
  my $ua = Mojo::UserAgent->new(insecure => 1);

  Scalar::Util::weaken $self;
  $ua->on(prepare => sub {
    my ($ua, $tx) = @_;
    my $url = $tx->req->url;

    if (defined(my $host = $self->host)) {
      $url->host($host);
    }

    if (defined(my $ssl = $self->ssl)) {
      $url->scheme($ssl ? 'https' : 'http');
    }

    if (my $token = $self->token) {
      $tx->req->headers->header('X-Auth-Token', $token);
    } elsif (my $userinfo = $self->_userinfo) {
      $url->userinfo($userinfo);
    }
  });

  return $ua;
};

sub get {
  my ($self, $url) = @_;
  my $tx = $self->ua->get($url);
  if (my $err = $tx->error) { Carp::croak $err->{message} }
  my $data = $tx->res->json;
  return $self->_result($tx->res->json);
}

sub root {
  my $self = shift;
  return $self->{root} ||= $self->get('/redfish/v1');
}

sub _result {
  my ($self, $data) = @_;
  return Mojo::Redfish::Client::Result->new(
    data   => $data,
    client => $self,
  );
};

sub _userinfo {
  my $self = shift;
  my ($user, $pass) = @{$self}{qw/username password/};
  return undef unless $user || $pass;
  return "$user:$pass";
};

1;

=head1 NAME

Mojo::Redfish::Client - A Redfish client with a Mojo flair

=head1 SYNOPSIS

  my $client = Mojo::Redfish::Client->new(host => '192.168.0.1');
  my $system = $client->root->get('/Systems')->get('/Members')->first;
  my $name   = $system->value('/Name');
  say "Name: $name";

=head1 DESCRIPTION

L<Redfish|https://redfish.dmtf.org/> is a modern standards-based system for querying computer systems for information.
It replaces the existing IPMI "standard", such as it was, both in standardization and in using JSON over HTTP rather than binary protocols.

L<Mojo::Redfish::Client> is, as the name suggests, a client for Redfish.
It works to smooth out some of the common pain points of working with Redfish, especially the task of walking the data structure to find relevant information.

This is still a work-in-progress, however the author uses it in work application so every effort will be made to keep the api reasonably stable while improving where possible.

=head1 ATTRIBUTES

L<Mojo::Redfish::Client> inherits all attributes from L<Mojo::Base> and implements the following new ones.

=head2 host

The Redfish host.

=head2 password

Password used for authentication by the default L</ua> (with L</username>).

=head2 ssl

If true, the default L</ua> will establish the connection using SSL/TLS by setting the request scheme to C<https>.
If false, the request scheme will be C<http>.
If not defined, the url scheme will not be set.
Default is true.

=head2 token

Session token to be used by the default L</ua>, overrides L</username> and L</password>.

=head2 ua

The instance of L<Mojo::UserAgent> used to make requests.
The default is an instance which subscribes to L<Mojo::UserAgent/prepare> to set authentication and ssl.

=head2 username

Username used for authentication by the default L</ua> (with L</password>).

=head1 METHODS

L<Mojo::Redfish::Client> inherits all methods from L<Mojo::Base> and implements the following new ones.

=head2 get

  my $result = $client->get('/redfish/v1/Systems');

Requests the requested url via the L</ua>.
Returns an instance of L<Mojo::Redfish::Client::Result>.
Dies on errors (the exact exception and behavior is subject to change).

=head2 root

  my $result = $client->root;

Requests the Redfish root url (C</redfish/v1>) from the L</host> via L</get> or fetches a cached copy.
Caches and returns the result.

  # same as (except for the caching)
  my $result = $client->get('/redfish/v1');

=head1 FUTURE WORK

This module is still in early development.
Future work will include

=over

=item *

Non-blocking (promise-based) api

=item *

Session management

=item *

Even more testing

=back


=head1 SEE ALSO

=over

=item L<https://redfish.dmtf.org>.

=back

=head1 THANKS

This module's development was sponsored by L<ServerCentral Turing Group|https://www.servercentral.com/>.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-Redfish-Client>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by L</AUTHOR> and L</CONTRIBUTORS>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


