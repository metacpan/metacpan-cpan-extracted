#!perl
use Test::More tests => 26;
use Test::Differences;
use strict;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
#my $logger = get_logger( 'default' );

use Net::CascadeCopy;

my $transfer_start = new Benchmark;

my $ccp;
ok( $ccp = Net::CascadeCopy->new( { ssh         => 'echo',
                                    command     => 'echo',
                                    source_path => '/foo',
                                    target_path => '/foo',
                                } ),
    "Creating a new ccp object"
);

my @hosts1 = map { "host$_" } 101 .. 105;
ok( $ccp->add_group( "first", [ @hosts1 ] ),
    "Adding first host group"
);

my @hosts2 = map { "host$_" } 201 .. 205;
ok( $ccp->add_group( "second", [ @hosts2 ] ),
    "Adding second host group"
);

{
    eq_or_diff( [ $ccp->_get_available_servers( 'first' ) ],
               [ 'localhost' ],
               "Checking that only localhost available in first group"
           );

    eq_or_diff( [ $ccp->_get_available_servers( 'second' ) ],
               [ 'localhost' ],
               "Checking that only localhost available in second group"
           );

    eq_or_diff( [ $ccp->_get_remaining_servers( 'first' ) ],
               \@hosts1,
               "Checking that all servers in first group are in the 'remaining' group"
           );

    eq_or_diff( [ $ccp->_get_remaining_servers( 'second' ) ],
               \@hosts2,
               "Checking that all servers in second group are in the 'remaining' group"
           );
}

ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

eq_or_diff( $ccp->get_transfer_map(),
           { localhost => { host101 => 1,
                            host201 => 1,
                        },
         },
           "Checking that localhost transferred to host101 and host201"
       );

sleep 1;

$ccp->_check_for_completed_processes();

{
    eq_or_diff( [ $ccp->_get_remaining_servers( 'first' ) ],
               [ @hosts1[ 1 .. $#hosts1 ] ],
               "Checking that one servers is no longer in the first group"
           );

    eq_or_diff( [ $ccp->_get_remaining_servers( 'second' ) ],
               [ @hosts2[ 1 .. $#hosts2 ] ],
               "Checking that one server is no longer in the second group"
           );

    eq_or_diff( [ $ccp->_get_available_servers( 'first' ) ],
               [ $hosts1[0] ],
               "Checking that one servers is now available in first dc"
           );

    eq_or_diff( [ $ccp->_get_available_servers( 'second' ) ],
               [ $hosts2[0] ],
               "Checking that one servers is now available in second dc"
           );
}


ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

eq_or_diff( $ccp->get_transfer_map(),
           { localhost => { host101 => 1,
                            host201 => 1,
                        },
             host101   => { host102 => 1,
                            host103 => 1,
                        },
             host201   => { host202 => 1,
                            host203 => 1,
                        },
         },
           "Checking that localhost transferred to host101 and host201"
       );

sleep 1;

$ccp->_check_for_completed_processes();

{
    eq_or_diff( [ sort $ccp->_get_remaining_servers( 'first' ) ],
               [ 'host104', 'host105' ],
               "Checking that host 104+105 are remaining"
           );

    eq_or_diff( [ sort $ccp->_get_remaining_servers( 'second' ) ],
               [ 'host204', 'host205' ],
               "Checking that host 204+205 are remaining"
           );

    eq_or_diff( [ sort $ccp->_get_available_servers( 'first' ) ],
               [ 'host101', 'host102', 'host103' ],
               "Checking that hosts 101-103 are now available for transfer"
           );

    eq_or_diff( [ sort $ccp->_get_available_servers( 'second' ) ],
               [ 'host201', 'host202', 'host203' ],
               "Checking that hosts 201-203 are now available for transfer"
           );
}

ok( $ccp->_transfer_loop( $transfer_start ),
    "Executing a single transfer loop"
);

eq_or_diff( $ccp->get_transfer_map(),
           { localhost => { host101 => 1,
                            host201 => 1,
                        },
             host101   => { host102 => 1,
                            host103 => 1,
                            host104 => 1,
                            host105 => 1,
                        },
             host201   => { host202 => 1,
                            host203 => 1,
                            host204 => 1,
                            host205 => 1,
                        },
         },
           "Checking that localhost transferred to host101 and host201"
       );

sleep 1;

$ccp->_check_for_completed_processes();

{
    eq_or_diff( [ sort $ccp->_get_remaining_servers( 'first' ) ],
               [ ],
               "checking that no servers are remaining in first group"
           );

    eq_or_diff( [ sort $ccp->_get_remaining_servers( 'second' ) ],
               [ ],
               "checking that no servers are remaining in second group"
           );

    eq_or_diff( [ sort $ccp->_get_available_servers( 'first' ) ],
               [ @hosts1 ],
               "Checking that all hosts in first group are now available for transfer"
           );

    eq_or_diff( [ sort $ccp->_get_available_servers( 'second' ) ],
               [ @hosts2 ],
               "Checking that all hosts in second group are now available for transfer"
           );
}

ok( ! $ccp->_transfer_loop( $transfer_start ),
    "making sure no loops left to run"
);
