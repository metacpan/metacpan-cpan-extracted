use Test::More;
use Carp 'verbose';
use Patro ':test';
use 5.012;
use Scalar::Util 'reftype';

# splice is not implemented for shared arrays
# see if our workaround will work

my $r1 = [ 1 .. 10 ];
my $r2 = [ 'red', 'green', 'blue' ];
my $r3 = [ 'red', 'green', 'blue' ];
my $r4 = [ 1, 2, 3 ];
my $r5 = [ 1, 2, 3 ];
my $r6 = [ [ 1, 2, 3],
	   [ 1, 2, 3],
	   [ 1, 2, 3] ];
my $r9 = [];
my $r10 = [];

ok($r1 && ref($r1) eq 'ARRAY', 'created remote var');

my $cfg = patronize($r1,$r2,$r3,$r4,$r5,$r6,$r9,$r10);
ok($cfg, 'got config for patronize array ref');

my ($p1,$p2,$p3,$p4,$p5,$p6,$p9,$p10) = Patro->new($cfg)->getProxies;

# see t/op/splice.t in perl source
sub j { join(":",@_) }
is( j(splice(@$p1, @$p1, 0, 11, 12)), '',
    'return val when nothing is removed, only added');
is( j(@$p1), j(1..12), '... added two elements');

is( j(splice(@$p1,-1)), "12", 'remove last element, return value');
is( j(@$p1), j(1..11), '... removed last element');

is( j(splice(@$p1,0,1)), "1", "remove first element, return value");
is( j(@$p1), j(2..11), '... first element removed');

is( j(splice(@$p1,0,0,0,1)), "", 'emulate shift, return value is empty');
is( j(@$p1), j(0..11), '... added two elements to beginning of the list');

is( j(splice(@$p1,5,1,5)), "5", 
    "remove and replace an element to the end of the list, ".
    "return value is the element");
is( j(@$p1), j(0..11), 'list remains the same');

is( j(splice(@$p1,@$p1,0,12,13)), "",
    "push two elements onto the end of the list, return value is empty");
is( j(@$p1), j(0..13), "... added two elements to the end of the list");

is( j(splice(@$p1,-@$p1,@$p1,1,2,3)), j(0..13),
    'splice the whole list out, add 3 elements, return value is @a');
is( j(@$p1), j(1..3), "... array only contains new elements");

is( j(splice(@$p1,1,-1,7,7)), "2",
    "replace middle element with two elements, negative offset, " .
    "return value is the element");
is( j(@$p1), j(1,7,7,3), '... array 1,7,7,3');

is( j(splice(@$p1,-3,-2,2)), "7",
    "replace first 7 with a 2, neg offset, neg length, return value is 7");
is( j(@$p1), j(1,2,7,3), '... array has 1,2,7,3');

is( j(splice(@$p1)), j(1,2,7,3),
    "bare slice empties the array, return value is the array");
is( j(@$p1), '', 'array is empty');


my $foo = splice @$p2, 1, 2;
is( $foo, 'blue', 'return a single element in scalar context' );
is( j(@$p2), "red", '... but more than one element is removed' );

$foo = shift @$p3;
is( $foo, 'red', 'return a single element in scalar context' );
is( j(@$p3), j("green","blue"), "... and remove a single element");

# insertion of deleted elements
splice(@$p4, 0, 3, $p4->[1], $p4->[0]);
is( j(@$p4), j(2,1), "splice and replace with indexes 1,0");

splice(@$p5, 0, 3, $p5->[2], $p5->[1], $p5->[0]);
is( j(@$p5), j(3,2,1), "splice and replace with indexes 2, 1, 0");

my $q6 = $p6->[0];
splice(@$q6, 0, 3, $q6->[0], $q6->[1], $q6->[2], $q6->[0], $q6->[1], $q6->[2]);
is( j(@$q6), j(1,2,3,1,2,3), "splice and replace with a whole bunch" );

my $q7 = $p6->[1];
splice(@$q7, 1, 2, $q7->[2], $q7->[1]);
is( j(@$q7), j(1,3,2), 'swap last two elements');

my $q8 = $p6->[2];
splice(@$q8, 1, 2, $q8->[1], $q8->[1]);
is( j(@$q8), j(1,2,2), 'duplicate middle element on the end');

no warnings 'uninitialized';

$#{$p9}++;
is( sprintf("%s",splice(@$p9,0,1)), "",
    "splice handles non existent elems when shrinking the array");

$#{$p10}++;
is( sprintf("%s",splice(@$p10,0,1,undef)), "",
    "splice handles non existent eleme when array len stays the same");


done_testing;

