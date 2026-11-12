use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Object::Proto;

# Method delegation: 'slot:Object:handles(...)' installs methods that call the
# same or another method on the object in the slot.

package Logger;
our @calls;
sub new   { my ($class, %a) = @_; bless { name => $a{name} // 'log' }, $class }
sub name  { $_[0]{name} }
sub info  { my $self = shift; push @calls, [ $self->{name}, 'info', @_ ]; return "info:@_" }
sub warn  { my $self = shift; return "warn:@_" }
sub error { my $self = shift; return "error:@_" }
sub context { wantarray ? 'list' : defined wantarray ? 'scalar' : do { $Logger::void++; 'void' } }
sub echo  { shift; return @_ }
sub many  { return (1) x 500 }
sub args  { shift; return scalar @_ }
sub boom  { die "boom\n" }
sub boom_object { die Logger::Error->new }
sub whoami { $_[0] }
package Logger::Error;
sub new { bless {}, shift }
package main;

Object::Proto::define('Svc',
    'logger:Object:handles(info, log_warn=>warn, error, context, echo, many, args, boom, boom_object, whoami, nope)',
    'name:Str');

my $log = Logger->new(name => 'main');
my $svc = Svc->new(logger => $log, name => 'svc');

# --- the basics -------------------------------------------------------------

is($svc->info('a', 'b'), 'info:a b', 'a same-name delegator calls the method on the delegate');
is($svc->log_warn('x'), 'warn:x', 'a renamed one calls the other name');
is($svc->error('e'), 'error:e', 'several in one slot');
ok(Svc->can('info'), 'the class can the delegated method');
ok(!Svc->can('warn'), 'but not a name it only delegates to');
is(refaddr($svc->whoami), refaddr($log), 'the delegate is the invocant');
is($svc->name, 'svc', 'the class\'s other slots are unaffected');

# --- arguments, context and results -----------------------------------------

is($svc->args, 0, 'no arguments');
is($svc->args(undef), 1, 'an undef argument is passed');
my @ref = ([1], { a => 1 });
is(refaddr(($svc->echo(@ref))[0]), refaddr($ref[0]), 'a reference is passed as is');
is_deeply([ $svc->echo(1, undef, 'x') ], [1, undef, 'x'], 'arguments keep their order');
is(scalar(my @list = $svc->context), 1, 'list context returns a list');
is(($svc->context)[0], 'list', 'the delegate sees list context');
is(scalar($svc->context), 'scalar', 'scalar context');
{
    local $Logger::void = 0;
    $svc->context;
    is($Logger::void, 1, 'void context');
}
is(scalar(() = $svc->many), 500, 'many results (the stack grows)');
is_deeply([ 0, $svc->echo(1, 2), 3 ], [0, 1, 2, 3], 'results land in the middle of a list');
is_deeply([ map { $svc->echo($_) } 1 .. 3 ], [1, 2, 3], 'in a map');
is_deeply([ map { scalar $svc->args(1 .. $_) } 1 .. 3 ], [1, 2, 3], 'nested calls with arguments');

# --- errors -----------------------------------------------------------------

eval { $svc->boom };
is($@, "boom\n", 'an exception from the delegate propagates');
eval { $svc->boom_object };
isa_ok($@, 'Logger::Error', 'an exception object stays an object');
eval { $svc->nope };
like($@, qr/^Can't locate object method "nope" via package "Logger"/, 'a method the delegate lacks: perl\'s own error');

my $empty = Svc->new(name => 'empty');
eval { $empty->info };
like($@, qr/^Cannot delegate info to logger: logger is not set at /, 'a delegate never set croaks');
eval { $empty->log_warn };
like($@, qr/^Cannot delegate log_warn to logger: logger is not set at /, 'naming the delegating method');
Object::Proto::define('Clearable', 'logger:Object:clearer:handles(info)');
my $cl = Clearable->new(logger => Logger->new);
is($cl->info(1), 'info:1', 'delegates');
$cl->clear_logger;
eval { $cl->info };
like($@, qr/^Cannot delegate info to logger: logger is not set at /, 'and croaks once cleared');

eval { Svc->can('info')->({}) };
like($@, qr/^Not an object at /, 'an invocant that is not an object croaks');
eval { Svc->can('info')->() };
like($@, qr/^Not an object at /, 'as does no invocant');
eval { Svc->info };
like($@, qr/^Not an object at /, 'or the class name');
eval { bless([undef], 'Svc')->info };
like($@, qr/^Cannot delegate info to logger: logger is not set at /, 'an object array too short for the slot: not set');
{
    my $holed = bless [undef], 'Svc';
    $#$holed = 3;
    eval { $holed->info };
    like($@, qr/^Cannot delegate info to logger: logger is not set at /, 'an empty element in the slot: not set');
}

# --- lazy, trigger, frozen, readonly, private ------------------------------

package LazySvc;
our $built = 0;
sub _build_logger { $built++; Logger->new(name => 'lazy') }
sub _build_undef  { undef }
package main;
Object::Proto::define('LazySvc', 'logger:Object:lazy:builder(_build_logger):handles(info)',
    'maybe:Object:lazy:builder(_build_undef):handles(maybe_info=>info)',
    'bare:Object:lazy:handles(bare_info=>info)');
{
    my $lazy = LazySvc->new;
    is($LazySvc::built, 0, 'a lazy delegate is not built by new');
    is($lazy->info(1), 'info:1', 'it is built on the first delegated call');
    $lazy->info(2);
    is($LazySvc::built, 1, 'once');
    eval { $lazy->maybe_info };
    like($@, qr/^Cannot delegate maybe_info to maybe: maybe is not set at /, 'a lazy builder returning undef: not set');
    eval { $lazy->bare_info };
    like($@, qr/^Cannot delegate bare_info to bare: bare is not set at /, 'a lazy slot with nothing to build from: not set');
}

package Triggered;
our @fired;
sub on_logger { push @fired, $_[1] }
package main;
Object::Proto::define('Triggered', 'logger:Object:trigger(on_logger):handles(info)');
{
    my $t = Triggered->new(logger => Logger->new);
    @Triggered::fired = ();
    $t->info(1);
    is(scalar @Triggered::fired, 0, 'delegation does not fire the slot\'s trigger');
}

{
    my $frozen = Svc->new(logger => Logger->new);
    Object::Proto::freeze($frozen);
    is($frozen->info('f'), 'info:f', 'a frozen object still delegates');
}

Object::Proto::define('ReadonlySvc', 'logger:Object:readonly:handles(info)');
is(ReadonlySvc->new(logger => Logger->new)->info('r'), 'info:r', 'a readonly slot delegates');

Object::Proto::define('PrivateSvc', 'logger:Object:private:handles(info)');
{
    my $p = PrivateSvc->new(logger => Logger->new);
    is($p->info('p'), 'info:p', 'a private slot\'s delegator is public');
    eval { $p->logger };
    like($@, qr/^cannot call private attribute logger on PrivateSvc from main at /,
        'while its accessor stays private');
}

# --- the delegate is an Object::Proto object --------------------------------

Object::Proto::define('Inner', 'label:Str', 'count:Int');
Object::Proto::define('Outer', 'inner:Object:handles(inner_label=>label, count)');
{
    my $outer = Outer->new(inner => Inner->new(label => 'in', count => 1));
    is($outer->inner_label, 'in', 'delegating to an Object::Proto accessor gets');
    is($outer->inner_label('out'), 'out', 'and sets');
    is($outer->inner->label, 'out', 'on the delegate');
    eval { $outer->count('x') };
    like($@, qr/Type constraint failed for 'count'/, 'the delegate\'s type check applies');
}

# --- prototypes: the delegate is found through the prototype chain -----------

{
    my $proto_log = Logger->new(name => 'proto');
    my $proto = Svc->new(logger => $proto_log, name => 'proto');
    my $obj = Svc->new(name => 'obj');
    $obj->set_prototype($proto);
    @Logger::calls = ();
    is($obj->info('p'), 'info:p', 'a delegate found on the prototype');
    is($Logger::calls[0][0], 'proto', 'is the prototype\'s');

    my $top = Svc->new(logger => Logger->new(name => 'top'));
    my $middle = Svc->new;
    $middle->set_prototype($top);
    my $bottom = Svc->new;
    $bottom->set_prototype($middle);
    @Logger::calls = ();
    $bottom->info;
    is($Logger::calls[0][0], 'top', 'or further up the chain');

    my $own = Svc->new(logger => Logger->new(name => 'own'));
    $own->set_prototype($proto);
    @Logger::calls = ();
    $own->info;
    is($Logger::calls[0][0], 'own', 'the object\'s own delegate comes first');

    my $other = Svc->new(logger => Logger->new(name => 'other'));
    $obj->set_prototype($other);
    @Logger::calls = ();
    $obj->info;
    is($Logger::calls[0][0], 'other', 'a new prototype is used on the next call');

    my $orphan = Svc->new;
    $orphan->set_prototype(Svc->new);
    eval { $orphan->info };
    like($@, qr/^Cannot delegate info to logger: logger is not set at /, 'nobody on the chain has one: not set');

    # A prototype of another class holds whatever is at that slot's index
    Object::Proto::define('Stringy', 'text:Str');
    my $stray = Svc->new;
    $stray->set_prototype(Stringy->new(text => 'Just::A::String'));
    eval { $stray->info };
    like($@, qr/^Can't locate object method "info" via package "Just::A::String"/,
        'a prototype of another class supplying a string: perl\'s own error');

    my ($a, $b) = (Svc->new, Svc->new);
    $a->set_prototype($b);
    $b->set_prototype($a);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $a->info };
    like($@, qr/^Cannot delegate info to logger: logger is not set at /, 'a circular chain: not set');
    like($warnings[0], qr/^Circular prototype reference detected/, 'with the chain\'s warning');
}

{
    # The prototype's delegate wins over a lazy build, as the getter has it
    local $LazySvc::built = 0;
    my $proto = LazySvc->new(logger => Logger->new(name => 'from proto'));
    my $lazy = LazySvc->new;
    $lazy->set_prototype($proto);
    @Logger::calls = ();
    $lazy->info;
    is($Logger::calls[0][0], 'from proto', 'a lazy slot uses its prototype\'s delegate');
    is($LazySvc::built, 0, 'without building its own');
}

# --- names a delegator may not take (D7) -----------------------------------

my $n = 0;
sub define_error { my @specs = @_; eval { Object::Proto::define('Clash' . ++$n, @specs); 1 } ? '' : $@ }

for my $reserved (qw(new DESTROY isa can BUILD prototype)) {
    like(define_error("x:Object:handles($reserved)"),
        qr/^handles for slot 'x': method '$reserved' is reserved at /, "$reserved is reserved");
}
like(define_error('info:Str', 'logger:Object:handles(info)'),
    qr/^handles for slot 'logger': method 'info' is already provided by slot 'info' at /,
    'a slot\'s accessor');
like(define_error('logger:Object:handles(info)', 'info:Str'),
    qr/^handles for slot 'logger': method 'info' is already provided by slot 'info' at /,
    'whichever comes first');
like(define_error('logger:Object:handles(logger)'),
    qr/^handles for slot 'logger': method 'logger' is already provided by slot 'logger' at /,
    'the slot\'s own accessor');
for my $case (
    [ 'a:clearer',                     'clear_a'   ],
    [ 'a:predicate',                   'has_a'     ],
    [ 'a:clearer(wipe)',               'wipe'      ],
    [ 'a:predicate(got_a)',            'got_a'     ],
    [ 'a:reader(get_a)',               'get_a'     ],
    [ 'a:writer(put_a)',               'put_a'     ],
) {
    my ($slot, $method) = @$case;
    like(define_error($slot, "logger:Object:handles($method)"),
        qr/^handles for slot 'logger': method '$method' is already provided by slot 'a' at /,
        "the generated method $method");
}
like(define_error('a:Object:handles(info)', 'b:Object:handles(info)'),
    qr/^handles for slot 'b': method 'info' is already provided by slot 'a' at /, 'another delegator');

package Local;
sub info { 'mine' }
use constant LEVEL => 3;
our $warn = 'a variable, not a method';
package main;
eval { Object::Proto::define('Local', 'logger:Object:handles(info)') };
like($@, qr/^You cannot overwrite a locally defined method \(info\) with a delegation at /,
    'a sub of the class\'s own');
is(Local->info, 'mine', 'which is left alone');
eval { Object::Proto::define('Local', 'logger:Object:handles(LEVEL)') };
like($@, qr/^You cannot overwrite a locally defined method \(LEVEL\) with a delegation at /,
    'a constant of the class\'s');
Object::Proto::define('Local', 'logger:Object:handles(warn)');
is(Local->new(logger => Logger->new)->warn('w'), 'warn:w', 'a variable of the same name is no method');

eval { Object::Proto::define('Half', 'a:Object:handles(m1, m2)', 'b:Object:handles(m2)') };
like($@, qr/is already provided by slot 'a'/, 'a clash');
ok(!Half->can('m1'), 'croaks before any delegator is installed');

# --- define twice, and method modifiers ------------------------------------

Object::Proto::define('Twice', 'logger:Object:handles(info)', 'spare:Object');
my $first_cv = \&Twice::info;
{
    no warnings 'redefine';
    Object::Proto::define('Twice', 'logger:Object:handles(info)', 'spare:Object');
}
is(refaddr(\&Twice::info), refaddr($first_cv), 'defining a class twice keeps its delegator');
is(Twice->new(logger => Logger->new)->info(2), 'info:2', 'which still works');
{
    no warnings 'redefine';
    Object::Proto::define('Twice', 'logger:Object', 'spare:Object:handles(info)');
}
{
    my $t = Twice->new(logger => Logger->new(name => 'old'), spare => Logger->new(name => 'spare'));
    @Logger::calls = ();
    $t->info;
    is($Logger::calls[0][0], 'spare', 'a redefinition moving it to another slot moves the delegation');
}

Object::Proto::define('Shrink', 'a', 'b', 'logger:Object:handles(info)');
{
    no warnings 'redefine';
    Object::Proto::define('Shrink', 'logger:Object:handles(info)');
}
ok(Shrink->can('info'), 'a redefinition with fewer slots keeps the delegator');

Object::Proto::define('Wrapped', 'logger:Object:handles(info)');
my @order;
Object::Proto::before('Wrapped::info', sub { push @order, 'before' });
Object::Proto::after('Wrapped::info',  sub { push @order, 'after' });
Object::Proto::around('Wrapped::info', sub { my ($orig, @rest) = @_; push @order, 'around'; uc $rest[0]->$orig(@rest[1 .. $#rest]) });
{
    my $w = Wrapped->new(logger => Logger->new);
    is($w->info('x'), 'INFO:X', 'before, after and around wrap a delegator');
    is_deeply(\@order, [qw(before around after)], 'in order');
    {
        no warnings 'redefine';
        Object::Proto::define('Wrapped', 'logger:Object:handles(info)');
    }
    @order = ();
    is($w->info('y'), 'INFO:Y', 'a redefinition keeps the wrapped delegator');
    is_deeply(\@order, [qw(before around after)], 'and its modifiers');
}

Object::Proto::define('Ghostly', 'logger:Object');
Object::Proto::before('Ghostly::ghost', sub { });
eval {
    no warnings 'redefine';
    Object::Proto::define('Ghostly', 'logger:Object:handles(ghost)');
};
like($@, qr/^You cannot overwrite a locally defined method \(ghost\) with a delegation at /,
    'a modifier on a method there was not is a method of the class\'s');

package ModLocal;
sub info { 'local' }
package main;
Object::Proto::define('ModLocal', 'x');
Object::Proto::around('ModLocal::info', sub { my $orig = shift; $orig->(@_) });
eval {
    no warnings 'redefine';
    Object::Proto::define('ModLocal', 'x', 'logger:Object:handles(info)');
};
like($@, qr/^You cannot overwrite a locally defined method \(info\) with a delegation at /,
    'as is a modifier on a sub of the class\'s');

done_testing;
