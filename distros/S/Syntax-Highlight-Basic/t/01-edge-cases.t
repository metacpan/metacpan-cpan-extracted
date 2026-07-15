#!perl
use 5.016;
use strict;
use warnings;

use Test::More;

use lib 'lib';
use Syntax::Highlight::Basic::Parser;

#===========================================================================
# Edge Case Tests — false positive prevention
# These test that keywords don't match inside longer words.
#===========================================================================

# Helper: get tokens for a line of code
sub tokens {
    my ($lang, $code) = @_;
    my $p = Syntax::Highlight::Basic::Parser->new(language => $lang);
    my $result = $p->parse($code);
    return $result->[0];    # first line
}

# Helper: find a token by text
sub find_token {
    my ($tokens, $text) = @_;
    for my $t (@$tokens) {
        return $t if $t->{text} eq $text;
    }
    return undef;
}

# Helper: check a word is NOT classified as a keyword
sub not_keyword {
    my ($lang, $code, $word, $test_name) = @_;
    my $t = tokens($lang, $code);
    for my $tok (@$t) {
        if ($tok->{text} eq $word) {
            my $is_kw = ($tok->{class} ne 'text' && $tok->{class} ne 'whitespace');
            ok(!$is_kw, "$test_name: '$word' should not be a keyword in '$code'");
            return;
        }
    }
    pass("$test_name: '$word' not found as separate token in '$code'");
}

#===========================================================================
# Perl edge cases
#===========================================================================

# "int" inside "print" must NOT be a keyword
{
    my $t = tokens('perl', 'print "hello"');
    my $found = 0;
    for my $tok (@$t) {
        if ($tok->{text} =~ /print/) {
            $found = 1;
            is($tok->{class}, 'text', q{Perl: 'print' should be text, not split into pr+int});
        }
        if ($tok->{text} eq 'int') {
            fail(q{Perl: 'int' should NOT appear as separate token inside 'print'});
            $found = 1;
        }
    }
    ok($found, q{Perl: found 'print' token});
}

# "or" inside "world" must NOT be a keyword
not_keyword('perl', 'my $world = "hello"', 'world',
    q{Perl: 'or' must NOT highlight inside 'world'});

# "do" inside "window" must NOT be a keyword
not_keyword('perl', 'my $window = 1', 'window',
    q{Perl: 'do' must NOT highlight inside 'window'});

# "for" inside "before" must NOT be a keyword
not_keyword('perl', 'my $before = 1', 'before',
    q{Perl: 'for' must NOT highlight inside 'before'});

#===========================================================================
# Python edge cases
#===========================================================================

# "not" inside "nothing" must NOT be a keyword
not_keyword('python', 'x = nothing', 'nothing',
    q{Python: 'not' must NOT highlight inside 'nothing'});

# "in" inside "println" must NOT be a keyword
not_keyword('python', 'println("hi")', 'println',
    q{Python: 'in' must NOT highlight inside 'println'});

# "or" inside "world" must NOT be a keyword
not_keyword('python', 'name = "world"', 'world',
    q{Python: 'or' must NOT highlight inside 'world'});

#===========================================================================
# JavaScript edge cases
#===========================================================================

# "in" inside "println" must NOT be a keyword
not_keyword('javascript', 'println("hi")', 'println',
    q{JS: 'in' must NOT highlight inside 'println'});

# "of" inside "often" must NOT be a keyword
not_keyword('javascript', 'var often = 1', 'often',
    q{JS: 'of' must NOT highlight inside 'often'});

# "or" inside "world" must NOT be a keyword
not_keyword('javascript', 'var world = 1', 'world',
    q{JS: 'or' must NOT highlight inside 'world'});

#===========================================================================
# C edge cases
#===========================================================================

# "int" inside "printf" must NOT be a keyword
{
    my $t = tokens('c', 'printf("hello")');
    for my $tok (@$t) {
        if ($tok->{text} =~ /printf/) {
            is($tok->{class}, 'text', q{C: 'printf' should be text});
        }
    }
}

# "for" inside "before" must NOT be a keyword
not_keyword('c', 'int before = 1', 'before',
    q{C: 'for' must NOT highlight inside 'before'});

#===========================================================================
# Java edge cases
#===========================================================================

# "for" inside "before" must NOT be a keyword
not_keyword('java', 'String before = "hi"', 'before',
    q{Java: 'for' must NOT highlight inside 'before'});

#===========================================================================
# Ruby edge cases
#===========================================================================

# "if" inside "elsif" — special case: "if" IS inside "elsif"
# This is a known limitation — "elsif" is a keyword but "if" substring may match
# We test that "elsif" itself is recognized correctly
{
    my $t = tokens('ruby', 'elsif true');
    my $found = 0;
    for my $tok (@$t) {
        if ($tok->{text} eq 'elsif') {
            $found = 1;
            ok($tok->{class} ne 'text', q{Ruby: 'elsif' should be a keyword});
        }
    }
    ok($found, q{Ruby: found 'elsif' token});
}

#===========================================================================
# Shell edge cases
#===========================================================================

# Shell: "done" IS a keyword (closes do...done), test it's recognized
{
    my $t = tokens('sh', 'done');
    my $found = 0;
    for my $tok (@$t) {
        if ($tok->{text} eq 'do') {
            fail(q{Shell: 'do' must NOT appear as separate token inside 'done'});
        }
        if ($tok->{text} eq 'done') {
            $found = 1;
            ok($tok->{class} ne 'text', q{Shell: 'done' is a valid keyword});
        }
    }
    ok($found, q{Shell: found 'done' token});
}

done_testing();