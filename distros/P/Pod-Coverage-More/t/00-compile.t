use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More;

plan tests => 19 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Dist/Zilla/Plugin/Test/Pod/Coverage/More.pm',
    'Pod/Coverage/More.pm',
    'Pod/Coverage/More/Analyzer.pm',
    'Pod/Coverage/More/Analyzer/Perl5_36.pm',
    'Pod/Coverage/More/Analyzer/Perl5_38.pm',
    'Pod/Coverage/More/Analyzer/Perl5_44.pm',
    'Pod/Coverage/More/Blurb.pm',
    'Pod/Coverage/More/Declared.pm',
    'Pod/Coverage/More/Declared/ClassTiny.pm',
    'Pod/Coverage/More/Declared/FunctionParameters.pm',
    'Pod/Coverage/More/Declared/Kavorka.pm',
    'Pod/Coverage/More/Declared/MOP.pm',
    'Pod/Coverage/More/Declared/ObjectPad.pm',
    'Pod/Coverage/More/Declared/TypeParams.pm',
    'Pod/Coverage/More/Documentation.pm',
    'Pod/Coverage/More/Generator.pm',
    'Pod/Coverage/More/Types.pm',
    'Pod/Weaver/Section/Blurbs.pm',
    'Test/Pod/Coverage/More.pm'
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



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


