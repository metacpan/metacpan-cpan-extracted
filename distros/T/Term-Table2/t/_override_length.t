#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::Require::Module 'Unicode::GCString';
use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

skip_all('Unicode::GCString does not work properly if Perl is compiled with -DDEBUGGING') if $^D;

no warnings 'uninitialized';
my $mockUnicodeGCString = Test2::Mock->new(
  class => 'Unicode::GCString',
  override => [
    columns  => sub { return 10 },
    new      => sub { bless({}, 'Unicode::GCString') }
  ]
);

my $loadDieFlag;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    load     => sub (*;@) { die('DIED') if $loadDieFlag },
  ]
);

$loadDieFlag = FALSE;
_override_length();
is(length('x'), 10, 'Overridden "length"');

$loadDieFlag = TRUE;
_override_length();
is(length('x'),  1, 'Original "length"');

done_testing();