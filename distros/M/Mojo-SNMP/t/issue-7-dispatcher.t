use Mojo::Base -strict;
use Test::More;
use Mojo::SNMP;
use Time::HiRes qw( gettimeofday );

plan skip_all => 'LIVE_TEST=0' unless $ENV{LIVE_TEST};

my @targets = qw( localhost localhost);
my @res;

my $test    = 0;
my $results = 0;
for my $target (@targets) {
  my $snmp     = Mojo::SNMP->new();
  my $start    = gettimeofday;
  my $instance = $test;
  $snmp->prepare(
    $target,
    {community => 'public', timeout => 2},
    'get' => [qw(1.3.6.1.2.1.2.2.1.10)],
    sub {
      my ($snmp, $err, $session) = @_;
      if ($err) {
        diag "Oops we got a problem $err";
        return;
      }
      my $time = gettimeofday - $start;
      diag "request $instance ran for: $time";
      $res[$instance] = $time;
      $results++;
      if ($results == 2) {
        Mojo::IOLoop->stop;
      }
    }
  );
  $test++;
}

# emergency stop;
Mojo::IOLoop->timer(5 => sub { Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

ok defined $res[1] && $res[1] < 1, 'concurrency check';

done_testing;
