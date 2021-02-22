use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_CHUNK_SIZE} = 1;
  $ENV{MOJO_REACTOR}    = 'Mojo::Reactor::Poll';
}

use Mojo::IOLoop::ReadWriteFork;
use Test::Mojo;
use Test::More;

my $attempts = 0;
my $len      = 4643;
my $max_loop = 20;
my $recv     = 0;

sub start_rwf {
  Mojo::IOLoop->stop if $attempts++ >= $max_loop;
  my $fork = Mojo::IOLoop::ReadWriteFork->new(conduit => {type => 'pty'});
  my $txt  = '';
  $fork->start(program => sub { printf "%s\n", 'a' x $len; }, program_args => [], env => {});
  $fork->on(read => sub { my ($self, $buf) = @_; $txt .= $buf; });
  $fork->on(
    close => sub {
      $txt =~ s/\r?\n//g;
      $recv += length($txt);
      undef $fork;
      return Mojo::IOLoop->timer(0, sub { start_rwf() });
    }
  );
}

Mojo::IOLoop->next_tick(\&start_rwf);
Mojo::IOLoop->start;

is $recv, $len * $max_loop, 'got all bytes';
done_testing;
