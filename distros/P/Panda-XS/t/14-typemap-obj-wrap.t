use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

# Class with wrapper

my @info = (
    ['Panda::XS::Test::PTRWBase', 'Panda::XS::Test::PTRWChild'],
    ['Panda::XS::Test::WBase',    'Panda::XS::Test::WChild'],
);

foreach my $row (@info) {
    dcnt(0);
    my ($class, $childclass) = @$row;
    my $obj = $class->new(777);
    is(ref $obj, $class, "output $class returns object");
    is($obj->val, 777, "input $class wrapped method works");
    is($obj->xval, 0, "input $class wrapper method works");
    $obj->xval(100);
    is($obj->val.$obj->xval, "777100", "input $class wrapper method works");
    undef $obj;
    is(dcnt(), 2, "obj $class desctructors called");
    
    dcnt(0);
    
    $obj = $childclass->new(777, 888);
    is(ref $obj, $childclass, "output $childclass returns object");
    is($obj->val, 777, "input $childclass wrapped method works");
    is($obj->val2, 888, "input $childclass wrapped-child method works");
    is($obj->xval, 0, "input $childclass wrapper method works");
    is($obj->xval2, 0, "input $childclass wrapper-child method works");
    $obj->xval(100);
    $obj->xval2(200);
    is($obj->val.$obj->val2.$obj->xval.$obj->xval2, "777888100200", "input $childclass wrapper method works");
    undef $obj;
    is(dcnt(), 3, "obj $childclass desctructors called");
}

done_testing();
