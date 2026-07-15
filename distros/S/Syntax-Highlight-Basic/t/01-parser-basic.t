#!perl
use 5.016;
use strict;
use warnings;

use Test::More;

use lib 'lib';
use Syntax::Highlight::Basic::Parser;

#===========================================================================
# Parser Basic Tests
#===========================================================================

# Helper: find a token in parse result
sub find_token {
    my ($result, %criteria) = @_;
    for my $line (@$result) {
        for my $token (@$line) {
            my $match = 1;
            for my $key (keys %criteria) {
                $match = 0 unless defined $token->{$key} && $token->{$key} eq $criteria{$key};
            }
            return $token if $match;
        }
    }
    return undef;
}

#===========================================================================
# Constructor
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    isa_ok($p, 'Syntax::Highlight::Basic::Parser', 'constructor with known language');
}

#===========================================================================
# parse() return structure
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse("if (\$x) {\n    print \"hello\";\n}");
    isa_ok($result, 'ARRAY', 'parse() returns arrayref');
    is(scalar @$result, 3, '3 lines in result');
    isa_ok($result->[0], 'ARRAY', 'each line is an arrayref');
    isa_ok($result->[1], 'ARRAY', 'line 2 is an arrayref');
    isa_ok($result->[2], 'ARRAY', 'line 3 is an arrayref');
}

#===========================================================================
# Keyword recognition
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('if');
    my $token = find_token($result, text => 'if');
    ok(defined $token, 'found token for "if"');
    ok($token->{class} ne 'text', '"if" is not classified as text');
}

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('my $x = 1;');
    my $token = find_token($result, text => 'my');
    ok(defined $token, 'found token for "my"');
    ok($token->{class} ne 'text', '"my" is not classified as text');
}

#===========================================================================
# Whitespace tokens
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('  if');
    my $token = $result->[0][0];
    is($token->{class}, 'whitespace', 'leading whitespace is whitespace class');
    is($token->{text}, '  ', 'whitespace text is preserved');
}

#===========================================================================
# Number recognition
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('42');
    my $token = find_token($result, text => '42');
    ok(defined $token, 'found token for "42"');
    ok($token->{class} eq 'Constant' || (defined $token->{sub_group} && $token->{sub_group} eq 'Number'),
        '42 is Constant/Number');
}

#===========================================================================
# String recognition
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('"hello"');
    my $token = find_token($result, sub_group => 'String');
    ok(defined $token, 'found String token for "hello"');
    like($token->{text}, qr/hello/, 'string token contains the text');
}

#===========================================================================
# Comment recognition
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('# this is a comment');
    my $token = find_token($result, class => 'Comment');
    ok(defined $token, 'found Comment token');
}

#===========================================================================
# Multi-line input
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse("line1\nline2\nline3");
    is(scalar @$result, 3, '3 lines returned');
}

#===========================================================================
# Empty input
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse('');
    isa_ok($result, 'ARRAY', 'empty input returns arrayref');
}

#===========================================================================
# Empty lines
#===========================================================================

{
    my $p = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $result = $p->parse("a\n\nb");
    is(scalar @$result, 3, '3 lines including empty middle line');
}

done_testing();