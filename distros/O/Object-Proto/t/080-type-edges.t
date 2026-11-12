use strict;
use warnings;
use Test::More;
use Object::Proto;

# Behaviour shared by the built-in types added in 1.05. Each type has its
# own t/07*-type-*.t file; this one covers the paths they all go through.

my @NEW = qw(Ref ScalarRef RegexpRef GlobRef FileHandle ClassName
             PositiveInt NegativeInt NonEmptyStr Undef);

package TEdge;
BEGIN {
    Object::Proto::define('TEdge',
        'p:PositiveInt:writer(set_p)', 'n:NegativeInt', 'str:NonEmptyStr');
}
sub fset_p      { p($_[0], $_[1]) }
sub fget_p      { p($_[0]) }
sub p_good      { p($_[0], 5) }
sub p_bad       { p($_[0], -5) }
sub n_good      { n($_[0], -5) }
sub n_bad       { n($_[0], 5) }
sub s_good      { str($_[0], 'x') }
sub s_bad       { str($_[0], '') }

package main;
my $o = TEdge->new;

# ---- positional new()
Object::Proto::define('TEdge::Pos', 'r:Ref', 'p:PositiveInt', 'u:Undef');
my $pos = TEdge::Pos->new([], 1, undef);
is($pos->p, 1, 'positional new() accepts good values');
eval { TEdge::Pos->new([], 0, undef) };
like($@, qr/Type constraint failed for 'p' in new\(\): expected PositiveInt\b/, 'positional new() rejects a bad value');

# ---- writer
is($o->set_p(3), 3, 'a writer accepts a good value');
eval { $o->set_p(0) };
like($@, qr/Type constraint failed for 'p': expected PositiveInt\b/, 'a writer rejects a bad value');

# ---- function-style accessors
is(TEdge::fset_p($o, 4), 4, 'a function-style setter accepts a good value');
eval { TEdge::fset_p($o, 0) };
like($@, qr/Type constraint failed for 'p': expected PositiveInt\b/, 'a function-style setter rejects a bad value');
is(TEdge::fget_p($o), 4, 'and the slot keeps the good one');

# constants are checked when the call is compiled; a failing one still
# fails when the call runs
is(TEdge::p_good($o), 5, 'a constant PositiveInt is accepted');
eval { TEdge::p_bad($o) };
like($@, qr/expected PositiveInt\b/, 'a constant that is not a PositiveInt is rejected');
is(TEdge::n_good($o), -5, 'a constant NegativeInt is accepted');
eval { TEdge::n_bad($o) };
like($@, qr/expected NegativeInt\b/, 'a constant that is not a NegativeInt is rejected');
is(TEdge::s_good($o), 'x', 'a constant NonEmptyStr is accepted');
eval { TEdge::s_bad($o) };
like($@, qr/expected NonEmptyStr\b/, 'a constant empty string is rejected');

# ---- lazy builder
{
    package TEdge::Lazy;
    BEGIN {
        Object::Proto::define('TEdge::Lazy',
            'good:NonEmptyStr:lazy:builder(_good)', 'bad:NonEmptyStr:lazy:builder(_bad)');
    }
    sub _good { 'built' }
    sub _bad  { '' }
}
my $lazy = TEdge::Lazy->new;
is($lazy->good, 'built', 'a lazy builder result that passes is kept');
eval { $lazy->bad };
like($@, qr/Type constraint failed for (lazy )?'bad'( in builder)?: expected NonEmptyStr\b/,
     'a lazy builder result that fails is rejected');

# ---- coercion runs before the check
{
    package TEdge::Co;
    sub abs_int { my $v = shift; defined $v && $v =~ /^-\d+$/ ? -$v : $v }
    BEGIN { Object::Proto::define('TEdge::Co', 'n:PositiveInt:coerce(TEdge::Co::abs_int)') }
}
is(TEdge::Co->new(n => -3)->n, 3, 'a coercion can produce a PositiveInt');
eval { TEdge::Co->new(n => 0) };
like($@, qr/in new\(\): expected PositiveInt\b/, 'and the check applies to its result');

# ---- inheritance
Object::Proto::define('TEdge::Base', 'u:Undef', 'c:ClassName');
Object::Proto::define('TEdge::Child', extends => 'TEdge::Base', 'extra');
my $child = TEdge::Child->new;
eval { $child->u(1) };
like($@, qr/expected Undef\b/, 'a subclass keeps an inherited Undef constraint');
eval { $child->c('TEdge::Nowhere') };
like($@, qr/expected ClassName\b/, 'and an inherited ClassName constraint');
is($child->c('TEdge::Child'), 'TEdge::Child', 'an Object::Proto subclass is a ClassName');

# ---- PositiveInt and NegativeInt split Int: every Int is exactly one of
# positive, negative or zero, whatever Int makes of the value
{
    Object::Proto::define('TEdge::Ints', 'i:Int', 'p:PositiveInt', 'n:NegativeInt');
    my $ints = TEdge::Ints->new;
    my $passes = sub { my ($slot, $v) = @_; eval { $ints->$slot($v); 1 } ? 1 : 0 };
    no warnings 'numeric';
    for my $v (0, 1, -1, '0', '-0', '+5', ' 5', '5 ', '007', '-007', 3.0, 1.5,
               1e3, '1e3', ~0, -(~0 >> 1) - 1, '2147483648', '-2147483649', 'x', '') {
        my ($i, $p, $n) = map { $passes->($_, $v) } qw(i p n);
        my $zero = $i && $v == 0 ? 1 : 0;
        is($p + $n + $zero, $i, "'$v' is an Int iff exactly one of PositiveInt, NegativeInt or zero");
    }
}

# ---- introspection
my %listed;
$listed{$_}++ for @{ Object::Proto::list_types() };
is($listed{$_}, 1, "list_types lists $_ once") for @NEW;

# type names are exact: case matters, and names of the same length differ
for my $near (qw(ref REF Rex undef Undex scalarref ScalarRex RegexpRex GlobRex
                 filehandle FileHandlx classname ClassNamx PositiveIns
                 NegativeIns NonEmptyStx)) {
    ok(!Object::Proto::has_type($near), "'$near' is not a type");
}
Object::Proto::define('TEdge::Near', 'v:undef');
ok(!Object::Proto::slot_info('TEdge::Near', 'v')->{has_type}, "a slot typed 'undef' is untyped");

done_testing;
