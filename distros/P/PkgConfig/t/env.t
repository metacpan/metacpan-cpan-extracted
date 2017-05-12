use strict;
use warnings;
use Test::More tests => 1;
use Env qw( @PKG_CONFIG_PATH @PKG_CONFIG_LIBDIR );

@PKG_CONFIG_PATH   = qw( /foo /bar );
@PKG_CONFIG_LIBDIR = qw( /baz /roger );

require PkgConfig;

no warnings 'once';
is_deeply \@PkgConfig::DEFAULT_SEARCH_PATH, [qw( /foo /bar /baz /roger )], "honors both PKG_CONFIG_PATH and PKG_CONFIG_LIBDIR";
