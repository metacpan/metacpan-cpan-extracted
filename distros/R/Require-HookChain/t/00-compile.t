use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 17 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'RHC.pm',
    'Require/HookChain.pm',
    'Require/HookChain/debug/dump_source/logger.pm',
    'Require/HookChain/debug/dump_source/stderr.pm',
    'Require/HookChain/log/logger.pm',
    'Require/HookChain/log/stderr.pm',
    'Require/HookChain/munge/prepend.pm',
    'Require/HookChain/source/test/code.pm',
    'Require/HookChain/source/test/str.pm',
    'Require/HookChain/test/fail.pm',
    'Require/HookChain/test/noop.pm',
    'Require/HookChain/test/noop_all.pm',
    'Require/HookChain/test/random_fail.pm',
    'Require/HookChain/timestamp/hires.pm',
    'Require/HookChain/timestamp/std.pm',
    'Require/HookChainTest/One.pm',
    'Require/HookChainTest/Two.pm'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


