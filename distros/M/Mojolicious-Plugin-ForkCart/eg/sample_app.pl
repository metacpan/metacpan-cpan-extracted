#!/opt/perl

use Mojolicious::Lite;

app->log->level("debug");

plugin Minion => { SQLite => 'sqlite:test.db' };
plugin qw(Mojolicious::Plugin::ForkCall);
plugin qw(ForkCart);

app->forked(sub {
    my $app = shift;

    $app->fork_call(
      sub {
        $0 = $ENV{HYPNOTOAD_APP} // $0;

        # I dunno why I have (or if I have) to do this for hypnotoad
        delete($ENV{HYPNOTOAD_APP});
        delete($ENV{HYPNOTOAD_EXE});
        delete($ENV{HYPNOTOAD_FOREGROUND});
        delete($ENV{HYPNOTOAD_REV});
        delete($ENV{HYPNOTOAD_STOP});
        delete($ENV{HYPNOTOAD_TEST});
        delete($ENV{MOJO_APP_LOADER});
        
        my @cmd = (
            $^X,
            $0,
            "minion",
            "worker"
        );

        $app->log->debug("$$: ForkCart minion worker");
        system(@cmd) == 0 
            or die("0: $?");

        return 1;
      },
      sub {
        exit;
      }
    );

    Mojo::IOLoop->start;
});

app->forked(sub {
  my $app = shift;
  
  Mojo::IOLoop->timer(4 => sub {
    $app->log->debug("$$: ForkCart server: 4000: timer hack");

    Mojo::IOLoop->server({port => 4000} => sub {
      my ($loop, $stream, $id) = @_;

      $app->log->debug("$$: ForkCart server: 4000: accept");
    
      $stream->on(read => sub {
        my ($stream, $bytes) = @_;
    
        $app->log->debug("$$: read: $bytes");
      });
    });
  });

  Mojo::IOLoop->start;
});

app->minion->add_task(echo => sub {
    my ($job, @args) = @_;

    my $id; $id = Mojo::IOLoop->client({port => 4000} => sub {
      my ($loop, $err, $stream) = @_;

      $stream->on(drain => sub {
        $job->finish;

        Mojo::IOLoop->remove($id);
        Mojo::IOLoop->stop;
      });

      $stream->write($args[0]);
    });

    Mojo::IOLoop->start;
});

get '/' => sub {
    my $c = shift;

    my $job_id = $c->minion->enqueue("echo", ["Joy: $$"]);

    $c->render(text => "Hello:" . $job_id);
};

app->start;
