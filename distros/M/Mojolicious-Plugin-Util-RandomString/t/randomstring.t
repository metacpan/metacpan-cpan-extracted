#!/usr/bin/env perl
use strict;
use warnings;
$|++;

BEGIN {
  our @INC;
  unshift(@INC, '../../lib', '../lib');
};

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

my $t = Test::Mojo->new;
my $app = $t->app;

$app->config('Util-RandomString' => {
  numericals => {
    alphabet => [2..9],
    length => 25
  }
});

$app->plugin('Util::RandomString' => {
  length => 15,
  base26 => {
    alphabet => '2345679bdfhmnprtFGHJLMNPRT',
    length   => 20
  },
  genetic => {
    alphabet => [qw/A C G T/],
    length => 35
  },
  alphabet => [1,0]
});

$app->plugin('Util::RandomString' => {
  entropy_test => {
    alphabet => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    entropy => 128
  }
});

my %TEST_RE = (
  default    => qr/^[01]+$/,
  genetic    => qr/^[ACGT]+$/,
  base26     => qr/^[2345679bdfhmnprtFGHJLMNPRT]+$/,
  numericals => qr/^[2-9]+$/,
  hexa       => qr/^[0-9a-f]+$/,
  full       => qr/^[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]+$/
);

my $r;
my $o = '';
my $fail = 0;
for (1..2) {
  foreach (0..20) {
    $r = $app->random_string;
    $fail++ if $r eq $o;
    $o = $r;
    ok($r, 'Random String is fine');
    like($r, $TEST_RE{default}, 'Random string has correct alphabet');
    is(length($r), 15, 'Random string has correct length');
  };

  foreach (0..20) {
    $r = $app->random_string('genetic');
    $fail++ if $r eq $o;
    $o = $r;
    ok($r, 'Genetic string is fine');
    like($r, $TEST_RE{genetic}, 'Genetic string has correct alphabet');
    is(length($r), 35, 'Genetic string has correct length');
  };

  foreach (0..20) {
    $r = $app->random_string('base26');
    $fail++ if $r eq $o;
    $o = $r;
    ok($r, 'base26 string is fine');
    like($r, $TEST_RE{base26}, 'Base26 string has correct alphabet');
    is(length($r), 20, 'Base26 string as correct length');
  };

  foreach (0..20) {
    $r = $app->random_string('numericals');
    $fail++ if $r eq $o;
    $o = $r;
    ok($r, 'Numerical string is fine');
    like($r, $TEST_RE{numericals}, 'Numerical string has correct alphabet');
    is(length($r), 25, 'Numerical string as correct length');
  };

  # This is rather unstable - but who cares?
  ok($fail < 2, 'Not much failing');

#  Mojo::IOLoop->stop;
};

$r = $app->random_string('numericals', length => 33);
ok($r, 'Numerical is fine');
is(length($r), 33, 'Numerical length is fine');
like($r, $TEST_RE{numericals}, 'Numerical string has correct alphabet');

$r = $app->random_string(alphabet => 'abc');
ok($r, 'Random String is fine');
like($r, qr/^[abc]+$/, 'Random string has correct alphabet');
is(length($r), 15, 'Random string has correct length');

$r = $app->random_string(default => alphabet => 'abc');
ok($r, 'Random String is fine');
like($r, qr/^[abc]+$/, 'Random string has correct alphabet');
is(length($r), 15, 'Random string has correct length');

$r = $app->random_string('genetic', length => 24);
ok($r, 'Genetic string is fine');
like($r, $TEST_RE{genetic}, 'Genetic string has correct alphabet');
is(length($r), 24, 'Genetic string has correct length');

$r = $app->random_string('base26', length => 101);
ok($r, 'base26 string is fine');
like($r, $TEST_RE{base26}, 'Base26 string has correct alphabet');
is(length($r), 101, 'Base26 string as correct length');

$r = $app->random_string('base50', length => 101);
ok(!$r, 'base50 string is not fine');
is(length($r), 0, 'Base50 string as correct length');

$r = $app->random_string('base50');
ok(!$r, 'base50 string is not fine');
is(length($r), 0, 'Base50 string as correct length');

$app->plugin('Util::RandomString' => {
  hexa => {
    alphabet => ['a'..'f', 0 .. 9],
    length   => 10
  }
});

$r = $app->random_string('numericals', length => 33);
ok($r, 'Numerical is fine');
is(length($r), 33, 'Numerical length is fine');
like($r, $TEST_RE{numericals}, 'Numerical string has correct alphabet');

$r = $app->random_string(alphabet => 'abc');
ok($r, 'Random String is fine');
like($r, qr/^[abc]+$/, 'Random string has correct alphabet');
is(length($r), 15, 'Random string has correct length');

$r = $app->random_string(default => alphabet => 'abc');
ok($r, 'Random String is fine');
like($r, qr/^[abc]+$/, 'Random string has correct alphabet');
is(length($r), 15, 'Random string has correct length');

$r = $app->random_string('genetic', length => 24);
ok($r, 'Genetic string is fine');
like($r, $TEST_RE{genetic}, 'Genetic string has correct alphabet');
is(length($r), 24, 'Genetic string has correct length');

$r = $app->random_string('base26', length => 101);
ok($r, 'base26 string is fine');
like($r, $TEST_RE{base26}, 'Base26 string has correct alphabet');
is(length($r), 101, 'Base26 string as correct length');

$r = $app->random_string('base50', length => 101);
ok(!$r, 'base50 string is not fine');
is(length($r), 0, 'Base50 string as correct length');

$r = $app->random_string('base50');
ok(!$r, 'base50 string is not fine');
is(length($r), 0, 'Base50 string as correct length');

foreach (0..20) {
  $r = $app->random_string('hexa');
  ok($r, 'Hexa string is fine');
  like($r, $TEST_RE{hexa}, 'Hexa string has correct alphabet');
  is(length($r), 10, 'Hexa string has correct length');
};

$app->helper(
  test_random_string => sub {
    my $c = shift;
    return $c->random_string('base26');
  }
);

ok($r = $app->test_random_string, 'Base26 can be generated');
like($r, $TEST_RE{base26}, 'Base26 string has correct alphabet');

ok($r = $app->test_random_string, 'Base26 can be repeatedly generated');
like($r, $TEST_RE{base26}, 'Base26 string has correct alphabet');

get '/path1' => sub {
  my $c = shift;
  $c->render(text => $c->random_string('base26'));
};

get '/path2' => sub {
  my $c = shift;
  $c->render(text => $c->test_random_string);
};

get '/path3' => sub {
  my $c = shift;
  $c->render(text => $c->random_string('entropy_test'));
};

$t->get_ok('/path1')->content_like($TEST_RE{base26});
$t->get_ok('/path1')->content_like($TEST_RE{base26});
$t->get_ok('/path2')->content_like($TEST_RE{base26});
$t->get_ok('/path2')->content_like($TEST_RE{base26});
$t->get_ok('/path3')->content_like($TEST_RE{full});
$t->get_ok('/path3')->content_like($TEST_RE{full});



done_testing;
