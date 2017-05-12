use Test::More tests => 2;

use strict;
use warnings;
use Carp;

use Net::LDAP;
use Net::LDAP::Server::Test;
use Net::LDAP::Entry;
use IO::Socket::INET;

#
# these tests pulled nearly verbatim from the Net::LDAP synopsis
#

my %opts = (
    port  => '10636',
    dnc   => 'ou=internal,dc=foo',
    debug => $ENV{PERL_DEBUG} || 0,
);

my $host = 'ldap://127.0.0.1:' . $opts{port};

my $socket = IO::Socket::INET->new(
    Listen    => 5,
    Proto     => 'tcp',
    Reuse     => 1,
    LocalPort => $opts{port}, 
);
ok( my $server = Net::LDAP::Server::Test->new( $socket ),
    "spawn new server with socket passed" );

ok( my $ldap = Net::LDAP->new( $host, %opts, ), "new LDAP connection" );

diag("stop() server");
$server->stop();
