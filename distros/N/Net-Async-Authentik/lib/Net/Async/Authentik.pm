package Net::Async::Authentik;

# ABSTRACT: Async Perl client for the authentik identity provider (IO::Async + Future)

use Moo;
extends 'IO::Async::Notifier';
use Net::Async::Authentik::API;
use Net::Async::Authentik::Error;
use Net::Async::Authentik::Error::API;
use Net::Async::Authentik::Error::Network;
use Net::Async::Authentik::Error::Validation;
use Net::Async::Authentik::OIDC;
use Net::Async::HTTP;
use Types::Standard qw( Object Str );
use URI::Escape qw( uri_escape_utf8 );

our $VERSION = '0.001';


# IO::Async::Notifier->new hands every constructor key to configure(), which
# croaks on keys it does not know. Keep ours away from it.
sub FOREIGNBUILDARGS {
  my ( $class, @args ) = @_;
  my %arg = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  delete @arg{qw( base_url application client_id token http )};
  return %arg;
}

has base_url => ( is => 'ro', isa => Str, required => 1 );


has application => ( is => 'ro', isa => Str, predicate => 'has_application' );


has client_id => ( is => 'ro', isa => Str, predicate => 'has_client_id' );


has token => ( is => 'ro', isa => Str, predicate => 'has_token' );


has http => ( is => 'lazy', isa => Object, predicate => 'has_http' );

sub _build_http {
  my ( $self ) = @_;
  my $http = Net::Async::HTTP->new(
    user_agent => 'Net-Async-Authentik/'.$VERSION,
    # no redirects: authentik answers 302 wherever it wants a browser, and
    # those answers are read, not followed
    max_redirects => 0,
    # a 4xx is an answer here, so that read_response can make an error with
    # authentik's own message out of it
    fail_on_error => 0,
    timeout       => 30
  );
  $self->add_child($http);
  return $http;
}


has oidc => ( is => 'lazy', init_arg => undef );

sub _build_oidc {
  my ( $self ) = @_;
  return Net::Async::Authentik::OIDC->new(
    application_url => $self->has_application && length $self->application ? $self->application_url : undef,
    http            => $self->http,
    $self->has_client_id ? ( client_id => $self->client_id ) : ()
  );
}


has api => ( is => 'lazy', init_arg => undef );

sub _build_api {
  my ( $self ) = @_;
  return Net::Async::Authentik::API->new(
    base_url => $self->base_url,
    http     => $self->http,
    $self->has_token ? ( token => $self->token ) : ()
  );
}


# The parent is not a Moo class, so there is no BUILDARGS to wrap.
sub BUILDARGS {
  my ( $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  $args{base_url} =~ s{/+\z}{} if defined $args{base_url};
  return \%args;
}

sub BUILD {
  my ( $self ) = @_;
  Net::Async::Authentik::Error::Validation->throw( message => __PACKAGE__.' needs a base_url' )
    unless length $self->base_url;
  return;
}

sub api_url { $_[0]->base_url.'/api/v3' }


sub application_url {
  my ( $self ) = @_;
  Net::Async::Authentik::Error::Validation->throw( message => __PACKAGE__.'->application_url needs an application slug' )
    unless $self->has_application && length $self->application;
  return $self->base_url.'/application/o/'.uri_escape_utf8( $self->application );
}


sub issuer { $_[0]->application_url.'/' }


sub for_application {
  my ( $self, $slug ) = @_;
  return ref($self)->new(
    base_url    => $self->base_url,
    application => $slug,
    http        => $self->http,
    $self->has_token ? ( token => $self->token ) : ()
    # deliberately not the client_id: it belongs to this application's provider
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Authentik - Async Perl client for the authentik identity provider (IO::Async + Future)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Future::AsyncAwait;
    use IO::Async::Loop;
    use Net::Async::Authentik;

    my $loop = IO::Async::Loop->new;
    my $ak   = Net::Async::Authentik->new(
      base_url    => 'https://id.example.org',
      application => 'my-app',                   # the application slug, for OIDC
      client_id   => $client_id,                 # its provider's client id, checked as the audience
      token       => $ENV{AUTHENTIK_TOKEN},      # an API token, for the REST API
    );
    $loop->add($ak);

    my $claims = await $ak->oidc->verify_token_f( $jwt, type => 'access' );
    my $r      = await $ak->api->ensure_user_f( username => 'alice', name => 'Alice' );

=head1 DESCRIPTION

The asynchronous twin of L<WWW::Authentik>, on L<IO::Async> and L<Future>:
the same facade, the same parts, every method with C<_f> returning a future.
Requests are built and responses read by the same code as in the synchronous
client, and the C<ensure_*_f> methods compare with the same
L<WWW::Authentik::Diff> and resolve names from the same table, so both
clients do the same thing to an authentik.

B<Add the object to a loop before the first request.> The
L<Net::Async::HTTP> it sends through is its child notifier; without a loop
every call fails with a L<Net::Async::Authentik::Error::Network> saying so.

Nothing here throws. A wrong argument fails the future the caller is already
holding, so one C<else> catches a validation error and a refused request
alike.

B<Hold the future you get back.> Dropping it does not undo anything: the
async sub has already begun, the request it waits on is held by the HTTP
client, and the work runs to the end — authentik is written to and the
answer goes nowhere, with a "lost its returning future" warning as the only
sign. To start something and not wait for it, say so with
C<< ->retain >>.

B<And let every future finish before the process ends.> A future of this
distribution that is still pending at exit can take the interpreter down
with C<double free or corruption> or a segmentation fault — in global
destruction, after the program's own work is done, so the damage is an exit
status rather than lost data. This is a defect in Future::AsyncAwait 0.71,
the newest release at the time of writing: an C<async sub> suspended at exit
whose saved frame holds a reference argument corrupts the heap. Eight lines
reproduce it with none of this distribution involved;
F<docs/future-asyncawait-0.71-crash.pl> has them, together with what does
and does not change it. Holding the future does not help and neither does
C<< ->retain >>; running the loop until the future is ready does.

=head2 Coming from WWW::Authentik

Two return values differ from what a Keycloak user would expect, and
deliberately: C<create_*_f> and C<update_*_f> give back the representation,
because authentik answers a create with the whole object and no C<Location>
header, and C<ensure_*_f> gives back
C<< { object => \%rep, changed => ... } >>, because authentik has no single
kind of identifier. Both are as in the synchronous client.

Developed and tested against authentik 2026.8.3.

=head2 base_url

Required. Where authentik is, without C</api/v3> and without
C</application/o/>. Trailing slashes are removed.

=head2 application

The slug of the application L</oidc> talks to. Without it every method of
L</oidc> fails.

=head2 client_id

The client id of L</application>'s provider.
L<Net::Async::Authentik::OIDC/verify_token_f> checks it as the audience,
which is what keeps a token of another application of the same authentik from
passing. Worth setting.

=head2 token

An authentik API token, sent as a bearer token with every call of L</api>.
Without it every method of L</api> fails. It is used as it is and never
renewed.

=head2 http

The L<Net::Async::HTTP> every part shares, built as a child of this notifier.
Pass one in to share it with something else; it is then not added as a child,
and whoever owns it is responsible for its loop.

Unlike the synchronous client, nothing has to be done about the C<TE>
connection token: L<Net::Async::HTTP> does not announce it, and authentik
answers every request. See the plan in F<docs/superpowers/plans/> for what
was measured.

=head2 oidc

The L<Net::Async::Authentik::OIDC> of L</application>. Without an application
slug the object still exists, and every one of its methods fails with a
validation error — an attribute does not throw.

=head2 api

The L<Net::Async::Authentik::API> of this instance. Without a token every one
of its methods fails with a validation error.

=head2 api_url

    print $ak->api_url;   # https://id.example.org/api/v3

=head2 application_url

    print $ak->application_url;   # https://id.example.org/application/o/my-app

Where this application's OpenID Connect endpoints live, without the trailing
slash. The slug is URI encoded.

=head2 issuer

    print $ak->issuer;   # https://id.example.org/application/o/my-app/

The issuer in its address form, which is what authentik puts into a token
while the provider is set to C<issuer_mode: per_provider> (its default). The
authoritative value is L<Net::Async::Authentik::OIDC/issuer_f>, read out of
the discovery document.

=head2 for_application

    my $other = $ak->for_application('second-app');

The same client for another application, sharing the L<Net::Async::HTTP> and
the API token. The new object is not a notifier in any loop of its own; it
sends through the shared C<http>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
