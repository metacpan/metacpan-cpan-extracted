use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Object::Proto;

# Delegators and inheritance: a child gets delegators of its own for the slots
# it inherits, at its own slot indices; what the child declares itself can
# extend or override them; and the delegate is found through prototypes of any
# class in the hierarchy.

package Logger;
our @calls;
sub new   { bless { name => $_[1] }, $_[0] }
sub info  { push @calls, "$_[0]{name}.info"; "info($_[0]{name})" }
sub warn  { push @calls, "$_[0]{name}.warn"; "warn($_[0]{name})" }
sub debug { push @calls, "$_[0]{name}.debug"; "debug($_[0]{name})" }
package main;

sub L { Logger->new(@_) }

Object::Proto::define('Parent', 'logger:Object:handles(info, log_warn=>warn)');
Object::Proto::define('Child', extends => 'Parent', 'extra');
Object::Proto::define('GrandChild', extends => 'Child', 'more');

# --- single inheritance -------------------------------------------------------

is(Child->new(logger => L('c'))->info, 'info(c)', 'a child delegates through an inherited slot');
is(Child->new(logger => L('c'))->log_warn, 'warn(c)', 'renamed too');
is(GrandChild->new(logger => L('g'))->info, 'info(g)', 'as does a grandchild');
isnt(refaddr(Child->can('info')), refaddr(Parent->can('info')), 'the child has a delegator of its own');
is(Parent::info(Child->new(logger => L('p'))), 'info(p)', 'the parent\'s on a child object still works');
is(Parent->new(logger => L('parent'))->info, 'info(parent)', 'and the parent is unchanged');

# --- multiple inheritance: the child's slot indices differ from a parent's ---

Object::Proto::define('P1', 'a:Object:handles(from_a=>info)');
Object::Proto::define('P2', 'x:Str', 'b:Object:handles(from_b=>info)');
Object::Proto::define('MI', extends => ['P1', 'P2']);
isnt(Object::Proto::slot_info('MI', 'b')->{index}, Object::Proto::slot_info('P2', 'b')->{index},
    'the second parent\'s slot has another index in the child');
{
    my $mi = MI->new(a => L('a'), x => 'text', b => L('b'));
    is($mi->from_b, 'info(b)', 'its delegator reaches the right slot');
    is($mi->from_a, 'info(a)', 'as does the first parent\'s');
}

# Two parents delegating the same name: the first parent wins, as for slots
Object::Proto::define('P3', 'c:Object:handles(shared)');
Object::Proto::define('P4', 'd:Object:handles(shared)');
Object::Proto::define('MI2', extends => ['P3', 'P4']);
{
    local @Logger::calls;
    package Logger; sub shared { push @calls, "$_[0]{name}.shared"; 'shared' } package main;
    MI2->new(c => L('c'), d => L('d'))->shared;
    is_deeply(\@Logger::calls, ['c.shared'], 'two parents delegating one name: the first parent\'s wins');
}
Object::Proto::define('P5', 'shared2');
Object::Proto::define('P6', 'e:Object:handles(shared2=>info)');
Object::Proto::define('MI3', extends => ['P5', 'P6']);
is(MI3->new(shared2 => 'plain', e => L('e'))->shared2, 'plain',
    'an earlier parent\'s accessor wins over a later parent\'s delegator');

# --- what the child declares ------------------------------------------------

package Kid;
sub info { 'kid\'s own' }
package main;
Object::Proto::define('Kid', extends => 'Parent');
is(Kid->new(logger => L('k'))->info, 'kid\'s own', 'a child\'s own sub overrides an inherited delegator');
is(Kid->new(logger => L('k'))->log_warn, 'warn(k)', 'its other delegators are kept');

Object::Proto::define('SizeParent', 'logger:Object:handles(size=>info)');
Object::Proto::define('SizeChild', extends => 'SizeParent', 'size:Int');
is(SizeChild->new(size => 5, logger => L('s'))->size, 5, 'as does a child\'s slot of the same name');
is(SizeParent->new(logger => L('s'))->size, 'info(s)', 'while the parent still delegates');

Object::Proto::define('Replaced', extends => 'Parent', 'logger:Object');
is(Replaced->new(logger => L('r'))->info, 'info(r)',
    'a child redeclaring the slot without handles still inherits the parent\'s delegator');

Object::Proto::define('Union', extends => 'Parent', '+logger:handles(debug)');
{
    my $u = Union->new(logger => L('u'));
    is($u->debug, 'debug(u)', '+attr adds a delegator');
    is($u->info, 'info(u)', 'and keeps the inherited ones');
    ok(!Parent->can('debug'), 'not in the parent');
}
Object::Proto::define('Swapped', extends => 'Parent', '+logger:handles(info=>debug)');
is(Swapped->new(logger => L('s'))->info, 'debug(s)', '+attr can point an inherited name elsewhere');
is(Parent->new(logger => L('p'))->info, 'info(p)', 'not in the parent');

Object::Proto::define('PlainParent', 'helper:Object');
Object::Proto::define('GivesHandles', extends => 'PlainParent', '+helper:handles(info)');
is(GivesHandles->new(helper => L('h'))->info, 'info(h)', '+attr can give an inherited slot handles');
ok(!PlainParent->can('info'), 'which the parent does not have');

package Kid2;
sub debug { 'mine' }
package main;
eval { Object::Proto::define('Kid2', extends => 'Parent', '+logger:handles(debug)') };
like($@, qr/^You cannot overwrite a locally defined method \(debug\) with a delegation at /,
    'handles the child declares itself do clash with its own sub');

# A lazy builder of the parent's, found by method resolution
package LazyParent;
sub _build_logger { Logger->new('built') }
package main;
Object::Proto::define('LazyParent', 'logger:Object:lazy:builder(_build_logger):handles(info)');
Object::Proto::define('LazyChild', extends => 'LazyParent');
is(LazyChild->new->info, 'info(built)', 'an inherited lazy slot builds through the parent\'s builder');

# --- inheritance and prototypes together -----------------------------------

{
    my $parent = Parent->new(logger => L('parent'));
    my $child = Child->new;
    $child->set_prototype($parent);
    is($child->info, 'info(parent)', 'a child object finds the delegate on a parent prototype');

    my $kid_proto = Child->new(logger => L('child'));
    my $parent_obj = Parent->new;
    $parent_obj->set_prototype($kid_proto);
    is($parent_obj->info, 'info(child)', 'a parent object on a child prototype');

    my $grand = GrandChild->new;
    my $middle = Child->new;
    $middle->set_prototype($parent);
    $grand->set_prototype($middle);
    is($grand->info, 'info(parent)', 'a grandchild through a chain of child and parent');

    my $swapped = Swapped->new;
    $swapped->set_prototype($parent);
    is($swapped->info, 'debug(parent)', 'the child\'s handles apply to a delegate from a parent prototype');

    my $mi = MI->new(x => 'text');
    $mi->set_prototype(MI->new(a => L('pa'), x => 't', b => L('pb')));
    is($mi->from_b, 'info(pb)', 'a multiple-inheritance object through a prototype of its class');

    my $lazy = LazyChild->new;
    $lazy->set_prototype(LazyParent->new(logger => L('proto')));
    is($lazy->info, 'info(proto)', 'an inherited lazy slot uses a prototype\'s delegate before building');
}

done_testing;
