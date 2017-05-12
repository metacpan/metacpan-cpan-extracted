#!/usr/bin/perl 

use strict;
use warnings;
use lib qw(../lib/perl);

use Config::Tiny;
use Net::DNS::Nameserver::Trivial;
#=======================================================================
my $Config 	= Config::Tiny->read( '../etc/dom.ini' );
my $Params 	= Config::Tiny->read( '../etc/dns.ini' );
#=======================================================================
=backup
# If You want to reload on HUP signal # UNIX only
$SIG{ HUP } = sub { 
	$Log->DEBUG( 'Ending...' );
	exec( $^X, $0 ) or $Log->FATAL( 'Cannot exec(): ' . $! ); 
	exit 1;
};
#-----------------------------------------------------------------------
# If You want graceful exit on INT signal # UNIX only
$SIG{ INT } = sub { 
	$Log->DEBUG( 'Ending...' );
	exit 0;			
};
=cut

#=======================================================================
my $ns = Net::DNS::Nameserver::Trivial->new( $Config, $Params );
$ns->main_loop;
#=======================================================================
