use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.036

use Test::More 0.94 tests => 4;



my @module_files = (
    'Role/HasPayload.pm',
    'Role/HasPayload/Auto.pm',
    'Role/HasPayload/Merged.pm',
    'Role/HasPayload/Meta/Attribute/Payload.pm'
);



# no fake home requested

my $inc_switch = q[-Mblib];

use File::Spec;
use IPC::Open3;
use IO::Handle;

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";
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



# no warning checks;

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
