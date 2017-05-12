use 5.010;
use Test::More 'no_plan';

use Regexp::Grammars;

my $grammar_top = qr{
    ^ a b $
}xms;

my $grammar_rule = qr{
    <Rule>

    <rule: Rule> ^ a b $
}xms;

my $grammar_token = qr{
    <Token>

    <token: Token> ^ a b $
}xms;

ok 'ab'  =~ $grammar_top => 'Top correctly matches without space';
ok 'a b' !~ $grammar_top => 'Top correctly fails with space';

ok 'ab'  =~ $grammar_token => 'Token correctly matches without space';
ok 'a b' !~ $grammar_token => 'Token correctly fails with space';

ok 'ab'  =~ $grammar_rule => 'Rule correctly matches without space';
ok 'a b' =~ $grammar_rule => 'Rule correctly matches with space';
