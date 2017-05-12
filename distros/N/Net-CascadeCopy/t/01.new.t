#!perl
use Test::More tests => 1;

use Net::CascadeCopy;

ok( Net::CascadeCopy->new( { ssh         => 'sleep 5; echo',
                             command     => 'sleep 3; echo',
                             source_path => '/foo',
                             target_path => '/foo',
                         } ),
    "Creating a new Net::CascadeCopy object"
);


