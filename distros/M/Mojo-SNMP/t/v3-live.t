use strict;
use warnings;
use Test::More;
use Mojo::SNMP;

plan skip_all => 'TEST_SNMP_PASSWORD=s3cret' unless $ENV{TEST_SNMP_PASSWORD};

my $snmp = Mojo::SNMP->new;
my (@response, @error, $finish);

$snmp->on(response => sub { push @response, $_[1]->var_bind_list });
$snmp->on(error    => sub { push @error,    $_[1] });
$snmp->on(finish   => sub { $finish++ });
$snmp->defaults({community => 'public', version => 2});

@response = ();
$snmp->prepare(
  'localhost',
  {
    version      => 'snmpv3',
    username     => 'authOnlyUser',
    authpassword => $ENV{TEST_SNMP_PASSWORD},
    authprotocol => 'md5',
    timeout      => 1,
    retries      => 0,
  },
  get => ['1.3.6.1.2.1.1.4.0']
)->wait;

is $finish, 1, 'finish event was emitted';
ok defined $response[0]{'1.3.6.1.2.1.1.4.0'}, 'got contact name';

done_testing;
