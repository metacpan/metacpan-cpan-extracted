use strict;
use warnings;
use Test::More;
use FindBin ();

BEGIN {
$ENV{PKG_CONFIG_PATH} = "$FindBin::Bin/data/dep_no_inherit_vars/lib/pkgconfig";
$ENV{PKG_CONFIG_PATH} =~ s{\\}{/}g;
}

require PkgConfig;
note "PKG_CONFIG_PATH = $ENV{PKG_CONFIG_PATH}";
note "PkgConfig = $INC{'PkgConfig.pm'}";

my $pkg = PkgConfig->find('nss');
is $pkg->errmsg, undef, 'no error';

is $pkg->get_var('prefix'), "/usr/local/opt/nss", "Correct prefix for nss";
is join(' ', $pkg->get_cflags), '-I/usr/local/opt/nss/include/nss -I/usr/local/Cellar/nspr/4.10.6/include/nspr', 'Cflags for nss correct';
is join(' ', $pkg->get_ldflags), '-L/usr/local/opt/nss/lib -lnss3 -lnssutil3 -lsmime3 -lssl3 -L/usr/local/Cellar/nspr/4.10.6/lib -lplds4 -lplc4 -lnspr4', 'Libs for nss correct';

$pkg = PkgConfig->find('foo');
like $pkg->errmsg, qr{Can't find bogus\.pc in any of}, 'not found error';
note $pkg->errmsg;

done_testing;
