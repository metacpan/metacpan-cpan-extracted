use strict;
use warnings;
use Test::More tests => 4;
use FindBin ();

$ENV{PKG_CONFIG_PATH} = "$FindBin::Bin/data/usr/lib/pkgconfig";
$ENV{PKG_CONFIG_PATH} =~ s{\\}{/}g;

use_ok 'PkgConfig';

note "PKG_CONFIG_PATH = $ENV{PKG_CONFIG_PATH}";
note "PkgConfig = $INC{'PkgConfig.pm'}";
my $pkg = PkgConfig->find('mono-lineeditor');

is $pkg->errmsg, undef, 'no error';

isa_ok $pkg, 'PkgConfig';

my $prefix = $pkg->get_var('prefix');
is $prefix, "$ENV{PKG_CONFIG_PATH}/../..", "prefix=$prefix";
