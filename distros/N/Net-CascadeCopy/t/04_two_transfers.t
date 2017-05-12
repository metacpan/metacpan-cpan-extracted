#!perl
use Test::More tests => 10;
use strict;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
#my $logger = get_logger( 'default' );

use Net::CascadeCopy;

my $transfer_start = new Benchmark;

my $ccp = Net::CascadeCopy->new( { ssh         => 'echo',
                                   command     => 'echo',
                                   source_path => '/foo',
                                   target_path => '/foo',
                               } );

ok( $ccp->add_group( "only", [ 'host1', 'host2' ] ),
    "Adding a single host to a single group"
);
is_deeply( [ $ccp->_get_available_servers( 'only' ) ],
           [ 'localhost' ],
           "Checking that only localhost is available"
       );

is_deeply( [ $ccp->_get_remaining_servers( 'only' ) ],
           [ 'host1', 'host2' ],
           "Checking that host1 and host2 are remaining"
       );

ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

sleep 1;

$ccp->_check_for_completed_processes();

is_deeply( [ $ccp->_get_remaining_servers( 'only' ) ],
           [ 'host2' ],
           "Checking that only host2 is left"
       );

is_deeply( [ $ccp->_get_available_servers( 'only' ) ],
           [ 'host1' ],
           "Checking that host1 is now available",
       );

ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

sleep 1;

$ccp->_check_for_completed_processes();

is_deeply( [ $ccp->_get_remaining_servers( 'only' ) ],
           [ ],
           "Checking that no hosts are remaining"
       );

is_deeply( [ $ccp->_get_available_servers( 'only' ) ],
           [ 'host1', 'host2' ],
           "Checking that all hosts are now available",
       );

ok( ! $ccp->_transfer_loop( $transfer_start ),
    "making sure no loops left to run"
);
