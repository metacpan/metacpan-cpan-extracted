use strict;
use warnings;

use Test::More;
my $fail;
BEGIN {
	eval "use Test::Memory::Cycle";
	$fail = $@;
}
plan skip_all => 'Need Test::Memory::Cycle' if $fail;


plan tests => 2;

use Net::XMPP;

my $conn   = Net::XMPP::Client->new;

memory_cycle_ok($conn, 'after creating object');

# TODO the user should be asked if he want to run networking tests!
SKIP: {
    skip 'Needs AUTHORS_TEST', 1 if not $ENV{AUTHORS_TEST};
    my $status = $conn->Connect(
        hostname       => 'talk.google.com',
        port           => 5222,
        componentname  => 'gmail.com',
        connectiontype => 'tcpip',
        tls            => 1,
        ssl_verify     => 0,
    );
    
    memory_cycle_ok($conn, 'after calling Connect');
}

