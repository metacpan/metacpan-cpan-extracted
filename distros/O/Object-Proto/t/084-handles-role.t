use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use Object::Proto;

# handles(role:Name): a delegator for every method within the role - the
# methods it requires, the subs of its own package and the methods its slots
# give a class that composes it.

# The role
package Storage::API;
use Scalar::Util qw(blessed);       # imported: not the role's
use constant LIMIT => 10;           # a constant: not delegated
sub describe { 'storage: ' . $_[0]->kind }
sub _helper  { 'private' }
package main;

Object::Proto::role('Storage::API', 'kind:Str:default(memory)', 'size:Int:reader(get_size):clearer',
    'secret:private');
Object::Proto::requires('Storage::API', 'get', 'put');

# A class that does the role: the delegate
package MemoryStore;
sub get { my ($self, $k) = @_; $self->data->{$k} }
sub put { my ($self, $k, $v) = @_; $self->data->{$k} = $v; $self }
package main;
Object::Proto::define('MemoryStore', 'data:HashRef:default({})');
Object::Proto::with('MemoryStore', 'Storage::API');

# The class delegating to it
Object::Proto::define('Cache', 'storage:Object:handles(role:Storage::API)');

my $store = MemoryStore->new(size => 3);
my $cache = Cache->new(storage => $store);

is(ref $cache->put(a => 1), 'MemoryStore', 'a required method is delegated');
is($cache->get('a'), 1, 'another');
is($cache->describe, 'storage: memory', 'a sub of the role\'s package');
is($cache->kind, 'memory', 'a role slot\'s accessor');
is($cache->get_size, 3, 'its reader');
is($cache->size, 3, 'its own accessor');
$cache->clear_size;
ok(!defined $store->size, 'its clearer, on the delegate');
ok(!Cache->can('blessed'), 'an imported function is not delegated');
ok(!Cache->can('LIMIT'), 'nor a constant');
ok(!Cache->can('_helper'), 'nor a _private sub');
ok(!Cache->can('secret'), 'nor a private slot\'s accessor');
is_deeply([ sort keys %{ Object::Proto::slot_info('Cache', 'storage')->{handles} } ],
    [ sort qw(get put describe kind size get_size clear_size) ], 'exactly those');

# A name given explicitly wins over the role's
Object::Proto::define('Renamed', 'storage:Object:handles(role:Storage::API, get=>describe)');
is(Renamed->new(storage => $store)->get, 'storage: memory', 'an explicit name wins over the role\'s');

# Loaded when not defined yet
Object::Proto::define('Loaded', 'storage:Object:handles(role:Handles::Storage)');
package Backend;
sub fetch    { "fetched $_[1]" }
sub store    { "stored $_[1]" }
sub describe { 'backend' }
package main;
{
    my $l = Loaded->new(storage => bless({}, 'Backend'));
    is($l->fetch('x'), 'fetched x', 'a role loaded from its module');
    is($l->describe, 'backend', 'with its own subs');
}

# Read when the class is defined
Object::Proto::role('Growing');
Object::Proto::requires('Growing', 'first');
Object::Proto::define('Early', 'thing:Object:handles(role:Growing)');
Object::Proto::requires('Growing', 'second');
ok(Early->can('first'), 'what the role requires at define time is delegated');
ok(!Early->can('second'), 'what it requires later is not');

# A method name outside Latin-1
package Greek;
sub Ω { 'omega' }
package main;
Object::Proto::role('Greek');
Object::Proto::define('Letters', 'greek:Object:handles(role:Greek)');
is(Letters->new(greek => bless({}, 'Greek'))->Ω, 'omega', 'a method with a UTF-8 name');

# with(): the delegators satisfy the role's required methods
Object::Proto::role('Needs');
Object::Proto::requires('Needs', 'get', 'put');
Object::Proto::define('Satisfied', 'storage:Object:handles(get, put)');
ok(eval { Object::Proto::with('Satisfied', 'Needs'); 1 }, 'delegators satisfy what a role requires');
ok(Object::Proto::does('Satisfied', 'Needs'), 'and the class does the role');
is(Satisfied->new(storage => $store)->get('a'), 1, 'and still delegates');

# A role's methods clash like any others
Object::Proto::role('HasName');
package HasName;
sub name { 'role name' }
package main;
eval { Object::Proto::define('Named', 'name:Str', 'other:Object:handles(role:HasName)') };
like($@, qr/^handles for slot 'other': method 'name' is already provided by slot 'name' at /,
    'a role method clashing with a slot croaks');
package OwnSub;
sub describe { 'own' }
package main;
eval { Object::Proto::define('OwnSub', 'storage:Object:handles(role:Storage::API)') };
like($@, qr/^You cannot overwrite a locally defined method \(describe\) with a delegation at /,
    'as does one clashing with a sub of the class\'s');

# A role slot with handles: each class composing the role delegates
Object::Proto::role('WithLogger', 'logger:Object:handles(log_info=>info)');
package Logger;
sub new  { bless { name => $_[1] }, $_[0] }
sub info { "$_[0]{name}: $_[1]" }
package main;
Object::Proto::define('UsesA', 'a');
Object::Proto::with('UsesA', 'WithLogger');
Object::Proto::define('UsesB', 'b');
Object::Proto::with('UsesB', 'WithLogger');
is(UsesA->new(logger => Logger->new('A'))->log_info('x'), 'A: x', 'a role slot\'s delegator in one class');
is(UsesB->new(logger => Logger->new('B'))->log_info('y'), 'B: y', 'and in another');
Object::Proto::define('UsesAChild', extends => 'UsesA');
is(UsesAChild->new(logger => Logger->new('C'))->log_info('z'), 'C: z', 'and in a child of one');

# with() adding a role slot whose methods would take a delegator's name
Object::Proto::role('SizeSlot', 'size:Int');
Object::Proto::define('Delegating', 'storage:Object:handles(size)');
eval { Object::Proto::with('Delegating', 'SizeSlot') };
like($@, qr/^Slot conflict: method 'size' of slot 'size' from role 'SizeSlot' is delegated in class 'Delegating' at /,
    'a role slot whose accessor a delegator has croaks');
Object::Proto::role('ReaderSlot', 'level:Int:reader(get_size)');
Object::Proto::define('Delegating2', 'storage:Object:handles(get_size)');
eval { Object::Proto::with('Delegating2', 'ReaderSlot') };
like($@, qr/^Slot conflict: method 'get_size' of slot 'level' from role 'ReaderSlot' is delegated in class 'Delegating2' at /,
    'as does one whose reader a delegator has');
is(Delegating->new(storage => MemoryStore->new(size => 7))->size, 7, 'and the delegator is left as it was');

# A role slot named like a sub of the class's own: the sub wins, as before
package OwnsLevel;
sub level { 'own level' }
package main;
Object::Proto::define('OwnsLevel', 'x');
ok(eval { Object::Proto::with('OwnsLevel', 'ReaderSlot'); 1 }, 'a role slot named like a class sub is no delegator clash');
is(OwnsLevel->new->level, 'own level', 'and the class\'s sub is kept');

# A role slot's delegator clashing with the class
Object::Proto::role('Clashing', 'other:Object:handles(info)');
Object::Proto::define('HasInfo', 'info:Str');
eval { Object::Proto::with('HasInfo', 'Clashing') };
like($@, qr/^handles for slot 'other': method 'info' is already provided by slot 'info' at /,
    'a role slot\'s delegator clashing with the class\'s slot croaks');

done_testing;
