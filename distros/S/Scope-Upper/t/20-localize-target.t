#!perl -T

use strict;
use warnings;

use Test::More tests => 70 + 4;

use Scope::Upper qw<localize UP HERE>;

# Scalars

our $x;

{
 local $x = 2;
 {
  localize *x, \1 => HERE;
  is $x, 1, 'localize *x, \1 => HERE [ok]';
 }
 is $x, 2, 'localize *x, \1 => HERE [end]';
}

sub _t { shift->{t} }

{
 local $x;
 {
  localize *x, \bless({ t => 1 }, 'main') => HERE;
  is ref($x), 'main', 'localize *x, obj => HERE [ref]';
  is $x->_t, 1, 'localize *x, obj => HERE [meth]';
 }
 is $x, undef, 'localize *x, obj => HERE [end]';
}

our $y;

{
 local $x = 1;
 local $y = 2;
 {
  local $y = 3;
  localize *x, 'y' => HERE;
  is $x, 3, "localize *x, 'y' => HERE [ok]";
 }
 is $x, 1, "localize *x, 'y' => HERE [end]";
}
undef *x;

{
 local $x = 7;
 {
  localize '$x', 2 => HERE;
  is $x, 2, 'localize "$x", 2 => HERE [ok]';
 }
 is $x, 7, 'localize "$x", 2 => HERE [end]';
}

{
 local $x = 8;
 {
  localize ' $x', 3 => HERE;
  is $x, 3, 'localize " $x", 3 => HERE [ok]';
 }
 is $x, 8, 'localize " $x", 3 => HERE [end]';
}

SKIP:
{
 skip 'Can\'t localize through a reference before 5.8.1' => 2
                                                            if "$]" < 5.008_001;
 eval q{
  no strict 'refs';
  local ${''} = 9;
  {
   localize '$', 4 => HERE;
   is ${''}, 4, 'localize "$", 4 => HERE [ok]';
  }
  is ${''}, 9, 'localize "$", 4 => HERE [end]';
 };
}

SKIP:
{
 skip 'Can\'t localize through a reference before 5.8.1' => 2
                                                            if "$]" < 5.008_001;
 eval q{
  no strict 'refs';
  local ${''} = 10;
  {
   localize '', 5 => HERE;
   is ${''}, 5, 'localize "", 4 => HERE [ok]';
  }
  is ${''}, 10, 'localize "", 4 => HERE [end]';
 };
}

{
 local $x = 2;
 {
  localize 'x', \1 => HERE;
  is $x, 1, 'localize "x", \1 => HERE [ok]';
 }
 is $x, 2, 'localize "x", \1 => HERE [end]';
}

{
 local $x = 4;
 {
  localize 'x', 3 => HERE;
  is $x, 3, 'localize "x", 3 => HERE [ok]';
 }
 is $x, 4, 'localize "x", 3 => HERE [end]';
}

{
 local $x;
 {
  localize 'x', bless({ t => 2 }, 'main') => HERE;
  is ref($x), 'main', 'localize "x", obj => HERE [ref]';
  is $x->_t, 2, 'localize "x", obj => HERE [meth]';
 }
 is $x, undef, 'localize "x", obj => HERE [end]';
}

sub callthrough (*$) {
 my ($what, $val) = @_;
 if (ref $what) {
  $what = $$what;
  $val  = eval "\\$val";
 }
 local $x = 'x';
 localize $what, $val => UP;
 is $x, 'x', 'localize callthrough [not yet]';
}

{
 package Scope::Upper::Test::Mock1;
 our $x;
 {
  main::callthrough(*x, 4);
  Test::More::is($x,       4,     'localize glob [ok - SUTM1]');
  Test::More::is($main::x, undef, 'localize glob [ok - main]');
 }
}

{
 package Scope::Upper::Test::Mock2;
 our $x;
 {
  main::callthrough(*main::x, 5);
  Test::More::is($x,       undef, 'localize qualified glob [ok - SUTM2]');
  Test::More::is($main::x, 5,     'localize qualified glob [ok - main]');
 }
}

{
 package Scope::Upper::Test::Mock3;
 our $x;
 {
  main::callthrough('$main::x', 6);
  Test::More::is($x,       undef, 'localize fully qualified name [ok - SUTM3]');
  Test::More::is($main::x, 6,     'localize fully qualified name [ok - main]');
 }
}

{
 package Scope::Upper::Test::Mock4;
 our $x;
 {
  main::callthrough('$x', 7);
  Test::More::is($x,       7,     'localize unqualified name [ok - SUTM4]');
  Test::More::is($main::x, undef, 'localize unqualified name [ok - main]');
 }
}

$_ = 'foo';
{
 package Scope::Upper::Test::Mock5;
 {
  main::callthrough('$_', 'bar');
  Test::More::ok(/bar/, 'localize $_ [ok]');
 }
}
undef $_;

# Arrays

our @a;
my $xa = [ 7 .. 9 ];

{
 local @a = (4 .. 6);
 {
  localize *a, $xa => HERE;
  is_deeply \@a, $xa, 'localize *a, [ ] => HERE [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize *a, [ ] => HERE [end]';
}

{
 local @a = (4 .. 6);
 {
  local @a = (5 .. 7);
  {
   localize *a, $xa => UP;
   is_deeply \@a, [ 5 .. 7 ], 'localize *a, [ ] => UP [not yet]';
  }
  is_deeply \@a, $xa, 'localize *a, [ ] => UP [ok]';
 }
 is_deeply \@a, [ 4 .. 6 ], 'localize *a, [ ] => UP [end]';
}

# Hashes

our %h;
my $xh = { a => 5, c => 7 };

{
 local %h = (a => 1, b => 2);
 {
  localize *h, $xh => HERE;
  is_deeply \%h, $xh, 'localize *h, { } => HERE [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize *h, { } => HERE [end]';
}

{
 local %h = (a => 1, b => 2);
 {
  local %h = (b => 3, c => 4);
  {
   localize *h, $xh => UP;
   is_deeply \%h, { b => 3, c => 4 }, 'localize *h, { } => UP [not yet]';
  }
  is_deeply \%h, $xh, 'localize *h, { } => UP [ok]';
 }
 is_deeply \%h, { a => 1, b => 2 }, 'localize *h, { } => UP [end]';
}

# Code

{
 local *foo = sub { 7 };
 {
  localize *foo, sub { 6 } => UP;
  is foo(), 7, 'localize *foo, sub { 6 } => UP [not yet]';
 }
 is foo(), 6, 'localize *foo, sub { 6 } => UP [ok]';
}

{
 local *foo = sub { 9 };
 {
  localize '&foo', sub { 8 } => UP;
  is foo(), 9, 'localize "&foo", sub { 8 } => UP [not yet]';
 }
 is foo(), 8, 'localize "&foo", sub { 8 } => UP [ok]';
}

{
 local *foo = sub { 'a' };
 {
  {
   localize *foo, sub { 'b' } => UP;
   is foo(), 'a', 'localize *foo, sub { "b" } => UP [not yet 1]';
   {
    no warnings 'redefine';
    local *foo = sub { 'c' };
    is foo(), 'c', 'localize *foo, sub { "b" } => UP [localized 1]';
   }
   is foo(), 'a', 'localize *foo, sub { "b" } => UP [not yet 2]';
  }
  is foo(), 'b', 'localize *foo, sub { "b" } => UP [ok 1]';
  {
   no warnings 'redefine';
   local *foo = sub { 'd' };
   is foo(), 'd', 'localize *foo, sub { "b" } => UP [localized 2]';
  }
  is foo(), 'b', 'localize *foo, sub { "b" } => UP [ok 2]';
 }
 is foo(), 'a', 'localize *foo, sub { "b" } => UP [end]';
}

{
 local *foo = sub { 'x' };
 {
  {
   localize *foo, sub { 'y' } => UP;
   is foo(), 'x', 'localize *foo, sub { "y" } => UP [not yet]';
  }
  is foo(), 'y', 'localize *foo, sub { "y" } => UP [ok]';
  no warnings 'redefine';
  *foo = sub { 'z' };
  is foo(), 'z', 'localize *foo, sub { "y" } => UP [replaced]';
 }
 is foo(), 'x', 'localize *foo, sub { "y" } => UP [end]';
}

sub X::foo { 'X::foo' }

{
 {
  {
   localize 'X::foo', sub { 'X::foo 2' } => UP;
   is(X->foo, 'X::foo', 'localize "X::foo", sub { "X::foo 2" } => UP [not yet]')
  }
  is(X->foo, 'X::foo 2', 'localize "X::foo", sub { "X::foo 2" } => UP [ok]');
 }
 is(X->foo, 'X::foo', 'localize "X::foo", sub { "X::foo 2" } => UP [end]');
}

@Y::ISA = 'X';

{
 {
  {
   localize 'X::foo', sub { 'X::foo 3' } => UP;
   is(Y->foo, 'X::foo', 'localize "X::foo", sub { "X::foo 3" } => UP [not yet]')
  }
  is(Y->foo, 'X::foo 3', 'localize "X::foo", sub { "X::foo 3" } => UP [ok]');
 }
 is(Y->foo, 'X::foo', 'localize "X::foo", sub { "X::foo 2" } => UP [end]');
}

{
 {
  {
   localize 'Y::foo', sub { 'Y::foo' } => UP;
   is(Y->foo, 'X::foo', 'localize "Y::foo", sub { "Y::foo" } => UP [not yet]');
  }
  is(Y->foo, 'Y::foo', 'localize "Y::foo", sub { "Y::foo" } => UP [ok]');
 }
 is(Y->foo, 'X::foo', 'localize "Y::foo", sub { "Y::foo" } => UP [end]');
}

# Invalid

sub invalid_ref { qr/^Invalid \Q$_[0]\E reference as the localization target/ }

{
 eval { localize \1, 0 => HERE };
 like $@, invalid_ref('SCALAR'), 'invalid localize \1, 0 => HERE';
}

{
 eval { localize [ ], 0 => HERE };
 like $@, invalid_ref('ARRAY'),  'invalid localize [ ], 0 => HERE';
}

{
 eval { localize { }, 0 => HERE };
 like $@, invalid_ref('HASH'),   'invalid localize { }, 0 => HERE';
}

{
 eval { localize sub { }, 0 => HERE };
 like $@, invalid_ref('CODE'),   'invalid localize sub { }, 0 => HERE';
}
