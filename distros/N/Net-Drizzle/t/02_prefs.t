use strict;
use warnings;
use Test::More tests => 9;
use Net::Drizzle;

my $dr = Net::Drizzle->new();
ok $dr;
my $con = $dr->con_create();

is $con->host, '127.0.0.1';
is $con->port, 4427;
$con->set_tcp('localhost', 10010);
is $con->host, 'localhost';
is $con->port, 10010;

is $con->user, 'root';
is $con->password, '';
$con->set_auth('root', 'mypw');
is $con->user, 'root';
is $con->password, 'mypw';

