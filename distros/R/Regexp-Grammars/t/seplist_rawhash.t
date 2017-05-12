use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $raw_hash = qr{
    \A
    (?: <solution> | <percentage> | <perl_hash> | <perl_mod> )
    \Z

    <token: percentage>
        \d{1,3} %

    <token: perl_hash>
        % \w+

    <rule: perl_mod>
        <perl_hash> % <percentage>

    <rule: solution>
        \d{1,3} \% solution

}xms;

no Regexp::Grammars;

ok +('7% solution' =~ $raw_hash) => 'Matched <solution>';
ok exists $/{solution}           => '...and matched correct rule';

ok +('7%' =~ $raw_hash)  => 'Matched <percentage>';
ok exists $/{percentage} => '...and matched correct rule';

ok +('%foo' =~ $raw_hash)  => 'Matched <perl_hash>';
ok exists $/{perl_hash} => '...and matched correct rule';

ok +('%bar % 42%' =~ $raw_hash)  => 'Matched <perl_mod>';
ok exists $/{perl_mod} => '...and matched correct rule';

