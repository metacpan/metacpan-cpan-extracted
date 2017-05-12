#!perl
use strict;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
#my $logger = get_logger( 'default' );

use Net::CascadeCopy;
use Test::More tests => 3;
use Test::Differences;

my $ccp = Net::CascadeCopy->new( { ssh         => 'sleep 5; echo',
                                   command     => 'sleep 3; echo',
                                   source_path => '/foo',
                                   target_path => '/foo',
                               } );


my @hosts1 = map { "host$_" } 101 .. 110;
ok( $ccp->add_group( "first", [ @hosts1 ] ),
    "Adding first host group"
);

$ccp->transfer();

my $map = $ccp->get_transfer_map();

eq_or_diff( [ sort keys %{ $map } ],
            [ qw( host101 host102 host103 localhost ) ],
            "Checking source hosts in the transfer map"
        );

eq_or_diff( [ keys %{ $map->{localhost} } ],
            [ 'host101' ],
            "Checking that localhost only xferred to host101"
        );

