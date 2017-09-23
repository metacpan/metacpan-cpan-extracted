package PkgConfig::Path;

use strict;
use warnings;
use File::Spec;
use Env qw( @PKG_CONFIG_LIBDIR );

sub import
{
  my(undef, @dir) = @_;

  @PKG_CONFIG_LIBDIR = map { File::Spec->rel2abs($_) } @dir;
  
  delete $ENV{$_} for qw(
    PKG_CONFIG_NO_OS_CUSTOMIZATION
    PKG_CONFIG_PATH
    PKG_CONFIG_ALLOW_SYSTEM_CFLAGS
    PKG_CONFIG_ALLOW_SYSTEM_LIBS
    LD_LIBRARY_PATH
    C_INCLUDE_PATH
    LD_RUN_PATH
    LD
  );
}

1;
