use 5.010000;
use warnings;
use strict;
use Test::More tests => 1;

use Time::Piece;
my $t = localtime;
my $this_year = $t->year;

my @files = (
    'README',
    'LICENSE',
    'lib/Term/Choose/Util.pm',
);

my $author = 'Matth..?us Kiem';

my $error = 0;
my $diag  = '';
for my $file ( @files ) {
    open my $fh, '<', $file or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /copyright \(c\) .*$author/i ) {
            if ( $line !~ /copyright \(c\) 20\d\d-\Q$this_year\E /i && $line !~ /copyright \(c\) \Q$this_year\E /i ) {
                $diag .= sprintf( "%15s - line %d: %s\n", $file, $., $line );
                $error++;
            }
        }
    }
    close $fh;
}




ok( $error == 0, "Copyright year" ) or diag( $diag );
diag( "\n" );

