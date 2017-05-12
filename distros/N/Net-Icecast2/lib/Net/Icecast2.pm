package Net::Icecast2;
{
  $Net::Icecast2::VERSION = '0.005';
}
# ABSTRACT: Icecast2 Server API
use Moo;
use MooX::Types::MooseLike::Base qw(Str Int);

use Carp;
use Safe::Isa;
use Sub::Quote qw( quote_sub );
use LWP::UserAgent;
use XML::Simple;

=head1 NAME

Net::Icecast2 - Icecast2 Server API

=head1 SYNOPSIS

  use Net::Icecast2;

  my $net_icecast = Net::Icecast2->new(
      host => 192.168.1.10,
      port => 8008,
      protocol => 'https',
      login    => 'source',
      password => 'hackme',
  );

  # Make request to "/admin/stats"
  $net_icecast->request( '/stats' );

=head1 DESCRIPTION

Make requsts and parse XML response from Icecast2 API

=head1 ATTRIBUTES

=head2 host

  Description : Icecast2 Server hostname
  Default     : localhost
  Required    : 0

=cut
has host     => (
    is       => 'ro',
    isa      => Str,
    default  => quote_sub(q{ 'localhost' }),
);

=head2 port

  Description : Icecast2 Server port
  Default     : 8000
  Required    : 0

=cut
has port     => (
    is       => 'ro',
    isa      => Int,
    default  => quote_sub(q{ 8000 }),
);

=head2 protocol

  Description : Icecast2 Server protocol ( scheme )
  Default     : http
  Required    : 0

=cut
has protocol => (
    is       => 'ro',
    isa      => Str,
    default  => quote_sub(q{ 'http' }),
);

=head2 login

  Description : Icecast2 Server API login
  Required    : 1

=cut
has login    => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 password

  Description : Icecast2 Server API password
  Required    : 1

=cut
has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _user_agent => (
    is       => 'ro',
    isa      => quote_sub( q{
        use Safe::Isa;
        $_[0]->$_isa('LWP::UserAgent')
            or die "_user_agent should be 'LWP::UserAgent'";
    }),
    lazy     => 1,
    builder  => '_build__user_agent',
);

sub _build__user_agent {
    my $self  = shift;
    my $user  = $self->login;
    my $pass  = $self->password;
    my $url   = $self->host . ':' . $self->port;
    my $realm = 'Icecast2 Server';
    my $agent = LWP::UserAgent->new;

    $agent->credentials( $url, $realm, $user, $pass );
    $agent;
}

=head1 METHODS

=head2 request

  Usage       : $net_icecast->request( '/stats' );
  Arguments   : Path to API action that goes after '/admin'
  Description : Method for making request to Icecast2 Server API
  Return      : Parsed XML server request

=cut
sub request {
    my $self = shift;
    my $path = shift;

    defined $path or croak '$path should be defined in request';

    my $url      = $self->protocol .'://'. $self->host .':'. $self->port;
    my $response = $self->_user_agent->get( $url .'/admin'. $path, @_ );

    $response->is_success or croak 'Error on request: ' .
        ( $response->code eq 401 ? 'wrong credentials' : $response->status_line );

    XML::Simple->new->XMLin( $response->content );
}

no Moo;
__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Icecast2 server: http://www.icecast.org
Icecast2 API Docs: http://www.icecast.org/docs/icecast-trunk/icecast2_admin.html

Related modules L<Net::Icecast2::Admin> L<Net::Icecast2::Mount>

=head1 AUTHOR

Pavel R3VoLuT1OneR Zhytomirsky <r3volut1oner@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Pavel R3VoLuT1OneR Zhytomirsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

