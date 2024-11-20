use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 31 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Tapper/MCP.pm',
    'Tapper/MCP/Child.pm',
    'Tapper/MCP/Config.pm',
    'Tapper/MCP/Control.pm',
    'Tapper/MCP/Daemon.pm',
    'Tapper/MCP/Info.pm',
    'Tapper/MCP/Master.pm',
    'Tapper/MCP/Net.pm',
    'Tapper/MCP/Net/Reset/DoNothing.pm',
    'Tapper/MCP/Net/Reset/Exec.pm',
    'Tapper/MCP/Net/Reset/OSRC.pm',
    'Tapper/MCP/Net/Reset/PM211MIP.pm',
    'Tapper/MCP/Net/TAP.pm',
    'Tapper/MCP/Plugin.pm',
    'Tapper/MCP/Plugin/Test/All.pm',
    'Tapper/MCP/Scheduler/Algorithm.pm',
    'Tapper/MCP/Scheduler/Algorithm/DummyAlgorithm.pm',
    'Tapper/MCP/Scheduler/Algorithm/WFQ.pm',
    'Tapper/MCP/Scheduler/Builder.pm',
    'Tapper/MCP/Scheduler/Controller.pm',
    'Tapper/MCP/Scheduler/Host.pm',
    'Tapper/MCP/Scheduler/Job.pm',
    'Tapper/MCP/Scheduler/ObjectBuilder.pm',
    'Tapper/MCP/Scheduler/PrioQueue.pm',
    'Tapper/MCP/Scheduler/Queue.pm',
    'Tapper/MCP/State.pm',
    'Tapper/MCP/State/Details.pm',
    'Tapper/MCP/State/Plugin/Dummy.pm',
    'Tapper/MCP/State/Plugin/OSRC.pm'
);

my @scripts = (
    'bin/tapper-mcp',
    'bin/tapper-mcp-daemon'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


