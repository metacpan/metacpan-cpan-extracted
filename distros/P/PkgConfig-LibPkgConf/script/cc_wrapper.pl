use strict;
use warnings;
use Config;
use Text::ParseWords qw( shellwords );
use Alien::pkgconf;

my @list = (
  $Config{cc},
  shellwords(Alien::pkgconf->cflags),
  '-DMY_PKGCONF_VERSION=' . Alien::pkgconf->version,
  @ARGV
);

#print "+@list\n";
exec @list;
