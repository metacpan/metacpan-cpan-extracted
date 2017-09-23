use Test::More;
use Patro ':test', ':paranoid';
use strict;
use warnings;

# what about HASH-type objects that overload '@{}'?
# ... that overload %{}?

diag "HASH-type reference";
my $r1 = Hashem->new;

ok($r1->{quux} == 42, 'hash deref 1');
ok($r1->[2] == 9, 'array deref 1');
$r1->[3] = 11;
ok($r1->[3] == 11, 'array deref and update');
ok(!defined($r1->{abc}), 'hash deref 2');
$r1->set_key("bar");
ok($r1->{abc} == 123, 'hash deref 3');
ok(!defined($r1->{quux}), 'hash deref 4');
$r1->{quux} = 19;
ok($r1->{quux} == 19, 'hash deref and update');
$r1->set_key("foo");
ok($r1->{quux} == 42, 'hash deref 5');

$r1 = Hashem->new;



diag "ARRAY-type reference";
my $r2 = Arrayed->new( { foo => 123, bar => 456 }, [7,8,9], 42 );
ok($r2->{foo} == 123, 'hash deref');
ok($r2->[0] == 7, 'array deref');
ok($$r2 == 42, 'scalar deref');
push @$r2, 14;
ok($r2->[3] == 14, 'push and array deref');
    
$r2 = Arrayed->new( { foo => 123, bar => 456 }, [7,8,9], 42 );




diag "REF-type reference";
my $r3 = Scalard->new( { foo => 123, bar => 456 }, [7,8,9], 42 );
ok($r3->{foo} == 123, 'hash deref');
ok($r3->[0] == 7, 'array deref');
ok($$r3 == 42, 'scalar deref');
push @$r3, 14;
ok($r3->[3] == 14, 'push and array deref');
    
$r3 = Scalard->new( { foo => 123, bar => 456 }, [7,8,9], 42 );



my ($p1,$p2,$p3) = getProxies(patronize($r1,$r2,$r3));
ok($p1, 'got proxy Hashem');

diag "HASH-type reference as proxy";
is(Patro::ref($p1), 'Hashem', 'proxy has correct ref');
is(Patro::reftype($p1),'HASH', 'proxy has correct reftype');
ok($p1->{quux} == 42, 'hash deref 1 over proxy');
ok($p1->[2] == 9, 'array deref 1 over proxy');
$p1->[3] = 11;
ok($p1->[3] == 11, 'array deref and update over proxy');
ok(!defined($p1->{abc}), 'hash deref 2 over proxy');
$p1->set_key("bar");
ok($p1->{abc} == 123, 'hash deref 3 over proxy');
ok(!defined($p1->{quux}), 'hash deref 4 over proxy');
$p1->{quux} = 19;
ok($p1->{quux} == 19, 'hash deref and update over proxy');
$p1->set_key("foo");
ok($p1->{quux} == 42, 'hash deref 5 over proxy');
ok($$p1 eq 'buzz', 'scalar deref over proxy');



diag "ARRAY-type reference as proxy";
is(Patro::ref($p2), 'Arrayed', 'proxy has correct ref');
is(Patro::reftype($p2),'ARRAY', 'proxy has correct reftype');
ok($p2->{foo} == 123, 'hash deref in proxy');
ok($p2->[0] == 7, 'array deref in proxy');
ok($$p2 == 42, 'scalar deref in proxy');
push @$p2, 14;
ok($p2->[3] == 14, 'push and array deref in proxy');



diag "REF-type reference as proxy";
is(Patro::ref($p3), 'Scalard', 'proxy has correct ref');
is(Patro::reftype($p3), 'REF', 'proxy has correct reftype');
ok($p3->{foo} == 123, 'hash deref in proxy');
ok($p3->[0] == 7, 'array deref in proxy');
ok($$p3 == 42, 'scalar deref in proxy');
push @$p3, 14;
ok($p3->[3] == 14, 'push and array deref in proxy');



done_testing;




package Hashem;
# a HASH-type object that overloads HASH and ARRAY derefence operators
use overload
    '%{}' => \&Hhash_deref,
    '@{}' => 'Harray_deref',
    '${}' => 'Hscalar_deref',
    bool => sub{1};
sub new {
    my $x = 'buzz';
    my $hash = { foo => { quux => 42 }, bar => { abc => 123, def => 456 },
		 baz => [7, 8, 9], fizz => \$x, __key__ => 'foo' };
    bless $hash, __PACKAGE__;
}
sub Hscalar_deref {
    my $self = shift;
    no overloading '%{}';
    my $ref = $self->{fizz};
    return $ref;
}
sub Harray_deref {
    my $self = shift;
    no overloading '%{}';
    my $ref = $self->{baz};
    return $ref;
}
sub Hhash_deref {
    my $self = shift;
    no overloading;
    my $key = $self->{__key__};
    my $ref = $self->{$key};
    return $ref;
}
sub set_key {
    my $self = shift;
    no overloading;
    $self->{__key__} = shift;
    return;
}


package Arrayed;
# an ARRAY-type object that overloads HASH, ARRAY, and SCALAR dereference ops
use overload
    '%{}' => 'Ahash_deref', 
    '@{}' => \&Aary_deref,
    '${}' => 'Ascalar_deref',
    bool => sub{1};
sub new {
    my ($pkg,$hash,$ary,$x) = @_;
    my $obj = [ $hash, $ary, \$x ];
    bless $obj, $pkg;
    return $obj;
}
sub Ahash_deref {
    no overloading;
    my $href = $_[0]->[0];
    $href;
}
sub Aary_deref  {
    my $self = shift;
    no overloading;
    my $ref = $self->[1];
    return $ref;
}
sub Ascalar_deref {
    no overloading;
    $_[0]->[2]
}


package Scalard;
use overload '%{}' => \&Shderef, '@{}' => \&Saderef, '${}' => \&Ssderef,
    bool => sub { 1 };
sub new {
    my ($pkg, $hash, $ary, $x) = @_;
    my $obj = { H => $hash, A => $ary, S => \$x };
    bless \$obj, $pkg;
}
sub Shderef {
    no overloading;
    return ${$_[0]}->{H};
}
sub Saderef {
    no overloading;
    return ${$_[0]}->{A};
}
sub Ssderef {
    no overloading;
    return ${$_[0]}->{S};
}
