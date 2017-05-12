
use Test::More;

BEGIN { $ENV{'MOJO_REACTOR'} = 'Mojo::Reactor::Poll' }

plan skip_all => 'set TEST_HOBOPROCESS to enable this test (developer only)!'
  unless $ENV{'TEST_HOBOPROCESS'};

use Mojo::IOLoop;
use Mojo::IOLoop::HoboProcess;
use Time::HiRes qw(sleep);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Huge result
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

my ($fail, $result) = (undef, '');
my $subprocess = Mojo::IOLoop::HoboProcess->new;

$subprocess->run(
  sub { shift->pid .':'. ('x' x 100000) },
  sub {
    my ($subprocess, $err, $two) = @_;
    $fail = $err;
    $result .= $two;
  }
);

Mojo::IOLoop->start;

ok !$fail, 'huge result, no error';
is $result, $subprocess->pid .':'. ('x' x 100000), 'right result';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Custom event loop
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

my $loop = Mojo::IOLoop->new;

$loop->hoboprocess(
  sub {'♥'},
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);

$loop->start;

ok !$fail, 'custom event loop, no error';
is_deeply $result, ['♥'], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Multiple return values
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

$subprocess = Mojo::IOLoop::HoboProcess->new;
$subprocess->run(
  sub { return '♥', [{two => 2}], 3 },
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);

Mojo::IOLoop->start;

ok !$fail, 'multiple return values, no error';
is_deeply $result, ['♥', [{two => 2}], 3], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Event loop in subprocess
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

$subprocess = Mojo::IOLoop::HoboProcess->new;
$subprocess->run(
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

ok !$fail, 'event loop in subprocess, no error';
is $result, 23, 'right result';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Concurrent subprocesses
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

Mojo::IOLoop->delay(
  sub {
    my $delay = shift;
    Mojo::IOLoop->hoboprocess(sub {1}, $delay->begin);
    Mojo::IOLoop->hoboprocess(sub {2}, $delay->begin);
  },
  sub {
    my ($delay, $err1, $result1, $err2, $result2) = @_;
    $fail = $err1 || $err2;
    $result = [$result1, $result2];
  }
)->wait;

ok !$fail, 'concurrent subprocesses, no error';
is_deeply $result, [1, 2], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# No result
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

Mojo::IOLoop::HoboProcess->new->run(
  sub { return },
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);

Mojo::IOLoop->start;

ok !$fail, 'no result, no error';
is_deeply $result, [], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Stream inherited from previous hoboprocesses
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

my $delay = Mojo::IOLoop->delay;
my $me    = $$;

for (0 .. 1) {
  my $end        = $delay->begin;
  my $subprocess = Mojo::IOLoop::HoboProcess->new;

  $subprocess->run(
    sub { 1 + 1 },
    sub {
      my ($subprocess, $err, $two) = @_;
      $fail ||= $err;
      push @$result, $two;
      is $me, $$, 'we are the parent';
      $end->();
    }
  );
}

$delay->wait;

ok !$fail, 'inherited, no error';
is_deeply $result, [2, 2], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Exception
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

Mojo::IOLoop::HoboProcess->new->run(
  sub { die 'Something'; 'not reached' },
  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);

Mojo::IOLoop->start;

like $fail, qr/Something/, 'exception, right error';
is_deeply $result, [], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Non-zero exit status
# MCE::Hobo workers spawn as threads on the Windows platform.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

Mojo::IOLoop::HoboProcess->new->run(

# sub { $^O eq 'MSWin32' ? shift->exit(3) : exit(3) }, # not recommended
  sub { shift->exit(3); 'foo' }, # do this instead or call MCE::Hobo->exit(3)

  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);

Mojo::IOLoop->start;

like $fail, qr/Hobo .* exited abnormally/, 'subprocess exited (non-zero)';
is_deeply $result, [], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Zero exit status
# MCE::Hobo workers spawn as threads on the Windows platform.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

($fail, $result) = ();

Mojo::IOLoop::HoboProcess->new->run(

# sub { $^O eq 'MSWin32' ? shift->exit(0) : exit(0) }, # not recommended
  sub { shift->exit(0); 'baz' }, # do this instead or call MCE::Hobo->exit(0)

  sub {
    my ($subprocess, $err, @results) = @_;
    $fail   = $err;
    $result = \@results;
  }
);

Mojo::IOLoop->start;

ok !$fail, 'subprocess exited (zero), no error';
is_deeply $result, [], 'right structure';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Timeout
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

if ($^O ne 'MSWin32') {
  ($fail, $result) = ();

  $subprocess = Mojo::IOLoop::HoboProcess->new;
  $subprocess->timeout(2);

  $subprocess->run(
    sub { sleep(0.3) for 1 .. 12; 'foo baz' }, # sleep for 3.6 seconds
    sub {
      my ($subprocess, $err, @results) = @_;
      $fail   = $err;
      $result = \@results;
    }
  );

  Mojo::IOLoop->start;

  like $fail, qr/Hobo .* timed out/, 'subprocess timed out';
  is_deeply $result, [], 'right structure';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Done testing
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

done_testing();

