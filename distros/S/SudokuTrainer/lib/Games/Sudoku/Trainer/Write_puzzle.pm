use strict;
use warnings;

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;    # cell objects		(1 .. 81)

#-----------------------------------------------------------------------
# IO routines for sudoku puzzles
#-----------------------------------------------------------------------

package
    Games::Sudoku::Trainer::Write_puzzle;

use version; our $VERSION = qv('0.01');    # PBP

# write the current state of the sudoku puzzle
#	write_result($outfile);
#
sub write_result {
    my $outfile = shift;

    # placeholder for unknown digits in sudoku output files
    my $unknown_digit = '-';
    my @alldigits = map( {
            my $value = $_->Value;
              $value ? $value : $unknown_digit
    } @cells[ 1 .. 81 ] );
    _write_puzzle( $outfile, \@alldigits );
    return;
}

# write the initial state of the sudoku puzzle
#	write_initial($outfile);
#
sub write_initial {
    my $outfile = shift;

    my $gamestring = Games::Sudoku::Trainer::Run::initial_puzzle();
    $gamestring =~ tr/[1-9]/-/c;    # convert all placeholders to '-'
    _write_puzzle( $outfile, [ split( '', $gamestring ) ] );
    return;
}

# write a sudoku puzzle
#	_write_puzzle($outfile, ref_to_chars_array);
#
sub _write_puzzle {
    my ( $outfile, $puzzle_chars_ref ) = @_;

    open( my $out, '>', $outfile )  or  do {
	  Run::user_err("Cannot open $outfile:\n$!");
	  return;
	};
    for ( my $pos = 0 ; $pos < $#$puzzle_chars_ref ; $pos += 9 ) {

        # for better human readability
        if ( $pos > 0 and $pos % 27 == 0 ) { print $out "\n" }
        printf $out "%s%s%s %s%s%s %s%s%s\n",
          ( @$puzzle_chars_ref[ $pos .. $pos + 8 ] );
    }
    close($out) or die "9\nCannot close $outfile: $!\n";
    return;
}

1;
