#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib  ../lib};

use Net::OBEX::FTP;
use File::Spec;
use Data::Dumper;

my $obex = Net::OBEX::FTP->new;

my $response = $obex->connect( address => '00:17:E3:37:76:BB', port => 9 )
    or die "Error: " . $obex->error;
print Dumper($response);
print "Mirroring root folder\n";

mirror_file( $obex, $_ )
    for @{ $obex->files };

mirror( $obex );

sub mirror {
    my $obex = shift;

    for my $folder ( @{ $obex->folders } ) {
        print "Mirroring `$folder`\n";

        $response = $obex->cwd( path => $folder )
            or die "Error: " . $obex->error;

        my $local_folder = File::Spec->catdir( @{ $obex->pwd } );
        mkdir $local_folder
            or die "Failed to create directory `$local_folder` ($!)";

        if ( @{ $obex->folders } ) {
            mirror( $obex );
        }

        mirror_file( $obex, $_ )
            for @{ $obex->files };

        $response = $obex->cwd( do_up => 1 )
        or die "Error: " . $obex->error;
    }
}

sub mirror_file {
    my ( $obex, $file ) = @_;
    printf "Mirroring %s\n\tsize is: %d bytes\n",
                $file, $obex->xml->size( $file );

    my $local_file = File::Spec->catfile( @{ $obex->pwd }, $file );
    open my $fh, '>', $local_file
        or die "Failed to open $local_file: $!";
    binmode $fh;

    $obex->get( $file, $fh )
        or die "Failed to get file $file: " . $obex->error;
    close $fh;
}