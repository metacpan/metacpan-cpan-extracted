use 5.006;
use strict;
use warnings;

use Sub::Multi::Tiny::SigParse;
use Test::Fatal;
use Test::More;

{
    package FakeYappParser;
    my $text = @ARGV ? $ARGV[0] : ",,,,,";

    sub new {
        my ($class, $text) = @_;
        my $self = ["$text"];
        bless $self, shift;
    }

    sub YYData {
        my $self = shift;
        return {TEXT=>\($self->[0])}
    };
}

# Back in package main

# --- Helpers ---------------------------------------------------------

# Map undef -> '<undef>' for ease of reading
sub _u { defined $_[0] ? $_[0] : '<undef>' }

# Line number as a string
sub _l {
    my (undef, undef, $line) = caller;
    return "line $line";
}

# Test a particular input string
sub CheckSuccess {
    my (undef, undef, $line) = caller;
    my ($text, $lrExpected) = @_;
    my $parser = FakeYappParser->new($text);

    my $testnum = 0;

    foreach my $test (@$lrExpected) {
        # Get the next token
        my ($ty, $val) = Sub::Multi::Tiny::SigParse::_next_token($parser);

        # Regularize
        $ty = _u $ty;
        $val = _u $val;
        $test->[$_] = _u $test->[$_] foreach 0..$#$test;
        #diag "Got $ty = $val";

        # Test
        is($ty, $test->[0],  "Token $test->[0] (line $line test $testnum)");
        is_deeply($val, $test->[1],
                "Value $test->[1] (line $line test $testnum)");

        ++$testnum;
    }
} #CheckSuccess()

# For tests we expect will die.  Returns ($ty, $val) if it succeeds.
sub FirstToken {
    my (undef, undef, $line) = caller;
    my ($text, $lrExpected) = @_;
    my $parser = FakeYappParser->new($text);
    return Sub::Multi::Tiny::SigParse::_next_token($parser);
} #FirstToken()

# Make a hashref representing a parameter
sub _p($$$) {
    +{ name=>$_[0], named=>!!$_[1], reqd=>!!$_[2] }
}

# --- Success tests ---------------------------------------------------

# Empty, or WS-only
CheckSuccess('', [['', '<undef>']]);
CheckSuccess(' ', [['', '<undef>']]);
CheckSuccess("\t", [['', '<undef>']]);
CheckSuccess("\n", [['', '<undef>']]);
CheckSuccess("\t  \t\n \n", [['', '<undef>']]);

# Comma, plus various whitespace combinations
CheckSuccess(',', [[SEPAR => 0]]);
CheckSuccess('   ,', [[SEPAR => 0]]);
CheckSuccess(',    ', [[SEPAR => 0]]);
CheckSuccess('   ,    ', [[SEPAR => 0]]);
CheckSuccess("\t,", [[SEPAR => 0]]);
CheckSuccess(",\t", [[SEPAR => 0]]);
CheckSuccess("\t,\t", [[SEPAR => 0]]);
CheckSuccess("\t,    ", [[SEPAR => 0]]);
CheckSuccess("  ,\t", [[SEPAR => 0]]);
CheckSuccess(" \n  , \n\t", [[SEPAR => 0]]);

# Positional parameters
CheckSuccess('$foo',[[PARAM=>_p('$foo', 0, 1)]]);
CheckSuccess('   $foo',[[PARAM=>_p('$foo', 0, 1)]]);
CheckSuccess('$foo   ',[[PARAM=>_p('$foo', 0, 1)]]);
CheckSuccess('@foo',[[PARAM=>_p('@foo', 0, 1)]]);
CheckSuccess('%foo',[[PARAM=>_p('%foo', 0, 1)]]);
CheckSuccess('&foo',[[PARAM=>_p('&foo', 0, 1)]]);
CheckSuccess('*foo',[[PARAM=>_p('*foo', 0, 1)]]);

# Named parameters
CheckSuccess(':$foo',[[PARAM=>_p('$foo', 1, 0)]]);
CheckSuccess('   :$foo',[[PARAM=>_p('$foo', 1, 0)]]);
CheckSuccess(':$foo   ',[[PARAM=>_p('$foo', 1, 0)]]);
CheckSuccess(':@foo',[[PARAM=>_p('@foo', 1, 0)]]);
CheckSuccess(':%foo',[[PARAM=>_p('%foo', 1, 0)]]);
CheckSuccess(':&foo',[[PARAM=>_p('&foo', 1, 0)]]);
CheckSuccess(':*foo',[[PARAM=>_p('*foo', 1, 0)]]);

# where {} clauses
CheckSuccess('where {1}', [[WHERE=>'{1}']]);
CheckSuccess('WHERE {1}', [[WHERE=>'{1}']]);
CheckSuccess('where {1}    ', [[WHERE=>'{1}']]);
CheckSuccess("   where\t{1}", [[WHERE=>'{1}']]);
CheckSuccess("where\n{1}", [[WHERE=>'{1}']]);
CheckSuccess('where {{}}', [[WHERE=>'{{}}']]);
CheckSuccess('where {"\}"}', [[WHERE=>'{"\}"}']]);

# Braced expressions
CheckSuccess('{1}', [[TYPE=>'{1}']]);
CheckSuccess('{1}    ', [[TYPE=>'{1}']]);
CheckSuccess("   \t{1}", [[TYPE=>'{1}']]);
CheckSuccess("\n{1}", [[TYPE=>'{1}']]);
CheckSuccess('{{}}', [[TYPE=>'{{}}']]);
CheckSuccess('{"\}"}', [[TYPE=>'{"\}"}']]);

# Single words
CheckSuccess('Int',[[TYPE=>'Int']]);
CheckSuccess('  Int',[[TYPE=>'Int']]);
CheckSuccess('Int  ',[[TYPE=>'Int']]);
CheckSuccess('Array[Int]',[[TYPE=>'Array[Int]']]);
CheckSuccess("t('Foo')",[[TYPE=>"t('Foo')"]]);

# Multiple words
CheckSuccess('Int String',[[TYPE=>'Int'], [TYPE=>'String']]);
CheckSuccess('  Int String',[[TYPE=>'Int'], [TYPE=>'String']]);
CheckSuccess('Int String  ',[[TYPE=>'Int'], [TYPE=>'String']]);
CheckSuccess("Int\t\n String  ",[[TYPE=>'Int'], [TYPE=>'String']]);
CheckSuccess('Int Array[Foo]  ',[[TYPE=>'Int'], [TYPE=>'Array[Foo]']]);

# A random big test
CheckSuccess('   {x} $foo,    where { $foo > 1 }, 42[bar] {long one},', [
    [ TYPE => '{x}' ],
    [ PARAM => _p('$foo', 0, 1) ],
    [ SEPAR => 0 ],
    [ WHERE => '{ $foo > 1 }' ],
    [ SEPAR => 0 ],
    [ TYPE => '42[bar]' ],
    [ TYPE => '{long one}' ],
    [ SEPAR => 0 ],
]);

# --- Failure tests ---------------------------------------------------

like exception { FirstToken 'where {' }, qr/'where' without/, _l;
like exception { FirstToken '{' }, qr/opening brace without/, _l;
like exception { FirstToken '  {' }, qr/opening brace without/, _l;
like exception { FirstToken '{  ' }, qr/opening brace without/, _l;
like exception { FirstToken "\n\t {\t\n  " }, qr/opening brace without/, _l;
like exception { FirstToken '\n\t {\t\n  ' }, qr/backslash/, _l;

done_testing;
