use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::Server::DaemonControl;

my $app = curfile->dirname->child(qw(t no-such-app.pl))->to_abs->to_string;

subtest 'stop' => sub {
  my $dctl = dctl(workers => 0);
  my @stop;
  for my $sig (qw(INT QUIT TERM)) {
    $dctl->once(stop  => sub { push @stop, $_[1] });
    $dctl->once(start => sub { kill $sig => $$ });
    $dctl->run($app);
  }

  is \@stop, [qw(INT QUIT TERM)], 'INT QUIT TERM';
};

subtest 'workers' => sub {
  my $dctl = dctl();

  note 'increase';
  $dctl->once(
    start => sub {
      my $dctl = shift;
      kill TTIN => $$ for 1 .. 2;
      kill TERM => $$;
    }
  );

  $dctl->run($app);
  is $dctl->workers, 6, 'inc workers';

  note 'mock working processes';
  $dctl->{pool}{$_} = {} for 1 .. $dctl->workers;
  $dctl->once(
    start => sub {
      my $dctl = shift;
      kill TTOU => $$ for 1 .. 2;
      kill TERM => $$;
    }
  );

  $dctl->run($app);
  is int(grep { $_->{graceful} } values %{$dctl->{pool}}),  2, 'set graceful';
  is int(grep { !$_->{graceful} } values %{$dctl->{pool}}), 4, 'rest is left alone';

  note 'decrease';
  $dctl->once(
    start => sub {
      my $dctl = shift;
      kill TTOU => $$ for 1 .. 10;
      kill TERM => $$;
    }
  );

  $dctl->run($app);
  is $dctl->workers, 1, 'min workers';
};

subtest 'reap' => sub {
  my $dctl = dctl(workers => 0);
  my ($running, @reap) = (1);
  $dctl->once(reap => sub { push @reap, $_[1]; $running = 0 });
  $dctl->once(
    start => sub {
      die "Can't fork: $!" unless defined(my $pid = fork);
      exit                 unless $pid;
      $dctl->{pool}{$pid} = {};
      1 while $running;
    }
  );
  $dctl->run($app);
  is int @reap, 1, 'reaped';
};

done_testing;

sub dctl {
  my $dctl = Mojo::Server::DaemonControl->new(@_);
  $dctl->on(start => sub { delete shift->{running} });
  return $dctl;
}
