use strict;
use warnings;

use File::Basename;
use Test::More;
use Test::Warnings;

BEGIN {
    push(@INC, dirname(__FILE__));
}

use Net::OpenStack::Client;
use mock_rest qw(auth);

use logger;

my $openrcfn = dirname(__FILE__)."/openrc_example";
ok(-f $openrcfn, "example openrc file exists");

my $cl = Net::OpenStack::Client->new(log => logger->new(), debugapi=>1);
isa_ok($cl, 'Net::OpenStack::Client::Auth', 'the client is an Auth instance');

is_deeply($cl->_parse_openrc($openrcfn), {
    OS_PROJECT_DOMAIN_NAME => 'Default',
    OS_USER_DOMAIN_NAME => 'Default',
    OS_PROJECT_NAME => 'admin',
    OS_USERNAME => 'admin',
    OS_PASSWORD => 'ADMIN_PASS',
    OS_AUTH_URL => 'http://controller:35357/v3',
    OS_IDENTITY_API_VERSION => '3',
    OS_IMAGE_API_VERSION => '2',
}, "parsed openrc example");

$cl->login(openrc => $openrcfn);
is($cl->{token}, 'mytoken', "login succesful and token set");
is_deeply($cl->{services}, {
   duper => 'somewhere/d/internal',
   identity => 'http://controller:35357/v3',
   super => 'somewhere/s/admin'
}, "services extracted from catalog");


done_testing;
