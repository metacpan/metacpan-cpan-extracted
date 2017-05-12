#!/usr/bin/env perl

use lib './lib';
use lib './t';

use Test::More tests => 6;
use Pony::Object qw/:try :noobject/;

eval { say "Hello 5.10" };
ok (!$@, "Just said \"Hello 5.10\"");
ok (!__PACKAGE__->can('new'), 'No new');
my $a = {a=>[{b=>[{c=>'d'}]}]};
ok (length(dump $a) > 0, 'Dumped');

try {
  die;
} catch {
  ok (1, 'Catched');
};

ok (!__PACKAGE__->can('ALL'), 'ALL are off');
ok (!__PACKAGE__->can('META'), 'no META');

diag( "Testing noobject for Pony::Object $Pony::Object::VERSION" );