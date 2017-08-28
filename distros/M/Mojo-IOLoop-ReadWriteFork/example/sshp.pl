#!/usr/bin/env perl
use Term::ANSIColor ':constants';
use Applify;
use Mojo::IOLoop::ReadWriteFork;

option bool => color => 'Force coloring of host names', aliases => ['c'];

app {
  my ($self, $command, @hosts) = @_;
  my $ioloop = Mojo::IOLoop->delay;
  my @color = ($self->color or -t STDOUT) ? (RED, CLEAR) : ('', '');
  my @forks;

  die "Usage: $0 [command] [host0] [host1] ...\n" unless $command and @hosts;

  for my $host (@hosts) {
    my $f   = Mojo::IOLoop::ReadWriteFork->new;
    my $cb  = $ioloop->begin;
    my $buf = '';

    $f->on(close => $cb);
    $f->on(error => sub { warn $_[1] });
    $f->on(
      read => sub {
        $buf .= $_[1];
        local $| = 1;
        printf "%s[%s]%s %s", $color[0], $host, $color[1], $1 while $buf =~ s!([^\r\n]*[\r\n]+)!!s;
      }
    );

    $f->run(ssh => $host => $command);
    push @forks, $f;
  }

  $ioloop->wait;

  return 0;
};
