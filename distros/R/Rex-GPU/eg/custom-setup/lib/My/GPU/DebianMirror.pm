package My::GPU::DebianMirror;
# Example: a Debian host whose sources point at a mirror of your own
# (apt-cacher-ng, a company mirror) without
# signed-by=/usr/share/keyrings/debian-archive-keyring.gpg. Rex::GPU enables
# contrib non-free non-free-firmware only in entries it recognises as
# Debian's archive; this class teaches it the mirror. Everything else is the
# built-in Debian setup.
use Moo;
use namespace::autoclean;

extends 'Rex::GPU::NVIDIA::Setup::Debian';

sub is_debian_archive_uri {
  my ( $self, $uri ) = @_;
  # only URIs that serve Debian's own archive (main is extended by non-free)
  return 1 if $uri =~ m{^http://apt-cache\.corp\.example:3142/debian(?:-security)?/?$};
  return $self->SUPER::is_debian_archive_uri($uri);
}

1;
