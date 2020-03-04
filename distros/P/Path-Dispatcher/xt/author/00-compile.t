use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More 0.94;

plan tests => 21;

my @module_files = (
    'Path/Dispatcher.pm',
    'Path/Dispatcher/Dispatch.pm',
    'Path/Dispatcher/Match.pm',
    'Path/Dispatcher/Path.pm',
    'Path/Dispatcher/Role/Rules.pm',
    'Path/Dispatcher/Rule.pm',
    'Path/Dispatcher/Rule/Alternation.pm',
    'Path/Dispatcher/Rule/Always.pm',
    'Path/Dispatcher/Rule/Chain.pm',
    'Path/Dispatcher/Rule/CodeRef.pm',
    'Path/Dispatcher/Rule/Dispatch.pm',
    'Path/Dispatcher/Rule/Empty.pm',
    'Path/Dispatcher/Rule/Enum.pm',
    'Path/Dispatcher/Rule/Eq.pm',
    'Path/Dispatcher/Rule/Intersection.pm',
    'Path/Dispatcher/Rule/Metadata.pm',
    'Path/Dispatcher/Rule/Regex.pm',
    'Path/Dispatcher/Rule/Sequence.pm',
    'Path/Dispatcher/Rule/Tokens.pm',
    'Path/Dispatcher/Rule/Under.pm'
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
    or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
