use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.029

use Test::More  tests => 6 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Parse/Path.pm',
    'Parse/Path/DZIL.pm',
    'Parse/Path/File/Unix.pm',
    'Parse/Path/File/Win32.pm',
    'Parse/Path/PerlClass.pm',
    'Parse/Path/Role/Path.pm'
);



# no fake home requested

use IPC::Open3;
use IO::Handle;

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stdin = '';     # converted to a gensym by open3
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, qq{$^X -Mblib -e"require q[$lib]"});
    binmode $stderr, ':crlf' if $^O; # eq 'MSWin32';
    waitpid($pid, 0);
    is($? >> 8, 0, "$lib loaded ok");

    if (my @_warnings = <$stderr>)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


