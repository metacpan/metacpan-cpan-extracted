#!perl
use Test::More tests => 7;
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

ok( $ccp->add_group( "only", [ 'host1' ] ),
    "Adding a single host to a single group"
);
is_deeply( [ $ccp->_get_available_servers( 'only' ) ],
           [ 'localhost' ],
           "Checking that only localhost is available"
       );

is_deeply( [ $ccp->_get_remaining_servers( 'only' ) ],
           [ 'host1' ],
           "Checking that host1 is remaining"
       );

ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

sleep 1;

$ccp->_check_for_completed_processes();

is_deeply( [ $ccp->_get_remaining_servers( 'only' ) ],
           [],
           "Checking that one servers is no longer in the only group"
       );

is_deeply( [ $ccp->_get_available_servers( 'only' ) ],
           [ 'host1' ],
           "Checking that one servers is now available in only group"
       );

ok( ! $ccp->_transfer_loop( $transfer_start ),
    "making sure no loops left to run"
);
