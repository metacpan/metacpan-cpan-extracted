#!perl -T

use strict;
use warnings;

use Test::More tests => 25 + 12;

use Scope::Upper qw<localize_elem UP HERE>;

# Arrays

our @a;

{
 local @a = (4 .. 6);
 {
  localize_elem '@main::a', 1, 8 => HERE;
  is_deeply \@a, [ 4, 8, 6 ], 'localize_elem "@a", 1, 8 => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_elem "@a", 1, 8 => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  localize_elem '@main::a', 4, 8 => HERE;
  is_deeply \@a, [ 4 .. 6, undef, 8 ], 'localize_elem "@a", 4, 8 => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_elem "@a", 4, 8 => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  localize_elem '@main::a', -2, 8 => HERE;
  is_deeply \@a, [ 4, 8, 6 ], 'localize_elem "@a", -2, 8 => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_elem "@a", -2, 8 => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  eval { localize_elem '@main::a', -4, 8 => HERE };
  like $@, qr/Modification of non-creatable array value attempted, subscript -4/, 'localize_elem "@a", -4, 8 => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_elem "@a", -4, 8 => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  local @a = (5 .. 7);
  {
   localize_elem '@main::a', 1, 12 => UP;
   is_deeply \@a, [ 5 .. 7 ], 'localize_elem "@a", 1, 12 => UP [not yet]';
  }
  is_deeply \@a, [ 5, 12, 7 ], 'localize_elem "@a", 1, 12 => UP [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_elem "@a", 1, 12 => UP [end]';
}

{
 local @a = (4 .. 6);
 {
  local @a = (5 .. 7);
  {
   localize_elem '@main::a', 4, 12 => UP;
   is_deeply \@a, [ 5 .. 7 ], 'localize_elem "@a", 4, 12 => UP [not yet]';
  }
  is_deeply \@a, [ 5 .. 7, undef, 12 ], 'localize_elem "@a", 4, 12 => UP [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize_elem "@a", 4, 12 => UP [end]';
}

{
 {
  localize_elem '@nonexistent', 2, 7;
  is_deeply eval('*nonexistent{ARRAY}'), [ undef, undef, 7 ],
                             'localize_elem "@nonexistent", 2, 7 => HERE [ok]';
 }
 is_deeply eval('*nonexistent{ARRAY}'), [ ],
                             'localize_elem "@nonexistent", 2, 7 => HERE [end]';
}

# Hashes

our %h;

{
 local %h = (a => 1, b => 2);
 {
  localize_elem '%main::h', 'a', 3 => HERE;
  is_deeply \%h, { a => 3, b => 2 }, 'localize_elem "%h", "a", 3 => HERE [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize_elem "%h", "a", 3 => HERE [end]';
}

{
 local %h = (a => 1, b => 2);
 {
  localize_elem '%main::h', 'c', 3 => HERE;
  is_deeply \%h, { a => 1, b => 2, c => 3 }, 'localize_elem "%h", "c", 3 => HERE [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize_elem "%h", "c", 3 => HERE [end]';
}

{
 local %h = (a => 1, b => 2);
 {
  local %h = (a => 3, c => 4);
  {
   localize_elem '%main::h', 'a', 5 => UP;
   is_deeply \%h, { a => 3, c => 4 }, 'localize_elem "%h", "a", 5 => UP [not yet]';
  }
  is_deeply \%h, { a => 5, c => 4 }, 'localize_elem "%h", "a", 5 => UP [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize_elem "%h", "a", 5 => UP [end]';
}

{
 {
  localize_elem '%nonexistent', 'a', 13;
  is_deeply eval('*nonexistent{HASH}'), { a => 13 },
                          'localize_elem "%nonexistent", "a", 13 => HERE [ok]';
 }
 is_deeply eval('*nonexistent{HASH}'), { },
                          'localize_elem "%nonexistent", "a", 13 => HERE [end]';
}

# Invalid

my $invalid_glob = qr/^Can't infer the element localization type from a glob and the value/;
my $invalid_type = qr/^Can't localize an element of something that isn't an array or a hash/;

{
 local *x;

 eval { localize_elem '$x', 0, 1 };
 like $@, $invalid_type, 'invalid localize_elem "$x", 0, 1';
}

{
 local *x;

 eval { localize_elem '&x', 0, sub { } };
 like $@, $invalid_type, 'invalid localize_elem "&x", 0, sub { }';
}

{
 local *x;

 eval { localize_elem '*x', 0, \1 };
 like $@, $invalid_type, 'invalid localize_elem "*x", 0, \1';
}

{
 local *x;

 eval { localize_elem *x, 0, \1 };
 like $@, $invalid_glob, 'invalid localize_elem *x, 0, \1';
}

{
 local *x;

 eval { localize_elem *x, 0, [ 1 ] };
 like $@, $invalid_glob, 'invalid localize_elem *x, 0, [ 1 ]';
}

{
 local *x;

 eval { localize_elem *x, 0, { a => 1 } };
 like $@, $invalid_glob, 'invalid localize_elem *x, 0, { a => 1 }';
}

{
 local *x;

 eval { localize_elem *x, 0, sub { } };
 like $@, $invalid_glob, 'invalid localize_elem *x, 0, sub { }';
}

{
 local *x;

 eval { localize_elem *x, 0, *x };
 like $@, $invalid_glob, 'invalid localize_elem *x, 0, *x';
}

sub invalid_ref { qr/^Invalid \Q$_[0]\E reference as the localization target/ }

{
 eval { localize_elem \1, 0, 0 => HERE };
 like $@, invalid_ref('SCALAR'), 'invalid localize_elem \1, 0, 0 => HERE';
}

{
 eval { localize_elem [ ], 0, 0 => HERE };
 like $@, invalid_ref('ARRAY'),  'invalid localize_elem [ ], 0, 0 => HERE';
}

{
 eval { localize_elem { }, 0, 0 => HERE };
 like $@, invalid_ref('HASH'),   'invalid localize_elem { }, 0, 0 => HERE';
}

{
 eval { localize_elem sub { }, 0, 0 => HERE };
 like $@, invalid_ref('CODE'),   'invalid localize_elem sub { }, 0, 0 => HERE';
}
