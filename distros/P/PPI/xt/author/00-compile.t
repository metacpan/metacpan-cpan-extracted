use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More 0.94;

plan tests => 95;

my @module_files = (
    'PPI.pm',
    'PPI/Cache.pm',
    'PPI/Document.pm',
    'PPI/Document/File.pm',
    'PPI/Document/Fragment.pm',
    'PPI/Document/Normalized.pm',
    'PPI/Dumper.pm',
    'PPI/Element.pm',
    'PPI/Exception.pm',
    'PPI/Exception/ParserRejection.pm',
    'PPI/Find.pm',
    'PPI/Lexer.pm',
    'PPI/Node.pm',
    'PPI/Normal.pm',
    'PPI/Normal/Standard.pm',
    'PPI/Singletons.pm',
    'PPI/Statement.pm',
    'PPI/Statement/Break.pm',
    'PPI/Statement/Compound.pm',
    'PPI/Statement/Data.pm',
    'PPI/Statement/End.pm',
    'PPI/Statement/Expression.pm',
    'PPI/Statement/Given.pm',
    'PPI/Statement/Include.pm',
    'PPI/Statement/Include/Perl6.pm',
    'PPI/Statement/Null.pm',
    'PPI/Statement/Package.pm',
    'PPI/Statement/Scheduled.pm',
    'PPI/Statement/Sub.pm',
    'PPI/Statement/Unknown.pm',
    'PPI/Statement/UnmatchedBrace.pm',
    'PPI/Statement/Variable.pm',
    'PPI/Statement/When.pm',
    'PPI/Structure.pm',
    'PPI/Structure/Block.pm',
    'PPI/Structure/Condition.pm',
    'PPI/Structure/Constructor.pm',
    'PPI/Structure/For.pm',
    'PPI/Structure/Given.pm',
    'PPI/Structure/List.pm',
    'PPI/Structure/Subscript.pm',
    'PPI/Structure/Unknown.pm',
    'PPI/Structure/When.pm',
    'PPI/Token.pm',
    'PPI/Token/ArrayIndex.pm',
    'PPI/Token/Attribute.pm',
    'PPI/Token/BOM.pm',
    'PPI/Token/Cast.pm',
    'PPI/Token/Comment.pm',
    'PPI/Token/DashedWord.pm',
    'PPI/Token/Data.pm',
    'PPI/Token/End.pm',
    'PPI/Token/HereDoc.pm',
    'PPI/Token/Label.pm',
    'PPI/Token/Magic.pm',
    'PPI/Token/Number.pm',
    'PPI/Token/Number/Binary.pm',
    'PPI/Token/Number/Exp.pm',
    'PPI/Token/Number/Float.pm',
    'PPI/Token/Number/Hex.pm',
    'PPI/Token/Number/Octal.pm',
    'PPI/Token/Number/Version.pm',
    'PPI/Token/Operator.pm',
    'PPI/Token/Pod.pm',
    'PPI/Token/Prototype.pm',
    'PPI/Token/Quote.pm',
    'PPI/Token/Quote/Double.pm',
    'PPI/Token/Quote/Interpolate.pm',
    'PPI/Token/Quote/Literal.pm',
    'PPI/Token/Quote/Single.pm',
    'PPI/Token/QuoteLike.pm',
    'PPI/Token/QuoteLike/Backtick.pm',
    'PPI/Token/QuoteLike/Command.pm',
    'PPI/Token/QuoteLike/Readline.pm',
    'PPI/Token/QuoteLike/Regexp.pm',
    'PPI/Token/QuoteLike/Words.pm',
    'PPI/Token/Regexp.pm',
    'PPI/Token/Regexp/Match.pm',
    'PPI/Token/Regexp/Substitute.pm',
    'PPI/Token/Regexp/Transliterate.pm',
    'PPI/Token/Separator.pm',
    'PPI/Token/Structure.pm',
    'PPI/Token/Symbol.pm',
    'PPI/Token/Unknown.pm',
    'PPI/Token/Whitespace.pm',
    'PPI/Token/Word.pm',
    'PPI/Token/_QuoteEngine.pm',
    'PPI/Token/_QuoteEngine/Full.pm',
    'PPI/Token/_QuoteEngine/Simple.pm',
    'PPI/Tokenizer.pm',
    'PPI/Transform.pm',
    'PPI/Transform/UpdateCopyright.pm',
    'PPI/Util.pm',
    'PPI/XSAccessor.pm'
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
