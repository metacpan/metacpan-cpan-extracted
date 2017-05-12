use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

my @info = (
    ['Panda::XS::Test::PTRMyRefCounted',   'Panda::XS::Test::PTRMyRefCountedChild',   'hold_ptr_myrefcounted',    'release_ptr_myrefcounted'],
    ['Panda::XS::Test::MyRefCounted',      'Panda::XS::Test::MyRefCountedChild',      'hold_myrefcounted',        'release_myrefcounted'],
    ['Panda::XS::Test::PTRMyRefCountedSP', 'Panda::XS::Test::PTRMyRefCountedChildSP', 'hold_ptr_myrefcounted_sp', 'release_ptr_myrefcounted_sp'],
    ['Panda::XS::Test::MyRefCountedSP',    'Panda::XS::Test::MyRefCountedChildSP',    'hold_myrefcounted_sp',     'release_myrefcounted_sp'],
    ['Panda::XS::Test::PTRMyBaseSP',       'Panda::XS::Test::PTRMyChildSP',           'hold_ptr_mybase_sp',       'release_ptr_mybase_sp'],
    ['Panda::XS::Test::MyBaseSP',          'Panda::XS::Test::MyChildSP',              'hold_mybase_sp',           'release_mybase_sp'],
    ['Panda::XS::Test::PTRMyBaseSSP',      'Panda::XS::Test::PTRMyChildSSP',          'hold_ptr_mybase_ssp',      'release_ptr_mybase_ssp'],
    ['Panda::XS::Test::MyBaseSSP',         'Panda::XS::Test::MyChildSSP',             'hold_mybase_ssp',          'release_mybase_ssp'],
);

foreach my $row (@info) {
    dcnt(0);
    my ($class, $childclass) = @$row;
    my $hold = Panda::XS::Test->can($row->[2]);
    my $release = Panda::XS::Test->can($row->[3]);
    
    my $o = $class->new(123);
    is(dcnt(), 0);
    is(ref $o, $class);
    is($o->val, 123);
    is($o->val, 123);
    undef $o;
    is(dcnt(), 1);
    
    dcnt(0);
    $o = $childclass->new(123, 321);
    is(dcnt(), 0);
    is(ref $o, $childclass);
    is($o->val, 123);
    is($o->val2, 321);
    undef $o;
    is(dcnt(), 2);
    
    dcnt(0);
    $o = $class->new(890);
    $hold->($o);
    undef $o;
    is(dcnt(), 0);
    my $o2 = $release->();
    is(dcnt(), 0);
    is($o2->val, 890);
    undef $o2;
    is(dcnt(), 1);
}

done_testing();
