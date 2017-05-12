use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.046

use Test::More  tests => 39 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Net/Launchpad.pm',
    'Net/Launchpad/Client.pm',
    'Net/Launchpad/Model.pm',
    'Net/Launchpad/Model/Archive.pm',
    'Net/Launchpad/Model/Base.pm',
    'Net/Launchpad/Model/Branch.pm',
    'Net/Launchpad/Model/Bug.pm',
    'Net/Launchpad/Model/BugTracker.pm',
    'Net/Launchpad/Model/Builder.pm',
    'Net/Launchpad/Model/CVE.pm',
    'Net/Launchpad/Model/Country.pm',
    'Net/Launchpad/Model/Distribution.pm',
    'Net/Launchpad/Model/Language.pm',
    'Net/Launchpad/Model/Person.pm',
    'Net/Launchpad/Model/Project.pm',
    'Net/Launchpad/Model/Query/Branch.pm',
    'Net/Launchpad/Model/Query/Builder.pm',
    'Net/Launchpad/Model/Query/Country.pm',
    'Net/Launchpad/Model/Query/Person.pm',
    'Net/Launchpad/Model/Query/Project.pm',
    'Net/Launchpad/Query.pm',
    'Net/Launchpad/Role/Archive.pm',
    'Net/Launchpad/Role/Branch.pm',
    'Net/Launchpad/Role/Bug.pm',
    'Net/Launchpad/Role/BugTracker.pm',
    'Net/Launchpad/Role/Builder.pm',
    'Net/Launchpad/Role/CVE.pm',
    'Net/Launchpad/Role/Common.pm',
    'Net/Launchpad/Role/Country.pm',
    'Net/Launchpad/Role/Distribution.pm',
    'Net/Launchpad/Role/Language.pm',
    'Net/Launchpad/Role/Person.pm',
    'Net/Launchpad/Role/Project.pm',
    'Net/Launchpad/Role/Query.pm',
    'Net/Launchpad/Role/Query/Branch.pm',
    'Net/Launchpad/Role/Query/Builder.pm',
    'Net/Launchpad/Role/Query/Country.pm',
    'Net/Launchpad/Role/Query/Person.pm',
    'Net/Launchpad/Role/Query/Project.pm'
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



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', explain \@warnings if $ENV{AUTHOR_TESTING};


