use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Hash::Util::FieldHash qw(fieldhash);
use Tie::Array;
use Object::Proto;

# Native ArrayRef delegation: each op is checked against the perl builtin it
# mirrors, on a plain array with the same contents, in list and scalar context.

package Bag;
our @fired;
sub on_tags { push @fired, [ $_[0], $_[1] ] }
package main;

Object::Proto::define('Bag',
    'tags:ArrayRef:clearer(drop_tags):trigger(on_tags):handles(push_tag=>push, unshift_tag=>unshift, pop_tag=>pop,'
  . ' shift_tag=>shift, all_tags=>list, elements_tags=>elements, tag_count=>count, no_tags=>is_empty,'
  . ' get_tag=>get, set_tag=>set, clear_tags=>clear)',
    'label:Str');

# [ what, starting contents, delegating method, arguments, the builtin ]
my @cases = (
    [ 'push one',              [1, 2],    push_tag     => [3],       sub { my $a = shift; push @$a, @_ } ],
    [ 'push several',          [],        push_tag     => [1, 2, 3], sub { my $a = shift; push @$a, @_ } ],
    [ 'unshift one',           [2],       unshift_tag  => [1],       sub { my $a = shift; unshift @$a, @_ } ],
    [ 'unshift several',       [3],       unshift_tag  => [1, 2],    sub { my $a = shift; unshift @$a, @_ } ],
    [ 'pop',                   [1, 2],    pop_tag      => [],        sub { pop @{ $_[0] } } ],
    [ 'pop an empty array',    [],        pop_tag      => [],        sub { pop @{ $_[0] } } ],
    [ 'shift',                 [1, 2],    shift_tag    => [],        sub { shift @{ $_[0] } } ],
    [ 'shift an empty array',  [],        shift_tag    => [],        sub { shift @{ $_[0] } } ],
    [ 'list',                  [1, 2, 3], all_tags     => [],        sub { @{ $_[0] } } ],
    [ 'list of an empty array', [],       all_tags     => [],        sub { @{ $_[0] } } ],
    [ 'elements',              [1, 2],    elements_tags => [],       sub { @{ $_[0] } } ],
    [ 'count',                 [1, 2, 3], tag_count    => [],        sub { scalar @{ $_[0] } } ],
    [ 'count of none',         [],        tag_count    => [],        sub { scalar @{ $_[0] } } ],
    [ 'is_empty, not',         [1],       no_tags      => [],        sub { !@{ $_[0] } } ],
    [ 'is_empty',              [],        no_tags      => [],        sub { !@{ $_[0] } } ],
    [ 'get',                   [1, 2, 3], get_tag      => [1],       sub { $_[0][ $_[1] ] } ],
    [ 'get from the end',      [1, 2, 3], get_tag      => [-1],      sub { $_[0][ $_[1] ] } ],
    [ 'get past the end',      [1, 2, 3], get_tag      => [7],       sub { $_[0][ $_[1] ] } ],
    [ 'get before the start',  [1, 2, 3], get_tag      => [-9],      sub { $_[0][ $_[1] ] } ],
    [ 'set',                   [1, 2, 3], set_tag      => [1, 'x'],  sub { $_[0][ $_[1] ] = $_[2] } ],
    [ 'set from the end',      [1, 2, 3], set_tag      => [-1, 'x'], sub { $_[0][ $_[1] ] = $_[2] } ],
    [ 'set past the end',      [1],       set_tag      => [3, 'x'],  sub { $_[0][ $_[1] ] = $_[2] } ],
    [ 'clear',                 [1, 2],    clear_tags   => [],        sub { @{ $_[0] } = () } ],
    [ 'clear an empty array',  [],        clear_tags   => [],        sub { @{ $_[0] } = () } ],
);
for my $case (@cases) {
    my ($what, $start, $method, $args, $builtin) = @$case;
    for my $context (qw(list scalar)) {
        my $bag = Bag->new(tags => [@$start]);
        my @plain = @$start;
        my (@got, @want);
        if ($context eq 'list') {
            @got  = $bag->$method(@$args);
            @want = $builtin->(\@plain, @$args);
        } else {
            $got[0]  = $bag->$method(@$args);
            $want[0] = $builtin->(\@plain, @$args);
        }
        is_deeply(\@got, \@want, "$what, $context context: returns as the builtin does");
        is_deeply($bag->tags, \@plain, "$what, $context context: leaves the array as the builtin does");
    }
}

# --- details ------------------------------------------------------------------

{
    my $bag = Bag->new;
    $#{ $bag->tags } = 2;
    is_deeply([ $bag->all_tags ], [undef, undef, undef], 'list over empty elements gives undef for each');
    my $x = 'original';
    $bag->push_tag($x);
    $x = 'changed';
    is($bag->get_tag(-1), 'original', 'a stored value is a copy');
    $bag->clear_tags;
    $bag->push_tag(1 .. 1000);
    is(scalar(my @all = $bag->all_tags), 1000, 'list of 1000 elements (the stack grows)');
    is_deeply([ @all[0, 999] ], [1, 1000], 'all in order');
    $_ .= '!' for $bag->all_tags;
    is($bag->get_tag(0), '1!', 'list gives the array\'s own elements, as @$ref does');
    eval { $bag->set_tag(-2000, 'x') };
    my @plain = (1);
    eval { $plain[-2] = 'x' };
    my $builtin_error = $@ =~ s/ at .*//sr;
    eval { Bag->new(tags => [1])->set_tag(-2, 'x') };
    like($@, qr/^\Q$builtin_error\E at /, 'set before the start croaks as the builtin does');
}

# --- arity (D12) ------------------------------------------------------------

{
    my $bag = Bag->new(tags => [1, 2]);
    local @Bag::fired;
    for my $case (
        [ tag_count  => [1],       'count takes 0' ],
        [ pop_tag    => [1],       'pop takes 0' ],
        [ get_tag    => [],        'get takes 1' ],
        [ get_tag    => [1, 2],    'get takes 1' ],
        [ set_tag    => [1],       'set takes 2' ],
        [ set_tag    => [1, 2, 3], 'set takes 2' ],
        [ push_tag   => [],        'push takes at least 1' ],
        [ unshift_tag => [],       'unshift takes at least 1' ],
        [ elements_tags => [1],    'list takes 0' ],
    ) {
        my ($method, $args, $says) = @$case;
        eval { $bag->$method(@$args) };
        like($@, qr/^Wrong number of arguments to $method \($says\) at /, "$method with " . @$args . " arguments croaks");
    }
    is_deeply($bag->tags, [1, 2], 'a call that croaks changes nothing');
    is(scalar @Bag::fired, 0, 'and fires no trigger');
}

# --- not set, implicit default, lazy, required (D3) -------------------------

{
    my ($one, $two) = (Bag->new, Bag->new);
    $one->push_tag('a');
    is_deeply($one->tags, ['a'], 'with no default written, push works on a new object');
    is_deeply($two->tags, [], 'each object has its own array');
    my $cleared = Bag->new(tags => [1]);
    $cleared->clear_tags;                    # the op: empties the array
    is_deeply($cleared->tags, [], 'clear empties it');
}
Object::Proto::define('Clearable', 'tags:ArrayRef:clearer(drop_tags):handles(push_tag=>push, tag_count=>count, all_tags=>list)');
{
    my $c = Clearable->new;
    $c->drop_tags;
    for my $method (qw(push_tag tag_count all_tags)) {
        eval { $c->$method($method eq 'push_tag' ? (1) : ()) };
        like($@, qr/^Cannot delegate $method to tags: tags is not set at /, "once the slot is cleared, $method croaks");
    }
}
package LazyBag;
our $built = 0;
sub _build_tags { $built++; ['built'] }
sub _build_none { undef }
package main;
Object::Proto::define('LazyBag', 'tags:ArrayRef:lazy:builder(_build_tags):handles(tag_count=>count)',
    'none:ArrayRef:lazy:builder(_build_none):handles(none_count=>count)',
    'implicit:ArrayRef:lazy:handles(implicit_push=>push)');
{
    my $l = LazyBag->new;
    is($LazyBag::built, 0, 'a lazy builder does not run in new');
    is($l->tag_count, 1, 'it runs on the first delegated call');
    is($LazyBag::built, 1, 'once');
    eval { $l->none_count };
    like($@, qr/^Cannot delegate none_count to none: none is not set at /, 'a builder returning undef: not set');
    is($l->implicit_push(1), 1, 'a lazy slot with the implicit default');
}
Object::Proto::define('ReqBag', 'tags:ArrayRef:required:handles(tag_count=>count)');
is(ReqBag->new(tags => [1, 2])->tag_count, 2, 'a required slot, given a value');

# --- frozen and locked (D4) -------------------------------------------------

{
    my $frozen = Bag->new(tags => [1, 2]);
    Object::Proto::freeze($frozen);
    for my $case ([ push_tag => [3] ], [ unshift_tag => [0] ], [ pop_tag => [] ], [ shift_tag => [] ],
                  [ set_tag => [0, 'x'] ], [ clear_tags => [] ]) {
        my ($method, $args) = @$case;
        eval { $frozen->$method(@$args) };
        like($@, qr/^Cannot modify frozen object at /, "a frozen object: $method croaks");
    }
    is_deeply($frozen->tags, [1, 2], 'and the array is untouched');
    is_deeply([ $frozen->all_tags ], [1, 2], 'the ops that read still work');
    is($frozen->tag_count, 2, 'count');
    is($frozen->get_tag(0), 1, 'get');
    ok(!$frozen->no_tags, 'is_empty');

    my $locked = Bag->new(tags => [1]);
    Object::Proto::lock($locked);
    is($locked->push_tag(2), 2, 'a locked object, not frozen, can push');

    fieldhash my %registry;
    my $magic = Bag->new(tags => [1]);
    $registry{$magic} = 1;
    is($magic->push_tag(2), 2, 'as can one carrying another module\'s magic');
}

# --- the trigger (D6) -------------------------------------------------------

{
    my $bag = Bag->new(tags => [1, 2, 3]);
    for my $case ([ push_tag => [4] ], [ unshift_tag => [0] ], [ pop_tag => [] ], [ shift_tag => [] ],
                  [ set_tag => [0, 'x'] ], [ clear_tags => [] ]) {
        my ($method, $args) = @$case;
        @Bag::fired = ();
        $bag->$method(@$args);
        is(scalar @Bag::fired, 1, "$method fires the trigger once");
        is(refaddr($Bag::fired[0][0]), refaddr($bag), 'with the object');
        is(refaddr($Bag::fired[0][1]), refaddr($bag->tags), 'and the array');
    }
    @Bag::fired = ();
    $bag->push_tag(1, 2);
    $bag->$_ for qw(all_tags tag_count no_tags);
    $bag->get_tag(0);
    is(scalar @Bag::fired, 1, 'the ops that read fire nothing');
    is_deeply(\@{ $Bag::fired[0][1] }, [1, 2], 'and the trigger sees the array after the change');
}

package Dying;
sub on_tags { die "trigger died\n" }
package Churning;
sub on_tags { my @junk = map { "junk $_" x 10 } 1 .. 1000; return }
package main;
Object::Proto::define('Dying', 'tags:ArrayRef:trigger(on_tags):handles(push_tag=>push)');
{
    my $d = Dying->new;
    eval { $d->push_tag('kept') };
    is($@, "trigger died\n", 'a trigger that dies: the exception propagates');
    is_deeply($d->tags, ['kept'], 'and the change stays');
}
Object::Proto::define('Churning', 'tags:ArrayRef:trigger(on_tags):handles(pop_tag=>pop, shift_tag=>shift)');
{
    my $c = Churning->new(tags => ['first', 'last']);
    is($c->pop_tag, 'last', 'a popped value outlives a trigger that makes many temporaries');
    is($c->shift_tag, 'first', 'as does a shifted one');
}
Object::Proto::define('NoName', 'tags:ArrayRef:trigger():handles(push_tag=>push)');
is(NoName->new->push_tag(1), 1, 'a trigger() with no name fires nothing');

# --- the container ------------------------------------------------------------

{
    my @log;
    package LoggedArray;
    our @ISA = ('Tie::StdArray');
    sub STORE { push @log, 'STORE'; shift->SUPER::STORE(@_) }
    sub FETCH { push @log, 'FETCH'; shift->SUPER::FETCH(@_) }
    sub FETCHSIZE { push @log, 'FETCHSIZE'; shift->SUPER::FETCHSIZE(@_) }
    package main;
    tie my @tied, 'LoggedArray';
    my $bag = Bag->new(tags => \@tied);
    is($bag->push_tag(1, 2, 3), 3, 'a tied array: push');
    ok((grep { $_ eq 'STORE' } @log), 'through the tie\'s STORE');
    is($bag->unshift_tag(0), 4, 'unshift');
    is($bag->pop_tag, 3, 'pop');
    is($bag->shift_tag, 0, 'shift');
    is_deeply([ $bag->all_tags ], [1, 2], 'list');
    @log = ();
    is($bag->get_tag(1), 2, 'get');
    ok((grep { $_ eq 'FETCH' } @log), 'through the tie\'s FETCH');
    is($bag->set_tag(0, 'x'), 'x', 'set');
    is($bag->tag_count, 2, 'count');
    ok(!$bag->no_tags, 'is_empty');
    $bag->clear_tags;
    is_deeply(\@tied, [], 'clear');
}
{
    my $blessed = bless [1, 2], 'Some::Class';
    is(Bag->new(tags => $blessed)->tag_count, 2, 'a blessed array is still an array');
}
{
    my @readonly = (1, 2);
    Internals::SvREADONLY(@readonly, 1);
    my $bag = Bag->new(tags => \@readonly);
    eval { $bag->push_tag(3) };
    like($@, qr/^Modification of a read-only value attempted at /, 'a read-only array: push croaks as perl does');
    is($bag->tag_count, 2, 'reading it works');
}
{
    Object::Proto::define('Stringy', 'text:Str');
    my $stray = Bag->new;
    my $index = Object::Proto::slot_info('Bag', 'tags')->{index};
    $stray->[$index] = undef;
    $stray->set_prototype(Stringy->new(text => 'not an array'));
    eval { $stray->tag_count };
    like($@, qr/^Cannot delegate tag_count to tags: tags is not an ARRAY reference at /,
        'a string from a prototype of another class croaks');
    my $direct = Bag->new;
    $direct->[$index] = { not => 'an array' };
    eval { $direct->push_tag(1) };
    like($@, qr/^Cannot delegate push_tag to tags: tags is not an ARRAY reference at /,
        'as does a hash written into the object directly');
}
for my $method (qw(push_tag tag_count)) {
    eval { Bag->can($method)->({}, 1) };
    like($@, qr/^Not an object at /, "$method: an invocant that is not an object croaks");
    eval { Bag->can($method)->() };
    like($@, qr/^Not an object at /, "$method: as does no invocant");
}

# --- prototypes ----------------------------------------------------------------

Object::Proto::define('Shared', 'tags:ArrayRef:clearer(drop):trigger(on_tags):handles(push_tag=>push, tag_count=>count, all_tags=>list)');
package Shared;
our @fired;
sub on_tags { push @fired, $_[0] }
package main;
{
    my $proto = Shared->new(tags => ['p']);
    my $obj = Shared->new;
    $obj->drop;                               # no array of its own
    $obj->set_prototype($proto);
    is($obj->tag_count, 1, 'an object without an array of its own uses its prototype\'s');
    @Shared::fired = ();
    $obj->push_tag('from obj');
    is_deeply($proto->tags, ['p', 'from obj'], 'push changes the prototype\'s array, as $obj->tags would');
    is(refaddr($Shared::fired[0]), refaddr($obj), 'the trigger fires on the object called');

    my $bottom = Shared->new;
    $bottom->drop;
    my $middle = Shared->new;
    $middle->drop;
    $middle->set_prototype($proto);
    $bottom->set_prototype($middle);
    is_deeply([ $bottom->all_tags ], ['p', 'from obj'], 'further up the chain');

    my $own = Shared->new(tags => ['own']);
    $own->set_prototype($proto);
    is_deeply([ $own->all_tags ], ['own'], 'an object\'s own array comes first');

    my $other = Shared->new(tags => ['other']);
    $obj->set_prototype($other);
    is($obj->tag_count, 1, 'a new prototype is used on the next call');

    Object::Proto::freeze($proto);
    $obj->set_prototype($proto);
    $obj->push_tag('x');
    is($proto->tag_count, 3, 'a frozen prototype does not stop its array changing through an object (the check is the caller\'s)');
    Object::Proto::freeze($obj);
    eval { $obj->push_tag('y') };
    like($@, qr/^Cannot modify frozen object at /, 'a frozen object does');
}

# --- inheritance, +attr, multiple inheritance, roles --------------------------

Object::Proto::define('BagChild', extends => 'Bag', 'extra');
{
    my $child = BagChild->new;
    is($child->push_tag(1, 2), 2, 'a child pushes through an inherited slot');
    is_deeply([ $child->all_tags ], [1, 2], 'and lists');
    isnt(refaddr($child->tags), refaddr(BagChild->new->tags), 'each child object has its own array');
    @Bag::fired = ();
    $child->pop_tag;
    is(refaddr($Bag::fired[0][0]), refaddr($child), 'the inherited trigger fires on the child');

    my $from_parent = BagChild->new;
    $from_parent->[ Object::Proto::slot_info('BagChild', 'tags')->{index} ] = undef;
    $from_parent->set_prototype(Bag->new(tags => ['parent']));
    is_deeply([ $from_parent->all_tags ], ['parent'], 'a child object, array on a parent prototype');
}
Object::Proto::define('PlusCount', extends => 'Clearable', '+tags:handles(is_empty)');
{
    my $p = PlusCount->new;
    ok($p->is_empty, '+attr adds an op');
    is($p->push_tag(1), 1, 'and keeps the inherited ones');
}
Object::Proto::define('AP1', 'x:Str');
Object::Proto::define('AP2', 'y:Str', 'list:ArrayRef:handles(add=>push, size=>count)');
Object::Proto::define('ArrayMI', extends => ['AP1', 'AP2']);
{
    my $mi = ArrayMI->new(x => 'x', y => 'y');
    $mi->add(1, 2);
    is($mi->size, 2, 'a second parent\'s array slot, at another index in the child');
    is($mi->y, 'y', 'leaving the neighbouring slot alone');
}
Object::Proto::role('Listed', 'items:ArrayRef:handles(add_item=>push, item_count=>count)');
Object::Proto::define('ListedA', 'a');
Object::Proto::with('ListedA', 'Listed');
{
    my $l = ListedA->new;
    $l->add_item(1);
    is($l->item_count, 1, 'a role\'s ArrayRef slot delegates');
}

done_testing;
