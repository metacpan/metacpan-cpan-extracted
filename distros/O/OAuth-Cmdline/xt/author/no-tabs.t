use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OAuth/Cmdline.pm',
    'lib/OAuth/Cmdline/Automatic.pm',
    'lib/OAuth/Cmdline/CustomFile.pm',
    'lib/OAuth/Cmdline/GoogleDrive.pm',
    'lib/OAuth/Cmdline/MicrosoftOnline.pm',
    'lib/OAuth/Cmdline/Mojo.pm',
    'lib/OAuth/Cmdline/Smartthings.pm',
    'lib/OAuth/Cmdline/Spotify.pm',
    'lib/OAuth/Cmdline/Youtube.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001Spotify.t',
    't/002Smartthings.t',
    't/003MicrosoftOnline.t'
);

notabs_ok($_) foreach @files;
done_testing;
