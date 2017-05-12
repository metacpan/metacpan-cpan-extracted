use strict;
use warnings;
use Test::More tests => 1;
use PkgConfig::LibPkgConf::Client;
use PkgConfig::LibPkgConf::Util;

diag '';
diag '';
diag '';

foreach my $method (qw( path filter_lib_dirs filter_include_dirs ))
{
  if(PkgConfig::LibPkgConf::Client->can($method))
  {
    # delete local $ENV{FOO} is the modern way to do this
    # but apparently only works in Perl 5.12 or better.
    local %ENV = %ENV;
    delete $ENV{$_} 
      for qw( PKG_CONFIG_PATH 
              PKG_CONFIG_LIBDIR 
              PKG_CONFIG_SYSTEM_LIBRARY_PATH 
              PKG_CONFIG_SYSTEM_INCLUDE_PATH );
    diag "[pkgconf $method]";
    foreach my $dir (PkgConfig::LibPkgConf::Client->new->env->$method)
    {
      diag $dir;
    }

    diag '';
  }
}

diag '[impl]';
diag $PkgConfig::LibPkgConf::impl;

diag '';

diag '[path_sep]';
diag(PkgConfig::LibPkgConf::Util::path_sep());

diag '';

diag '[version]';
diag(PkgConfig::LibPkgConf::Util::version());

diag '';
diag '';


ok 1;
done_testing;
