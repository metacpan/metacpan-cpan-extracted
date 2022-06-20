use Mojo::Base -strict;
use Errno qw(EAGAIN ECONNRESET EINTR EPIPE EWOULDBLOCK EIO);
use IO::Handle;
use Test::More;

BEGIN {
  no warnings qw(redefine);
  *IO::Handle::sysread = sub { $! = $main::errno; $main::bytes_read };
}

use Mojo::Run3;

subtest 'read error' => sub {
  my $run3 = Mojo::Run3->new;
  my $err;
  $run3->on(error => sub { $err = $_[1] });
  local $main::bytes_read = undef;
  local $main::errno      = 1;
  $run3->_read(stdout => \*STDIN);
  is int($err), 1, 'event';
};

subtest 'read ignore' => sub {
  my $run3 = Mojo::Run3->new;
  for my $errno (EAGAIN, EINTR, EWOULDBLOCK) {
    local $main::bytes_read = undef;
    local $main::errno      = $errno;
    is $run3->_read(stdout => \*STDIN), undef, "errno $errno";
  }
};

subtest 'read kill' => sub {
  my $run3 = Mojo::Run3->new;
  for my $errno (ECONNRESET, EPIPE) {
    local $main::bytes_read = undef;
    local $main::errno      = $errno;
    is $run3->_read(stdout => \*STDIN), -1, "errno $errno";
  }
};

subtest 'read eof' => sub {
  my $run3 = Mojo::Run3->new;

  my $finished = 0;
  $run3->on(finish => sub { $finished++ });

  local $main::bytes_read = 0;
  local $main::errno      = 0;
  is $run3->_read(stdout => \*STDIN), 0, 'stdout eof';
  is_deeply $run3->{finish}, {stdout => 1}, 'finish stdout';

  local $main::bytes_read = undef;
  local $main::errno      = EIO;
  is $run3->_read(stderr => \*STDERR), 0, 'stderr eio';
  is_deeply $run3->{finish}, {stderr => 1, stdout => 1}, 'finish stderr';

  is $run3->_maybe_finish('child'), 1, 'finish';
  is $finished,                     1, 'finish event';
};

done_testing;
