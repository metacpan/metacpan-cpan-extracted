use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

my ($s, $u, $r);

my @info = (
    ['Panda::XS::Test::PTRBRStorage', 'Panda::XS::Test::PTRBRUnit', 'Panda::XS::Test::MyPTRBRUnit'],
    ['Panda::XS::Test::BRStorage', 'Panda::XS::Test::BRUnit', 'Panda::XS::Test::MyBRUnit'],
);

foreach my $row (@info) {
    dcnt(0);
    my ($stclass, $unit_class, $myunit_class, $myunit_advanced_class) = @$row;
    $s = $stclass->new();
    is($s->unit(), undef);
    
    # basic class
    $u = $unit_class->new(100);
    is(ref $u, $unit_class);
    is($u->id, 100);
    $s->unit($u);
    $r = $s->unit;
    is(ref $r, $unit_class);
    is($r->id, 100);
    $s->unit(undef);
    is($s->unit(), undef);
    undef $u; is(dcnt(), 0);
    undef $r; is(dcnt(), 1);
    
    dcnt(0);
    
    # subclassing with non-xsbackref class has no effect even with 'backref' param in typemap
    $u = $myunit_class->new(200);
    is(ref $u, $myunit_class);
    is($u->id, 311);
    $s->unit($u);
    $r = $s->unit;
    is(ref $r, $unit_class);
    is($r->id, 200);
    undef $u; undef $r;
    is(dcnt, 0);
    $s->unit(undef);
    is(dcnt, 1);
    
    dcnt(0);
    
    # subclassing with xsbackref class preserves original perl object
    $u = $myunit_class->new_enabled(200);
    is(ref $u, $myunit_class);
    is($u->id, 311);
    $s->unit($u);
    $r = $s->unit;
    is($r, $u);
    is(ref $r, $myunit_class);
    is($r->id, 311);
    undef $r; undef $u;
    is(dcnt, 0);
    $s->unit(undef);
    is(dcnt, 1);
    
    undef $s;
}

# Advanced class only for OEXT as OPTR cannot upgrade to hash.

dcnt(0);

$s = Panda::XS::Test::BRStorage->new;

# perl data can be used after PERL -> C -> PERL
$u = Panda::XS::Test::MyBRUnitAdvanced->new(200, 777);
is(ref $u, 'Panda::XS::Test::MyBRUnitAdvanced');
is($u->id, 311);
is($u->special, 777);
$s->unit($u);
$r = $s->unit;
is(ref $r, 'Panda::XS::Test::MyBRUnitAdvanced');
is($r->id, 311);
is($r->special, 777);
undef $u; undef $r;
$s->unit(undef);
is(dcnt, 1);

dcnt(0);

# now check that perl object survives if retained from C, even when perl loses all references (shared ref counter)
$u = Panda::XS::Test::MyBRUnitAdvanced->new(200, 777);
$s->unit($u);
undef $u;
$r = $s->unit;
is(ref $r, 'Panda::XS::Test::MyBRUnitAdvanced');
is($r->id, 311);
is($r->special, 777);

done_testing();