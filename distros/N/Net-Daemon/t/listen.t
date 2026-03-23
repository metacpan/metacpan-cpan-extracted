use strict;
use warnings;
use Test::More tests => 3;

use Net::Daemon;

# Verify that 'listen' is a recognized option
my $opts = Net::Daemon->Options();
ok( exists $opts->{'listen'}, '--listen option exists in Options()' );
is( $opts->{'listen'}{'template'}, 'listen=i', '--listen template accepts integer' );

# Verify that --listen value is passed through to the object
my $server = Net::Daemon->new(
    {
        'localport' => 12345,
        'proto'     => 'tcp',
        'mode'      => 'single',
    },
    [ '--listen', '20' ]
);
is( $server->{'listen'}, 20, '--listen value is stored on the object' );
