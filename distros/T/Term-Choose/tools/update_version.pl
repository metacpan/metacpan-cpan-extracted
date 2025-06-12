#!/usr/bin/env perl
use warnings;
use 5.10.1;
use File::Find;
use File::Copy qw(move);
use File::Temp qw(tempfile);

use FindBin;



my $old = '1.774';
my $new = '1.775';
 
my $pattern_our = qr/^our \$VERSION = '\Q$old\E';/;
my $replacement_our = "our \$VERSION = '$new';";


my $pattern_pod = qr/^Version \Q$old\E(?=$)/;
my $replacement_pod = "Version $new";



my $directory = "$FindBin::Bin/../lib";

find( \&wanted, $directory );

sub wanted {
    return unless -f;
    return unless /\.pm\z/;
    my $file = $File::Find::name;
    my $changed = 0;
    my ( $out, $tempfile ) = tempfile();
    open my $in, '<', $file or die "$file: $!";

    while ( my $line = <$in> ) {
        if ( $line =~ $pattern_our ) {
            $line =~ s/$pattern_our/$replacement_our/;
            $changed = 1;
        }
        if ( $changed && $line =~ $pattern_pod ) {
            $line =~ s/$pattern_pod/$replacement_pod/;
        }
        print $out $line;
    }
    close $in;
    close $out;

    if ( $changed ) {
        move( $tempfile, $file ) or die "Can't overwrite $file: $!";
        say "Updated: $file";
    } 
    else {
        unlink $tempfile;
    }
}
