package Modern::OpenAPI::Generator::CodeGen::Auth;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);

sub emit_plugins {
    my ( $class, %arg ) = @_;
    my $writer = $arg{writer}   // croak 'writer';
    my $base   = $arg{base}     // croak 'base';
    my $sigs   = $arg{signatures} // [];

    my $lib = 'lib/' . _pathify_dir($base);

    for my $sig (@$sigs) {
        if ( $sig eq 'hmac' ) {
            $writer->write( "$lib/Auth/Plugin/Hmac.pm", _hmac_pm("$base\::Auth::Plugin::Hmac") );
        }
        elsif ( $sig eq 'bearer' ) {
            $writer->write( "$lib/Auth/Plugin/Bearer.pm", _bearer_pm("$base\::Auth::Plugin::Bearer") );
        }
    }
}

sub _pathify_dir {
    my ($name) = @_;
    $name =~ s{::}{/}g;
    return $name;
}

sub _hmac_pm {
    my ($pkg) = @_;
    return <<"HEAD" . <<'BODY';
package $pkg;

use v5.26;
use Modern::Perl::Prelude -class;

use Moo;
use Carp qw(croak);
use Digest::SHA qw(sha256_hex hmac_sha256_hex);

has api_secret => (
  is       => 'ro',
  required => 0,
);

HEAD
sub apply {
  my ( $self, $tx, $meta ) = @_;
  return unless $self->api_secret;

  my $req = $tx->req;
  my $ts  = time;
  my $method = $req->method;
  my $path   = $req->url->path->to_string;
  my $body   = $req->body // '';
  my $idem   = $req->headers->header('Idempotency-Key') // '';
  my $bh     = sha256_hex($body);
  my $canonical = join "\n", $ts, $method, $path, ( length $idem ? "$idem\n" : '' ), $bh;
  my $sig = hmac_sha256_hex( $canonical, $self->api_secret );
  $req->headers->header( 'X-Signature' => "t=$ts,v1=$sig" );
}

1;

=encoding utf8

=head1 NAME

HMAC request signing plugin (adjust canonical string for your API)

=cut
BODY
}

sub _bearer_pm {
    my ($pkg) = @_;
    return <<"HEAD" . <<'BODY';
package $pkg;

use v5.26;
use Modern::Perl::Prelude -class;

use Moo;

has token => (
  is       => 'ro',
  required => 0,
);

HEAD
sub apply {
  my ( $self, $tx, $meta ) = @_;
  return unless my $t = $self->token;
  $tx->req->headers->header( Authorization => "Bearer $t" );
}

1;
BODY
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CodeGen::Auth - Emit optional C<::Auth::Plugin::*> modules

=head1 DESCRIPTION

Writes HMAC or Bearer auth helper classes when requested via generator options.

=head2 emit_plugins

Class method. Arguments: C<writer>, C<base>, C<signatures> (e.g. C<hmac>,
C<bearer>).

=cut
