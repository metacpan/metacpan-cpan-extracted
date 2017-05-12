use 5.010;
use Test::More 'no_plan';

use Regexp::Grammars;

my $grammar_noRG  = qr{^a b$};
my $grammar_top   = qr{ ^ a b $ <rule: unused> };
my $grammar_rule  = qr{ <Rule>  <rule: Rule> ^ <let> <let> $ <token: let> \w};
my $grammar_token = qr{ <Token> <token: Token> ^ <let> <let> $ <token: let> \w};

ok 'ab'  !~ $grammar_noRG => 'No RG correctly fails without space';
ok 'a b' =~ $grammar_noRG => 'No RG correctly matches with space';

ok 'ab'  =~ $grammar_top => 'Top correctly matches without space';
ok 'a b' !~ $grammar_top => 'Top correctly fails with space';

ok 'ab'  =~ $grammar_token => 'Token correctly matches without space';
ok 'a b' !~ $grammar_token => 'Token correctly fails with space';

ok 'ab'  =~ $grammar_rule => 'Rule correctly matches without space';
ok 'a b' =~ $grammar_rule => 'Rule correctly matches with space';

