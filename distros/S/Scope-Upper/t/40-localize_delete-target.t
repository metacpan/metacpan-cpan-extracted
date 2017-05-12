#!perl -T

use strict;
use warnings;

use Test::More tests => 53 + 4;

use Scope::Upper qw<localize_delete UP HERE>;

# Arrays

our @a;

{
 local @a = (4 .. 6);
 {
  localize_delete '@main::a', 1 => HERE;
  is_deeply \@a, [ 4, undef, 6 ], 'localize_delete "@a", 1 => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 1 => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  localize_delete '@main::a', 4 => HERE;
  is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 4 (nonexistent) => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 4 (nonexistent) => HERE [end]';
}

{
 local @a = (4 .. 6);
 local $a[4] = 7;
 {
  localize_delete '@main::a', 4 => HERE;
  is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 4 (exists) => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6, undef, 7 ], 'localize_delete "@a", 4 (exists) => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  localize_delete '@main::a', -2 => HERE;
  is_deeply \@a, [ 4, undef, 6 ], 'localize_delete "@a", -2 => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", -2 => HERE [end]';
}

{
 local @a = (4 .. 6);
 local $a[4] = 7;
 {
  localize_delete '@main::a', -1 => HERE;
  is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", -1 (exists) => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6, undef, 7 ], 'localize_delete "@a", -1 (exists) => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  eval { localize_delete '@main::a', -4 => HERE };
  like $@, qr/Modification of non-creatable array value attempted, subscript -4/, 'localize_delete "@a", -4 (out of bounds) => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", -4 (out of bounds) => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  local @a = (5 .. 7);
  {
   localize_delete '@main::a', 1 => UP;
   is_deeply \@a, [ 5 .. 7 ], 'localize_delete "@a", 1 => UP [not yet]';
  }
  is_deeply \@a, [ 5, undef, 7 ], 'localize_delete "@a", 1 => UP [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 1 => UP [end]';
}

{
 local @a = (4 .. 6);
 {
  local @a = (5 .. 7);
  {
   localize_delete '@main::a', 4 => UP;
   is_deeply \@a, [ 5 .. 7 ], 'localize_delete "@a", 4 (nonexistent) => UP [not yet]';
  }
  is_deeply \@a, [ 5 .. 7 ], 'localize_delete "@a", 4 (nonexistent) => UP [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 4 (nonexistent) => UP [end]';
}

{
 local @a = (4 .. 6);
 {
  local @a = (5 .. 7);
  local $a[4] = 8;
  {
   localize_delete '@main::a', 4 => UP;
   is_deeply \@a, [ 5 .. 7, undef, 8 ], 'localize_delete "@a", 4 (exists) => UP [not yet]';
  }
  is_deeply \@a, [ 5 .. 7 ], 'localize_delete "@a", 4 (exists) => UP [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_delete "@a", 4 (exists) => UP [end]';
}

{
 {
  localize_delete '@nonexistent', 2;
  is_deeply eval('*nonexistent{ARRAY}'), [ ],
                       'localize_delete "@nonexistent", anything => HERE [ok]';
 }
 is_deeply eval('*nonexistent{ARRAY}'), [ ],
                       'localize_delete "@nonexistent", anything => HERE [end]';
}

# Hashes

our %h;

{
 local %h = (a => 1, b => 2);
 {
  localize_delete '%main::h', 'a' => HERE;
  is_deeply \%h, { b => 2 }, 'localize_delete "%h", "a" => HERE [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize_delete "%h", "a" => HERE [end]';
}

{
 local %h = (a => 1, b => 2);
 {
  localize_delete '%main::h', 'c' => HERE;
  is_deeply \%h, { a => 1, b => 2 }, 'localize_delete "%h", "c" => HERE [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize_delete "%h", "c" => HERE [end]';
}

{
 local %h = (a => 1, b => 2);
 {
  local %h = (a => 3, c => 4);
  {
   localize_delete '%main::h', 'a' => UP;
   is_deeply \%h, { a => 3, c => 4 }, 'localize_delete "%h", "a" => UP [not yet]';
  }
  is_deeply \%h, { c => 4 }, 'localize_delete "%h", "a" => UP [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize_delete "%h", "a" => UP [end]';
}

{
 {
  localize_delete '%nonexistent', 'a';
  is_deeply eval('*nonexistent{HASH}'), { },
                       'localize_delete "%nonexistent", anything => HERE [ok]';
 }
 is_deeply eval('*nonexistent{HASH}'), { },
                       'localize_delete "%nonexistent", anything => HERE [end]';
}

# Scalars

our $x = 1;
{
 localize_delete '$x', 2 => HERE;
 is $x, undef, 'localize_delete "$x", anything => HERE [ok]';
}
is $x, 1, 'localize_delete "$x", anything => HERE [end]';

{
 {
  localize_delete '$nonexistent', 2;
  is eval('${*nonexistent{SCALAR}}'), undef,
                       'localize_delete "$nonexistent", anything => HERE [ok]';
 }
 is eval('${*nonexistent{SCALAR}}'), undef,
                       'localize_delete "$nonexistent", anything => HERE [end]';
}

# Code

sub x { 1 };
{
 localize_delete '&x', 2 => HERE;
 ok !exists(&x), 'localize_delete "&x", anything => HERE [ok]';
}
is x(), 1, 'localize_delete "&x", anything => HERE [end]';

{
 {
  localize_delete '&nonexistent', 2;
  is eval('exists &nonexistent'), !1,
                       'localize_delete "&nonexistent", anything => HERE [ok]';
 }
 is eval('exists &nonexistent'), !1,
                       'localize_delete "&nonexistent", anything => HERE [end]';
}

{
 localize_delete *x, sub { } => HERE;
 is !exists(&x),  1, 'localize_delete *x, anything => HERE [ok 1]';
 is !defined($x), 1, 'localize_delete *x, anything => HERE [ok 2]';
}
is x(), 1, 'localize_delete *x, anything => HERE [end 1]';
is $x,  1, 'localize_delete *x, anything => HERE [end 2]';

sub X::foo { 'X::foo' }

{
 {
  {
   localize_delete '&X::foo', undef => UP;
   is(X->foo(), 'X::foo', 'localize_delete "&X::foo", undef => UP [not yet X]');
  }
  ok(!X->can('foo'), 'localize_delete "&X::foo", undef => UP [ok X]');
 }
 is(X->foo(), 'X::foo', 'localize_delete "&X::foo", undef => UP [end X]');
}

@Y::ISA = 'X';

{
 {
  {
   localize_delete '&X::foo', undef => UP;
   is(Y->foo(), 'X::foo', 'localize_delete "&X::foo", undef => UP [not yet Y]');
  }
  ok(!Y->can('foo'), 'localize_delete "&X::foo", undef => UP [ok Y]');
 }
 is(Y->foo(), 'X::foo', 'localize_delete "&X::foo", undef => UP [end Y]');
}


{
 local *Y::foo = sub { 'Y::foo' };
 {
  {
   localize_delete '&Y::foo', undef => UP;
   is(Y->foo(), 'Y::foo', 'localize_delete "&Y::foo", undef => UP [not yet]');
  }
  is(Y->foo(), 'X::foo', 'localize_delete "&Y::foo", undef => UP [ok]');
 }
 is(Y->foo(), 'Y::foo', 'localize_delete "&Y::foo", undef => UP [end]');
}

{
 # Prevent 'only once' warnings
 local *Y::foo = *Y::foo;
}

# Invalid

sub invalid_ref { qr/^Invalid \Q$_[0]\E reference as the localization target/ }

{
 eval { localize_delete \1, 0 => HERE };
 like $@, invalid_ref('SCALAR'), 'invalid localize_delete \1, 0 => HERE';
}

{
 eval { localize_delete [ ], 0 => HERE };
 like $@, invalid_ref('ARRAY'),  'invalid localize_delete [ ], 0 => HERE';
}

{
 eval { localize_delete { }, 0 => HERE };
 like $@, invalid_ref('HASH'),   'invalid localize_delete { }, 0 => HERE';
}

{
 eval { localize_delete sub { }, 0 => HERE };
 like $@, invalid_ref('CODE'),   'invalid localize_delete sub { }, 0 => HERE';
}
