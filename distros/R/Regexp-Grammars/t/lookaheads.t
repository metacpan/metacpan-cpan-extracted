use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $neg_lookahead = qr{
    <List>

    <rule: List>
        START  <[Item]> ** <ws>  <?EOL(Token=>'END')>  END

    <token: Item>
        <!EOL(Token=>'END')> \w+

    <token: EOL>
        <\:Token>
}xms;

ok "START do it END END" =~ $neg_lookahead => 'Match';
is_deeply $/{List}{Item}, ["do","it"]      => 'Correct match';

