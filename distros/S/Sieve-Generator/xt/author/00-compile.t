use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More 0.94;

plan tests => 16;

my @module_files = (
    'Sieve/Generator.pm',
    'Sieve/Generator/Element.pm',
    'Sieve/Generator/Element/Block.pm',
    'Sieve/Generator/Element/BracketComment.pm',
    'Sieve/Generator/Element/Command.pm',
    'Sieve/Generator/Element/Comment.pm',
    'Sieve/Generator/Element/Document.pm',
    'Sieve/Generator/Element/Heredoc.pm',
    'Sieve/Generator/Element/IfElse.pm',
    'Sieve/Generator/Element/Junction.pm',
    'Sieve/Generator/Element/Num.pm',
    'Sieve/Generator/Element/Qstr.pm',
    'Sieve/Generator/Element/QstrList.pm',
    'Sieve/Generator/Element/Terms.pm',
    'Sieve/Generator/Sugar.pm'
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

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'}.$str.q{'} }
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



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
