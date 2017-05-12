use Test::More tests => 20;
use Test::Deep;
use lib '../lib';

use_ok( 'SimpleDB::Class::Exception');
use_ok( 'SimpleDB::Class' );
diag( "Testing SimpleDB::Class $SimpleDB::Class::VERSION" );

my $db = SimpleDB::Class->new(secret_key=>'secretxx', access_key=>'accessyy', cache_servers=>[{'socket' => '/tmp/foo/bar'}]);

isa_ok($db, 'SimpleDB::Class');
isa_ok($db->cache, 'SimpleDB::Class::Cache');

use_ok( 'SimpleDB::Class::SQL');
use_ok( 'SimpleDB::Class::ResultSet');
use_ok( 'SimpleDB::Class::Domain' );
use_ok( 'SimpleDB::Class::Item' );

SimpleDB::Class::Item->set_domain_name('test');

my %attributes = (
    'xxx'=>{ isa => 'Str', trigger=>sub { my $self = shift; $self->foo('xxx')} },
    'foo'=> { isa => 'Str', default=>'abc'}, 
    'bar'=>{ isa => 'Int', default=>24}, 
    );
SimpleDB::Class::Item->add_attributes(%attributes);
cmp_deeply(SimpleDB::Class::Item->attributes, \%attributes, 'setting attributes works');
$attributes{this} = {isa => 'Str'};
SimpleDB::Class::Item->add_attributes(this => { isa => 'Str' } );
cmp_deeply(SimpleDB::Class::Item->attributes, \%attributes, 'adding attributes works');


my $domain = $db->domain('SimpleDB::Class::Item');
isa_ok($domain, 'SimpleDB::Class::Domain');

is($domain->name, 'test', 'domain name assignment works');
is($domain->item_class, 'SimpleDB::Class::Item', 'item_class');

my $item = SimpleDB::Class::Item->new(simpledb=>$db, id=>1);
isa_ok($item, 'SimpleDB::Class::Item');
ok($item->can('foo'), 'attributes create accessors');
$item->foo('11');
is($item->foo, 11, 'can set added accessor');
is($item->bar, 24, 'defaults on attributes work');
$item->xxx('blah');
is($item->foo, 'xxx', 'triggers on attributes work');

SimpleDB::Class::Item->has_many('many', 'XXX', 'x');
ok($item->can('many'), 'has_many creates a method');

SimpleDB::Class::Item->belongs_to('belongs', 'XXX', 'foo');
ok($item->can('belongs'), 'belongs_to creates a method');



# everything else requires a connection
