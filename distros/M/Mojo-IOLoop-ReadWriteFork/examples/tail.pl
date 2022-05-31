use Mojolicious::Lite;
use Mojo::IOLoop::ReadWriteFork;

# NOTE!
# THIS APPLICATION IS A BAD IDEA.
# IT SHOULD ONLY SERVE AS AN EXAMPLE.

get '/tail/:name', sub {
  my $self = shift->render_later;
  my $file = '/var/log/' . $self->stash('name');
  my $rwf  = Mojo::IOLoop::ReadWriteFork->new;

  # The request will end after 15 seconds of inactivity.
  # The line below can be used to increase that timeout,
  # but it is required to make sure we don't run the
  # "tail" process forever.
  # Mojo::IOLoop->stream($self->tx->connection)->timeout(60);

  # Make sure the object does not go out of scope
  $self->stash(rwf => $rwf);

  $self->write_chunk("# tail -f $file\n");

  # Make sure we kill "tail" after the request is finished
  # NOTE: This code might be to simple
  $self->on(
    finish => sub {
      my $self = shift;
      my $rwf  = $self->stash('rwf') or return;
      app->log->debug("Ending tail process");
      $rwf->kill;
    }
  );

  # Write data from "tail" directly to browser
  $rwf->on(
    read => sub {
      my ($rwf, $buffer) = @_;
      $self->write_chunk($buffer);
    }
  );

  # Start the tail program.
  # "-n50" is just to make sure we have enough data to make the browser
  # display anything. It should work just fine from curl, Mojo::UserAgent,
  # ..., but from chrome, ie, ... we need a big chunk of data before it
  # gets visible.
  $rwf->start(program => 'tail', program_args => ['-f', '-n50', $file]);
};

app->start;
