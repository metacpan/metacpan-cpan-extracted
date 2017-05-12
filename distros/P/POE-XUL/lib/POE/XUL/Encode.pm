package POE::XUL::Encode;
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

#
# This was an attempt at a faster binary format for transmitting data
# to the browser.  But JavaScript fails when it comes to binary formats
# so JSON is used
#

use strict;
use warnings;

use Encode ();
sub content_type { return "application/vnd.poe-xul" }

my $utf8 = Encode::find_encoding( "utf-8" );

our $VERSION = '0.0601';

my $ETB = "\x17";       # HASH/ARRAY end
my $FS = "\x1C";        # field sep
my $GS = "\x1D";        # HASH begin
my $RS = "\x1E";        # record sep 
my $US = "\x1F";        # ARRAY begin

sub encode
{
    my( $package, $AofA ) = @_;
    my @ret;
    foreach my $A ( @$AofA ) {
        push @ret, join $FS, map { $package->encode_S( $_ ) } @$A;
    }
    return Encode::encode $utf8, join $RS,  @ret;
}

sub encode_S
{
    my( $package, $T ) = @_;
    my $r = ref $T;
    return $T unless $r;
    return $GS.join( $FS, %$T ).$ETB if 'HASH' eq $r;
    return $US.join( $FS, @$T ).$ETB if 'ARRAY' eq $r;
    return $T;
}

########## Following is deprecated because JS can't handle binary data
sub pack_S
{
    my( $package, $scalar ) = @_;
    my $s = '' . $scalar;
    return join '', $package->pack_number( length $s ), $s;
}

sub pack_AofS
{
    my( $package, $array ) = @_;
    $array ||= [];
    my @ret = $package->pack_number( 0+@$array );
    foreach my $el ( @$array ) {
        push @ret, $package->pack_S( $el );
    }
    return join '', @ret;
}

sub pack_AofA
{
    my( $package, $array ) = @_;
    $array ||= [];
    my @ret = $package->pack_number( 0+@$array );
    foreach my $el ( @$array ) {
        push @ret, $package->pack_AofS( $el );
    }
    return join '', @ret;
}

sub pack_number
{
    my( $package, $num ) = @_;
    if( $num < 255 ) {
        return pack "C", 0+$num;
    }
    else {
        return pack "CN", 255, 0+$num;
    }
}

1;
