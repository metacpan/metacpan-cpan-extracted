#!/opt/local/bin/perl

use strict;
use warnings;
use RRD::CGI::Image;
use CGI qw[header Vars];

print header( 'image/png' );

my $artist = RRD::CGI::Image->new(
	rrd_base  => '/opt/rrd/',
	error_img => '/Library/WebServer/Documents/dateslider/img/graphing_error.png',
	logging   => 0,
);
$artist->print_graph( Vars() );
