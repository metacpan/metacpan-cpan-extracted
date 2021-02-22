#!/usr/bin/env perl
use Term::ANSIColor ':constants';
use Applify;
use Mojo::IOLoop::ReadWriteFork;

option bool => color => 'Force coloring of host names', aliases => ['c'];

app {
  my ($self, $command, @hosts) = @_;
  my @color = ($self->color or -t STDOUT) ? (RED, CLEAR) : ('', '');
  my (@forks, @p);

  die "Usage: $0 [command] [host0] [host1] ...\n" unless $command and @hosts;

  for my $host (@hosts) {
    my $f   = Mojo::IOLoop::ReadWriteFork->new;
    my $buf = '';

    $f->on(
      read => sub {
        $buf .= $_[1];
        local $| = 1;
        printf "%s[%s]%s %s", $color[0], $host, $color[1], $1 while $buf =~ s!([^\r\n]*[\r\n]+)!!s;
      }
    );

    push @p, $f->run_p(ssh => $host => $command);
  }

  Mojo::Promise->all(@p)->wait;

  return 0;
};
