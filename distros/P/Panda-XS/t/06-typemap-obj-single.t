use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

is(dcnt(), 0, "dcnt is 0");

my @bad_values = (*STDOUT{IO}, map {bless $_, 'ABCD'} sub {}, [], {});
push @bad_values, 0, 1, '', 'asd', sub {}, [], {}, map {\(my $a = $_)} 0, 1, '', 'asd';

my @info = ('Panda::XS::Test::PTRMyBase', 'Panda::XS::Test::MyBase');

foreach my $class (@info) {
    dcnt(0);
    is(dcnt(), 0, "dcnt is 0");
    ok(!defined $class->new(0), "output $class returns undef for NULL RETVALs");
    my $obj = new $class(123);
    is(ref $obj, $class, "output $class return object");
    is($obj->val, 123, "input THIS for $class works");
    my $f = $class->can('val');
    ok(!eval {$f->(undef); 1}, "input THIS for $class doesnt allow undefs");
    for my $badval (@bad_values) {
        ok(!eval {$f->($badval); 1}, "input THIS for $class doesnt allow bad values ($badval)");
    }
    
    $obj->set_from(undef);
    is($obj->val, 123, "input arg for $class allows undefs");
    $obj->set_from(new $class(1000));
    is($obj->val, 1000, "input arg for $class works");
    is(dcnt(), 1, 'tmp obj desctructor called');
    for my $badval (@bad_values) {
        ok(!eval {$obj->set_from($badval); 1}, "input arg for $class doesnt allow bad values ($badval)");
    }
    undef $obj;
    is(dcnt(), 2, '$obj desctructor called');
}

done_testing();
