BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Errno qw(EAGAIN EBADF ECONNRESET EINTR EPIPE EWOULDBLOCK EIO);
use IO::Handle;
use Test::More;
use Mojo::Run3;

generate_mock_handle_class();

subtest 'read error' => sub {
  my $run3 = Mojo::Run3->new;
  my $fh   = MockHandle->new;
  my $err;
  local $! = 1;
  $run3->on(error => sub { $err = $_[1] });
  $run3->_read(stdout => $fh);
  is int($err), 1, 'event';
};

subtest 'read ignore' => sub {
  my $run3 = Mojo::Run3->new;
  my $fh   = MockHandle->new;
  for my $errno (EAGAIN, EINTR, EWOULDBLOCK) {
    local $! = $errno;
    is $run3->_read(stdout => $fh), undef, "errno $errno";
  }
};

subtest 'read kill' => sub {
  my $run3 = Mojo::Run3->new;
  my $fh   = MockHandle->new;
  for my $errno (ECONNRESET, EPIPE) {
    local $! = $errno;
    is $run3->_read(stdout => $fh), -1, "errno $errno";
  }
};

subtest 'read eof' => sub {
  my $run3 = Mojo::Run3->new;

  # Test data from pty.t
  $run3->{fh} = {map { ($_ => MockHandle->new(name => $_)) } qw(pty stderr stdin stdout)};
  $run3->{watching}{$_} = 1 for qw(pid pty stderr stdout);

  my ($err, $finished) = ('', 0);
  $run3->on(error  => sub { $err = $_[1] });
  $run3->on(finish => sub { $finished++ });

  $run3->{fh}{stdout}{bytes_read} = 0;
  is $run3->_read(stdout => $run3->{fh}{stdout}), 0, 'stdout eof';
  is int(grep {$_} values %{$run3->{fh}}),        4, 'nothing has been closed yet';

  local $! = EAGAIN;
  is $run3->_read(stderr => $run3->{fh}{stderr}), undef, 'stderr eagain';
  is int(grep {$_} values %{$run3->{fh}}),        4,     'nothing has been closed yet';

  local $! = EBADF;
  $run3->_read(stderr => $run3->{fh}{stderr});
  is int $err,                             EBADF, 'stderr ebadf';
  is int(grep {$_} values %{$run3->{fh}}), 4,     'nothing has been closed yet';

  $run3->{fh}{stderr}{bytes_read} = 0;
  is $run3->_read(stderr => $run3->{fh}{stderr}), 0, 'stderr eof';
  is int(grep {$_} values %{$run3->{fh}}),        4, 'nothing has been closed yet';

  local $! = EIO;
  is $run3->_read(pty => $run3->{fh}{pty}), 0, 'pty eio';
  is int(grep {$_} values %{$run3->{fh}}),  4, 'nothing has been closed yet';

  $run3->{status} = 0;
  is $run3->_close_from_child('pid'),      1, 'pid';
  is $finished,                            1, 'finish event';
  is int(grep {$_} values %{$run3->{fh}}), 0, 'all got closed';
};

done_testing;

sub generate_mock_handle_class {
  require Mojo::Reactor::Poll;
  no warnings qw(once redefine);
  *Mojo::Reactor::Poll::remove = sub { };

  eval <<'HERE' or die $@;
package MockHandle;
use Mojo::Base -base;
sub close { $_[0]->{closed}++ }
sub sysread { $_[0]->{bytes_read} }
1;
HERE
}
