use strict;
use warnings;

use Test::More 'no_plan';

use vars '$pkg';

BEGIN {
  $pkg = 'Switch::Perlish::Smatch';
  use_ok( $pkg );
  $pkg->import(qw/ smatch value_cmp /);
}

can_ok(__PACKAGE__, $_)
  for @Switch::Perlish::Smatch::EXPORT_OK;

my $comp = sub {
  pass sprintf "called comparator for %s<=>%s", map ref, @_;
};

my $newobj = sub { bless {}, shift };
my @to_dispatch = (
  [ foo => bar   => $comp, ($newobj) x 2  ],
  [ foo => VALUE => $comp, $newobj, sub { 'stuff' } ],
  [ foo => ARRAY => $comp, $newobj, sub { [qw/ some values /] }, 1],
  [ ARRAY => ARRAY => $comp, (sub { [qw/this and that/] }) x 2 ],
);

for(@to_dispatch) {
  my($tt, $mt, $sub, $t, $m, $rev) = @$_;
  eval {
    local $SIG{__WARN__} = sub {
          $tt eq uc($tt)
      and $mt eq uc($mt)
      and like $_[0], qr/Overriding existing comparator/,
               "Got expected warning when overriding $tt<=>$mt";
    };
    Switch::Perlish::Smatch->register(
      topic   => $tt,
      match   => $mt,
      compare => $sub,
      reversible => $rev,
    );
  };
  ok !$@, "No errors registering $tt<=>$mt";

  ok(Switch::Perlish::Smatch->is_registered($tt),
     "Topic category $tt is registered");
  ok(Switch::Perlish::Smatch->is_registered($tt, $mt),
     "Comparator $tt<=>$mt is registered");

  Switch::Perlish::Smatch->dispatch($tt, $mt, &$t($tt), &$m($mt));
  Switch::Perlish::Smatch->dispatch($mt, $tt, &$m($mt), &$t($tt))
    if $rev;
}

{
  package Switch::Perlish::Smatch::_test;

  sub _VALUE {
    ::pass 'Called comparator registered by register_package()';
  }

  Switch::Perlish::Smatch->register_package( ( __PACKAGE__ ) x 2 );
}

my $test_obj = bless([], 'Switch::Perlish::Smatch::_test');
ok smatch($test_obj, 'value'), 'correctly smatch()ed test object with value';

my @vals = (
  [42    => 42],
  [4.2   => 4.2],
  ['abc' => 'abc'],
  ['123' => '123'],
  [123   => '123'],
  ['123' => 123],
  [3.14  => '3.14'],
  ['3.14'=> 3.14],
);

ok( value_cmp(@$_), "Compared $_->[0] with $_->[1] successfully" )
  for @vals
