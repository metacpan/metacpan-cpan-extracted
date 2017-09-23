#! perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

diag "Patro - Proxy Access To Remote Objects - on $^O $]";
use_ok( 'Patro' );
use_ok( 'Patro::Archy' );
diag "Threads avail: ", $threads::threads || 0;

use lib '.';
require_ok( 't::PatroNetworkOK' )
    or BAIL_OUT("Network unavailable for testing. "
		. "See can_socket() in Makefile.PL");

done_testing();

