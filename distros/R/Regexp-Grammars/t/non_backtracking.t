use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $list_nonempty = qr{
    <List>

    <rule: List>
        \(  <[Value]> ** (?> [,] )  \)

    <token: Value>
        \d+
}xms;

my $list_empty = qr{
    <List>

    <rule: List>
        \(  (?> <[Value]> ** , (?> x? ) )?  \)
            (?{ $MATCH{Value} //= [] })

    <token: Value>
        (?> \d+ )
}xms;

ok 1;

ok "foo bar" =~ m{
  <BAR>
  <token: BAR> \w+ \s <MATCH= ( (?> bar ) ) >
}x;
