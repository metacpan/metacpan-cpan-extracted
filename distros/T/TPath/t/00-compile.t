use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.044

use Test::More  tests => 64 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'TPath.pm',
    'TPath/Attribute.pm',
    'TPath/AttributeTest.pm',
    'TPath/Attributes/Extended.pm',
    'TPath/Attributes/Standard.pm',
    'TPath/Compiler.pm',
    'TPath/Concatenation.pm',
    'TPath/Context.pm',
    'TPath/Expression.pm',
    'TPath/Forester.pm',
    'TPath/Function.pm',
    'TPath/Grammar.pm',
    'TPath/Index.pm',
    'TPath/LogStream.pm',
    'TPath/Math.pm',
    'TPath/Numifiable.pm',
    'TPath/Predicate.pm',
    'TPath/Predicate/Attribute.pm',
    'TPath/Predicate/AttributeTest.pm',
    'TPath/Predicate/Boolean.pm',
    'TPath/Predicate/Expression.pm',
    'TPath/Predicate/Index.pm',
    'TPath/Selector.pm',
    'TPath/Selector/Expression.pm',
    'TPath/Selector/Id.pm',
    'TPath/Selector/Parent.pm',
    'TPath/Selector/Predicated.pm',
    'TPath/Selector/Previous.pm',
    'TPath/Selector/Quantified.pm',
    'TPath/Selector/Self.pm',
    'TPath/Selector/Test.pm',
    'TPath/Selector/Test/Anywhere.pm',
    'TPath/Selector/Test/AnywhereAttribute.pm',
    'TPath/Selector/Test/AnywhereMatch.pm',
    'TPath/Selector/Test/AnywhereTag.pm',
    'TPath/Selector/Test/AxisAttribute.pm',
    'TPath/Selector/Test/AxisMatch.pm',
    'TPath/Selector/Test/AxisTag.pm',
    'TPath/Selector/Test/AxisWildcard.pm',
    'TPath/Selector/Test/ChildAttribute.pm',
    'TPath/Selector/Test/ChildMatch.pm',
    'TPath/Selector/Test/ChildTag.pm',
    'TPath/Selector/Test/ClosestAttribute.pm',
    'TPath/Selector/Test/ClosestMatch.pm',
    'TPath/Selector/Test/ClosestTag.pm',
    'TPath/Selector/Test/Match.pm',
    'TPath/Selector/Test/Root.pm',
    'TPath/StderrLog.pm',
    'TPath/Stringifiable.pm',
    'TPath/Test.pm',
    'TPath/Test/And.pm',
    'TPath/Test/Boolean.pm',
    'TPath/Test/Compound.pm',
    'TPath/Test/Node.pm',
    'TPath/Test/Node/Attribute.pm',
    'TPath/Test/Node/Complement.pm',
    'TPath/Test/Node/Match.pm',
    'TPath/Test/Node/Tag.pm',
    'TPath/Test/Node/True.pm',
    'TPath/Test/Not.pm',
    'TPath/Test/One.pm',
    'TPath/Test/Or.pm',
    'TPath/TypeCheck.pm',
    'TPath/TypeConstraints.pm'
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



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


