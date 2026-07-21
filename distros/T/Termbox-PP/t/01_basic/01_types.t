use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Params::Check';
  require_ok 'Termbox::PP';
}

sub _check {
  my ($tmpl, $vals) = @_;
  my %tmpl = %{$tmpl};
  my %vals = %{$vals};

  local $Params::Check::SANITY_CHECK_TEMPLATE = 1;
  local $Params::Check::NO_DUPLICATES         = 1;
  local $Params::Check::ALLOW_UNKNOWN         = 0;

  return Params::Check::check({ v => \%tmpl }, \%vals) ? 1 : 0;
}

subtest 'numeric templates' => sub {
  plan tests => 10;

  is(_check(Termbox::_PositiveInt(), { v => 1 }), 1, '_PositiveInt accepts 1');
  is(_check(Termbox::_PositiveInt(), { v => 0 }), 0, '_PositiveInt rejects 0');

  is(_check(Termbox::_PositiveOrZeroInt(), { v => 0 }), 1, 
    '_PositiveOrZeroInt accepts 0');
  is(_check(Termbox::_PositiveOrZeroInt(), { v => -1 }), 0, 
    '_PositiveOrZeroInt rejects -1');

  is(_check(Termbox::_Int(), { v => -10 }), 1, '_Int accepts negative');
  is(_check(Termbox::_Int(), { v => 0 }),   1, '_Int accepts zero');
  is(_check(Termbox::_Int(), { v => 'x' }), 0, '_Int rejects non-numeric');

  is(_check(Termbox::_Bool(), { v => 0 }), 1, '_Bool accepts 0');
  is(_check(Termbox::_Bool(), { v => 1 }), 1, '_Bool accepts 1');
  is(_check(Termbox::_Bool(), { v => 2 }), 0, '_Bool rejects 2');
};

subtest 'string and class templates' => sub {
  plan tests => 4;

  is(_check(Termbox::_Str(), { v => 'abc' }), 1, 
    '_Str accepts non-empty string');
  is(_check(Termbox::_Str(), { v => '' }), 1, 
    '_Str accepts empty string');

  is(_check(Termbox::_ClassName(), { v => 'Termbox::Event' }), 1,
    '_ClassName accepts package-like name');
  is(_check(Termbox::_ClassName(), { v => 'Termbox-Event' }), 0,
    '_ClassName rejects invalid class name');
};

subtest 'reference and instance templates' => sub {
  plan tests => 14;

  my $x = 42;
  is(_check(Termbox::_Ref(), { v => \$x }), 1, '_Ref accepts scalar ref');
  is(_check(Termbox::_Ref(), { v => $x }),  0, '_Ref rejects non-ref');

  is(_check(Termbox::_ArrayRef(), { v => [] }), 1, 
    '_ArrayRef accepts array ref');
  is(_check(Termbox::_ArrayRef(), { v => {} }), 0, 
    '_ArrayRef rejects hash ref');

  my $s = 'abc';
  is(_check(Termbox::_ScalarRef(), { v => \undef }), 1,
    '_ScalarRef accepts \undef');
  is(_check(Termbox::_ScalarRef(), { v => \0 }), 1,
    '_ScalarRef accepts scalar int ref');
  is(_check(Termbox::_ScalarRef(), { v => \$s }), 1,
    '_ScalarRef accepts scalar string ref');
  is(_check(Termbox::_ScalarRef(), { v => undef }), 0,
    '_ScalarRef rejects undef');
  is(_check(Termbox::_ScalarRef(), { v => $s }), 0,
    '_ScalarRef rejects non-ref scalar');
  is(_check(Termbox::_ScalarRef(), { v => [] }), 0,
    '_ScalarRef rejects array ref');

  my $event = Termbox::Event->new();
  is(_check(Termbox::_Object(), { v => $event }), 1,
    '_Object accepts blessed object');
  is(_check(Termbox::_Object(), { v => [] }), 0,
    '_Object rejects unblessed ref');

  my $fn = sub {};
  is(_check(Termbox::_CodeRef(), { v => $fn }), 1, 
    '_CodeRef accepts code ref');
  is(_check(Termbox::_CodeRef(), { v => [] }), 0, 
    '_CodeRef rejects non-code ref');
};

done_testing;
