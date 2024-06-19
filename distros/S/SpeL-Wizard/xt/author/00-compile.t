use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 50;

my @module_files = (
    'SpeL/I18n.pm',
    'SpeL/I18n/en.pm',
    'SpeL/I18n/nl.pm',
    'SpeL/Object/Arrow.pm',
    'SpeL/Object/Binop.pm',
    'SpeL/Object/Command.pm',
    'SpeL/Object/Document.pm',
    'SpeL/Object/Element.pm',
    'SpeL/Object/ElementList.pm',
    'SpeL/Object/Environment.pm',
    'SpeL/Object/Expression.pm',
    'SpeL/Object/Expressionrest.pm',
    'SpeL/Object/Fraction.pm',
    'SpeL/Object/Function.pm',
    'SpeL/Object/Group.pm',
    'SpeL/Object/Interval.pm',
    'SpeL/Object/Item.pm',
    'SpeL/Object/Limitscommand.pm',
    'SpeL/Object/Limitsexpression.pm',
    'SpeL/Object/MathElement.pm',
    'SpeL/Object/MathElementList.pm',
    'SpeL/Object/MathEnvironment.pm',
    'SpeL/Object/MathEnvironmentInner.pm',
    'SpeL/Object/MathEnvironmentSimple.pm',
    'SpeL/Object/MathGroup.pm',
    'SpeL/Object/MathInline.pm',
    'SpeL/Object/MathUnit.pm',
    'SpeL/Object/Mathtotextcommand.pm',
    'SpeL/Object/Matrix.pm',
    'SpeL/Object/Number.pm',
    'SpeL/Object/Operator.pm',
    'SpeL/Object/Option.pm',
    'SpeL/Object/Power.pm',
    'SpeL/Object/Realnumber.pm',
    'SpeL/Object/RelOperator.pm',
    'SpeL/Object/Relation.pm',
    'SpeL/Object/Squareroot.pm',
    'SpeL/Object/Subscript.pm',
    'SpeL/Object/TokenSequence.pm',
    'SpeL/Object/Unop.pm',
    'SpeL/Object/Variable.pm',
    'SpeL/Object/VerbatimEnvironment.pm',
    'SpeL/Parser/Auxiliary.pm',
    'SpeL/Parser/Chunk.pm',
    'SpeL/Wizard.pm'
);

my @scripts = (
    'bin/awspolly.pl',
    'bin/balabolka.pl',
    'bin/festival.pl',
    'bin/spel-wizard.pl'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


