#!perl

use strict;
use warnings;
use Test::More;
use Sub::Lib;


{
  my $lib = Sub::Lib->new;
  isa_ok($lib, 'Sub::Lib');

  my $_lib = $lib->();
  is(ref $_lib, 'HASH', 'internal library reference');
  ok(keys %$_lib == 0, 'internal library reference');
}

{
  my $lib = Sub::Lib->new({foo => sub {$_[0]}});
  ok( defined $lib->has('foo'), 'has installed sub');
  ok(!defined $lib->has('qux'), 'has missing sub');

  is($lib->('foo')->('qux'), 'qux', 'installed sub');
  is($lib->run('foo', 'qux'), 'qux', 'installed sub');
  is($lib->call('foo', $lib, 'qux'), $lib, 'installed sub');

  ok( defined $lib->void('foo')->('qux'), 'void sub');
  ok(!defined $lib->void('qux')->('qux'), 'void sub');

  {
    my $c = $lib->curry('foo', 'qux');
    is($c->(), 'qux', 'curry');
  }

  {
    my $o = $lib->o('foo', $lib, 'qux');
    is($o->(), $lib, 'o');
  }

  $lib->y('foo', sub {
    my ($sub, @args) = @_;
    is($sub->($_), $_, 'y')
      for @args;
  }, 'qux')->('qux');

  {
    my $winning = eval {$lib->('foo', sub {'bar:return'}); 1};
    ok(!defined $winning, 'sub already installed');
    like($@, qr/^sub-routine .* already .* library$/, 'sub already installed');
  }

  {
    my $winning = eval {$lib->('bar')->(); 1};
    ok(!defined $winning, 'sub not installed');
    like($@, qr/^sub-routine .* not .* library$/, 'sub already installed');
  }

  {
    my $winning = eval {$lib->y(qw(foo bar)); 1};
    ok(!defined $winning, 'lambda code reference');
    like($@, qr/^code reference .* lambda$/, 'lambda code reference');
  }
}

{
  my $winning = eval {Sub::Lib->new(qw(fail) x 1); 1};
  ok(!defined $winning, 'invalid single arg to new()');
  like($@, qr/^reference .* HASH$/, 'invalid single arg to new()');
}

{
  my $winning = eval {Sub::Lib->new(qw(fail) x 2); 1};
  ok(!defined $winning, 'invalid sub arg to new()');
  like($@, qr/^sub-routine .* sub-routine\?$/, 'invalid sub arg to new()');
}

{
  my $winning = eval {Sub::Lib->new(qw(fail) x 3); 1};
  ok(!defined $winning, 'odd arguments to new()');
  like($@, qr/^non-reference .* elements$/, 'odd arguments to new()');
}

done_testing();
