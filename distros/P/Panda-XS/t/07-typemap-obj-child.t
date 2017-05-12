use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

my @info = (['Panda::XS::Test::PTRMyChild', 'Panda::XS::Test::PTRMyBase'],
            ['Panda::XS::Test::MyChild', 'Panda::XS::Test::MyBase']);

foreach my $row (@info) {
    dcnt(0);
    my ($class, $baseclass) = @$row;
    my $obj = $class->new(10, 20);
    is(ref $obj, $class, "output $class return object");
    is($obj->val, 10, "input THIS base method works");
    is($obj->val2, 20, "input THIS child method works");
    $obj->set_from($class->new(7,8));
    is(dcnt(), 2, 'tmp obj desctructors called');
    is($obj->val.'-'.$obj->val2, "7-8", "input arg child method works");
    
    my $base = $baseclass->new(123);
    my $f = $class->can('val2');
    ok(!eval{$f->(); 1}, "input THIS doesnt allow wrong type objects");
    ok(!eval{$obj->set_from($base); 1}, "input arg doesnt allow wrong type objects");
    undef $base;
    undef $obj;
    is(dcnt(), 5, 'base and obj desctructors called');
}

done_testing();
