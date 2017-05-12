use Mojo::Base -strict;
use Test::More;
use Mojo::SNMP;

plan skip_all => 'LIVE_TEST=0' unless $ENV{LIVE_TEST};

my $snmp = Mojo::SNMP->new;
my $host = '127.0.0.1';
my $err  = 'no error';

$snmp->on(
  error => sub {
    my ($snmp, $str, $session, $args) = @_;
    $err = "ERROR: $str";
  }
);

$snmp->get(
  '127.0.0.1',
  {community => 'public', version => 2},
  [qw( 1.3.6.1.2.1.1.3.0 )],
  sub {
    my ($snmp, $err, $session) = @_;
    non_existing_function();
    $err = 'should not come to this';
  }
)->wait;

like $err, qr{ERROR: .*\&main::non_existing_function}, 'got error';

done_testing;
