#!/usr/bin/perl
########################################################################
#
# $Id: http_over_socks_chain.pl,v 1.5 2002/09/02 20:57:28 gosha Exp $
#
# Copyright (C)  Okunev Igor gosha@prv.mts-nn.ru 2002
#
########################################################################

#======================================================================#
# Old style for Net::SC v 1.10                                         #
#======================================================================#

use strict;
use Net::SC;
use Getopt::Long;

sub main {
	my ( $rc, $sh, $host, $port, $doc, $self, $data );
	my %opt;
	
	GetOptions( \%opt,	'rnd!'	,	# RANDOM
						'l=i'	,	# CHAIN_LEN
						'd:i'	,	# DEBUG
						'to=i'	,	# TIME OUT
						'lf=s'	,	# LOG_FILE
						't=s'	,	# TARGET
						'type=s' );	# REQUEST TYPE ( GET | POST ... )

	unless ( defined $opt{'t'} ) {
		print STDERR "Target not defined...\n";
		return SOCKS_FAILED;
	}
	
	$self = Net::SC->new(TIMEOUT			=> ( $opt{'to'}  || 10		),
						CHAIN_LEN		=> ( $opt{'l'}   || 2		),
						DEBUG			=> ( $opt{'d'}   || 0x01	),
						LOG_FILE		=> ( $opt{'lf'}  || undef	),
						RANDOM_CHAIN	=> ( $opt{'rnd'} || 0		),
					);
	
	die unless ref $self;

	unless ( ( $rc = $self->read_chain_data() ) == SOCKS_OKAY ) {
		warn( 'ERROR: ' . ( socks_error($rc) ), "\n" );
		return $rc;
	}
	
    if ( $opt{'t'} =~ m#^([^:\s/]+)(?::(\d+))?(/.*?)?\s*$# ) {
		( $host, $port, $doc ) = ( $1, ( $2 || 80), ( $3 || '/index.html' ) );
	} else {
		print STDERR "Unsupport url scheme...\n";
		return SOCKS_FAILED;
	}
	
	unless ( ( $rc = $self->create_chain( $host, $port, 1 ) ) == SOCKS_OKAY ) {
		warn ( 'ERROR: ' . socks_error($rc) . "\n" );
		return $rc;
	} elsif ( $sh = $self->{sock_h} ) {
		if (	exists $opt{'type'} &&
				defined $opt{'type'} &&
				$opt{'type'} !~ /^GET$/i ) {
			print $sh $opt{'type'}," $doc HTTP/1.0\n";
		} else {
			print $sh "GET $doc HTTP/1.0\n";
		}
		unless ( -t STDIN ) {
			print $sh $_ while <STDIN>;
		} else {
			print $sh "Host: $host\n";
			print $sh "Referer: $host/$doc\n\n";
		}
		{
			$rc = $self->read_data( $sh , \*STDOUT, 1 );
			if ( $rc == 0 ) {
				print STDERR "Timeout. Connection lost...\n";
			} elsif ( $rc > 0 ) {
				redo;
			}
		}
		return SOCKS_OKAY;
	} else {
		return SOCKS_FAILED;
	}
}

main( );

