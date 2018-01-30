#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::CheckManifest;
use IO::File;
use File::Basename;
use File::Spec;

SKIP: {
    skip 'Test not needed on Windows', 1 if $^O =~ /Win32/;

    {
        my $dir = dirname( File::Spec->rel2abs( __FILE__ ) );

        # create file
        my $fh_manifest = IO::File->new( $dir . '/MANIFEST', 'w' );
        $fh_manifest->print( $_ . "\n" ) for (qw/MANIFEST A.txt B.txt 02_issue1.t 03_issue7.t/);
        $fh_manifest->close or die $!;
        
        # create file
        my $fh = IO::File->new( $dir . '/A.txt', 'w' );
        $fh->print( scalar localtime ) or die $!;
        $fh->close or die $!;
        
        # create symlink
        eval { symlink $dir . '/A.txt', $dir . '/B.txt' };

        ok_manifest({ dir => $dir });
    }

}
