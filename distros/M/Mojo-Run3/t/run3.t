use Mojo::Base -strict;
use Mojo::Run3;
use Test::More;

subtest 'before start' => sub {
  my $run3 = Mojo::Run3->new;
  is $run3->bytes_waiting, 0,  'zero bytes waiting';
  is $run3->pid,           -1, 'pid';
  is $run3->status,        -1, 'status';

  $run3->write('foo');
  is $run3->bytes_waiting, 3, 'three bytes waiting';

  $run3->write('bar');
  is $run3->bytes_waiting, 6, 'six bytes waiting';
};

subtest 'stdout' => sub {
  my $run3   = Mojo::Run3->new;
  my $stdout = '';
  $run3->on(stderr => sub { diag "STDERR <<< $_[1]" });
  $run3->on(stdout => sub { $stdout .= $_[1] });
  $run3->run_p(sub { print STDOUT "cool beans\n" })->wait;
  is $stdout, "cool beans\n", 'read';
  ok $run3->pid > 0, 'pid';
  is $run3->status, 0, 'status';
};

subtest 'stderr' => sub {
  my $run3   = Mojo::Run3->new;
  my $stderr = '';
  $run3->on(stderr => sub { $stderr .= $_[1] });
  $run3->on(stdout => sub { diag "STDOUT <<< $_[1]" });
  $run3->run_p(sub { print STDERR "cool beans\n" })->wait;
  is $stderr, "cool beans\n", 'read';
  ok $run3->pid > 0, 'pid';
  is $run3->status, 0, 'status';
};

subtest 'stdin' => sub {
  my $run3 = Mojo::Run3->new;
  my ($drained, $waiting, $stdout) = (0, -1, '');
  $run3->on(stderr => sub { diag "STDERR <<< $_[1]" });
  $run3->on(stdout => sub { $stdout .= $_[1] });
  $run3->on(
    spawn => sub {
      my ($run3) = @_;
      $run3->write("cool beans\n", sub { $drained++ });
      $waiting = $run3->bytes_waiting;
    }
  );
  $run3->run_p(sub { print scalar <STDIN> })->wait;
  is $waiting, 0,              'all got written';
  is $drained, 1,              'drained';
  is $stdout,  "cool beans\n", 'read';
  ok $run3->pid > 0, 'pid';
  is $run3->status, 0, 'status';
};

subtest 'kill' => sub {
  my $run3 = Mojo::Run3->new;
  is $run3->kill, -1, 'without pid';

  $run3->on(spawn => sub { shift->kill('TERM') });
  $run3->run_p(sub { exec sleep => 10 })->wait;
  ok $run3->pid > 0, 'pid';
  is $run3->status,       15, 'status';
  is $run3->exit_status,  0,  'exit_status';
  is $run3->status & 127, 15, 'signal';
};

subtest 'close' => sub {
  my $run3 = Mojo::Run3->new;
  ok $run3->close('stdin'), 'noop';

  my ($stdout, %fh) = ('');
  $run3->on(stderr => sub { diag "STDERR <<< $_[1]" });
  $run3->on(stdout => sub { $stdout .= $_[1] });
  $run3->on(
    spawn => sub {
      my $run3 = shift;
      $run3->handle($_) && $fh{$_}++ for qw(stdin stdout stderr);
      $run3->write("ice cool\n")->close('stdin');
    }
  );

  $run3->run_p(sub { exec qw(cat -) })->wait;
  ok !$run3->handle('stdin'), 'stdin closed';
  is_deeply \%fh, {stdin => 1, stdout => 1, stderr => 1}, 'got filehandles in parent';
  is $stdout, "ice cool\n", 'read';
  ok $run3->pid > 0, 'pid';
  is $run3->status, 0, 'status';
};

done_testing;
