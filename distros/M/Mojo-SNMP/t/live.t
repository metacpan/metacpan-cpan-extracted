use strict;
use warnings;
use Test::More;
use Mojo::SNMP;
use constant TEST_MEMORY => $ENV{TEST_MEMORY} && eval 'use Test::Memory::Cycle; 1';

plan skip_all => 'LIVE_TEST=0' unless $ENV{LIVE_TEST};

my %T;

sub d {
  return if $T{"@_"}++;
  diag(Data::Dumper->new([@_])->Terse(1)->Indent(0)->Dump);
}

my $snmp = Mojo::SNMP->new;
my (@response, @error, $finish);

$snmp->on(response => sub { push @response, $_[1]->var_bind_list });
$snmp->on(error    => sub { push @error,    $_[1] });
$snmp->on(finish   => sub { $finish++ });
$snmp->defaults({community => 'public', version => 2});

memory_cycle_ok($snmp) if TEST_MEMORY;

@response = ();
$snmp->prepare('127.0.0.1', {timeout => 1}, get => ['1.2.42.42'])->wait;
is $response[0]{'1.2.42.42'}, 'noSuchObject', '1.2.42.42 does not exist';

@response = ();
$snmp->prepare(
  '127.0.0.1', {timeout => 1},
  get      => [qw( 1.3.6.1.2.1.1.3.0 1.3.6.1.2.1.1.4.0 )],
  get      => [qw( 1.3.6.1.2.1.1.4.0 )],
  get_next => [qw( 1.3.6.1.2.1 )],
)->wait;

is $finish, 2, 'finish event was emitted';
like $response[0]{'1.3.6.1.2.1.1.3.0'}, qr{\d}, 'get 0 uptime'           or d $response[0];
like $response[0]{'1.3.6.1.2.1.1.4.0'}, qr{\w}, 'get 0 contact name'     or d $response[0];
like $response[1]{'1.3.6.1.2.1.1.4.0'}, qr{\w}, 'get 1 contact name'     or d $response[1];
like $response[2]{'1.3.6.1.2.1.1.1.0'}, qr{\w}, 'get_next 2 system name' or d $response[2];

memory_cycle_ok($snmp) if TEST_MEMORY;

@response = ();
$snmp->prepare('127.0.0.1', {timeout => 1}, walk => ['1.3.6.1.2.1.1'])->wait;

is $finish, 3, 'finish event was emitted';
like $response[0]{'1.3.6.1.2.1.1.3.0'}, qr{\d}, 'walk uptime'       or d $response[0];
like $response[0]{'1.3.6.1.2.1.1.4.0'}, qr{\w}, 'walk contact name' or d $response[0];
like $response[0]{'1.3.6.1.2.1.1.1.0'}, qr{\w}, 'walk system name'  or d $response[0];

memory_cycle_ok($snmp) if TEST_MEMORY;

@response = ();
$snmp->prepare('127.0.0.1', {timeout => 1}, bulk_walk => ['1.3.6.1.2.1.1'])->wait;

is $finish, 4, 'finish event was emitted';
like $response[0]{'1.3.6.1.2.1.1.3.0'}, qr{\d}, 'bulk_walk uptime'       or d $response[0];
like $response[0]{'1.3.6.1.2.1.1.4.0'}, qr{\w}, 'bulk_walk contact name' or d $response[0];
like $response[0]{'1.3.6.1.2.1.1.1.0'}, qr{\w}, 'bulk_walk system name'  or d $response[0];

memory_cycle_ok($snmp) if TEST_MEMORY;

done_testing;
