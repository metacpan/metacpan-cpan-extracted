use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'Changes',
    'GPLv3',
    'MANIFEST.SKIP',
    'VERSION',
    'lib/Systemd/Daemon.pm',
    'lib/Systemd/Daemon/Stub.pm',
    'lib/Systemd/Daemon/XS.pm',
    't/01-stub-export.t',
    't/02-stub-func.t',
    't/03-xs-export.t',
    't/04-xs-func.t',
    't/05-export.t',
    't/06-notify.t',
    't/lib/TestSD.pm',
    't/notify.pl',
    'xt/aspell-en.pws',
    'xt/perlcritic.ini'
);

notabs_ok($_) foreach @files;
done_testing;
