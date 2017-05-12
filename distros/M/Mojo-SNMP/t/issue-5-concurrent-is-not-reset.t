use Mojo::Base -strict;
use Test::More;
use Mojo::SNMP;
use Time::HiRes qw( gettimeofday );

plan skip_all => 'LIVE_TEST=0' unless $ENV{LIVE_TEST};

my $snmp     = Mojo::SNMP->new(concurrent => 10);
my $interval = 0.02;
my $limit    = 14;
my @targets  = qw( localhost 127.0.0.1 );
my @res;

for my $target (@targets) {
  my $action;
  my $round = 0;
  $action = sub {
    my $lastCall = gettimeofday;
    diag "ACTION" if Mojo::SNMP::DEBUG;
    $snmp->get(
      $target,
      {community => 'public'},
      [qw(1.3.6.1.2.1.1.1.0)],
      sub {
        my ($snmp, $err, $res) = @_;
        my $now  = gettimeofday;
        my $wait = $lastCall + $interval - $now;
        push @res, $err || join ',', values %{$res->var_bind_list} if @_ == 3;
        if ($wait <= 0) {
          diag "Oops, SNMP took " . ($interval - $wait) if Mojo::SNMP::DEBUG;
          Mojo::IOLoop->next_tick($action);
        }
        else {
          $round++;
          diag "Schedule Next $wait (Round $round)" if Mojo::SNMP::DEBUG;
          Mojo::IOLoop->timer($wait => $action);
        }

        Mojo::IOLoop->stop if @res == $limit;
      }
    );
  };
  Mojo::IOLoop->next_tick($action);
}

Mojo::IOLoop->timer(2 => sub { push @res, 'TIMEOUT!'; Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

is int(@res), $limit, 'not stopped by concurrent limit';
diag join "\n", @res if Mojo::SNMP::DEBUG;

done_testing;
