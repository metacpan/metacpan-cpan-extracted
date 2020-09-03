#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Fcntl ':mode';
use JSON::PP 'decode_json';

exit(0) unless -f 'MYMETA.json';

sub cat {
    my $file = shift;
    local $/;
    my $f;
    open( $f, '<', $file ) or die "Cannot open '$file': $!\n";
    my $output = readline($f);
    close($f);
    return $output;
}

my $version = decode_json( cat('MYMETA.json') )->{version};
die "Version not found in MYMETA.json\n" unless $version;
$version =~ s/^v//;
die "Invalid version string '$version'\n" unless $version =~ m/^[0-9.]+$/s;

foreach ( "Syntax-SourceHighlight-$version", 'blib' ) {
    my $libdir = "$_/lib/Syntax";
    foreach my $mfile ( glob("$libdir/*.pm $libdir/SourceHighlight/*.pm") ) {
        my $mode   = ( stat($mfile) )[2];
        my $module = cat($mfile);
        if ( $module =~ m/^our \$VERSION/m ) {
            print("    $mfile (skipping)\n");
            last;
        }
        print("    $mfile\n");
        $module =~ s/^
            (package\s+[a-z0-9_:]+\s*;\s*\n+use.*?\n\n)
            /$1our \$VERSION = '$version';\n\n/isx;
        chmod( $mode | S_IWUSR, $mfile );
        my $f;
        open( $f, '>', $mfile ) or die "Cannot open '$mfile': $!\n";
        print( $f $module );
        close($f);
        chmod( $mode, $mfile );
    }
}
