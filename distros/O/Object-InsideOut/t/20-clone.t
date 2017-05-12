use strict;
use warnings;

use Test::More 'tests' => 9;

package Foo; {
    use Object::InsideOut;
    my @foo :Field('Acc' => 'foo')
            :Deep;
}

package Bar; {
    use Object::InsideOut 'Foo';
    my @bar :Field('Acc' => 'bar');
}

package Baz; {
    use Object::InsideOut;
    my @baz :Field :All(baz);
}

package main;

my $adat = [ 'foo', 'bar', 'baz' ];
my $hdat = { 'bing' => 'bang', 'bop' => 'BOOM' };

my $obj = Bar->new();
$obj->foo($adat);
$obj->bar($hdat);

my $obj2 = $obj->clone();
is_deeply($obj->dump(), $obj2->dump()   => 'Clone equal');

$adat->[1] = 'trap';

my $data = $obj2->foo();
is($data->[1], 'bar'                    => 'Deep field copy');

$hdat->{'test'} = 'here';
$data = $obj->bar();
is($data->{'test'}, 'here'              => 'Shared data');

$data = $obj2->bar();
is($data->{'test'}, 'here'              => 'Shared data');

my $obj3 = $obj2->clone(1);
is_deeply($obj2->dump(), $obj3->dump()  => 'Clone equal');

$obj2->foo({ 'junk' => 0 });
$obj2->bar('data');

$data = $obj3->bar();
is($data->{'bop'}, 'BOOM'               => 'Deep object clone');
$data = $obj3->foo();
is($data->[2], 'baz'                    => 'Deep object clone');

my $baz = Baz->new();
$baz->baz($obj);
my $baz2 = $baz->clone(1);
my $objx = $baz->baz();
$data = $objx->bar();
is($data->{'test'}, 'here'              => 'Internal object');

$baz = Baz->new();
$baz->baz({'baz' => $obj});
$baz2 = $baz->clone(1);
$data = $baz->baz();
$objx = $$data{'baz'};
$data = $objx->bar();
is($data->{'test'}, 'here'              => 'Deep internal object');

exit(0);

# EOF
