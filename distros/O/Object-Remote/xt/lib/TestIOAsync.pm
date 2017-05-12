package TestIOAsync;

use Moo;
use Object::Remote;
use Object::Remote::Future;
use IO::Async::Loop;
use IO::Async::Process;
use IO::Async::LineStream;

Object::Remote->current_loop(our $Loop = IO::Async::Loop->new);

sub run {
  my ($self, $coderef) = @_;
  return future {
    my $f = shift;
    my $process = IO::Async::Process->new(
      command => [ 'ls' ],
      on_finish => sub {
        $Loop->remove($_[0]); $f->done; undef($f);
      },
    );
    my $line_stream = IO::Async::LineStream->new(
      on_read_line => sub { $coderef->($_[1]) },
      transport => $process->stdout,
    );
    $process->add_child($line_stream); # request cleanup
    $Loop->add($process);
    return $f;
  }
}

1;
