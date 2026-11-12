use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use lib 't/lib';
use Object::Proto;

# handles(...) as a slot spec: parsed, resolved against the slot's type,
# checked at define time and shown by slot_info. The delegating methods
# themselves are tested in t/083 on.

my $n = 0;
sub fresh { 'HS' . ++$n }

# Define a throwaway class and return the slot_info of its first slot
sub handles_of {
    my ($spec) = @_;
    my $class = fresh();
    Object::Proto::define($class, $spec);
    (my $name = $spec) =~ s/:.*//s;
    return Object::Proto::slot_info($class, $name);
}

# The message a define of these specs croaks with
sub define_error {
    my (@specs) = @_;
    return eval { Object::Proto::define(fresh(), @specs); 1 } ? '' : $@;
}

# --- accepted forms ---------------------------------------------------------

is_deeply(handles_of('logger:Object:handles(info,warn,error)')->{handles},
    { info => 'info', warn => 'warn', error => 'error' }, 'same-name methods');
is_deeply(handles_of('logger:Object:handles(log_info=>info,log_error=>error)')->{handles},
    { log_info => 'info', log_error => 'error' }, 'renamed methods');
is_deeply(handles_of('logger:Object:handles( info , log_warn  =>  warn ,	debug )')->{handles},
    { info => 'info', log_warn => 'warn', debug => 'debug' }, 'white space around names and arrows');
is_deeply(handles_of('logger:handles(info):Object')->{handles},
    { info => 'info' }, 'handles before the type');
is_deeply(handles_of('logger:Object:handles(info):handles(warn=>log_warn)')->{handles},
    { info => 'info', warn => 'log_warn' }, 'two handles(...) in one spec add up');
is_deeply(handles_of('f:CodeRef:handles(format)')->{handles},
    { format => 'call' }, 'a CodeRef bare name calls the code');
is_deeply(handles_of('f:CodeRef:handles(fmt=>call,run=>method)')->{handles},
    { fmt => 'call', run => 'method' }, 'a CodeRef maps to call or method');
is_deeply(handles_of('tags:ArrayRef:handles(push_tag=>push,all_tags=>elements,tag_count=>count)')->{handles},
    { push_tag => 'push', all_tags => 'list', tag_count => 'count' }, 'ArrayRef ops, elements shown as list');
is_deeply(handles_of('tags:ArrayRef:handles(list,pop,shift,unshift,is_empty,get,set,clear)')->{handles},
    { map { $_ => $_ } qw(list pop shift unshift is_empty get set clear) }, 'every ArrayRef op');
is_deeply(handles_of('opts:HashRef:handles(get_opt=>get,set_opt=>set,has_opt=>exists)')->{handles},
    { get_opt => 'get', set_opt => 'set', has_opt => 'exists' }, 'HashRef ops');
is_deeply(handles_of('opts:HashRef:handles(defined,delete,keys,values,kv,count,is_empty,clear)')->{handles},
    { map { $_ => $_ } qw(defined delete keys values kv count is_empty clear) }, 'every HashRef op');

my $plain = handles_of('plain:Str');
is($plain->{has_handles}, 0, 'a slot without handles says so');
ok(!exists $plain->{handles}, 'and has no handles key');
ok(!exists $plain->{default_implicit}, 'nor an implicit default');
is(handles_of('logger:Object:handles(info)')->{has_handles}, 1, 'a slot with handles says so');

# --- parse errors -------------------------------------------------------------

for my $case (
    [ 'x:Object:handles()',         qr/^handles\(\) needs at least one method for slot 'x' at / ],
    [ 'x:Object:handles(  )',       qr/^handles\(\) needs at least one method for slot 'x' at / ],
    [ 'x:Object:handles(log-info)', qr/^Invalid method name 'log-info' in handles for slot 'x' at / ],
    [ 'x:Object:handles(9lives)',   qr/^Invalid method name '9lives' in handles for slot 'x' at / ],
    [ 'x:Object:handles(a,,b)',     qr/^Invalid method name '' in handles for slot 'x' at / ],
    [ 'x:Object:handles(a,)',       qr/^Invalid method name '' in handles for slot 'x' at / ],
    [ 'x:Object:handles(=>b)',      qr/^Invalid method name '' in handles for slot 'x' at / ],
    [ 'x:Object:handles(a=>)',      qr/^Invalid method name '' in handles for slot 'x' at / ],
    [ 'x:Object:handles(a=>b-c)',   qr/^Invalid method name 'b-c' in handles for slot 'x' at / ],
    [ 'x:Object:handles(a=>b=>c)',  qr/^Invalid method name 'b=>c' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:)',    qr/^Invalid role name '' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:9X)',  qr/^Invalid role name '9X' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:A:)',  qr/^Invalid role name 'A:' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:A:b)', qr/^Invalid role name 'A:b' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:A:bc)', qr/^Invalid role name 'A:bc' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:A:::B)', qr/^Invalid role name 'A:::B' in handles for slot 'x' at / ],
    [ 'x:Object:handles(role:A-B)', qr/^Invalid role name 'A-B' in handles for slot 'x' at / ],
    [ 'x:Object:handles(a,b,a)',    qr/^Method 'a' appears twice in handles for slot 'x' at / ],
    [ 'x:Object:handles(ab,role:R,cd,ab=>z)', qr/^Method 'ab' appears twice in handles for slot 'x' at / ],
    [ 'x:Object:handles(ab):handles(ab=>c)',  qr/^Method 'ab' appears twice in handles for slot 'x' at / ],
    [ 'x:Object:handles(a,b',       qr/^Unterminated '\(' in slot spec 'x:Object:handles\(a,b' at / ],
) {
    my ($spec, $error) = @$case;
    like(define_error($spec), $error, "'$spec' croaks");
}
is_deeply(handles_of('x:Object:handles(ab,cd,abc)')->{handles}, { ab => 'ab', cd => 'cd', abc => 'abc' },
    'names that share a length or a prefix are not duplicates');
is_deeply(handles_of('x:Object:handles(role:Handles::Storage,role:Handles::Storage)')->{handles},
    { fetch => 'fetch', store => 'store', describe => 'describe' }, 'a role named twice is one role');

# --- types (D1, D18) and weak (D14) ---------------------------------------

Object::Proto::register_type('Email', sub { 1 });
for my $type (qw(Any Defined Str Num Bool Ref ScalarRef RegexpRef GlobRef FileHandle ClassName
                 NonEmptyStr PositiveInt NegativeInt Int Undef Email)) {
    my $article = $type =~ /^[AEIOU]/ ? 'an' : 'a';
    like(define_error("x:$type:handles(m)"), qr/^handles is not supported on $article $type slot 'x' at /,
        "handles on a $type slot croaks");
}
like(define_error('x:handles(m)'), qr/^handles is not supported on an untyped slot 'x' at /,
    'handles on an untyped slot croaks');
for my $type (qw(CodeRef ArrayRef HashRef)) {
    like(define_error("x:$type:weak:handles(m)"), qr/^weak slot 'x' cannot have $type handles at /,
        "a weak $type slot cannot have handles");
}
is_deeply(handles_of('parent:Object:weak:handles(info)')->{handles}, { info => 'info' },
    'a weak Object slot can');

# --- ops (D15, D9) and readonly (D5) --------------------------------------

like(define_error('tags:ArrayRef:handles(frob)'),
    qr/^Unknown ArrayRef method 'frob' in handles for slot 'tags' \(valid: push, pop, shift, unshift, list, count, is_empty, get, set, clear\) at /,
    'an unknown ArrayRef method croaks and lists the valid ones');
like(define_error('opts:HashRef:handles(x=>frob)'),
    qr/^Unknown HashRef method 'frob' in handles for slot 'opts' \(valid: get, set, exists, defined, delete, keys, values, kv, count, is_empty, clear\) at /,
    'an unknown HashRef method croaks and lists the valid ones');
like(define_error('f:CodeRef:handles(run=>frob)'),
    qr/^CodeRef handles for slot 'f' must map to call or method, not 'frob' at /,
    'a CodeRef maps to call or method only');

is_deeply(handles_of('tags:ArrayRef:readonly:handles(list,count,is_empty,get,elements)')->{handles},
    { list => 'list', count => 'count', is_empty => 'is_empty', get => 'get', elements => 'list' },
    'a readonly ArrayRef slot may have the ops that only read');
is_deeply(handles_of('opts:HashRef:readonly:handles(get,exists,defined,keys,values,kv,count,is_empty)')->{handles},
    { map { $_ => $_ } qw(get exists defined keys values kv count is_empty) },
    'as may a readonly HashRef slot');
for my $op (qw(push pop shift unshift set clear)) {
    like(define_error("tags:ArrayRef:readonly:handles(m=>$op)"),
        qr/^Cannot delegate m=>$op on readonly slot 'tags' at /, "ArrayRef $op on a readonly slot croaks");
}
for my $op (qw(set delete clear)) {
    like(define_error("opts:HashRef:readonly:handles(m=>$op)"),
        qr/^Cannot delegate m=>$op on readonly slot 'opts' at /, "HashRef $op on a readonly slot croaks");
}
is_deeply(handles_of('logger:Object:readonly:handles(info)')->{handles}, { info => 'info' },
    'a readonly Object slot delegates');

# --- implicit defaults (D3) -------------------------------------------------

{
    my $tags = handles_of('tags:ArrayRef:handles(push)');
    is($tags->{has_default}, 1, 'an ArrayRef slot with handles gets a default');
    is_deeply($tags->{default}, [], 'of []');
    is($tags->{default_implicit}, 1, 'marked implicit');
    my $opts = handles_of('opts:HashRef:handles(get)');
    is_deeply($opts->{default}, {}, 'a HashRef slot gets {}');
    is($opts->{default_implicit}, 1, 'also implicit');
    is(handles_of('logger:Object:handles(info)')->{has_default}, 0, 'an Object slot gets none');
    is(handles_of('f:CodeRef:handles(run)')->{has_default}, 0, 'nor a CodeRef slot');
}

Object::Proto::define('Bag', 'tags:ArrayRef:handles(push)', 'opts:HashRef:handles(get)');
{
    my ($one, $two) = (Bag->new, Bag->new);
    is(ref $one->tags, 'ARRAY', 'an object gets an array from the implicit default');
    is(ref $one->opts, 'HASH', 'and a hash');
    isnt(refaddr($one->tags), refaddr($two->tags), 'each object its own array');
    isnt(refaddr($one->opts), refaddr($two->opts), 'and its own hash');
    push @{ $one->tags }, 'x';
    is_deeply(Bag->new->tags, [], 'a later object still starts empty');
    is_deeply(Bag->new(tags => [1, 2])->tags, [1, 2], 'a value given to new is kept');
}

# H1: an implicit default does not make new() read positional arguments as pairs
Object::Proto::define('PosImplicit', 'label', 'note', 'tags:ArrayRef:handles(push)');
Object::Proto::define('PosExplicit', 'label', 'note', 'tags:ArrayRef:default([])');
{
    my $implicit = PosImplicit->new('hello', 'world');
    is($implicit->label, 'hello', 'positional new still fills the first slot beside an implicit default');
    is($implicit->note, 'world', 'and the second');
    is_deeply($implicit->tags, [], 'and the default still applies');
    my $explicit = PosExplicit->new('hello', 'world');
    ok(!defined $explicit->label, 'unlike an explicit default, which makes new() read pairs (unchanged from 1.05)');
    is(PosImplicit->new(label => 'named')->label, 'named', 'named arguments still work');
}

# H2: required - no default is added, the value must be given
{
    my $req = handles_of('tags:ArrayRef:required:handles(push)');
    is($req->{has_default}, 0, 'a required slot gets no implicit default');
    ok(!exists $req->{default_implicit}, 'and is not marked');
    Object::Proto::define('ReqTags', 'tags:ArrayRef:required:handles(push)');
    eval { ReqTags->new };
    like($@, qr/Required slot 'tags' not provided/, 'so new() without it croaks');
    is_deeply(ReqTags->new(tags => [3])->tags, [3], 'and new() with it works');
}

# H3: a builder - no default is added, the builder runs
package BuildTags;
sub _build_tags { ['built'] }
sub _build_lazy { ['lazy built'] }
package BuildChild;
sub _build_tags { ['child built'] }
package main;
{
    is(handles_of('tags:ArrayRef:builder(_b):handles(push)')->{has_default}, 0,
        'a slot with a builder gets no implicit default');
    Object::Proto::define('BuildTags', 'tags:ArrayRef:builder(_build_tags):handles(push)',
        'lazy:ArrayRef:lazy:builder(_build_lazy):handles(push_lazy=>push)');
    my $b = BuildTags->new;
    is_deeply($b->tags, ['built'], 'so the builder\'s value is used');
    is_deeply($b->lazy, ['lazy built'], 'and a lazy builder runs on first use');
}

# A lazy slot with neither: its implicit default is built lazily
Object::Proto::define('LazyTags', 'tags:ArrayRef:lazy:handles(push)');
is_deeply(LazyTags->new->tags, [], 'a lazy slot without builder or default gets [] on first use');
is(Object::Proto::slot_info('LazyTags', 'tags')->{default_implicit}, 1, 'from an implicit default');

# An explicit default of the right kind is kept; of the wrong kind croaks
{
    my $kept = handles_of('tags:ArrayRef:default([]):handles(push)');
    is($kept->{has_default}, 1, 'an explicit [] default is kept');
    ok(!exists $kept->{default_implicit}, 'and not marked implicit');
    ok(!exists handles_of('opts:HashRef:default({}):handles(get)')->{default_implicit}, 'nor an explicit {}');
}
for my $case (
    [ 'tags:ArrayRef:default(5):handles(push)',     'ArrayRef', 'tags', '\[\]' ],
    [ 'tags:ArrayRef:default(undef):handles(push)', 'ArrayRef', 'tags', '\[\]' ],
    [ 'tags:ArrayRef:default():handles(push)',      'ArrayRef', 'tags', '\[\]' ],
    [ 'tags:ArrayRef:default({}):handles(push)',    'ArrayRef', 'tags', '\[\]' ],
    [ 'opts:HashRef:default([]):handles(get)',      'HashRef',  'opts', '\{\}' ],
) {
    my ($spec, $type, $slot, $want) = @$case;
    like(define_error($spec), qr/^The default of $type slot '$slot' must be $want for handles at /,
        "'$spec' croaks");
}

# --- inheritance and +attr (D17) --------------------------------------------

Object::Proto::define('HParent', 'logger:Object:handles(info)', 'tags:ArrayRef:handles(push)', 'plain:Object');
Object::Proto::define('HChild', extends => 'HParent');
is_deeply(Object::Proto::slot_info('HChild', 'logger')->{handles}, { info => 'info' },
    'a child inherits a slot\'s handles');
is(Object::Proto::slot_info('HChild', 'tags')->{default_implicit}, 1,
    'and works out its own implicit default');
isnt(refaddr(HChild->new->tags), refaddr(HChild->new->tags), 'which gives each child object its own array');

Object::Proto::define('HUnion', extends => 'HParent', '+logger:handles(warn)');
is_deeply(Object::Proto::slot_info('HUnion', 'logger')->{handles}, { info => 'info', warn => 'warn' },
    '+attr adds to the inherited handles');
Object::Proto::define('HReplace', extends => 'HParent', '+logger:handles(info=>log_info,debug)');
is_deeply(Object::Proto::slot_info('HReplace', 'logger')->{handles}, { info => 'log_info', debug => 'debug' },
    'and replaces one of the same name');
Object::Proto::define('HAdd', extends => 'HParent', '+plain:handles(run)');
is_deeply(Object::Proto::slot_info('HAdd', 'plain')->{handles}, { run => 'run' },
    '+attr can give an inherited slot handles it had none of');
is_deeply(Object::Proto::slot_info('HParent', 'logger')->{handles}, { info => 'info' },
    'the parent is unchanged');

Object::Proto::define('HBuilt', extends => 'HParent', '+tags:builder(_build_tags)');
{
    my $info = Object::Proto::slot_info('HBuilt', 'tags');
    is($info->{has_default}, 0, '+attr adding a builder drops the inherited implicit default');
    is_deeply($info->{handles}, { push => 'push' }, 'and keeps the handles');
}
package HBuilt;
sub _build_tags { ['from the child builder'] }
package main;
is_deeply(HBuilt->new->tags, ['from the child builder'], 'so the child\'s builder runs');

like(define_error(extends => 'HParent', '+tags:readonly'),
    qr/^Cannot delegate push=>push on readonly slot 'tags' at /, '+attr is checked again: readonly');
like(define_error(extends => 'HParent', '+tags:weak'),
    qr/^weak slot 'tags' cannot have ArrayRef handles at /, 'and weak');
like(define_error(extends => 'HParent', '+logger:Str'),
    qr/^handles is not supported on a Str slot 'logger' at /, 'and a changed type');

# A croak leaves the class as it was
Object::Proto::define('Intact', 'a', 'tags:ArrayRef:handles(push)');
eval { Object::Proto::define('Intact', 'a', 'tags:ArrayRef:handles(push)', 'b:Str:handles(x)') };
like($@, qr/not supported on a Str slot 'b'/, 'a redefinition with a bad slot croaks');
is_deeply(Intact->new(a => 1)->tags, [], 'and the class still builds objects');

# --- roles (D8) -------------------------------------------------------------

package OnlySubs;
use Scalar::Util qw(blessed);
use constant PROXY => 1;
use constant UPGRADED => 2;
our $VERSION = '1';
sub alpha { 1 }
sub beta  { 2 }
sub _private { 3 }
sub new { 4 }
sub DESTROY { }
sub LIMIT () { 5 }    # a constant defined in the role's own package
package main;
my $force = \&OnlySubs::UPGRADED;    # a constant taken by reference becomes a glob
# A constant made at run time stays a reference in the package, not a glob
# (made now rather than with use constant: Devel::Cover turns those into
# globs when it looks the packages over at compile time)
$OnlySubs::{LATE} = \6;

Object::Proto::role('OnlyRequires');
Object::Proto::requires('OnlyRequires', 'fetch', 'store');
Object::Proto::role('OnlySubs');
Object::Proto::role('OnlySlots', 'size:Int', 'label:reader(get_label):writer(set_label)',
    'cache:clearer:predicate', 'pool:clearer(drain):predicate(has_water)', 'secret:private');
Object::Proto::role('AllThree', 'level:Int');
Object::Proto::requires('AllThree', 'run');
package AllThree;
sub stop { 1 }
package main;
Object::Proto::role('Nothing');
Object::Proto::role('OnlyPrivate', 'hidden:private');

is_deeply(handles_of('s:Object:handles(role:OnlyRequires)')->{handles},
    { fetch => 'fetch', store => 'store' }, 'a role\'s required methods');
is_deeply(handles_of('s:Object:handles(role:OnlySubs)')->{handles},
    { alpha => 'alpha', beta => 'beta' },
    'a role\'s own subs: not imported ones, constants, _private ones, reserved names or variables');
is_deeply(handles_of('s:Object:handles(role:OnlySlots)')->{handles},
    { map { $_ => $_ } qw(size label get_label set_label cache clear_cache has_cache pool drain has_water) },
    'the methods of a role\'s slots, but not of its private ones');
is_deeply(handles_of('s:Object:handles(role:AllThree)')->{handles},
    { run => 'run', stop => 'stop', level => 'level' }, 'all three together');
is_deeply(handles_of('s:Object:handles(role:AllThree,role:OnlyRequires)')->{handles},
    { run => 'run', stop => 'stop', level => 'level', fetch => 'fetch', store => 'store' }, 'two roles');
is_deeply(handles_of('s:Object:handles(role:OnlyRequires,fetch=>get)')->{handles},
    { fetch => 'get', store => 'store' }, 'a method given explicitly wins over the role\'s');
is_deeply(handles_of('s:Object:handles(role:Handles::Storage)')->{handles},
    { fetch => 'fetch', store => 'store', describe => 'describe' }, 'a role not yet defined is loaded');

Object::Proto::define('HRoleParent', 's:Object:handles(role:OnlyRequires)');
Object::Proto::define('HRoleChild', extends => 'HRoleParent', '+s:handles(fetch=>get,extra)');
is_deeply(Object::Proto::slot_info('HRoleChild', 's')->{handles},
    { fetch => 'get', store => 'store', extra => 'extra' }, '+attr over an inherited role entry');

is_deeply(handles_of('s:Object:handles(role:OnlyRequires):handles(extra)')->{handles},
    { fetch => 'fetch', store => 'store', extra => 'extra' }, 'a second handles(...) after a role');
Object::Proto::define('HRoleOver', extends => 'HParent', '+logger:handles(role:OnlyRequires,info=>log_info)');
is_deeply(Object::Proto::slot_info('HRoleOver', 'logger')->{handles},
    { info => 'log_info', fetch => 'fetch', store => 'store' }, '+attr adding a role and replacing a name');

Object::Proto::role('Growing');
Object::Proto::requires('Growing', 'first');
Object::Proto::define('Snapshot', 's:Object:handles(role:Growing)');
Object::Proto::requires('Growing', 'second');
is_deeply(Object::Proto::slot_info('Snapshot', 's')->{handles}, { first => 'first' },
    'the role is read when the class is defined');

like(define_error('s:Object:handles(role:NotARole)'),
    qr/^Role 'NotARole' in handles for slot 's' is not defined at /, 'a module that is not a role croaks');
like(define_error('s:Object:handles(role:No::Such::Role)'),
    qr/^Can't locate No\/Such\/Role\.pm/, 'a role that cannot be loaded croaks as require does');
like(define_error('s:Object:handles(role:Nothing)'),
    qr/^Role 'Nothing' in handles for slot 's' has no methods at /, 'a role with no methods croaks');
like(define_error('s:Object:handles(role:OnlyPrivate)'),
    qr/^Role 'OnlyPrivate' in handles for slot 's' has no methods at /, 'as does one with only private slots');
like(define_error('f:CodeRef:handles(role:OnlyRequires)'),
    qr/^handles\(role:\.\.\.\) needs an Object slot, 'f' is CodeRef at /, 'a role on a CodeRef slot croaks');
like(define_error('t:ArrayRef:handles(push,role:OnlyRequires)'),
    qr/^handles\(role:\.\.\.\) needs an Object slot, 't' is ArrayRef at /, 'as on an ArrayRef slot');

# A role's own slot with handles: each class composing it resolves it
Object::Proto::role('Listy', 'items:ArrayRef:handles(add_item=>push)');
Object::Proto::define('ListA', 'a');
Object::Proto::with('ListA', 'Listy');
Object::Proto::define('ListB', 'b');
Object::Proto::with('ListB', 'Listy');
is_deeply(Object::Proto::slot_info('ListA', 'items')->{handles}, { add_item => 'push' },
    'a role slot\'s handles in one class');
is(Object::Proto::slot_info('ListB', 'items')->{default_implicit}, 1, 'and in another, with its implicit default');
isnt(refaddr(ListA->new->items), refaddr(ListB->new->items), 'each object its own array');

Object::Proto::role('BadSlot', 'bad:Str:handles(x)');
Object::Proto::define('Composer', 'c');
eval { Object::Proto::with('Composer', 'BadSlot') };
like($@, qr/^handles is not supported on a Str slot 'bad' at /, 'a role slot is checked when it is composed');
is_deeply([ Object::Proto::properties('Composer') ], ['c'], 'and a croak leaves the class without the slot');
is(Composer->new(c => 1)->c, 1, 'and still working');

done_testing;
