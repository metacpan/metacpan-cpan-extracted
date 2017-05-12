use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More 0.94;

plan tests => 30 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Search/GIN.pm',
    'Search/GIN/Callbacks.pm',
    'Search/GIN/Core.pm',
    'Search/GIN/DelegateToIndexed.pm',
    'Search/GIN/Driver.pm',
    'Search/GIN/Driver/Hash.pm',
    'Search/GIN/Driver/Pack.pm',
    'Search/GIN/Driver/Pack/Delim.pm',
    'Search/GIN/Driver/Pack/IDs.pm',
    'Search/GIN/Driver/Pack/Length.pm',
    'Search/GIN/Driver/Pack/UUID.pm',
    'Search/GIN/Driver/Pack/Values.pm',
    'Search/GIN/Driver/TXN.pm',
    'Search/GIN/Extract.pm',
    'Search/GIN/Extract/Attributes.pm',
    'Search/GIN/Extract/Callback.pm',
    'Search/GIN/Extract/Class.pm',
    'Search/GIN/Extract/Delegate.pm',
    'Search/GIN/Extract/Multiplex.pm',
    'Search/GIN/Indexable.pm',
    'Search/GIN/Keys.pm',
    'Search/GIN/Keys/Deep.pm',
    'Search/GIN/Keys/Expand.pm',
    'Search/GIN/Keys/Join.pm',
    'Search/GIN/Query.pm',
    'Search/GIN/Query/Attributes.pm',
    'Search/GIN/Query/Class.pm',
    'Search/GIN/Query/Manual.pm',
    'Search/GIN/Query/Set.pm',
    'Search/GIN/SelfIDs.pm'
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
    or diag 'got warnings: ', explain(\@warnings) if $ENV{AUTHOR_TESTING};

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
