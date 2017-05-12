#!/usr/local/bin/perl

package Stem::Debug ;

use strict ;
use Data::Dumper ;
use Scalar::Util qw( openhandle ) ;

use base 'Exporter' ;
our @EXPORT_OK = qw ( dump_data dump_socket dump_owner ) ;

sub dump_data {

	my( $data ) = @_ ;

	local $Data::Dumper::Sortkeys = \&dump_filter ;

	return Dumper $data ;
}

sub dump_filter {

	my( $href ) = @_ ;

	my @keys ;

	my %fh_dumps ;

	while( my( $key, $val ) = each %{$href} ) {

		if( my $fh_val = dump_socket( $val ) ) {

			my $fh_key = "$key.FH" ;
			$fh_dumps{$fh_key} = $fh_val ;
			push @keys, $fh_key ;
			next ;
		}

		push @keys, $key ;
	}

	@{$href}{ keys %{fh_dumps} } = values %{fh_dumps} ;

#print "KEYS [@keys]\n" ;

	return [ sort @keys ] ;
}

sub dump_socket {

	my ( $sock ) = @_ ;

	return 'UNDEF' unless defined $sock ;
	return 'EMPTY' unless $sock ;
	return 'NOT REF' unless ref $sock ;

	return 'NOT GLOB' unless $sock =~ /GLOB/ ;

warn "SOCK [$sock]\n" ;

	my $fdnum = fileno( $sock ) ;

	return 'NO FD' unless defined $fdnum ;

	my $opened = openhandle( $sock ) ? 'OPEN' : 'CLOSED' ;

#	return "CLOSED $sock" if $opened eq 'CLOSED' ;

#	$fdnum = 'NONE' unless defined $fdnum ;

#	my $fdnum = "FOO" ;

#	return "FD [$fdnum]" unless $sock->isa('IO::Socket') ;

	return "FD [$fdnum] *$opened*   $sock" ;
}



sub dump_owner {

	my ( $owner ) = @_ ;

	my $owner_dump = "$owner" ;

	while( $owner->{object} ) {

		$owner = $owner->{object} ;
		$owner_dump .= " -> $owner " ;
	}

	return $owner_dump ;
}

1 ;
