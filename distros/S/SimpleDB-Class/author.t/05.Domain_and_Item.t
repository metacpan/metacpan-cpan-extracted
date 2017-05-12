use Test::More tests => 51;
use Test::Deep;
use lib ('../lib', 'lib');
$|=1;

my $access = $ENV{AWS_ACCESS_KEY};
my $secret = $ENV{AWS_SECRET_ACCESS_KEY};

unless (defined $access && defined $secret) {
    die "You need to set environment variables AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY to run these tests.";
}

use Foo;
my %params = (secret_key=>$secret, access_key=>$access, cache_servers=>[{host=>'127.0.0.1', port=>11211}]);
if ($ARGV[0]) {
    $params{domain_prefix} = $ARGV[0];
}
my $foo = Foo->new(%params);
$foo->cache->flush;
my $domain = $foo->domain('foo_domain');
isa_ok($domain,'SimpleDB::Class::Domain');
isa_ok($domain->simpledb,'SimpleDB::Class');

my $parent = $foo->domain('foo_parent');
ok($parent->create, 'create a domain');
my $domain_expected = 'foo_parent';
if ($ARGV[0]) {
    $domain_expected = $ARGV[0].$domain_expected;
}
ok(grep({$_ eq $domain_expected} @{$foo->list_domains}), 'got created domain');
is($parent->count, 0, 'should be 0 items');
my $parent_one = $parent->insert({title=>'One'},id=>'one');
$parent->insert({title=>'Two'},id=>'two');
is($parent->count(consistent=>1), 2, 'should be 2 items');

$domain->create;
ok($domain->insert({color=>'red',size=>'large',parentId=>'one',quantity=>5}, id=>'largered'), 'adding item with id');
ok($domain->insert({color=>'blue',size=>'small',parentId=>'two',quantity=>1}), 'adding item without id');
is($domain->find('largered')->size, 'large', 'find() works');

my $x = $domain->insert({color=>'orange',size=>'large',parentId=>'one',properties=>{this=>'that'},quantity=>3});
isa_ok($x, 'Foo::Domain');
cmp_deeply($x->to_hashref, {properties=>{this=>'that'}, color=>'orange',size=>'large',size_formatted=>'Large',parentId=>'one', start_date=>ignore(), components=>[], notes=>'', quantity=>3}, 'to_hashref()');
$domain->insert({color=>'green',size=>'small',parentId=>'two',quantity=>11});
$domain->insert({color=>'black',size=>'huge',parentId=>'one',quantity=>2});
is($domain->max('quantity', consistent=>1), 11, 'max');
is($domain->min('quantity', consistent=>1), 1, 'min');
is($domain->max('quantity',consistent=>1, where=>{parentId=>'one'}), 5, 'max with clause');
is($domain->min('quantity', consistent=>1, where=>{parentId=>'one'}), 2, 'min with clause');

my $foos = $domain->search(where=>{size=>'small'}, consistent=>1);
isa_ok($foos, 'SimpleDB::Class::ResultSet');
isa_ok($foos->next, 'Foo::Domain');
my $a_domain = $foos->next;
ok($a_domain->can('size'), 'attribute methods created');
ok(!$a_domain->can('title'), 'other class attribute methods not created');
is($a_domain->size, 'small', 'fetched an item from the result set');
$foos = $domain->search(consistent=>1, where=>{'itemName()'=>$a_domain->id});
my $b_domain = $foos->next;
is($b_domain->id, $a_domain->id, "searching on itemName() works");
$foos = $domain->search(where=>{size=>'small', 'itemName()'=>['>','0']}, consistent=>1, order_by=>'itemName()');
$a_domain = $foos->next;
$b_domain = $foos->next;
ok($a_domain->id < $b_domain->id, 'order by itemName() works');
my $c_domain = $b_domain->copy;
is($b_domain->size, $c_domain->size, "copy() works.");
cmp_ok($b_domain->id, 'ne', $c_domain->id, "copy() provides new id");
$foos = $domain->search(where=>{size=>'large'}, consistent=>1);
is($foos->count, 2, 'counting items in a result set');
$foos = $domain->search(consistent=>1, where=>{size=>'large'});
is($foos->count(where=>{color=>'orange'}), 1, 'counting subset of items in a result set');

is($parent_one->domains->count, 3, "can count result set");
is($parent_one->domains(where=>{color=>'red'})->count, 1, "can narrow relationship");

my $children = $foo->domain('foo_child');
$children->create;
my $child = $children->insert({domainId=>'largered'});
isa_ok($child, 'Foo::Child');
my $subchild = $children->insert({domainId=>'largered', class=>'Foo::SubChild'});
isa_ok($subchild, 'Foo::SubChild');

my $largered = $domain->find('largered', set => { parent => $parent_one } );
is($parent_one, $largered->parent, 'presetting parent works');
is($largered->parent->title, 'One', 'belongs_to works');
$largered->parentId('two');
is($largered->parent->title, 'Two', 'belongs to clear works');
is($domain->find('largered')->children->next->domainId, 'largered', 'has_many works');

my $note = 'NOTE: 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
This is a really long note that I am adding to prove that we can have really long notes in SimpleDB. 
';

my $j = $domain->insert({start_date=>DateTime->new(year=>2000, month=>5, day=>5, hour=>5, minute=>5, second=>5), color=>'orange',size=>'large',parentId=>'one',properties=>{this=>'that'},quantity=>4, notes=>$note, components=>['cotton','dye','thread']});
$foo->cache->flush;
my $j1 = $domain->find($j->id, consistent=>1);
cmp_ok($j->start_date, '==', $j1->start_date, 'dates in are dates out');
is($j->start_date->year, 2000, 'year');
is($j->start_date->month, 5, 'month');
is($j->start_date->day, 5, 'day');
is($j->start_date->hour, 5, 'hour');
is($j->start_date->minute, 5, 'minute');
is($j->start_date->second, 5, 'second');
is($j1->properties->{this}, 'that', 'hash refs work');
is($j1->notes, $note, 'medium strings work');
is($j1->components->[1], 'dye', 'arrays of strings work');

my $page2 = $domain->search(
    where => { quantity => ['>', 1] },
    consistent => 1,
    order_by => 'quantity'
    )->paginate(2,2);
is($page2->next->color, 'orange', "pagination works");

my $bighashref = {this=>'that',really_long_line_to_see_a_multiattribute_hash_ref_work=>'this is me testing to see what happens if i have a string that is too long to fit in one attribute value. perhaps its broken. 0000000000  0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000 0000000000'};
my $bigprops = $domain->insert({start_date=>DateTime->new(year=>2000, month=>5, day=>5, hour=>5, minute=>5, second=>5), color=>'orange',size=>'large',parentId=>'one',properties=>$bighashref,quantity=>4, notes=>$note, components=>['cotton','dye','thread']});

$foo->cache->flush;
my $bigprops2 = $domain->find($bigprops->id, consistent=>1);
is($bigprops2->properties->{really_long_line_to_see_a_multiattribute_hash_ref_work}, $bighashref->{really_long_line_to_see_a_multiattribute_hash_ref_work}, 'long hashref works');

my $rs = $domain->search(limit=>3);
my $i = 0;
while ($rs->next) {
    $i++;
}
is($i, 3, 'limits are held');

my $ids = $domain->fetch_ids(where => { color=>'orange' }, consistent=>1);
is(scalar(@{$ids}), 3, 'fetch_ids gets the right amount');
ok($bigprops->id ~~ @{$ids}, 'fetch_ids returns expected id');

ok($domain->delete,'deleting domain');
$parent->delete;
$children->delete;
ok(!grep({$_ eq 'foo_domain'} @{$foo->list_domains}), 'domain deleted');


