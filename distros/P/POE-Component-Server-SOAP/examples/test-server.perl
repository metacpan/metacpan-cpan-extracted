#!/usr/bin/perl
use strict; use warnings;

# Include the local directory to LIB
use FindBin qw($Bin);
use lib "$Bin/../lib";

use POE;
sub POE::Component::Server::SOAP::DEBUG () { 2 }
use POE::Component::Server::SOAP;

POE::Component::Server::SOAP->new(
	'ALIAS'		=>	'MySOAP',
	'ADDRESS'	=>	'localhost',
	'PORT'		=>	32080,
	'HOSTNAME'	=>	'MyHost.com',
);

POE::Session->create(
	inline_states => {
		_start => \&setup_service,
		_stop  => \&shutdown_service,
		Sum_Things => \&do_sum,
		Dump_Things => \&do_dump,
		LocalTime => \&do_time,
		Get_XML => \&do_xml,
	}
);

$poe_kernel->run;
exit 0;

sub setup_service {
	my $kernel = $_[KERNEL];
	$kernel->alias_set( 'MyServer' );
	$kernel->post( 'MySOAP', 'ADDMETHOD', 'MyServer', 'Sum_Things' );
	$kernel->post( 'MySOAP', 'ADDMETHOD', 'MyServer', 'Get_XML' );
	$kernel->post( 'MySOAP', 'ADDMETHOD', 'MyServer', 'Dump_Things', 'MyServer', 'DUMP' );
	$kernel->post( 'MySOAP', 'ADDMETHOD', 'MyServer', 'LocalTime', 'TimeServer', 'Time' );
}

sub shutdown_service {
	$_[KERNEL]->post( 'MySOAP', 'DELMETHOD', 'MyServer', 'Sum_Things' );
	$_[KERNEL]->post( 'MySOAP', 'DELMETHOD', 'MyServer', 'DUMP' );
	$_[KERNEL]->post( 'MySOAP', 'DELSERVICE', 'TimeServer' );
}

sub do_sum {
	my $response = $_[ARG0];
	my $params = $response->soapbody;
	my $sum = 0;
	while (my ($field, $value) = each(%$params)) {
		$sum += $value;
	}

	# Fake an error
	if ( $sum < 100 ) {
		$_[KERNEL]->post( 'MySOAP', 'FAULT', $response, 'Add:Error', 'The sum must be above 100' );
	} else {
		$response->content( $sum );
		$_[KERNEL]->post( 'MySOAP', 'DONE', $response );
	}
}

sub do_dump {
	my $response = $_[ARG0];
	require Data::Dumper;
	$response->content( Data::Dumper::Dumper( $response->soapbody ) );
	$_[KERNEL]->post( 'MySOAP', 'DONE', $response );
}

sub do_time {
	my $response = $_[ARG0];
	$response->content( scalar( localtime() ) );
	$_[KERNEL]->post( 'MySOAP', 'DONE', $response );
	#$_[KERNEL]->post( 'MySOAP', 'SHUTDOWN', 'GRACEFUL' );
}

sub do_xml {
	my $response = $_[ARG0];
	$response->content( '<data><var1>57</var1><var2>abc</var2></data>' );
	$_[KERNEL]->post( 'MySOAP', 'RAWDONE', $response );
}
