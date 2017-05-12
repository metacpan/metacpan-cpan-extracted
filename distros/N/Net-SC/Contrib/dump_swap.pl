#!/usr/bin/perl -w
########################################################################
#
# $Id: dump_swap.pl,v 1.1 2002/09/02 21:02:36 gosha Exp $
#
# Copyright (C)  Okunev Igor gosha@prv.mts-nn.ru 2002
#
########################################################################
use strict;
use Net::SC;

sub main {
	my ( $rc, $sc, $conf, $hash_ref );
	
	$conf = {	
				DEBUG			=> 0,
				LOG_FILE		=> undef
			};
	
	if ( defined $ENV{SC_CONF} ) {
		$conf->{CHAIN_FILE} = $ENV{SC_CONF};
	}
	
	$sc = Net::SC->new( %$conf );
	
	die unless ref $sc;
	
	if ( scalar @ARGV and defined $ARGV[0] and $ARGV[0] eq 'load' ) {
		$sc->{CFG_CHAIN_DATA} = [];
		while ( $_ = <STDIN> ) {
			chomp;
			push @{$sc->configure( 'CHAIN_DATA' )}, { $sc->dump_cfg_filter( split(/ : /, $_) ) };
		}
		if ( scalar @{$sc->configure( 'CHAIN_DATA' )} ) {
			$rc = $sc->dump_cfg_data();
		}
	} else {
		unless ( ( $rc = $sc->read_chain_data() ) == SOCKS_OKAY ) {
			exit;
		}
		if ( -e $sc->configure('CHAIN_FILE') . '.db' ) {
			$rc = $sc->restore_cfg_data();
		}
		if ( $rc == SOCKS_OKAY )  {
			foreach $hash_ref ( @{$sc->configure( 'CHAIN_DATA' )} ) {
				print join( ' : ', $sc->dump_cfg_filter( map { $_ => $hash_ref->{$_} } sort { Net::SC::SOCKS_PARAM->{$a} <=> Net::SC::SOCKS_PARAM->{$b} } keys %$hash_ref ) ),"\n";
			}
		}
	}
	print STDERR socks_error( $rc ) , " [ $rc ] \n";
}

main();

