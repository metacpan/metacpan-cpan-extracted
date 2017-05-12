#!/usr/bin/perl -w

use strict;
use warnings;

use CDB_File;
use LWP::Simple;
use Getopt::Long;
use Carp;

my $url  = 'http://www.ifast.org/files/SIDNumeric.htm';
my $tmpdir = "./";
my $file   = "./sid.cdb";
my $result = GetOptions (
    "url=s"  => \$url,
    "tmpdir=s" => \$tmpdir,
    "file=s"   => \$file,
);

# Create CDB file

my $tmpcdb = $tmpdir . "sid.tmp";
my $cdb = new CDB_File ($file, $tmpcdb) or die "Create failed: $!\n";
$cdb->insert( '00000', 'Reserved (not to be assigned)' );

# Parse data URL

my $cont = get($url);

while ( $cont =~ />(\d+)\sto\s(\d+)<(?:\/a>|td).+?<td\swidth="60%">(.+?)</g ) {
    my ( $rng_st, $rng_ed, $name ) = ( $1, $2, $3 );
    my $cntr = $rng_st;    

    $name =~ s/\s+$//;

    while ( $cntr <= $rng_ed ) {
        my $key = sprintf( "%05d", $cntr );
        if ( $cntr % 1000 == 0 && $cntr + 999 <= $rng_ed ) {
            $key = sprintf( "%02d", int( $cntr / 1000 )) . "XXX";
            $cntr += 1000;
        } elsif ( $cntr % 100 == 0 && $cntr + 99 <= $rng_ed ) {
            $key = sprintf( "%03d", int( $cntr / 100 )) . "XX";
            $cntr += 100;
        } elsif ( $cntr % 10 == 0 && $cntr + 9 <= $rng_ed ) {
            $key = sprintf( "%04d", int( $cntr / 10 )) . "X";
            $cntr += 10;
        } else {
            $cntr++;
        }
        $cdb->insert( $key, $name );
    }
}
$cdb->finish or die "$0: CDB_File finish failed: $!\n";

__END__
