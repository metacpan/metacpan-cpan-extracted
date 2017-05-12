use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

my $obj = new Panda::XS::Test::OSV("hello");

my %data = (
    OSV => ["hello", "world", undef],
    OAV => [[1,2,3], [4,5], []],
    OHV => [{a => 1, b => 2}, {c => 3}, {}],
    OIO => [*STDOUT{IO}, *STDIN{IO}, *STDERR{IO}],
);
my @bad = (0, 1, '', 'asd', sub {}, [], {}, map {\(my $a = $_)} 0, 1, '', 'asd');
my %bad = (
    OSV => [*STDOUT{IO}, map {bless $_, 'ABCD'} sub {}, [], {}],
    OAV => [*STDOUT{IO}, map {bless $_, 'ABCD'} sub {}, {}, map {\(my $a = $_)} 0, 1, '', 'asd'],
    OHV => [*STDOUT{IO}, map {bless $_, 'ABCD'} sub {}, [], map {\(my $a = $_)} 0, 1, '', 'asd'],
    OIO => [map {bless $_, 'ABCD'} sub {}, [], {}, map {\(my $a = $_)} 0, 1, '', 'asd'],
);

test_type($_) for keys %data;

sub test_type {
    my $type = shift;
    my $class = "Panda::XS::Test::$type";
    my $get_val_sub = $class->can('get_val');
    my ($val, $val2, $valu) = @{$data{$type}};
    my ($cval, $cval2, $cvalu) = $type eq 'OIO' ? (1, 0, 2) : ($val, $val2, $valu);
    is($class->new(undef), undef, "output $type returns undef for NULL RETVALs");
    my $obj = $class->new($val);
    is(ref $obj, $class, "output $type returns blessed object");
    cmp_deeply($obj->get_val, $cval, "input THIS for $type works");
    ok(!eval {$get_val_sub->(undef); 1}, "input THIS for $type doesn't allow undefs");
    foreach my $bad_val (@bad, @{$bad{$type}}) {
        ok(!eval {$get_val_sub->($bad_val); 1}, "input THIS for $type doesn't allow bad values ($bad_val)");
    }
    
    $obj->set_val($class->new($val2));
    cmp_deeply($obj->get_val, $cval2, "input arg for $type works");
    $obj->set_val(undef);
    cmp_deeply($obj->get_val, $cvalu, "input arg for $type allow undefs");
    foreach my $bad_val (@bad, @{$bad{$type}}) {
        ok(!eval {$obj->set_val($bad_val); 1}, "input arg for $type doesn't allow bad values ($bad_val)");
    }
    
    $obj->set_val($class->new($val));
    my $obj2 = $obj->clone;
    is(ref $obj2, $class, "output for non-constructors $type returns blessed object");
    cmp_deeply($obj2->get_val, $obj->get_val, "output for non-constructors $type works");
}

done_testing();
