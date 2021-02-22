package Foo;
use Moo;
use MooX::Clone;

has scalar   => ( is => 'rw' );
has arrayref => ( is => 'rw', default => sub { [ [0], [1] ] });

package main;
use Test::More;

my $foo = Foo->new( scalar => 1 );
my $bar = $foo->clone;

is $foo->scalar, $bar->scalar, 'scalar value was cloned';

$bar->scalar(2);
isnt $foo->scalar, $bar->scalar, '... and the clone is not connected to the original';

is_deeply $foo->arrayref, $bar->arrayref, 'deep structure was cloned';
isnt $foo->arrayref . q{}, $bar->arrayref . q{}, '... and they are not the same reference';

done_testing;