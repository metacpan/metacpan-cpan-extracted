#!/usr/bin/env perl 
use 5.8.0;
use strict;
use warnings;

QProc->run(
	conf_file => './qproc.conf',
);

package QProc;

use lib '../lib';

use base 'NetSDS::App::QueueProcessor';

use Data::Dumper;

sub start {

	my ($self) = @_;

	for ( my $i = 1 ; $i < 10 ; $i++ ) {
		$self->{server}->push( 'myq', { c => $i, a => 1, b => 2 } );
	}

}

sub process {

	my ( $self, $msg ) = @_;

	print Dumper($msg);

}

1;
