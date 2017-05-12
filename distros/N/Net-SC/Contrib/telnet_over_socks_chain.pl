#!/usr/bin/perl -w
########################################################################
#
# $Id: telnet_over_socks_chain.pl,v 1.10 2004/03/27 12:31:04 gosha Exp $
#
# Copyright (C)  Okunev Igor gosha@prv.mts-nn.ru 2002-2004
#
########################################################################
use strict;

use Getopt::Long;
use IO::Socket;
use Net::SC 1.11;
use Symbol;

sub main {
	my ( $rc, $sh, $socks_c, $socket, $sh1, $child );
	my ( $local_port, $local_host, $port, $host, %opt, $sym );

	GetOptions( \%opt,	'rnd!'	,	# Random
						'as!'	,	# Auto_save
						'l=i'	,	# Chain_len
						'd:i'	,	# Debug
						'to=i'	,	# Time out
						'lf=s'	,	# Log_file
						't=s'	,	# Target
						'cd=i'	,	# Check_delay
						'asc!'	,	# Asc command name for exec
						'if=s'	,	# Read command name for exec from file
						'cmd=s',	# Command name for exec
						'cfg=s',	# Configuration file
						'lo=i',		# Loop connection flag
					);
	
    $socket = IO::Socket::INET->new(
				Listen      => 3,
				Proto       => 'tcp',
				Timeout     => $opt{ 'to' } || 30,
				Type        => IO::Socket::SOCK_STREAM
			) || die $!;

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

	$local_port	= $socket->sockport();
	$local_host = $socket->sockhost();

	if ( fork ) {
		alarm 30;
		LOOP: {
			$sh = $socket->accept();
			unless ( defined $sh ) {
				die $!
			}
			if ( $sh->peerhost() ne $local_host and $sh->peerhost() ne '127.0.0.1' ) {
				print $sh "Accsess deny\n";
				print STDERR "Accsess deny [ ". $sh->peerhost ." ]\n";
				$sh->close;
				redo LOOP;
			}
		}
		alarm 0;
		print STDERR "\nConnect to $host:$port - please wait....\n";
		unless ( ( $rc = $socks_c->connect( $host, $port ) ) == SOCKS_OKAY ) {
			print STDERR "\nCan't connect to $host:$port [".( socks_error($rc) )."]\n";
			shutdown $sh, 2;
			exit;
		}
		print STDERR "\nConnect to $host:$port - Ok\n";
		$sh1 = $socks_c->sh;
		if ( fork ) {
			select((select($sh1), $| = 1)[0]);
			while ( read( $sh, $_, 1 ) ) { print $sh1 $_ }
		} else {
			select((select($sh), $| = 1)[0]);
			while ( read( $sh1, $_, 1 ) ) { print $sh $_ }
		}
		shutdown $sh, 2;
		shutdown $sh1, 2;
	} else {
		sleep(1);
		if ( $opt{'asc'} ) {
			if ( -t STDIN ) {
				print STDERR "Enter command : ";
			}
			undef $/; $_ = <STDIN>; $/ = "\n";
			s#\%PORT\%#$local_port#gs;
			exec( $_ );
		} elsif ( $opt{'cmd'} ) {
			( $_ = $opt{'cmd'} ) =~ s#\%PORT\%#$local_port#gs;
			exec( $_ );
		} elsif ( $opt{'if'} && -e $opt{'if'} ) {
			$sym = gensym;
			open ( $sym, '<' . $opt{'if'} ) || die "Can't open data file: $!\n";
			undef $/; $_ = <$sym>; $/ = "\n";
			s#\%PORT\%#$local_port#gs;
			exec( $_ );
		} else {
			exec( '/usr/bin/telnet', 'localhost', $local_port );
		}
	}
}

unless ( scalar @ARGV ) {
	print <<END_HELP;

    Usage $0 \%OPTIONS\%

    OPTIONS :
            -rnd     - Create random chain
            -asc     - ASC Command name for exec
            -as      - No auto save socks data structure
            -cmd XX  - Command name for exec
            -cfg XX  - Configuration file
            -lo  XX  - Loop connection flag
            -l   XX  - Create chain of XX length
            -d   XX  - Debug on
            -to  XX  - Set timeout to XX for create chain
            -lf  XX  - Dump log to XX file
            -if  XX  - Read command for exec from file XX
            -cd  XX  - Delay for new checing Socks server ( in seconds )
            -t   XX  - Destination host ( host[:port] )
END_HELP
	exit;
}

main();

