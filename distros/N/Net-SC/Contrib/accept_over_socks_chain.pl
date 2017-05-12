#!/usr/bin/perl
########################################################################
#
# $Id: accept_over_socks_chain.pl,v 1.3 2002/09/02 20:41:55 gosha Exp $
#
# Copyright (C)  Okunev Igor gosha@prv.mts-nn.ru 2002
#
########################################################################
use strict;

use Getopt::Long;
use Net::SC 1.11;
use Symbol;

sub main {
	my ( $rc, $sh, $self, $sh1, $child );
	my ( $port, $host, %opt, $sym );
	
	GetOptions( \%opt,	'rnd!'	,	# RANDOM
						'l=i'	,	# CHAIN_LEN
						'd:i'	,	# DEBUG
						'to=i'	,	# TIME OUT
						't=s'	,	# TARGET
						'lf=s'	,	# LOG_FILE
					);
	
	$self = new Net::SC(TIMEOUT			=> ( $opt{'to'}  || 10		),
						CHAIN_LEN		=> ( $opt{'l'}   || 2		),
						DEBUG			=> ( $opt{'d'}   || 0x04	),
						LOG_FILE		=> ( $opt{'lf'}  || undef	),
						RANDOM_CHAIN	=> ( $opt{'rnd'} || 0		),

						AUTO_SAVE		=> 1
					) || die;
	
	die unless ref $self;
	
	if ( defined $ENV{SC_CONF} ) {
		$self->configure( CHAIN_FILE => $ENV{SC_CONF} );
	}
    
	if ( $opt{'t'} =~ m#^([^:\s/]+)(?::(\d+))?$# ) {
		( $host, $port ) = ( $1, ( $2 || 0) );
	} else {
		( $host, $port ) = ( 'localhost', 0 );
	}
	
	unless ( ( $rc = $self->bind( $host, $port ) ) == SOCKS_OKAY ) {
		print STDERR "Can't bind socket [".( socks_error($rc) )."]\n";
		exit;
	}
	
	print "Binding the port : ", $self->socks_param('listen_port'), "\n";
	print "     in the addr : ", $self->socks_param('listen_addr'), "\n";
	print "     for $host\n";
	
	$self->configure(TIMEOUT => 45);
	unless ( ( $rc = $self->accept() ) == SOCKS_OKAY ) {
		return $rc;
	}
	$self->configure(TIMEOUT => 30);
	$sh = $self->sh;
	
	print 'Connect from: ', $self->socks_param('listen_addr'),':',
							$self->socks_param('listen_port'), "\n";
	
	print $sh 'Hello : ', $self->socks_param('listen_addr'), "\n";
	print $sh ' port : ', $self->socks_param('listen_port'), "\n";
	print $sh '> ';
	
	if ( fork ) {
		while ( <$sh> ) {
			print "> $_";
		}
	} else {
		while ( <STDIN> ) {
			( print $sh "> $_" ) || last;
		}
	}
	shutdown( $sh, 2 );

	return SOCKS_OKAY;
}

unless ( scalar @ARGV ) {
	print <<END_HELP;

    Usage $0 \%OPTIONS\%

    OPTIONS :
            -rnd     - Create random chain
            -l   XX  - Create chin of XX length
            -d   XX  - Debug on
            -to  XX  - Set timeout to XX for create chain
            -lf  XX  - Dump log to XX file
            -t   XX  - Destination host ( host[:port] )
END_HELP
}

print socks_error( main() ), "\n";


