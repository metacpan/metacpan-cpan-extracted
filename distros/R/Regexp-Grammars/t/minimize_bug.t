use 5.010;
use Data::Dumper;
use Regexp::Grammars;

my $nocontext = qr{
  <nocontext:>

  <list>

  <rule: list>
    <[expr]>+ % <[sep=([\w,;])]>
    <minimize:>

  <rule: expr>
    <[item]>+ % <[op=([+-])]>
    <minimize:>

  <token:item> (\d+)

}xms;

use Test::More;

plan tests => 2;

if ("1+2,3" =~ $nocontext) {
    is_deeply \%/,  { 'list' => {
                        'sep'  => [','],
                        'expr' => [{ 'item' => ['1','2'], 'op' => ['+'] }, '3']
                       }
                    } => 'Should not minimize';
}
else {
    fail 'Should not minimize (did not match)';
}

if ("1" =~ $nocontext) {
    is_deeply \%/,  { 'list' => 1 } => 'Should minimize';
}
else {
    fail 'Should minimize (did not match)';
}
