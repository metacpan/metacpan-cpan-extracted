#!/usr/bin/perl -w
########################################################################
#
# $Id: over_inetd.pl,v 1.1 2004/09/24 08:17:02 gosha Exp $
#
# Copyright (C)  Okunev Igor gosha@prv.mts-nn.ru 2002-2004
#
########################################################################
use strict;

use Getopt::Long;
use Net::SC 1.11;
use Symbol;

close STDERR;

sub main {
	my ( $rc, $socks_c, $sh1, $child );
	my ( $local_port, $local_host, $port, $host, %opt, $sym );

	GetOptions( \%opt,	'rnd!'	,	# Random
						'as!'	,	# Auto_save
						'l=i'	,	# Chain_len
						'd:i'	,	# Debug
						'to=i'	,	# Time out
						'lf=s'	,	# Log_file
						't=s'	,	# Target
						'cd=i'	,	# Check_delay
						'cfg=s',	# Configuration file
						'lo=i',		# Loop connection flag
					);
	
	$socks_c = Net::SC->new( 
								Timeout			=> ( $opt{'to'}  || 10		),
			                    Chain_Len		=> ( $opt{'l'}   || 2		),
            			        Debug			=> ( $opt{'d'}   || 0x09	),
			                    Log_File		=> ( $opt{'lf'}  || undef	),
			                    Check_Delay		=> ( $opt{'cd'}  || 3600 * 24),
			                    Random_Chain	=> ( $opt{'rnd'} || 0		),
								Auto_Save		=> ( $opt{'as'}  ?  0:1		),
								Loop_Connection	=> ( $opt{'lo'}  || 0x03	),
						) || die;

	die unless ref $socks_c;

	if ( exists $opt{'cfg'} and defined $opt{'cfg'} ) {
		$socks_c->configure( Chain_file => $opt{'cfg'} );
	} elsif ( exists $ENV{SC_CONF} and defined $ENV{SC_CONF} ) {
		$socks_c->configure( Chain_file => $ENV{SC_CONF} );
	}

	if ( $opt{'t'} =~ m#^([^:\s/]+)(?::(\d+))?$# ) {
		( $host, $port ) = ( $1, ( $2 || 23) );
	} else {
		( $host, $port ) = ( 'localhost', 23 );
	}

#	print STDERR "\nConnect to $host:$port - please wait....\n";

	unless ( ( $rc = $socks_c->connect( $host, $port ) ) == SOCKS_OKAY ) {
#		print STDERR "\nCan't connect to $host:$port [".( socks_error($rc) )."]\n";
		exit;
	}
	
#	print STDERR "\nConnect to $host:$port - Ok\n";
	
	$sh1 = $socks_c->sh;
	
	if ( fork ) {
		select((select($sh1), $| = 1)[0]);
		while ( read( STDIN, $_, 1 ) ) { print $sh1 $_ }
	} else {
		select((select(STDOUT), $| = 1)[0]);
		while ( read( $sh1, $_, 1 ) ) { print STDOUT $_ }
	}
	shutdown $sh1, 2;
}

main();

