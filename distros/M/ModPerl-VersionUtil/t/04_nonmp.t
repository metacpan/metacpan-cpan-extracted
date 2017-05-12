use strict;
use warnings;
use Test::More tests => 6;
use ModPerl::VersionUtil;

ok(!ModPerl::VersionUtil->is_mp);
ok(!ModPerl::VersionUtil->is_mp1);
ok(!ModPerl::VersionUtil->is_mp19);
ok(!ModPerl::VersionUtil->is_mp2);
ok(!ModPerl::VersionUtil->mp_version_string);
ok(!ModPerl::VersionUtil->mp_version);
