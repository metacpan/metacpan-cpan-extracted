use strict;
use warnings;
use Test::More;
use Test::LeakTrace;
use Package::Prototype;

my $callback = sub { 'called' };
my $spec = { count => { value => 0, writer => 'set_count' },
             callback => { value => $callback },
             items => { value => [1,2] },
             optional => { value => undef },
             hidden => { value => 7, reader => '_hidden' } };
my $obj = Package::Prototype->create(properties => $spec,
    methods => { increment => sub { $_[0]->set_count($_[0]->count + 1) } },
    classname => 'Counter');
is ref($obj), 'Counter', 'class label';
is $obj->count, 0, 'default reader';
is $obj->increment, 1, 'writer returns assigned value';
is $obj->count, 1, 'reader observes writer';
is $obj->callback, $callback, 'CODE stored as data';
is $obj->callback->(), 'called', 'callback remains callable';
is_deeply [$obj->items], [[1,2]], 'new readers preserve references in list context';
ok !defined($obj->optional), 'undef value';
is $obj->_hidden, 7, 'explicit underscore reader';
is $spec->{count}{value}, 0, 'input specification unchanged';
ok !$obj->can('set_callback'), 'no implicit writer';
my $other = Package::Prototype->create(properties => $spec);
is $other->count, 0, 'storage independent between instances';
$obj->set_count(undef);
ok !defined($obj->count), 'writer accepts undef';
for my $invoke (sub { $obj->count(3) }, sub { $obj->set_count }, sub { $obj->set_count(1,2) }) {
    eval { $invoke->() };
    like $@, qr/expects .*arguments?/, 'accessor arity checked';
}
for my $args (
    [properties => { x => {} }],
    [properties => []],
    [methods => { x => 1 }],
    [properties => { x => { value => 1, typo => 2 } }],
    [properties => { x => { value => 1, reader => '' } }],
    [properties => { x => { value => 1, writer => 'x' } }],
    [properties => { x => { value => 1 } }, methods => { x => sub {} }],
    [methods => { prototype => sub {} }],
    [unknown => 1],
    ['methods'],
) {
    eval { Package::Prototype->create(@$args) };
    ok $@, 'invalid specification rejected';
}
no_leaks_ok {
    my $o = Package::Prototype->create(properties => { x => { value => [1], writer => 'set_x' } });
    $o->set_x([2]);
    my $reader = $o->can('x');
    undef $o;
    my $value = $reader->(undef);
} 'property storage is released with the last accessor';
done_testing;
