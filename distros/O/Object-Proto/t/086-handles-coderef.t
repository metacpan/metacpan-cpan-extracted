use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed reftype);
use Object::Proto;

# CodeRef delegation: 'f:CodeRef:handles(format)' makes $o->format(@a) call
# $o->f->(@a); 'f:CodeRef:handles(run=>method)' calls $o->f->($o, @a).

our $void;
sub context { wantarray ? 'list' : defined wantarray ? 'scalar' : do { $void++; 'void' } }

Object::Proto::define('Fmt',
    'formatter:CodeRef:clearer:handles(format, fmt=>call)',
    'callback:CodeRef:handles(run=>method)',
    'label:Str');

my @seen;
my $fmt = Fmt->new(
    formatter => sub { @seen = @_; return wantarray ? ('list', @_) : 'scalar:' . join(',', @_) },
    callback  => sub { @seen = @_; return scalar @_ },
    label     => 'fmt',
);

# --- call: the code is called with the arguments, without the invocant --------

is_deeply([ $fmt->format(1, 2) ], ['list', 1, 2], 'call passes the arguments, not the invocant');
is(scalar $fmt->format(1, 2), 'scalar:1,2', 'in scalar context');
is_deeply([ $fmt->fmt('x') ], ['list', 'x'], '=>call is the same as a bare name');
is_deeply([ $fmt->format ], ['list'], 'no arguments');
is_deeply([ $fmt->format(undef) ], ['list', undef], 'an undef argument');
my $ref = [1];
$fmt->format($ref);
is(refaddr($seen[0]), refaddr($ref), 'a reference is passed as is');
is_deeply([ 0, $fmt->format('m'), 9 ], [0, 'list', 'm', 9], 'results land in the middle of a list');
is_deeply([ map { scalar $fmt->format($_) } 1 .. 3 ], [ map { "scalar:$_" } 1 .. 3 ], 'in a map');

# --- method: the invocant comes first ------------------------------------------

is($fmt->run('a', 'b'), 3, 'method passes the invocant and the arguments');
is(refaddr($seen[0]), refaddr($fmt), 'the invocant is the object itself');
is_deeply([ @seen[1, 2] ], ['a', 'b'], 'followed by the arguments');
is($fmt->run, 1, 'with no arguments, just the invocant');

# --- context ---------------------------------------------------------------------

Object::Proto::define('Ctx', 'call:CodeRef:handles(ctx_call=>call)', 'meth:CodeRef:handles(ctx_method=>method)',
    'lots:CodeRef:handles(many)');
my $ctx = Ctx->new(call => \&context, meth => \&context, lots => sub { (1) x 500 });
is(($ctx->ctx_call)[0], 'list', 'call: list context');
is(scalar $ctx->ctx_call, 'scalar', 'call: scalar context');
{ local $void = 0; $ctx->ctx_call; is($void, 1, 'call: void context') }
is(($ctx->ctx_method)[0], 'list', 'method: list context');
is(scalar $ctx->ctx_method, 'scalar', 'method: scalar context');
{ local $void = 0; $ctx->ctx_method; is($void, 1, 'method: void context') }
is(scalar(() = $ctx->many), 500, 'many results (the stack grows)');
is_deeply([ ($ctx->many)[0, 499] ], [1, 1], 'all moved into place');

# --- the kinds of code -----------------------------------------------------------

{
    my $count = 0;
    my $c = Fmt->new(formatter => sub { ++$count });
    $c->format for 1 .. 3;
    is($count, 3, 'a closure over a lexical');
    $c->formatter(sub { 'replaced' });
    is($c->format, 'replaced', 'the code replaced at run time is called next');
    sub named { "named:@_" }
    $c->formatter(\&named);
    is($c->format('n'), 'named:n', 'a reference to a named sub');
    $c->formatter(\&Scalar::Util::blessed);
    is($c->format($c), 'Fmt', 'an XSUB, called');
    my $m = Fmt->new(callback => \&Scalar::Util::reftype);
    is($m->run, 'ARRAY', 'an XSUB, as a method');

    # The code replaces itself while it runs: that call completes, the next one is the new code
    my $self_replacing;
    $self_replacing = Fmt->new(formatter => sub { $self_replacing->formatter(sub { 'second' }); 'first' });
    is($self_replacing->format, 'first', 'code that replaces itself finishes its call');
    is($self_replacing->format, 'second', 'and the replacement runs next');
}

# Re-entrant: the code calls back into the delegator
{
    my $r;
    $r = Fmt->new(formatter => sub { my $n = shift; $n ? $n + $r->format($n - 1) : 0 });
    is($r->format(4), 10, 'code that calls the delegator again');
}

# --- errors ---------------------------------------------------------------------

eval { Fmt->new(formatter => sub { die "code died\n" })->format };
is($@, "code died\n", 'an exception from the code propagates');
eval { Fmt->new(formatter => sub { die bless {}, 'My::Error' })->format };
isa_ok($@, 'My::Error', 'an exception object stays an object');

my $empty = Fmt->new;
eval { $empty->format };
like($@, qr/^Cannot delegate format to formatter: formatter is not set at /, 'code never set croaks');
eval { $empty->run };
like($@, qr/^Cannot delegate run to callback: callback is not set at /, 'for method too');
{
    my $cleared = Fmt->new(formatter => sub { 1 });
    $cleared->clear_formatter;
    eval { $cleared->format };
    like($@, qr/^Cannot delegate format to formatter: formatter is not set at /, 'or once cleared');
}

# A value that is no code reference is not called, not even by name
sub main::victim { die "called by name\n" }
Object::Proto::define('Stringy', 'text:Str', 'more:Str');
{
    my $stray = Fmt->new;
    $stray->set_prototype(Stringy->new(text => 'main::victim', more => 'main::victim'));
    eval { $stray->format };
    like($@, qr/^Cannot delegate format to formatter: formatter is not a CODE reference at /,
        'a string from a prototype of another class croaks, instead of calling the sub it names');
    eval { $stray->run };
    like($@, qr/^Cannot delegate run to callback: callback is not a CODE reference at /, 'for method too');
    my $direct = Fmt->new;
    $direct->[ Object::Proto::slot_info('Fmt', 'formatter')->{index} ] = { not => 'code' };
    eval { $direct->format };
    like($@, qr/^Cannot delegate format to formatter: formatter is not a CODE reference at /,
        'as does a hash written into the object directly');
}

for my $method (qw(format run)) {
    eval { Fmt->can($method)->({}) };
    like($@, qr/^Not an object at /, "$method: an invocant that is not an object croaks");
    eval { Fmt->can($method)->() };
    like($@, qr/^Not an object at /, "$method: as does no invocant");
}

# --- lazy, frozen, readonly, trigger --------------------------------------------

package LazyFmt;
our $built = 0;
sub _build_formatter { $built++; sub { "lazy:@_" } }
sub _build_nothing { undef }
package main;
Object::Proto::define('LazyFmt', 'formatter:CodeRef:lazy:builder(_build_formatter):handles(format)',
    'nothing:CodeRef:lazy:builder(_build_nothing):handles(nothing_call=>call)');
{
    my $l = LazyFmt->new;
    is($LazyFmt::built, 0, 'lazy code is not built by new');
    is($l->format('x'), 'lazy:x', 'it is built on the first delegated call');
    $l->format;
    is($LazyFmt::built, 1, 'once');
    eval { $l->nothing_call };
    like($@, qr/^Cannot delegate nothing_call to nothing: nothing is not set at /, 'a builder returning undef: not set');
}

{
    my $frozen = Fmt->new(formatter => sub { 'still' });
    Object::Proto::freeze($frozen);
    is($frozen->format, 'still', 'a frozen object still calls its code');
}
Object::Proto::define('RoFmt', 'formatter:CodeRef:readonly:handles(format)');
is(RoFmt->new(formatter => sub { 'ro' })->format, 'ro', 'as does a readonly slot');

package TrigFmt;
our $fired = 0;
sub on_set { $fired++ }
package main;
Object::Proto::define('TrigFmt', 'formatter:CodeRef:trigger(on_set):handles(format)');
{
    my $t = TrigFmt->new(formatter => sub { 1 });
    $TrigFmt::fired = 0;
    $t->format;
    is($TrigFmt::fired, 0, 'calling the code does not fire the slot\'s trigger');
}

# --- prototypes -----------------------------------------------------------------

{
    my $proto = Fmt->new(formatter => sub { "proto:@_" }, callback => sub { $_[0] });
    my $obj = Fmt->new(label => 'obj');
    $obj->set_prototype($proto);
    is($obj->format('p'), 'proto:p', 'code found on the prototype');
    is(refaddr($obj->run), refaddr($obj), 'method passes the object, not the prototype the code came from');

    my $bottom = Fmt->new;
    my $middle = Fmt->new;
    $middle->set_prototype($proto);
    $bottom->set_prototype($middle);
    is($bottom->format('deep'), 'proto:deep', 'further up the chain');

    my $own = Fmt->new(formatter => sub { 'own' });
    $own->set_prototype($proto);
    is($own->format, 'own', 'the object\'s own code comes first');
}

# --- inheritance and +attr --------------------------------------------------------

Object::Proto::define('FmtChild', extends => 'Fmt', 'extra');
{
    my $child = FmtChild->new(formatter => sub { "child:@_" }, callback => sub { ref $_[0] });
    is($child->format('c'), 'child:c', 'a child calls code in an inherited slot');
    is($child->run, 'FmtChild', 'method passes the child object');
    my $from_parent = FmtChild->new;
    $from_parent->set_prototype(Fmt->new(formatter => sub { 'parent proto' }));
    is($from_parent->format, 'parent proto', 'a child object, code on a parent prototype');
}

Object::Proto::define('ModeSwap', extends => 'Fmt', '+callback:handles(run=>call)');
is(ModeSwap->new(callback => sub { scalar @_ })->run('a'), 1, '+attr switches method to call');
is(Fmt->new(callback => sub { scalar @_ })->run('a'), 2, 'not in the parent');

Object::Proto::define('CP1', 'x:Str');
Object::Proto::define('CP2', 'y:Str', 'code:CodeRef:handles(code_run=>method)');
Object::Proto::define('CodeMI', extends => ['CP1', 'CP2']);
{
    my $mi = CodeMI->new(x => 'x', y => 'y', code => sub { $_[0]->y });
    is($mi->code_run, 'y', 'a second parent\'s CodeRef slot, at another index in the child');
}

# --- redefinition and modifiers -----------------------------------------------

Object::Proto::define('Switch', 'f:CodeRef:handles(go)', 'o:Object');
my $switch_cv = \&Switch::go;
is(Switch->new(f => sub { scalar @_ })->go('a'), 1, 'a call delegator');
{
    no warnings 'redefine';
    Object::Proto::define('Switch', 'f:CodeRef:handles(go=>method)', 'o:Object');
}
is(refaddr(\&Switch::go), refaddr($switch_cv), 'a redefinition keeps the delegator');
is(Switch->new(f => sub { scalar @_ })->go('a'), 2, 'switched from call to method');
{
    no warnings 'redefine';
    Object::Proto::define('Switch', 'f:CodeRef:handles(go)', 'o:Object');
}
is(Switch->new(f => sub { scalar @_ })->go('a'), 1, 'and back to call');
package Target;
sub go { 'a method' }
package main;
{
    no warnings 'redefine';
    Object::Proto::define('Switch', 'f:CodeRef', 'o:Object:handles(go)');
}
is(Switch->new(o => bless({}, 'Target'))->go, 'a method', 'from a CodeRef slot to an Object slot');
{
    no warnings 'redefine';
    Object::Proto::define('Switch', 'f:CodeRef:handles(go=>method)', 'o:Object');
}
is(Switch->new(f => sub { 'code again' })->go, 'code again', 'and back to a CodeRef slot');

Object::Proto::define('WrappedFmt', 'f:CodeRef:handles(format)');
Object::Proto::around('WrappedFmt::format', sub { my ($orig, @args) = @_; '[' . $orig->(@args) . ']' });
is(WrappedFmt->new(f => sub { "w:@_" })->format('x'), '[w:x]', 'around wraps a code delegator');

# --- a role's CodeRef slot ----------------------------------------------------

Object::Proto::role('Hooked', 'hook:CodeRef:handles(fire=>method)');
Object::Proto::define('HasHook', 'name:Str');
Object::Proto::with('HasHook', 'Hooked');
is(HasHook->new(name => 'h', hook => sub { $_[0]->name })->fire, 'h', 'a role\'s CodeRef slot delegates');

is_deeply(Object::Proto::slot_info('Fmt', 'formatter')->{handles}, { format => 'call', fmt => 'call' },
    'slot_info shows call');
is_deeply(Object::Proto::slot_info('Fmt', 'callback')->{handles}, { run => 'method' }, 'and method');

done_testing;
