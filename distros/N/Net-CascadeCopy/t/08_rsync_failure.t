#!perl
use Test::More tests => 5;
use strict;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
#my $logger = get_logger( 'default' );

use Net::CascadeCopy;

my $transfer_start = new Benchmark;

my $ccp = Net::CascadeCopy->new( { ssh         => 'echo',
                                   command     => 'false',
                                   source_path => '/foo',
                                   target_path => '/foo',
                               } );

ok( $ccp->add_group( "only", [ 'host1' ] ),
    "Adding a single host to a single group"
);

ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

sleep 1;

$ccp->_check_for_completed_processes();

is_deeply( [ $ccp->_get_remaining_servers( 'only' ) ],
           [],
           "Checking that no servers remaining in the 'only' group"
       );

is_deeply( [ $ccp->_get_available_servers( 'only' ) ],
           [],
           "Checking that now servers are available in 'only' group"
       );

ok( ! $ccp->_transfer_loop( $transfer_start ),
    "making sure no loops left to run"
);
