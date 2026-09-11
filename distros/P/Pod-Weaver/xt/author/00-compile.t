use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More 0.94;

plan tests => 28;

my @module_files = (
    'Pod/Weaver.pm',
    'Pod/Weaver/Config.pm',
    'Pod/Weaver/Config/Assembler.pm',
    'Pod/Weaver/Config/Finder.pm',
    'Pod/Weaver/Plugin/EnsurePod5.pm',
    'Pod/Weaver/Plugin/H1Nester.pm',
    'Pod/Weaver/Plugin/SingleEncoding.pm',
    'Pod/Weaver/Plugin/Transformer.pm',
    'Pod/Weaver/PluginBundle/CorePrep.pm',
    'Pod/Weaver/PluginBundle/Default.pm',
    'Pod/Weaver/Role/Dialect.pm',
    'Pod/Weaver/Role/Finalizer.pm',
    'Pod/Weaver/Role/Plugin.pm',
    'Pod/Weaver/Role/Preparer.pm',
    'Pod/Weaver/Role/Section.pm',
    'Pod/Weaver/Role/StringFromComment.pm',
    'Pod/Weaver/Role/Transformer.pm',
    'Pod/Weaver/Section/Authors.pm',
    'Pod/Weaver/Section/Bugs.pm',
    'Pod/Weaver/Section/Collect.pm',
    'Pod/Weaver/Section/GenerateSection.pm',
    'Pod/Weaver/Section/Generic.pm',
    'Pod/Weaver/Section/Leftovers.pm',
    'Pod/Weaver/Section/Legal.pm',
    'Pod/Weaver/Section/Name.pm',
    'Pod/Weaver/Section/Region.pm',
    'Pod/Weaver/Section/Version.pm'
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
