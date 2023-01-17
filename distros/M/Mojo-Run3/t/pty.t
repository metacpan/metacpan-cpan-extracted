use Mojo::Base -strict;
use Mojo::Run3;
use Test::More;

my ($bash) = grep { -x "$_/bash" } split /:/, $ENV{PATH} || '';
plan skip_all => 'bash was not found' unless $bash;

subtest 'stdin=pty, stdout=pipe, stderr=pipe' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  my ($sent, %read);
  $run3->on(pty    => sub { $read{pty}    .= $_[1] });
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->write("echo cool beans && exit\n");
  guard($run3->run_p(sub { exec qw(bash -i) }));
  ok $run3->pid > 0, 'pid';
  is $read{pty}, "echo cool beans && exit\r\n", 'stdout' or diag $read{stderr};
  like $read{stdout}, qr{cool beans\n$}s, 'stdout' or diag $read{stderr};
};

subtest 'stdin=pipe, stdout=pipe, stderr=pty' => sub {
  my $run3 = Mojo::Run3->new(driver => {stdin => 'pipe', stdout => 'pipe', stderr => 'pty'});
  my ($sent, %read);
  $run3->on(pty    => sub { $read{pty}    .= $_[1] });
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->write("cool beans\n", "stdin", sub { shift->close('stdin') });
  guard($run3->run_p(sub { exec qw(cat -) }));
  ok $run3->pid > 0, 'pid';
  is $read{pty},    undef,          'pty';
  is $read{stderr}, undef,          'stderr';
  is $read{stdout}, "cool beans\n", 'stdout';
};

subtest 'stdin=pipe, stdout=pty, stderr=pipe' => sub {
  my $run3 = Mojo::Run3->new(driver => {stdin => 'pipe', stdout => 'pty', stderr => 'pipe'});
  my ($sent, %read);
  $run3->on(pty    => sub { $read{pty}    .= $_[1] });
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->write("cool beans\n", "stdin", sub { shift->close('stdin') });
  guard($run3->run_p(sub { exec qw(cat -) }));
  ok $run3->pid > 0, 'pid';
  is $read{pty},    "cool beans\r\n", 'pty';
  is $read{stderr}, undef,            'stderr';
  is $read{stdout}, undef,            'stdout';
};

subtest 'stdin=pty, stdout=pty, stderr=closed' => sub {
  my $run3 = Mojo::Run3->new(driver => {stdin => 'pty', stdout => 'pty'});
  my ($sent, %read);
  $run3->on(pty    => sub { $read{pty}    .= $_[1] });
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  guard($run3->run_p(sub { print STDERR "foo\n"; print STDOUT "bar\n"; close STDOUT; exit 0 }));
  ok $run3->pid > 0, 'pid';
  is $read{pty},    "bar\r\n", 'pty';
  is $read{stderr}, undef,     'stderr';
  is $read{stdout}, undef,     'stdout';
};

subtest 'close stdin' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  $run3->on(
    spawn => sub {
      my ($run3) = @_;
      ok $run3->handle('pty'), 'got pty';
      $run3->close('stdin');
      ok !$run3->handle('pty'), 'close stdin also close pty';
    }
  );

  guard($run3->run_p(sub { exec qw(bash -i) }));
  ok $run3->pid > 0, 'pid';
};

done_testing;

sub guard {
  Mojo::Promise->race(shift, Mojo::Promise->timeout(2))->then(sub { ok 1, 'run_p' }, sub { is $_[0], '', 'run_p' })
    ->wait;
}
