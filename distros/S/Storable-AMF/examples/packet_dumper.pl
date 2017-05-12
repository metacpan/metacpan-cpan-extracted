#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  amf.pl
#
#        USAGE:  ./amf.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/06/2011 11:20:55 AM
#     REVISION:  ---
#===============================================================================

use strict;
use Data::Dumper;
use Storable::AMF 0.94;


if ( @ARGV ){
	for my $file ( @ARGV ){
		main( $file );
	}
}
else {
	for my $file ( 'input','amf_result3', 'amf_packet1', 'amf_packet2'  ){
		main( $file );
		last;
	}
}

sub main {
    my ( $amf_packet_file, $buf, $obj, $psize ) = ($_[0]);
	print STDERR "Reading file $amf_packet_file\n";

    open AMF, $amf_packet_file or die;
    binmode AMF;
    read( AMF, $buf, 32768 ) or die;
    close AMF or die;
	my $offset = 0;

    while ( length $buf ) {

        #($obj, $psize) = Storable::AMF3::deparse_amf($buf);
        ( $obj, $psize ) = eval { deparse_packet($buf) };
        if ( !ref($obj) || $@ ) {
            printf( "Skipped: 0x%02X (1 byte)\n", ord($buf) );
			if ( $@ ){
	            $buf =~ s/.//s if $@;
				++$offset;
			}
        }
        else {
			print "offset=$offset\n";
            print Dumper($obj);
        }
		substr $buf, 0, $psize, '' and $offset +=$psize if !$@;
    }
}

sub deparse_packet {
    my $buf = shift;
	my $start_len = length $buf;
	
	my $raise_error = Storable::AMF0::parse_option('raise_error');
        my $class = {};

        $class->{'headers'} = [];
        $class->{'bodies'}  = [];

        my $sent_encoding = unpack 'n', ( substr $buf, 0, 2, '' );
		die "wrong encoding" if $sent_encoding>3 or $sent_encoding < 0;

        $class->{encoding} = ( $sent_encoding != 0 and $sent_encoding != 3 ) ? 0 : $sent_encoding;

        my $totalHeaders = unpack( 'n', substr $buf, 0, 2, '' );
        for ( my $i = 0 ; $i < $totalHeaders ; $i++ ) {
            my $header = {};

            my $strLen = unpack( 'n', substr $buf, 0, 2, '' );
            $header->{name} = substr( $buf, 0, $strLen, '' );
            $header->{required} = ord( substr $buf, 0, 1, '' );

            # skiping length header'
            substr $buf, 0, 4, '';

            ( $header->{data}, my $length ) = Storable::AMF0::deparse_amf($buf, $raise_error);
            substr $buf, 0, $length, '';
            push @{ $class->{headers} }, $header;
        }

        my $totalBodies = unpack( 'n', substr $buf, 0, 2, '' );
        for ( my $i = 0 ; $i < $totalBodies ; $i++ ) {
            my $body = {};

            for ( 'target', 'response' ) {
                my $strLen = unpack( 'n', substr $buf, 0, 2, '' );
                $body->{$_} = substr $buf, 0, $strLen, '';
            }
            substr $buf, 0, 4, '';    # skip length

#print STDERR Dumper( $class, $totalBodies, $body, ord $buf, Storable::AMF0::deparse_amf($buf, $raise_error ));exit;
            if ( ord $buf == 10 ) {
                substr $buf, 0, 1, '';
                my $num = unpack "N", substr $buf, 0, 4, '';
                $body->{data} = [];

                for my $j ( 1 .. $num ) {
                    ( my $obj, my $length ) = Storable::AMF0::deparse_amf($buf, $raise_error);
                    substr $buf, 0, $length, '';
                    push @{ $body->{data} }, $obj;
                }
            }
            else {

                # I am not sure for need of this branches
                # and I think it need to be replaced with
                # only  Storable::AMF0::deparse_amf($buf)
                my ( $obj, $length ) =
                  ( $class->{encoding} == 0 )
                  ? Storable::AMF0::deparse_amf($buf, $raise_error)
                  : Storable::AMF0::deparse_amf($buf, $raise_error);
                substr $buf, 0, $length, '';
                $body->{data} = $obj;
            }
            push @{ $class->{bodies} }, $body;
        }

        return ( $class, $start_len - length $buf );
}


