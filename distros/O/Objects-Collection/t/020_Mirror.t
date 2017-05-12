# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';    #tests => 'noplan';

use Test::More tests =>24 ;
use lib 't/lib';
use Data::Dumper;

BEGIN {
    use_ok('Objects::Collection::Mirror');
    use_ok('Collection::Mem');
    use_ok('Objects::Collection');
    use_ok('Objects::Collection::ActiveRecord');
}
my $obj;
my ( %h1, %h2 );

$h1{1} = { 1 => 11 };
$h2{2} = { 2 => 22 };
ok my $coll1 = ( new Collection::Mem:: mem => \%h1 ), 'create collection1';
ok my $coll2 = ( new Collection::Mem:: mem => \%h2 ), 'create collection2';

is_deeply $coll1->fetch_object('1'), { '1' => 11 }, 'fetch key 1 from coll1';
is_deeply $coll2->fetch_object('2'), { '2' => 22 }, 'fetch key 2 from coll2';
ok !$coll1->fetch_object('2'), 'non exists key  1 in coll1';

isa_ok my $mirror_coll1 = ( new Objects::Collection::Mirror:: $coll1, $coll2 ),
  'Objects::Collection::Mirror', 'create mirror';

is_deeply \%h1, { '1' => { '1' => 11 } }, 'check orig state of coll1';
is_deeply \%h2, { '2' => { '2' => 22 } }, 'check orig state of coll2';

is_deeply $mirror_coll1->fetch_object('2'), { '2' => 22 }, 'get mirrored key';

is_deeply \%h1,
  {
    '1' => { '1' => 11 },
    '2' => { '2' => 22 }
  },
  'check merge to first key';
is_deeply $mirror_coll1->fetch_object('3'), undef, 'get non exists key';
$mirror_coll1->create( { 3 => { 3 => 33 } } );
is_deeply \%h1,
  {
    '1' => { '1' => 11 },
    '3' => { '3' => 33 },
    '2' => { '2' => 22 }
  },
  'check coll1 after create key';

is_deeply \%h2,
  {
    '3' => { '3' => 33 },
    '2' => { '2' => 22 }
  },
  'check coll2 after create key';

#check storables
my $rec = $mirror_coll1->fetch_object('3');
$rec->{'3_'} = '3__';
ok( ( tied %$rec )->_changed, 'check modify record' );

#diag "Cahnged".Dumper $mirror_coll1->get_changed_id;
$mirror_coll1->store_changed();
is_deeply \%h2,
  {
    '3' => {
        '3_' => '3__',
        '3'  => '33'
    },
    '2' => { '2' => 22 }
  },
  'check mirrored changes to coll2';

is_deeply [ sort { $a <=> $b } @{ $mirror_coll1->list_ids() } ],
  [ '1', '2', '3' ], 'check list_ids';

$mirror_coll1->delete_objects(3);

is_deeply \%h1,
  {
    '1' => { '1' => 11 },
    '2' => { '2' => '22' }
  },
  'coll1: after delete key';
is_deeply \%h2, { '2' => { '2' => 22 } }, 'coll2: after delete key';

#$mirror_coll1->create([{ 4=>44 }]);
ok my $o1 = $mirror_coll1->fetch_object(1), 'get key 1';
$o1->{1}++;
$mirror_coll1->store_changed();
is_deeply \%h2, \%h1, 'check synced';

#diag Dumper \%h1;
#diag Dumper \%h2;

