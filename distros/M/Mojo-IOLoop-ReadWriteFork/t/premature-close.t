use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_CHUNK_SIZE} = 1;
  $ENV{MOJO_REACTOR}    = 'Mojo::Reactor::Poll';
}

use Mojo::IOLoop::ReadWriteFork;
use Test::Mojo;
use Test::More;

my ($attempts, $len, $max_loop, $recv) = (0, 4643, $ENV{TEST_MAX_LOOPS} || 20, 0);
Mojo::IOLoop->next_tick(\&start_rwf);
Mojo::IOLoop->start;

is $recv, $len * $max_loop, 'got all bytes';

done_testing;

sub start_rwf {
  Mojo::IOLoop->stop if $attempts++ >= $max_loop;
  my $rwf    = Mojo::IOLoop::ReadWriteFork->new(conduit => {type => 'pty'});
  my $output = '';
  $rwf->run(sub { printf "%s\n", 'a' x $len; }, {env => {}});
  $rwf->on(read => sub { $output .= $_[1] });
  $rwf->on(
    finish => sub {
      $output =~ s/\r?\n//g;
      $recv += length $output;
      Mojo::IOLoop->next_tick(\&start_rwf);
    }
  );
}
