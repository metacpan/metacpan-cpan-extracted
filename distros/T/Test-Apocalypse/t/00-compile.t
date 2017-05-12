use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 36 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Test/Apocalypse.pm',
    'Test/Apocalypse/AutoLoader.pm',
    'Test/Apocalypse/CPANChanges.pm',
    'Test/Apocalypse/CPANMeta.pm',
    'Test/Apocalypse/CPANMeta_JSON.pm',
    'Test/Apocalypse/CPANMeta_YAML.pm',
    'Test/Apocalypse/Compile.pm',
    'Test/Apocalypse/ConsistentVersion.pm',
    'Test/Apocalypse/DOSnewline.pm',
    'Test/Apocalypse/Dependencies.pm',
    'Test/Apocalypse/DirChecks.pm',
    'Test/Apocalypse/DistManifest.pm',
    'Test/Apocalypse/EOL.pm',
    'Test/Apocalypse/FileChecks.pm',
    'Test/Apocalypse/FilePortability.pm',
    'Test/Apocalypse/Fixme.pm',
    'Test/Apocalypse/HasVersion.pm',
    'Test/Apocalypse/Kwalitee.pm',
    'Test/Apocalypse/MinimumVersion.pm',
    'Test/Apocalypse/Mojibake.pm',
    'Test/Apocalypse/NoBreakpoints.pm',
    'Test/Apocalypse/NoPlan.pm',
    'Test/Apocalypse/PPPort.pm',
    'Test/Apocalypse/PerlCritic.pm',
    'Test/Apocalypse/PerlMetrics.pm',
    'Test/Apocalypse/Pod.pm',
    'Test/Apocalypse/Pod_CommonMistakes.pm',
    'Test/Apocalypse/Pod_Coverage.pm',
    'Test/Apocalypse/Pod_LinkCheck.pm',
    'Test/Apocalypse/Pod_No404s.pm',
    'Test/Apocalypse/Pod_Spelling.pm',
    'Test/Apocalypse/Script.pm',
    'Test/Apocalypse/Signature.pm',
    'Test/Apocalypse/Strict.pm',
    'Test/Apocalypse/Synopsis.pm',
    'Test/Apocalypse/UnusedVars.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


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


