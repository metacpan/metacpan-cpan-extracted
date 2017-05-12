#!/usr/bin/perl
use strict;
use warnings;

my ( $fa, $fb, $dst_f ) = @ARGV;

open my $fha, '<', $fa;
chomp( my $ahead = <$fha> );
$ahead =~ s#^.+?,.+?,##;
open my $fhb, '<', $fb;
chomp( my $bhead = <$fhb> );
$bhead =~ s#^.+?,.+?,##;

my ( $a_s, $a_e, $ad ) = read_line( $fha );
my $null_ad = get_null_s( $ad );
my ( $b_s, $b_e, $bd ) = read_line( $fhb );
my $null_bd = get_null_s( $bd );

open my $fhw, '>', $dst_f;
print $fhw join( ",", 's', 'e', $ahead, $bhead ), "\n";
while ( $a_s and $b_s ) {
  if ( $b_e < $a_s ) {
    print $fhw join( ",", $b_s, $b_e, $null_ad, $bd ), "\n";
    $b_s = $b_e + 1;
  } elsif ( $b_s < $a_s ) {
    print $fhw join( ",", $b_s, $a_s - 1, $null_ad, $bd ), "\n";
    $b_s = $a_s;
  } elsif ( $b_s > $a_e ) {
    print $fhw join( ",", $a_s, $a_e, $ad, $null_bd ), "\n";
    $a_s = $a_e + 1;
  } elsif ( $b_s > $a_s ) {
    print $fhw join( ",", $a_s, $b_s - 1, $ad, $null_bd ), "\n";
    $a_s = $b_s;
  } elsif ( $b_e <= $a_e ) {
    print $fhw join( ",", $b_s, $b_e, $ad, $bd ), "\n";
    $b_s = $b_e + 1;
    $a_s = $b_e + 1;
  } else {
    print $fhw join( ",", $b_s, $a_e, $ad, $bd ), "\n";
    $a_s = $a_e + 1;
    $b_s = $a_e + 1;
  }

  if ( $a_s > $a_e ) {
    ( $a_s, $a_e, $ad ) = read_line( $fha );
  }

  if ( $b_s > $b_e ) {
    ( $b_s, $b_e, $bd ) = read_line( $fhb );
  }
} ## end while ( $a_s and $b_s )

while ( $a_s ) {
  print $fhw join( ",", $a_s, $a_e, $ad, $null_bd ), "\n";
  ( $a_s, $a_e, $ad ) = read_line( $fha );
}

while ( $b_s ) {
  print $fhw join( ",", $b_s, $b_e, $null_ad, $bd ), "\n";
  ( $b_s, $b_e, $bd ) = read_line( $fhb );
}

close $fhw;

sub get_null_s {
  my ( $h ) = @_;
  my @head = map { "" } ( split /,/, $h, -1 );
  my $null_s = join( ",", @head );
}

sub read_line {
  my ( $fhr ) = @_;
  my $c = <$fhr>;
  return unless ( $c );
  chomp( $c );
  my ( $s, $e, $d ) = $c =~ m#^(.+?),(.+?),(.*)$#;
  $d ||= '';
  return ( $s, $e, $d );
}
