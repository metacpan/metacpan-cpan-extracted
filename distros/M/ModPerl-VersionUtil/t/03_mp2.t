use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    $ENV{MOD_PERL} = 'mod_perl/2.0.2';
    $ENV{MOD_PERL_API_VERSION} = 2;
    $INC{'Apache2/RequestRec.pm'} = 1;
    require ModPerl::VersionUtil;
}

ok(ModPerl::VersionUtil->is_mp);
ok(!ModPerl::VersionUtil->is_mp1);
ok(!ModPerl::VersionUtil->is_mp19);
ok(ModPerl::VersionUtil->is_mp2);
is(ModPerl::VersionUtil->mp_version_string, '2.0.2');
is(ModPerl::VersionUtil->mp_version, '2.02');
