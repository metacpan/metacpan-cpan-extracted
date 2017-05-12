use warnings;
use strict;

use Test::More (1 ? (tests => 35) : ('no_plan'));

sub mydo {
  my ($file) = @_;
  do('./t/samples/' . $file);
  die "error $file -- $!" if($!);
  die if($@);
}

sub checks {
  my ($package) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  ok(eval("require $package"), "set \%INC ok ($package)");
  ok($package->can('thing'),   "can ok      ($package)");
  is($package->thing, 7,       "check       ($package)");
}

mydo('00-explicit');
checks('Foo');

mydo('00-findme');
checks('Bar');

mydo('00-findme.2');
checks('Baz');
checks('Baz::Bat');

mydo('00-findme.sneaky');
checks('Baz::Bar');
checks('Baz::Bop');
checks('Bop');

mydo('00-messy');
checks('Mess::1');
checks('Mess2');

mydo('00-subclass');
checks('Who::sYourDaddy');
checks('What::sInAName');
ok(What::sInAName->can('method'), 'can ok');
is(What::sInAName->method, 7, 'check');

# vi:syntax=perl:ts=2:sw=2:et:sta
