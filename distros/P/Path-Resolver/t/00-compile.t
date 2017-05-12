use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.034

use Test::More 0.94 tests => 15;



my @module_files = (
    'Path/Resolver.pm',
    'Path/Resolver/CustomConverter.pm',
    'Path/Resolver/Resolver/AnyDist.pm',
    'Path/Resolver/Resolver/Archive/Tar.pm',
    'Path/Resolver/Resolver/DataSection.pm',
    'Path/Resolver/Resolver/DistDir.pm',
    'Path/Resolver/Resolver/FileSystem.pm',
    'Path/Resolver/Resolver/Hash.pm',
    'Path/Resolver/Resolver/Mux/Ordered.pm',
    'Path/Resolver/Resolver/Mux/Prefix.pm',
    'Path/Resolver/Role/Converter.pm',
    'Path/Resolver/Role/FileResolver.pm',
    'Path/Resolver/Role/Resolver.pm',
    'Path/Resolver/SimpleEntity.pm',
    'Path/Resolver/Types.pm'
);



# no fake home requested

use File::Spec;
use IPC::Open3;
use IO::Handle;

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, '-Mblib', '-e', "require q[$lib]");
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



# no warning checks;

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
