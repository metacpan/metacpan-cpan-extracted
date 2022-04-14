
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'bin/ooi',
    'lib/OPM/Installer.pm',
    'lib/OPM/Installer/Logger.pm',
    'lib/OPM/Installer/Utils/Config.pm',
    'lib/OPM/Installer/Utils/File.pm',
    'lib/OPM/Installer/Utils/Linux.pm',
    'lib/OPM/Installer/Utils/TS.pm',
    'lib/OPM/Installer/Utils/Test.pm',
    't/config/base.t',
    't/config/croak.t',
    't/config/myhome.t',
    't/config/rel.rc',
    't/config/rel.t',
    't/config/set.t',
    't/config/test.rc',
    't/file/base.t',
    't/file/file_exists.t',
    't/file/framework6.t',
    't/file/is_url.t',
    't/file/not_there.t',
    't/file/repo/AccountedTimeInOverview-6.0.1.opm',
    't/file/repo/ActionDynamicFieldSet-6.0.1.opm',
    't/file/repo/DynamicFieldCheckedDate-5.0.6.opm',
    't/file/repo/InvalidOPM-6.0.6.opm',
    't/file/repo/TicketOverviewHooked-5.0.6.opm',
    't/file/repo/otrs.xml',
    't/file/url_with_otrs_xml.t',
    't/file/wrong_framework_version.t',
    't/functions/check_matching_version.t',
    't/installer/install.t',
    't/installer/lib/MyLogger.pm',
    't/installer/lib/MyManager.pm',
    't/installer/lib/MyUtils.pm',
    't/logger/base.t',
    't/logger/messages.t',
    't/logger/path.t',
    't/otrs/base.t',
    't/otrs/opt/Kernel/System/ObjectManager.pm',
    't/otrs/opt/RELEASE'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
