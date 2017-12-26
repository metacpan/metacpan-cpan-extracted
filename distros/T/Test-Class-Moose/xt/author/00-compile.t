use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 24;

my @module_files = (
    'Test/Class/Moose.pm',
    'Test/Class/Moose/AttributeRegistry.pm',
    'Test/Class/Moose/CLI.pm',
    'Test/Class/Moose/Config.pm',
    'Test/Class/Moose/Deprecated.pm',
    'Test/Class/Moose/Executor/Parallel.pm',
    'Test/Class/Moose/Executor/Sequential.pm',
    'Test/Class/Moose/Load.pm',
    'Test/Class/Moose/Report.pm',
    'Test/Class/Moose/Report/Class.pm',
    'Test/Class/Moose/Report/Instance.pm',
    'Test/Class/Moose/Report/Method.pm',
    'Test/Class/Moose/Report/Time.pm',
    'Test/Class/Moose/Role.pm',
    'Test/Class/Moose/Role/AutoUse.pm',
    'Test/Class/Moose/Role/CLI.pm',
    'Test/Class/Moose/Role/Executor.pm',
    'Test/Class/Moose/Role/HasTimeReport.pm',
    'Test/Class/Moose/Role/ParameterizedInstances.pm',
    'Test/Class/Moose/Role/Reporting.pm',
    'Test/Class/Moose/Runner.pm',
    'Test/Class/Moose/Tutorial.pm',
    'Test/Class/Moose/Util.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


