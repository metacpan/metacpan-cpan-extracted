package Mojo::UserAgent::DigestAuth;
use Mojo::Base qw(Exporter);

use Mojo::UserAgent;
use Mojo::Util qw(deprecated md5_sum);

our $VERSION = '0.06';
our @EXPORT  = qw( $_request_with_digest_auth );

our $_request_with_digest_auth = sub {
  deprecated q[$_request_with_digest_auth() is DEPRECATED in favor of $ua->with_roles('+DigestAuth')->$method(...)];
  my @cb = ref $_[-1] eq 'CODE' ? (pop) : ();
  my ($ua, $method) = (shift, uc shift);
  $ua = $ua->with_roles('+DigestAuth') unless $ua->DOES('Mojo::UserAgent::Role::DigestAuth');
  return $ua->start($ua->build_tx($method, @_), @cb);
};

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::DigestAuth - Allow Mojo::UserAgent to execute digest auth requests

=head1 VERSION

0.06

=head1 DESCRIPTION

L<Mojo::UserAgent::DigestAuth> is DEPRECATED in favor of L<Mojo::UserAgent::Role::DigestAuth>.

=head1 SYNOPSIS

See L<Mojo::UserAgent::Role::DigestAuth>.

=head1 SEE ALSO

L<Mojo::UserAgent::Role::DigestAuth>.

=cut
