use Test::More 'no_plan';
use strict;
use warnings;

use lib 't/object-simple';

BEGIN {
  $SIG{__WARN__} = sub {
    my $message = shift;
    
    unless ($message =~ /DEPRECATED/ && $message =~ /Object::Simple/) {
      warn $message;
    }
  };
}

# -base flag
{
  {
    use Some::T2;
    my $o = Some::T2->new;
    is($o->x, 1);
    is($o->y, 2);
  }
  
  {
    use T3;
    my $o = T3->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
  
  {
    package T4;
    use Object::Simple -base => 'T3';
  }
  
  {
    my $o = T4->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }

  {
    package T4_2;
    use Object::Simple -base => 'T3_2';
  }
  
  {
    my $o = T4_2->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
  
  {
    package T4_3;
    use Object::Simple 'T3_2';
  }

  {
    my $o = T4_3->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
  
  {
    package T3_3;
    use T3 -base;
  }
  
  {
    my $o = T3_3->new;
    is($o->x, 1);
    is($o->y, 2);
    is($o->z, 3);
  }
}


# Test name
my $test;
sub test {$test = shift}

my $o;

test 'new()';
use T1;

$o = T1->new(m1 => 1, m2 => 2);
is_deeply($o, {m1 => 1, m2 => 2}, "$test : hash");
isa_ok($o, 'T1');

$o = T1->new({m1 => 1, m2 => 2});
is_deeply($o, {m1 => 1, m2 => 2}, "$test : hash ref");
isa_ok($o, 'T1');

$o = T1->new;
is_deeply($o, {}, "$test : no arguments");


test 'methods';
$o = T1->new;
can_ok($o, qw/attr class_attr dual_attr/);


test 'accessor';
$o = T1->new;
$o->m1(1);
is($o->m1, 1, "$test : attr : set and get");
T1->m2(2);
is(T1->m2, 2, "$test : class_attr : set and get");
$o->m3(3);
is($o->m3, 3, "$test : dual_attr : set and get object");
T1->m3(4);
is(T1->m3, 4, "$test : dual_attr : set and get class");


test 'accessor array';
$o = T1->new;
$o->m4_1(1);
is($o->m4_1, 1, "$test : attr : set and get 1");
$o->m4_2(1);
is($o->m4_2, 1, "$test : attr : set and get 2");
T1->m5_1(2);
is(T1->m5_1, 2, "$test : class_attr : set and get 1");
T1->m5_2(2);
is(T1->m5_2, 2, "$test : class_attr : set and get 2");
$o->m6_1(3);
is($o->m6_1, 3, "$test : dual_attr : set and get object 1");
T1->m6_1(4);
is(T1->m6_1, 4, "$test : dual_attr : set and get class 1");
$o->m6_2(3);
is($o->m6_2, 3, "$test : dual_attr : set and get object 2");
T1->m6_2(4);
is(T1->m6_2, 4, "$test : dual_attr : set and get class 2");


test 'constructor';
$o = T1->new(m1 => 1);
is($o->m1, 1, "$test : hash");

$o = T1->new({m1 => 2});
is($o->m1, 2, "$test : hash ref");


test 'default option';
$o = T1->new;

is(T1->m9, 9, "$test : class_attr");
is($o->m10, 10, "$test : dual_attr : object");
is(T1->m10, 10, "$test : dual_attr : class");

is($o->m11, 1, "$test : shortcut scalar");
is($o->m12, 9, "$test : shortcut code ref");

is(T1->m13, 'm13', "$test : shortcut scalar class_attr");
is(T1->m14, 'm14', "$test : shortcut code ref class_attr");

is(T1->m15, 'm15', "$test : shortcut scalar dual_attr from class");
is($o->m15, 'm15', "$test : shortcut scalar dual_attr from instance");

is(T1->m16, 'm16', "$test : shortcut code ref dual_attr from class");
is($o->m16, 'm16', "$test : shortcut code ref dual_attr from instance");


test 'array and default';
is($o->m18, 5, "$test : attr : first");
is($o->m19, 5, "$test : attr :second");

is(T1->m20, 6, "$test : class_attr : first");
is(T1->m21, 6, "$test : class_attr : second");

is($o->m22, 7, "$test : dual_attr : from instance : first");
is($o->m23, 7, "$test : dual_attr : from instance :second");
is(T1->m22, 7, "$test : dual_attr : from class : first");
is(T1->m23, 7, "$test : dual_attr : from class :second");


test 'inherit option hash_copy';
is_deeply(T1_2->m24, {a => 1}, "$test : subclass 1 : class");

$o = T1_2->new;
is_deeply($o->m24, {a => 1}, "$test : subclass 1 : object");

$o->m24->{b} = 1;
is_deeply(T1_2->m24, {a => 1}, "$test : subclass : no effect");

T1_2->m24->{c} = 1;
is_deeply(T1_3->m24, {a => 1, c => 1}, "$test :subclass 2 : class");

$o = T1_3->new;
is_deeply($o->m24, {a => 1, c => 1}, "$test :subclass 2 : object");


test 'inherit options array copy';
is_deeply(T1_2->m25, [1, 2], "$test : subclass 1 : class");

$o = T1_2->new;
is_deeply($o->m25, [1, 2], "$test : subclass 1 : object");

$o->m25->[2] = 3;
is_deeply(T1_2->m25, [1, 2], "$test : subclass : no effect");

T1_2->m25->[2] = 3;
is_deeply(T1_3->m25, [1, 2, 3], "$test :subclass 2 : class");

$o = T1_3->new;
is_deeply($o->m25, [1, 2, 3], "$test :subclass 2 : object");


test 'inherit options scalar copy';
is_deeply(T1_2->m26, 1, "$test : subclass 1 : class");

$o = T1_2->new;
is_deeply($o->m26, 1, "$test : subclass 1 : object");

$o->m26(3);
is_deeply(T1_2->m26, 1, "$test : subclass : no effect");

T1_2->m26(3);
is_deeply(T1_3->m26, 3, "$test :subclass 2 : class");

$o = T1_3->new;
is_deeply($o->m26, 3, "$test :subclass 2 : object");


test 'Error';

{
    package Some::T2;
    use base 'Object::Simple';

    eval{__PACKAGE__->attr(m1 => {})};
    Test::More::like($@, qr/Default has to be a code reference or constant value.*Some::T2::m1/,
         'default is not scalar or code ref');

    eval{__PACKAGE__->class_attr('m2', inherit => 'no')};
    Test::More::like($@, qr/\Q'inherit' opiton must be 'scalar_copy', 'array_copy', 'hash_copy', or code reference (Some::T2::m2)/,
                     'invalid inherit options');

    eval{__PACKAGE__->class_attr('m4', no => 1)};
    Test::More::like($@, qr/\Q'no' is invalid option/, "$test : invalid option : class_attr");

    eval{__PACKAGE__->dual_attr('m5', no => 1)};
    Test::More::like($@, qr/\Q'no' is invalid option/, "$test : invalid option : dual_attr");
}


test 'Method export';
{
    package T3;
    use Object::Simple qw/new attr class_attr dual_attr/;
    __PACKAGE__->attr('m1');
    __PACKAGE__->class_attr('m2');
    __PACKAGE__->dual_attr('m3');
}
$o = T3->new;
$o->m1(1);
T3->m2(2);
$o->m3(3);
is($o->m1, 1, "$test : export attr");
is(T3->m2, 2, "$test : export class_attr");
is($o->m3, 3, "$test : export dual_attr");


test 'Method export error';
{
    package T4;
    eval "use Object::Simple '-none';";
}
like($@, qr/'-none' is invalid option/, "$test");

test 'Inherit class_attr';
is_deeply(T1->m27, {a1 => 1}, "$test : no effect : hash");
is_deeply(T1_2->m27, {a1 => 1, a2 => 2}, "$test : inhert : hash");
is_deeply(T1->m28, [1], "$test : no effect : hash");
is_deeply(T1_2->m28, [1, 2], "$test : inherit : hash");
is(T1->m29, 5, "$test: inherit : sub ref default");


test 'Normal accessor';
$o = T1->new;
$o->m1(1);
is($o->m1, 1, "$test : set and get");
is($o->m1(1), $o, "$test : set return");

test 'Normal accessor with default';
$o = T1->new;
$o->m11(2);
is($o->m11, 2, "$test : set and get");
is($o->m11(2), $o, "$test : set return");
$o = T1->new;
is($o->m11, 1, "$test : default");
is($o->m12, 9, "$test : default sub reference");


test 'Normal accessor with inherit';
$o = T1->new;
$o->m24(1);
is($o->m24, 1, "$test : set and get");
is($o->m24(1), $o, "$test : set return");


test 'Class accessor';
T1->m2(1);
is(T1->m2, 1, "$test : set and get");
is(T1->m2(1), 'T1', "$test : set return");
eval {T1->m2(1, 2)};
like($@, qr/\QOne argument must be passed to "T1::m2()"/, "$test : One argument must be passed");
eval {T1->new->m2};
like($@, qr/T1::m2 must be called from class/, "$test : must be called from class");


test 'Class accessor with default';
T1->m13(2);
is(T1->m13, 2, "$test : set and get");
is(T1->m13(2), 'T1', "$test : set return");
eval {T1->m13(1, 2)};
like($@, qr/\QOne argument must be passed to "T1::m13()"/, "$test : One argument must be passed");
delete $T1::CLASS_ATTRS->{'m13'};
is(T1->m13, 'm13', "$test : default");
is(T1->m14, 'm14', "$test : default sub reference");
eval {T1->new->m13};
like($@, qr/T1::m13 must be called from class/, "$test : must be called from class");

test 'Class accessor with inherit';
T1->m24(1);
is(T1->m24, 1, "$test : set and get");
is(T1->m24(1), 'T1',  "$test : set return");
eval {T1->m24(1, 2)};
like($@, qr/\QOne argument must be passed to "T1::m24()"/, "$test : One argument must be passed");
eval{T1->new->m27};
like($@, qr/T1::m27 must be called from class/, "$test : must be called from class");

test 'new()';
$o = T1->new(m1 => 1);
isa_ok($o, 'T1');
is($o->m1, 1, "$test : from class : hash");

$o = T1->new({m1 => 1});
isa_ok($o, 'T1');
is($o->m1, 1, "$test : from class : hash ref");

$o = $o->new(m1 => 1);
isa_ok($o, 'T1');
is($o->m1, 1, "$test : from object : hash");

$o = $o->new({m1 => 1});
isa_ok($o, 'T1');
is($o->m1, 1, "$test : from object : hash ref");

test 'default';
$o = T1->new;
is($o->m31, 5, "$test : self : attr");
is(T1->m32, 5, "$test : self : class_attr");

test 'easy definition';
$o = T1->new;
ok($o->can('m33'), $test);
ok($o->can('m34'), $test);
is($o->m35, 1, $test);
is($o->m36, 5, $test);
is($o->m37, 1, $test);
is($o->m38, 5, $test);

test 'attr from object';
$o = T1->new;
$o->attr('from_object');
ok($o->can('from_object'), $test);


