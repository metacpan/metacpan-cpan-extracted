#! perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

diag "Patro on $^O $]";
use_ok( 'Patro' );
use_ok( 'Patro::Server' );
diag "Threads avail: ", $threads::threads || 0;

use lib '.';
require_ok( 't::PatroNetworkOK' )
    or BAIL_OUT("Network unavailable for testing. "
		. "See can_socket() in Makefile.PL");

done_testing();

