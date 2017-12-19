use strict;
use warnings;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

use Mojo::IOLoop;
use Mojo::IOLoop::Subprocess::Sereal;

# Huge result
my ($fail, $result);
my $subprocess = Mojo::IOLoop->$_subprocess(
  sub { shift->pid . $$ . ('x' x 100000) },
  sub {
    my ($subprocess, $err, $two) = @_;
    $fail = $err;
    $result .= $two;
  }
);
$result = $$;
Mojo::IOLoop->start;
ok !$fail, 'no error';
is $result, $$ . 0 . $subprocess->pid . ('x' x 100000), 'right result';

# Custom event loop
($fail, $result) = ();
my $loop = Mojo::IOLoop->new;
$loop->$_subprocess(
  sub {'♥'},
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);
$loop->start;
ok !$fail, 'no error';
is_deeply $result, ['♥'], 'right structure';

# Multiple return values
($fail, $result) = ();
$subprocess = Mojo::IOLoop->$_subprocess(
  sub { return '♥', [{two => 2}], 3 },
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);
Mojo::IOLoop->start;
ok !$fail, 'no error';
is_deeply $result, ['♥', [{two => 2}], 3], 'right structure';

# Event loop in subprocess
($fail, $result) = ();
$subprocess = Mojo::IOLoop->$_subprocess(
  sub {
    my $result;
    Mojo::IOLoop->next_tick(sub { $result = 23 });
    Mojo::IOLoop->start;
    return $result;
  },
  sub {
    my ($subprocess, $err, $twenty_three) = @_;
    $fail   = $err;
    $result = $twenty_three;
  }
);
Mojo::IOLoop->start;
ok !$fail, 'no error';
is $result, 23, 'right result';

# Concurrent subprocesses
($fail, $result) = ();
Mojo::IOLoop->delay(
  sub {
    my $delay = shift;
    Mojo::IOLoop->$_subprocess(sub {1}, $delay->begin);
    Mojo::IOLoop->$_subprocess->run(sub {2}, $delay->begin);
  },
  sub {
    my ($delay, $err1, $result1, $err2, $result2) = @_;
    $fail = $err1 || $err2;
    $result = [$result1, $result2];
  }
)->wait;
ok !$fail, 'no error';
is_deeply $result, [1, 2], 'right structure';

# No result
($fail, $result) = ();
Mojo::IOLoop->$_subprocess(
  sub {return},
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);
Mojo::IOLoop->start;
ok !$fail, 'no error';
is_deeply $result, [], 'right structure';

# Exception
$fail = undef;
Mojo::IOLoop->$_subprocess(
  sub { die 'Whatever' },
  sub {
    my ($subprocess, $err) = @_;
    $fail = $err;
  }
);
Mojo::IOLoop->start;
like $fail, qr/Whatever/, 'right error';

# Non-zero exit status
$fail = undef;
Mojo::IOLoop->$_subprocess(
  sub { exit 3 },
  sub {
    my ($subprocess, $err) = @_;
    $fail = $err;
  }
);
Mojo::IOLoop->start;
like $fail, qr/Sereal/, 'right error';

# Blessed result with FREEZE/THAW
{package Mojo::IOLoop::Subprocess::Sereal::TestFreeze;
  use Mojo::Base -base;
  has 'abc';
  sub FREEZE { $_[0]->abc }
  sub THAW { $_[0]->new(abc => $_[2]) }
}

($fail, $result) = (undef, undef);
Mojo::IOLoop->$_subprocess(
  sub { Mojo::IOLoop::Subprocess::Sereal::TestFreeze->new(abc => 'test') },
  sub {
    my ($subprocess, $err, $obj) = @_;
    $fail = $err;
    $result = $obj;
  }
);
Mojo::IOLoop->start;
ok !$fail, 'no error';
isa_ok $result, 'Mojo::IOLoop::Subprocess::Sereal::TestFreeze';
is $result->abc, 'test', 'right attribute value';

done_testing();
