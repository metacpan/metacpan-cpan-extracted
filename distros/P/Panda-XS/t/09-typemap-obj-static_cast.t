use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

my @info = (
    ['Panda::XS::Test::PTRMyStatic', 'Panda::XS::Test::PTRMyStaticChild'],
    ['Panda::XS::Test::MyStatic',    'Panda::XS::Test::MyStaticChild'],
);

foreach my $row (@info) {
    dcnt(0);
    my ($class, $childclass) = @$row;
    my $obj = $class->new(123);
    is(ref $obj, $class, "output returns object");
    is($obj->val, 123, "input works");
    my $f = $class->can('val');
    ok(!eval {$f->(undef); 1}, "input THIS doesnt allow undefs");
    undef $obj;
    
    $obj = $childclass->new(123, 321);
    is(ref $obj, $childclass, "output returns object");
    cmp_deeply([$obj->val, $obj->val2], [123, 321], "input works");
    my $f2 = $childclass->can('val2');
    ok(!eval {$f->(undef); 1}, "input THIS doesnt allow undefs");
    ok(!eval {$f2->(undef); 1}, "input THIS doesnt allow undefs");
    undef $obj;
}

done_testing();
