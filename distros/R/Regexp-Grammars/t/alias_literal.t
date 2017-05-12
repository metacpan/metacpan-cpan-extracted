use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $test_grammar = qr{ one    <alt=1>
                     | negtwo <alt= -2e+1 >
                     | str    <alt='str\'ing'>
                     }xms;

no Regexp::Grammars;

ok "one" =~ $test_grammar    => 'One matched';
is $/{alt}, 1                => 'Correct alternative';

ok "negtwo" =~ $test_grammar => 'NegTwo matched';
is $/{alt}, -20              => 'Correct alternative';

ok "str" =~ $test_grammar    => 'Str matched';
is $/{alt}, "str'ing"        => 'Correct alternative';
