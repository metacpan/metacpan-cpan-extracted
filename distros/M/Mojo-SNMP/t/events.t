use strict;
use warnings;
use Test::More;
use Mojo::SNMP;
use constant TEST_MEMORY => $ENV{TEST_MEMORY} && eval 'use Test::Memory::Cycle; 1';

my $snmp = Mojo::SNMP->new;
my $net_snmp = Net::SNMP->new(nonblocking => 1);
my (@request, @response, @error, $timeout, $finish, $guard);

plan skip_all => 'Crypt::DES is required' unless eval 'require Crypt::DES; 1';

$snmp->concurrent(0);    # required to set up the queue
$snmp->defaults({timeout => 1, community => 'public', username => 'foo'});
$snmp->on(response => sub { push @response, $_[1]->var_bind_list });
$snmp->on(error    => sub { push @error,    $_[1] });
$snmp->on(finish   => sub { $finish++ });
$snmp->on(timeout  => sub { $timeout++ });

$snmp->prepare('1.2.3.4', {version => '2c'}, get => ['1.3.6.1.2.1.1.4.0']);

memory_cycle_ok($snmp) if TEST_MEMORY;

no warnings 'redefine';
*Net::SNMP::get_request = sub { shift; push @request, @_ };
$net_snmp->{_error} = 'yikes!';
$snmp->concurrent(1);
$snmp->prepare('*');

is_deeply $request[1], ['1.3.6.1.2.1.1.4.0'], 'varbindlist was passed on to get_request';
is ref $request[3], 'CODE', 'callback was passed on to get_request';

$request[3]->($net_snmp);
is $error[0], 'yikes!', 'on(error) was triggered';
is $finish, 1, 'on(finish) was triggered';

$snmp->master_timeout(0.0001);
$snmp->_setup;
$guard = 10_000;
$snmp->ioloop->one_tick while $guard--;
is $timeout, 1, 'on(timeout) was triggered';

memory_cycle_ok($snmp) if TEST_MEMORY;
done_testing;
