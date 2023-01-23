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
  guard($run3->run_p(sub { exec qw(bash --norc -i -l) }));
  ok $run3->pid > 0, 'pid';
  like $read{pty},    qr{^echo cool beans && exit}, 'stdout' or diag $read{stderr};
  like $read{stdout}, qr{cool beans\n$}s,           'stdout' or diag $read{stderr};
};

subtest 'stdin=pipe, stdout=pipe, stderr=pty' => sub {
  my $run3 = Mojo::Run3->new(driver => {pipe => 1, stderr => 'pty'});
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

subtest 'close slave' => sub {
  my $run3 = Mojo::Run3->new(driver => {close_slave => 0, pipe => 1, pty => 1});

  my $p = Mojo::Promise->new;
  $run3->on(stdout => sub { $p->resolve });
  $run3->start(sub { print STDOUT "started\n"; sleep 2 });
  guard($p);

  my $master = $run3->handle('pty');
  local $TODO = 'Looks like the internal structure has changed' unless ${*$master}{io_pty_slave};
  ok exists ${*$master}{io_pty_slave}, 'slave open';

  local $! = 0;
  $run3->close('slave');
  ok !$!,                               'closed' or diag $!;
  ok !exists ${*$master}{io_pty_slave}, 'slave closed';

  $p = Mojo::Promise->new;
  $run3->on(finish => sub { $p->resolve });
  $run3->kill;
  guard($p);
};

subtest 'internal test to check close-from-child.t mock state' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  my (@fh, @watching);
  $run3->on(
    spawn => sub {
      my ($run3) = @_;
      @fh       = sort keys %{$run3->{fh}};
      @watching = sort keys %{$run3->{watching}};
    }
  );

  guard($run3->run_p(sub { exec qw(mojo-run3-hopefully-no-such-command --with --this) }));
  is_deeply \@fh,       [qw(pty stderr stdin stdout)], 'fh';
  is_deeply \@watching, [qw(pid pty stderr stdout)],   'watching';
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

  guard($run3->run_p(sub { exec qw(bash --norc -i -l) }));
  ok $run3->pid > 0, 'pid';
};

done_testing;

sub guard {
  Mojo::Promise->race(shift, Mojo::Promise->timeout(2))->then(sub { ok 1, 'run_p' }, sub { is $_[0], '', 'run_p' })
    ->wait;
}
