use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.052

use Test::More;

plan tests => 13 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'SmokeRunner/Multi.pm',
    'SmokeRunner/Multi/Config.pm',
    'SmokeRunner/Multi/DBI.pm',
    'SmokeRunner/Multi/Reporter.pm',
    'SmokeRunner/Multi/Reporter/Screen.pm',
    'SmokeRunner/Multi/Reporter/Smolder.pm',
    'SmokeRunner/Multi/Runner.pm',
    'SmokeRunner/Multi/Runner/Prove.pm',
    'SmokeRunner/Multi/Runner/TAPArchive.pm',
    'SmokeRunner/Multi/SafeRun.pm',
    'SmokeRunner/Multi/TestSet.pm',
    'SmokeRunner/Multi/TestSet/SVN.pm',
    'SmokeRunner/Multi/Validate.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


