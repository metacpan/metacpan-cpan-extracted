#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 10;

use Scope::Context;

my $fail_rx = qr/^Context has expired at \Q$0\E line [0-9]+/;

{
 my $sc;
 {
  $sc = Scope::Context->new;
  ok $sc->is_valid, 'freshly created context is valid';
  ok $sc->up->is_valid, 'up context is valid as well';
  {
   ok $sc->is_valid, 'also valid in a subblock';
  }
 }
 ok !$sc->is_valid, 'context has expired';

 my @methods = qw<
  up sub eval
  reap localize localize_elem localize_delete
  unwind yield
  uplevel
 >;
 for my $action (@methods) {
  local $@;
  eval {
   $sc->$action;
  };
  my $line = __LINE__-2;
  like $@, qr/^Context has expired at \Q$0\E line \Q$line\E/,
           "$action\->up croaks";
 }
}
