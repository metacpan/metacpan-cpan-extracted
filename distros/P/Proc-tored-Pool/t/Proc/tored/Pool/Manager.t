use Test2::Bundle::Extended;
use Path::Tiny;
use Proc::tored::Pool::Manager;

my $name = 'proc-tored-pool-test';
my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;

my $assignment;
my $success;
my $failure;
my $mgr = Proc::tored::Pool::Manager->new(
  name          => $name,
  dir           => "$dir",
  workers       => 5,
  on_assignment => sub { $assignment = [@_] },
  on_success    => sub { $success = [@_] },
  on_failure    => sub { $failure = [@_] },
);

sub reset_vars {
  undef $assignment;
  undef $success;
  undef $failure;
  $mgr->clear_flags;
  ok !$mgr->is_running, 'not running';
  is $mgr->pending, 0, 'no pending tasks';
};

subtest 'positive path' => sub {
  reset_vars();
  ok $mgr->assign(sub { 'foo' }, 'id-foo'), 'assign';
  $mgr->sync;
  is $assignment, [$mgr, 'id-foo'], 'assigned';
  is $success, [$mgr, 'id-foo', 'foo'], 'success';
  is $failure, undef, 'failure';
};

subtest 'wantarray' => sub {
  reset_vars();
  ok $mgr->assign(sub { ('foo', 'bar') }, 'id-foo'), 'assign';
  $mgr->sync;
  is $assignment, [$mgr, 'id-foo'], 'assigned';
  is $success, [$mgr, 'id-foo', 'foo', 'bar'], 'success';
  is $failure, undef, 'failure';
};

subtest 'failure' => sub {
  reset_vars();
  ok $mgr->assign(sub { die 'bar' }, 'id-foo'), 'assign';
  $mgr->sync;
  is $assignment, [$mgr, 'id-foo'], 'assigned';
  is $success, undef, 'success';
  like $failure, [$mgr, 'id-foo', qr/bar/], 'failure';
};

subtest 'no id' => sub {
  reset_vars();
  ok $mgr->assign(sub { 'foo' }), 'assign';
  $mgr->sync;
  is $assignment, [$mgr, undef], 'assigned';
  is $success, [$mgr, undef, 'foo'], 'success';
  is $failure, undef, 'failure';
  ok $mgr->assign(sub { die 'bar' }), 'assigned to die';
  $mgr->sync;
  like $failure, [$mgr, undef, qr/bar/], 'failure';
};

subtest 'service' => sub {
  reset_vars();
  my $i = 0;

  $mgr->service(sub {
    if (++$i == 10) {
      $mgr->stop;
    } elsif ($i == 20) {
      die 'backstop';
    }

    $mgr->assign(sub { ($i, $i * 2) }, $i);
    return $i;
  });

  ok !$mgr->is_running, '!is_running';
  ok $mgr->is_stopped, 'is_stopped';
  is $i, 10, 'expected work completed';
};

subtest 'fork/exec' => sub {
  reset_vars();

  $mgr->service(sub {
    $mgr->assign(sub { exec q{perl -e '1'} }, 'id_exec');
    return 0;
  });

  ok !$mgr->is_running, '!is_running';
  is $assignment, [$mgr, 'id_exec'], 'assigned';
  is $success, [$mgr, 'id_exec', '0 but true'], 'success';
  is $failure, undef, 'failure';
  ok $success->[2], 'result is true';
  ok $success->[2] == 0, 'result == 0';
};

done_testing;
