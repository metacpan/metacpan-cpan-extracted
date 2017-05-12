#!perl
use Test::More tests => 8;
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

ok( $ccp->add_group( "first", [ 'xhost1', 'xhost2', 'xhost3', 'xhost4' ] ),
    "Adding hosts to group 'first'"
);
is_deeply( [ $ccp->_get_remaining_servers( 'first' ) ],
           [ 'xhost1', 'xhost2', 'xhost3', 'xhost4' ],
           "Checking that servers match original insert order which was already sorted"
       );


ok( $ccp->add_group( "second", [ 'xhost4', 'xhost3', 'xhost2', 'xhost1' ] ),
    "Adding hosts to group 'second'"
);
is_deeply( [ $ccp->_get_remaining_servers( 'second' ) ],
           [ 'xhost4', 'xhost3', 'xhost2', 'xhost1' ],
           "Checking that servers match original insert order which was reverse sorted"
       );


ok( $ccp->add_group( "third", [ 'xhost3', 'xhost1', 'xhost4', 'xhost2' ] ),
    "Adding hosts to group 'third'"
);
is_deeply( [ $ccp->_get_remaining_servers( 'third' ) ],
           [ 'xhost3', 'xhost1', 'xhost4', 'xhost2' ],
           "Checking that servers match original insert order which was unsorted"
       );


ok( $ccp->add_group( "fourth", [ 'xhost1', 'xhost2', 'xhost3', 'xhost4', 'xhost1' ] ),
    "Adding hosts to group 'fourth'"
);
is_deeply( [ $ccp->_get_remaining_servers( 'fourth' ) ],
           [ 'xhost1', 'xhost2', 'xhost3', 'xhost4' ],
           "Server listed twice keeps original sort order"
       );

