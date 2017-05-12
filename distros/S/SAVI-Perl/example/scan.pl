#!/usr/local/bin/perl -w

use SAVI;
use strict;

my $savi = new SAVI();

ref $savi or print "Error initializing savi: " . SAVI->error_string($savi) . " ($savi)\n" and die;

my $version = $savi->version();

ref $version or print "Error getting version: " . $savi->error_string($version) . " ($version)\n" and die;

printf("Version %s (engine %d.%d) recognizing %d viruses\n", $version->string, $version->major,
       $version->minor, $version->count);

foreach ($version->ide_list) {
    printf("\tIDE %s released %s\n", $_->name, $_->date);
}

set_options();

print "\n";

foreach (@ARGV) {
    print "Scanning $_ - ";
    
    my $results = $savi->scan($_);
    ref $results or print "error: " . $savi->error_string($results) . " ($results)\n" and next;
    
    print "clean\n" and next if ! $results->infected;

    print "infected by";
    
    foreach ($results->viruses) {
	print " $_";
    }
    print "\n";
}

sub set_options {

    my @options = qw(
	GrpArchiveUnpack GrpSelfExtract GrpExecutable GrpInternet GrpMSOffice
        GrpMisc !GrpDisinfect !GrpClean
        EnableAutoStop FullSweep FullPdf Xml
      );


    my $error = $savi->set('MaxRecursionDepth', 32);
    defined($error) and print "Error setting MaxRecursionDepth: " . $savi->error_string($error) . " ($error)\n";

    foreach (@options) {
        my $value = ($_ =~ s/^!//) ? 0 : 1;

        $error = $savi->set($_, $value);
	defined($error) and print "Error setting $_: " . $savi->error_string($error) . " ($error)\n";
    }
}
