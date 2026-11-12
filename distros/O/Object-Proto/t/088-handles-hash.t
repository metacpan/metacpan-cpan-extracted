use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw(refaddr);
use Tie::Hash;
use Object::Proto;

# Native HashRef delegation: each op is checked against the perl builtin it
# mirrors, on a plain hash with the same contents, in list and scalar context.

package Opts;
our @fired;
sub on_opts { push @fired, [ $_[0], $_[1] ] }
package main;

Object::Proto::define('Opts',
    'opts:HashRef:clearer(drop_opts):trigger(on_opts):handles(get_opt=>get, set_opt=>set, has_opt=>exists,'
  . ' defined_opt=>defined, del_opt=>delete, opt_keys=>keys, opt_values=>values, opt_kv=>kv,'
  . ' opt_count=>count, no_opts=>is_empty, clear_opts=>clear)');

# [ what, starting contents, delegating method, arguments, the builtin ]
my @cases = (
    [ 'get one',              { a => 1 },         get_opt     => ['a'],          sub { $_[0]{ $_[1] } } ],
    [ 'get a missing key',    { a => 1 },         get_opt     => ['z'],          sub { $_[0]{ $_[1] } } ],
    [ 'get several',          { a => 1, b => 2 }, get_opt     => ['a', 'z', 'b'], sub { my $h = shift; @$h{@_} } ],
    [ 'set one',              {},                 set_opt     => [a => 1],        sub { $_[0]{ $_[1] } = $_[2] } ],
    [ 'set over a value',     { a => 1 },         set_opt     => [a => 2],        sub { $_[0]{ $_[1] } = $_[2] } ],
    [ 'set several',          { a => 1 },         set_opt     => [a => 2, b => 3], sub { my $h = shift; my @k = @_[ grep { !($_ % 2) } 0 .. $#_ ]; my @v = @_[ grep { $_ % 2 } 0 .. $#_ ]; @$h{@k} = @v } ],
    [ 'set one key twice',    {},                 set_opt     => [a => 1, a => 2], sub { my $h = shift; @$h{'a', 'a'} = (1, 2) } ],
    [ 'exists',               { a => undef },     has_opt     => ['a'],          sub { exists $_[0]{ $_[1] } } ],
    [ 'exists, missing',      {},                 has_opt     => ['a'],          sub { exists $_[0]{ $_[1] } } ],
    [ 'defined, undef value', { a => undef },     defined_opt => ['a'],          sub { defined $_[0]{ $_[1] } } ],
    [ 'defined',              { a => 0 },         defined_opt => ['a'],          sub { defined $_[0]{ $_[1] } } ],
    [ 'defined, missing',     {},                 defined_opt => ['a'],          sub { defined $_[0]{ $_[1] } } ],
    [ 'delete one',           { a => 1, b => 2 }, del_opt     => ['a'],          sub { delete $_[0]{ $_[1] } } ],
    [ 'delete a missing key', { a => 1 },         del_opt     => ['z'],          sub { delete $_[0]{ $_[1] } } ],
    [ 'delete several',       { a => 1, b => 2, c => 3 }, del_opt => ['a', 'z', 'c'], sub { my $h = shift; delete @$h{@_} } ],
    [ 'count',                { a => 1, b => 2 }, opt_count   => [],             sub { scalar keys %{ $_[0] } } ],
    [ 'count of none',        {},                 opt_count   => [],             sub { scalar keys %{ $_[0] } } ],
    [ 'is_empty, not',        { a => 1 },         no_opts     => [],             sub { !%{ $_[0] } } ],
    [ 'is_empty',             {},                 no_opts     => [],             sub { !%{ $_[0] } } ],
    [ 'clear',                { a => 1 },         clear_opts  => [],             sub { %{ $_[0] } = () } ],
    [ 'clear an empty hash',  {},                 clear_opts  => [],             sub { %{ $_[0] } = () } ],
);
for my $case (@cases) {
    my ($what, $start, $method, $args, $builtin) = @$case;
    for my $context (qw(list scalar)) {
        my $o = Opts->new(opts => { %$start });
        my %plain = %$start;
        my (@got, @want);
        if ($context eq 'list') {
            @got  = $o->$method(@$args);
            @want = $builtin->(\%plain, @$args);
        } else {
            $got[0]  = $o->$method(@$args);
            $want[0] = $builtin->(\%plain, @$args);
        }
        is_deeply(\@got, \@want, "$what, $context context: returns as the builtin does");
        is_deeply($o->opts, \%plain, "$what, $context context: leaves the hash as the builtin does");
    }
}

# keys, values and kv: the same pairs in some order, and their number in scalar context
{
    my %start = (a => 1, b => 2, c => 3);
    my $o = Opts->new(opts => { %start });
    is_deeply([ sort $o->opt_keys ], [ sort keys %start ], 'keys');
    is_deeply([ sort $o->opt_values ], [ sort values %start ], 'values');
    is_deeply({ map { @$_ } $o->opt_kv }, \%start, 'kv gives key, value pairs');
    is(scalar $o->opt_keys, 3, 'keys in scalar context');
    is(scalar $o->opt_values, 3, 'values in scalar context');
    is(scalar $o->opt_kv, 3, 'kv in scalar context');
    is_deeply([ Opts->new->opt_keys ], [], 'keys of an empty hash');
    my @keys = $o->opt_keys;
    my @pairs = $o->opt_kv;
    is_deeply([ map { $_->[0] } @pairs ], \@keys, 'kv in the order keys gives');
    $_++ for $o->opt_values;
    is_deeply($o->opts, { a => 2, b => 3, c => 4 }, 'values gives the hash\'s own values, as values does');
    my ($pair) = $o->opt_kv;
    $pair->[1] = 'changed';
    isnt($o->get_opt($pair->[0]), 'changed', 'kv gives copies');
}

# --- details ------------------------------------------------------------------

{
    my $o = Opts->new;
    my $v = 'original';
    $o->set_opt(k => $v);
    $v = 'changed';
    is($o->get_opt('k'), 'original', 'a stored value is a copy');
    is($o->del_opt('k'), 'original', 'delete gives the value');
    ok(!$o->has_opt('k'), 'and the key is gone');
    $o->set_opt('ключ' => 'значение', 42 => 'number');
    is($o->get_opt('ключ'), 'значение', 'a UTF-8 key');
    ok($o->has_opt('ключ'), 'exists with a UTF-8 key');
    is_deeply([ sort $o->opt_keys ], [ sort('ключ', 42) ], 'keys gives the UTF-8 key back');
    my %kv = map { @$_ } $o->opt_kv;
    is($kv{'ключ'}, 'значение', 'as does kv');
    is($o->get_opt(42), 'number', 'a number as a key');
    is($o->del_opt('ключ'), 'значение', 'delete with a UTF-8 key');
    $o->clear_opts;
    $o->set_opt(map { ("k$_" => $_) } 1 .. 1000);
    is(scalar(my @k = $o->opt_keys), 1000, 'keys of 1000 (the stack grows)');
    is(scalar(my @kv = $o->opt_kv), 1000, 'kv of 1000');
}

# A caller's each loop over the hash starts again after keys, as with keys itself
{
    my $o = Opts->new(opts => { a => 1, b => 2, c => 3 });
    my ($first) = each %{ $o->opts };
    $o->opt_keys;
    my ($again) = each %{ $o->opts };
    is($again, $first, 'keys in void context starts the hash\'s iterator afresh, as keys does');
    each %{ $o->opts };
    my $count = $o->opt_keys;
    ($again) = each %{ $o->opts };
    is($again, $first, 'as does keys in scalar context');
    each %{ $o->opts };
    my @all = $o->opt_values;
    ($again) = each %{ $o->opts };
    is($again, $first, 'and values in list context');
}

# --- arity (D12) ------------------------------------------------------------

{
    my $o = Opts->new(opts => { a => 1 });
    local @Opts::fired;
    for my $case (
        [ get_opt     => [],           'get takes at least 1' ],
        [ del_opt     => [],           'delete takes at least 1' ],
        [ has_opt     => [],           'exists takes 1' ],
        [ has_opt     => ['a', 'b'],   'exists takes 1' ],
        [ defined_opt => ['a', 'b'],   'defined takes 1' ],
        [ set_opt     => [],           'set takes key\/value pairs' ],
        [ set_opt     => ['a'],        'set takes key\/value pairs' ],
        [ set_opt     => ['a', 1, 'b'], 'set takes key\/value pairs' ],
        [ opt_count   => ['x'],        'count takes 0' ],
        [ clear_opts  => ['x'],        'clear takes 0' ],
    ) {
        my ($method, $args, $says) = @$case;
        eval { $o->$method(@$args) };
        like($@, qr/^Wrong number of arguments to $method \($says\) at /, "$method with " . @$args . " arguments croaks");
    }
    is_deeply($o->opts, { a => 1 }, 'a call that croaks changes nothing');
    is(scalar @Opts::fired, 0, 'and fires no trigger');
}

# --- not set, lazy (D3) ----------------------------------------------------

{
    my ($one, $two) = (Opts->new, Opts->new);
    $one->set_opt(a => 1);
    is_deeply($one->opts, { a => 1 }, 'with no default written, set works on a new object');
    is_deeply($two->opts, {}, 'each object has its own hash');
    $one->drop_opts;
    for my $method (qw(get_opt set_opt opt_keys)) {
        eval { $one->$method($method eq 'opt_keys' ? () : $method eq 'set_opt' ? (a => 1) : ('a')) };
        like($@, qr/^Cannot delegate $method to opts: opts is not set at /, "once the slot is cleared, $method croaks");
    }
}
Object::Proto::define('LazyOpts', 'opts:HashRef:lazy:handles(set_opt=>set, opt_count=>count)');
{
    my $l = LazyOpts->new;
    $l->set_opt(a => 1);
    is($l->opt_count, 1, 'a lazy slot with the implicit default');
}

# --- frozen (D4) and the trigger (D6) ---------------------------------------

{
    my $frozen = Opts->new(opts => { a => 1 });
    Object::Proto::freeze($frozen);
    for my $case ([ set_opt => ['b', 2] ], [ del_opt => ['a'] ], [ clear_opts => [] ]) {
        my ($method, $args) = @$case;
        eval { $frozen->$method(@$args) };
        like($@, qr/^Cannot modify frozen object at /, "a frozen object: $method croaks");
    }
    is_deeply($frozen->opts, { a => 1 }, 'and the hash is untouched');
    is($frozen->get_opt('a'), 1, 'reading works');
    is(scalar $frozen->opt_keys, 1, 'keys');
}
{
    my $o = Opts->new(opts => { a => 1 });
    for my $case ([ set_opt => ['b', 2] ], [ set_opt => [c => 3, d => 4] ], [ del_opt => ['a'] ], [ clear_opts => [] ]) {
        my ($method, $args) = @$case;
        @Opts::fired = ();
        $o->$method(@$args);
        is(scalar @Opts::fired, 1, "$method fires the trigger once");
        is(refaddr($Opts::fired[0][1]), refaddr($o->opts), 'with the hash');
    }
    @Opts::fired = ();
    $o->set_opt(a => 1);
    $o->$_('a') for qw(get_opt has_opt defined_opt);
    $o->$_ for qw(opt_keys opt_values opt_kv opt_count no_opts);
    is(scalar @Opts::fired, 1, 'the ops that read fire nothing');
}
package Churn;
sub on_opts { my @junk = map { "junk $_" x 10 } 1 .. 1000; return }
package main;
Object::Proto::define('Churn', 'opts:HashRef:trigger(on_opts):handles(del_opt=>delete)');
{
    my $c = Churn->new(opts => { a => 'kept', b => 'too' });
    is_deeply([ $c->del_opt('a', 'b') ], ['kept', 'too'], 'deleted values outlive a trigger that makes many temporaries');
}

# --- the container ------------------------------------------------------------

{
    my @log;
    package LoggedHash;
    our @ISA = ('Tie::StdHash');
    sub STORE  { push @log, 'STORE'; shift->SUPER::STORE(@_) }
    sub FETCH  { push @log, 'FETCH'; shift->SUPER::FETCH(@_) }
    sub DELETE { push @log, 'DELETE'; shift->SUPER::DELETE(@_) }
    package main;
    tie my %tied, 'LoggedHash';
    my $o = Opts->new(opts => \%tied);
    is($o->set_opt(a => 1), 1, 'a tied hash: set');
    ok((grep { $_ eq 'STORE' } @log), 'through the tie\'s STORE');
    $o->set_opt(b => 2, c => undef);
    is($o->get_opt('a'), 1, 'get');
    ok((grep { $_ eq 'FETCH' } @log), 'through FETCH');
    ok($o->has_opt('c'), 'exists');
    ok(!$o->defined_opt('c'), 'defined, through FETCH');
    ok($o->defined_opt('a'), 'defined of a defined value');
    is($o->opt_count, 3, 'count, through the tie');
    ok(!$o->no_opts, 'is_empty, through the tie');
    is_deeply([ sort $o->opt_keys ], [qw(a b c)], 'keys');
    is_deeply({ map { @$_ } $o->opt_kv }, { a => 1, b => 2, c => undef }, 'kv');
    is($o->del_opt('a'), 1, 'delete');
    ok((grep { $_ eq 'DELETE' } @log), 'through DELETE');
    $o->clear_opts;
    is_deeply(\%tied, {}, 'clear');
    ok($o->no_opts, 'is_empty of an empty tied hash');
}
{
    require Hash::Util;
    my %locked = (a => 1);
    Hash::Util::lock_ref_keys(\%locked);
    my $o = Opts->new(opts => \%locked);
    is($o->set_opt(a => 2), 2, 'a restricted hash: an allowed key can be set');
    eval { $o->set_opt(z => 1) };
    like($@, qr/^Attempt to access disallowed key 'z' in a restricted hash at /, 'a disallowed one croaks as perl does');
}
{
    Object::Proto::define('Stringy', 'text:Str');
    my $index = Object::Proto::slot_info('Opts', 'opts')->{index};
    my $stray = Opts->new;
    $stray->[$index] = undef;
    $stray->set_prototype(Stringy->new(text => 'not a hash'));
    eval { $stray->opt_count };
    like($@, qr/^Cannot delegate opt_count to opts: opts is not a HASH reference at /,
        'a string from a prototype of another class croaks');
    my $direct = Opts->new;
    $direct->[$index] = [ 'an array' ];
    eval { $direct->set_opt(a => 1) };
    like($@, qr/^Cannot delegate set_opt to opts: opts is not a HASH reference at /,
        'as does an array written into the object directly');
}
for my $method (qw(get_opt opt_keys)) {
    eval { Opts->can($method)->({}, 'a') };
    like($@, qr/^Not an object at /, "$method: an invocant that is not an object croaks");
}

# --- prototypes ----------------------------------------------------------------

{
    my $proto = Opts->new(opts => { from => 'proto' });
    my $obj = Opts->new;
    $obj->drop_opts;
    $obj->set_prototype($proto);
    is($obj->get_opt('from'), 'proto', 'an object without a hash of its own uses its prototype\'s');
    $obj->set_opt(added => 1);
    is($proto->get_opt('added'), 1, 'set changes the prototype\'s hash, as $obj->opts would');

    my $bottom = Opts->new;
    $bottom->drop_opts;
    my $middle = Opts->new;
    $middle->drop_opts;
    $middle->set_prototype($proto);
    $bottom->set_prototype($middle);
    is($bottom->opt_count, 2, 'further up the chain');

    my $own = Opts->new(opts => { own => 1 });
    $own->set_prototype($proto);
    is_deeply([ $own->opt_keys ], ['own'], 'an object\'s own hash comes first');
}

# --- inheritance, +attr, multiple inheritance, roles --------------------------

Object::Proto::define('OptsChild', extends => 'Opts', 'extra');
{
    my $child = OptsChild->new;
    $child->set_opt(a => 1);
    is($child->get_opt('a'), 1, 'a child sets and gets through an inherited slot');
    isnt(refaddr($child->opts), refaddr(OptsChild->new->opts), 'each child object has its own hash');
    my $from_parent = OptsChild->new;
    $from_parent->[ Object::Proto::slot_info('OptsChild', 'opts')->{index} ] = undef;
    $from_parent->set_prototype(Opts->new(opts => { p => 1 }));
    is($from_parent->get_opt('p'), 1, 'a child object, hash on a parent prototype');
}
Object::Proto::define('OptsPlus', extends => 'LazyOpts', '+opts:handles(opt_keys=>keys)');
{
    my $p = OptsPlus->new;
    $p->set_opt(k => 1);
    is_deeply([ $p->opt_keys ], ['k'], '+attr adds an op, keeping the inherited ones');
}
Object::Proto::define('HP1', 'x:Str');
Object::Proto::define('HP2', 'y:Str', 'map:HashRef:handles(put=>set, fetch=>get)');
Object::Proto::define('HashMI', extends => ['HP1', 'HP2']);
{
    my $mi = HashMI->new(x => 'x', y => 'y');
    $mi->put(k => 'v');
    is($mi->fetch('k'), 'v', 'a second parent\'s hash slot, at another index in the child');
    is($mi->y, 'y', 'leaving the neighbouring slot alone');
}
Object::Proto::role('Configured', 'config:HashRef:handles(conf=>get, set_conf=>set)');
Object::Proto::define('ConfiguredA', 'a');
Object::Proto::with('ConfiguredA', 'Configured');
{
    my $c = ConfiguredA->new;
    $c->set_conf(level => 3);
    is($c->conf('level'), 3, 'a role\'s HashRef slot delegates');
}

# --- a redefinition changes a delegator's kind ------------------------------

package Target;
sub go { 'a method' }
package main;
Object::Proto::define('Kinds', 'list:ArrayRef:handles(go=>count)', 'map:HashRef', 'obj:Object');
my $kinds_cv = \&Kinds::go;
is(Kinds->new(list => [1, 2])->go, 2, 'an array delegator');
{
    no warnings 'redefine';
    Object::Proto::define('Kinds', 'list:ArrayRef', 'map:HashRef:handles(go=>count)', 'obj:Object');
}
is(refaddr(\&Kinds::go), refaddr($kinds_cv), 'a redefinition keeps the delegator');
is(Kinds->new(map => { a => 1 })->go, 1, 'now a hash delegator');
{
    no warnings 'redefine';
    Object::Proto::define('Kinds', 'list:ArrayRef', 'map:HashRef', 'obj:Object:handles(go)');
}
is(Kinds->new(obj => bless({}, 'Target'))->go, 'a method', 'now a method delegator');
{
    no warnings 'redefine';
    Object::Proto::define('Kinds', 'list:ArrayRef:handles(go=>count)', 'map:HashRef', 'obj:Object');
}
is(Kinds->new(list => [1])->go, 1, 'and an array delegator again');

done_testing;
