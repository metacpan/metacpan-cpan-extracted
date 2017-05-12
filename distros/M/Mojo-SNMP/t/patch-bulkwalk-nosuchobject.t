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
$snmp->prepare('127.0.0.1', {timeout => 1}, bulk_walk => ['1.3.6.1.2.1.1.3'])->wait;
like $response[0]{'1.3.6.1.2.1.1.3.0'}, qr{\d}, 'bulk_walk uptime' or d $response[0];

memory_cycle_ok($snmp) if TEST_MEMORY;

@response = ();
$snmp->prepare('127.0.0.1', {timeout => 1}, bulk_walk => ['1.3.6.1.2.1.1.3.0'])->wait;
is $response[0]{'1.3.6.1.2.1.1.3.0'}, 'noSuchObject', '1.3.6.1.2.1.1.3.0 cannot be walked' or d $response[0];

memory_cycle_ok($snmp) if TEST_MEMORY;

@response = ();
$snmp->prepare('127.0.0.1', {timeout => 1}, bulk_walk => ['1.3.6.1.2.1.1.888'])->wait;
is $response[0]{'1.3.6.1.2.1.1.888'}, 'noSuchObject', '1.3.6.1.2.1.1.888 does not exist' or d $response[0];

memory_cycle_ok($snmp) if TEST_MEMORY;

@response = ();
$snmp->prepare('127.0.0.1', {timeout => 1}, bulk_walk => ['1.3.6.1.2.1.1.888.0'])->wait;
is $response[0]{'1.3.6.1.2.1.1.888.0'}, 'noSuchObject', '1.3.6.1.2.1.1.888.0 does not exist' or d $response[0];

memory_cycle_ok($snmp) if TEST_MEMORY;

done_testing;
