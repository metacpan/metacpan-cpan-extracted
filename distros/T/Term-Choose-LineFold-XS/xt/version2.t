use 5.16.0;
use strict;
use warnings;
use Time::Piece;
use Test::More tests => 3;



my $v = -1;
my $v_pod = -1;
open my $fh, '<', 'lib/Term/Choose/LineFold/XS.pm' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^our\s\$VERSION\s=\s'(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v = $1;
    }
    if ( $line =~ /^=pod/ .. $line =~ /^=cut/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $v_pod = $1;
        }
    }
}
close $fh;
is( $v, $v_pod, 'Version in POD Term::Choose::LineFold::XS OK' );




my $release_date = -1;
my $v_changes = -1;

open my $fh_ch, '<', 'Changes' or die $!;
while ( my $line = <$fh_ch> ) {
    if ( $line =~ /^\s*(\d+\.\d\d\d(?:_\d\d)?)\s+(\d\d\d\d-\d\d-\d\d)\s*\z/ ) {
        $v_changes = $1;
        $release_date = $2;
        last;
    }
}
close $fh_ch;
is( $v, $v_changes, 'Version in "Changes" OK' );




my $t = localtime;
my $today = $t->ymd;
is( $release_date, $today, 'Release date in Changes is date from today' );
