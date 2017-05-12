use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

qr{
    <grammar: Base>

    <rule: baserule>
        baserule

    <rule: baserule2>
        baserule2
}x;

qr{
    <grammar: Intermediate>
    <extends: Base>
}x;

my $baserule = qr{
    <extends: Intermediate>

    <Intermediate::baserule>
}x;

my $baserule2 = qr{
    <extends: Intermediate>

    <NEXT::baserule2>
}x;

ok 'baserule'  =~ $baserule  =>  'Specific polymorphism worked';
ok 'baserule2' =~ $baserule2  => 'Generic polymorphism worked';
