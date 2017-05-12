use strict;
use warnings;
#use feature 'say';

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;     # cell objects		(1 .. 81)
our @rows;      # row objects		(1 .. 9)
our @cols;      # col objects		(1 .. 9)
our @blocks;    # block objects		(1 .. 9)
our @units;     # all unit objects	(0 .. 26)  rows, columns, and blocks
our @lines;     # all line objects	(0 .. 17)  rows and columns

package
    Games::Sudoku::Trainer::Strategies;

use version; our $VERSION = qv('0.04');    # PBP

use List::Util;        # for first
use List::MoreUtils;   # for uniq and firstidx

# This is the priority loop. All supported strategies (exept Full house)
# are tried in turn in the sequence of their priorities, until one
# strategy is successful. The info about the found hit is returned as an
# anonymous array, which is then passed to module Found_info, which makes
# an object of it.
# Called from sub Run::_run_puzzle, the main loop of this program.
#
# At this step, strategy Full house (which has always highest priority) has
# already been tried. See sub full_house for details.

# Structure of the anonymous array returned by a successful strategy:
#   Each element is a ref to an array with 4 elements
#     0:   strategy name
#     1:   action ('insert' or 'exclude')
#     2:   ref to array of clues
#          clues are unit objects, cell objects, candidate ids (in any sequence)
#          clues are used by dialogs 'Show details' and 'History > Details'
#          candidate ids have the stucture "cell name" . '-' . "cand digit"
#     3:   ref to array of results
#          for action 'insert': (value, cell object)
#          for action 'exclude': each element has the structure
#          $cell->Cell_num . '-' . "cand digit"
#

sub try_strategies {
	# protect against problems
	# on an excessive strategy scan after solving a puzzle
	use List::Util qw(first);
#	my @candcells = grep {! $_->Value} @cells[1 .. 81];
	return unless grep {! $_->Value} @cells[1 .. 81];

    foreach
      my $strat_func ( @{ Games::Sudoku::Trainer::Priorities::strat_funcs_ref() } )
    {
        no strict 'refs';
        my $found_ref = &$strat_func();
        next unless $found_ref;

        Games::Sudoku::Trainer::Found_info->new($found_ref);
        return;
    }
    return;
}

sub _bivalue_universal_grave {
	my @candcells = grep {! $_->Value} @cells[1 .. 81];
	# protect against the confusing "not unique" message
	# on an excessive strategy scan after solving a puzzle
	return unless @candcells;

    my $cand3cell;
    foreach my $cell (@candcells) {
        next unless $cell;    # skip index 0
        my $cell_cands = $cell->Candidates;
        my $candcount  = length($cell_cands);
        return if $candcount > 3;
        if ( $candcount == 3 ) {
            return if $cand3cell;    # more than 1 cell with 3 cand.s
            $cand3cell = $cell;
        }
    }

    $cand3cell or die "1\nThis sudoku puzzle is not unique\n";
    my $cell_cands = $cand3cell->Candidates;
    my @cand3 = split( '', $cell_cands );
    foreach my $unit ( $cand3cell->get_Containers ) {
        foreach my $cand (@cand3) {
            if ( $unit->get_Cand_count($cand) == 3 ) {
                my @clues = ( $unit, $cell_cands, $cand3cell );
                my @result = ( $cand, $cand3cell );
                return [ 'Bivalue Universal Grave',
                    'insert', \@clues, \@result ];
            }
        }
    }
    return;
} ## end sub _bivalue_universal_grave

sub _bli_and_lbi {
    return _BLIandLBI('');
}

sub _block_line_interaction {
    return _BLIandLBI('Block-Line Interaction');
}

# The working horse for strats 'Block-Line Interaction',
# 'Line-Block Interaction', and 'BLI and LBI'
#   ($found_strat, $clues_ref, $exclude_ref) = _BLIandLBI($wanted_strat);
#      $wanted_strat: 'Block-Line Interaction', 'Line-Block Interaction' or ''
#      returns undef if $wanted_strat strategy given, but found the opposite
#
sub _BLIandLBI {
    my $wanted = shift;

    foreach my $block ( @blocks[ 1 .. 9 ] ) {
        my @members    = $block->get_Members;
        my $cell1      = $members[0];
        my $cell9      = $members[8];
        my @crosslines = (                      # all lines crossing this block
            @rows[ $cell1->Row_num .. $cell9->Row_num ],
            @cols[ $cell1->Col_num .. $cell9->Col_num ],
        );
        foreach my $line (@crosslines) {
            my @cross = $block->crosssection($line);    # the common cells
            foreach my $digit ( 1 .. 9 ) {
                my $block_cand = $block->get_Cand_count($digit);
                next if $block_cand < 2;
                my $line_cand = $line->get_Cand_count($digit);
                next if $line_cand < 2;

                # extract the cells with this digit
                # as candidate in the cross section
                my @have_cand = _cand_cells( $digit, @cross );
                my $have_cand = @have_cand;
                next if $have_cand < 2;
                my ( $hit_unit, $strat );
                next
                  unless (
                    $have_cand == $block_cand xor $have_cand == $line_cand );

                # we found a BLI or LBI; is it the wanted type?
                ( $hit_unit, $strat ) =
                  $have_cand == $block_cand
                  ? ( $line, 'Block-Line Interaction' )
                  : ( $block, 'Line-Block Interaction' );
                next if ( $wanted and $strat ne $wanted );    # sorry

                my @clues = ( $block, $line, $digit, @have_cand );
                my $exclude_ref =
                  _excl_cands_exept( $hit_unit, $digit, @have_cand );
                return [ $strat, 'exclude', \@clues, $exclude_ref ];
            }
        }
    } ## end foreach...
    return;
} ## end sub _BLIandLBI

# This is the only strategy that isn't called from the strategy loop
# (sub try_strategies). It is called from sub Run::_insert_presets and
# sub Trainer::_run_puzzle (the main loop of the Sudoku trainer).
#   full_house($cell);
#     $cell: The 3 container units of this cell are checked for full house
#
sub full_house {
    my $cell = shift;

    my %found_cells;
    my $digit;

    my @cell_containers = $cell->get_Containers;
    foreach my $unit (@cell_containers) {
        my @novalue_cells = $unit->active_Members;
        next unless ( @novalue_cells == 1 );
        my $novalue_cell = $novalue_cells[0];

        # ignore if value already found for this cell (in a prev. unit)
        next
          if exists $found_cells{ $novalue_cell };
        $found_cells{$novalue_cell}++;
        $digit = $novalue_cell->Candidates;
        $digit =~ /^[1-9]$/
          or die "3\nNo candidate found in cell ", $novalue_cell->Name,
          "\n ";
        my @result = ( $digit, $novalue_cell );
        my @clues  = ( $unit,  @result );
        my $found_ref = [ 'Full House', 'insert', \@clues, \@result ];
        my $found_obj = Games::Sudoku::Trainer::Found_info->new($found_ref);
    }
    return;
}

sub _hidden_pair {
    foreach my $unit (@units) {

        # collect all digits that are candidates in exactly 2 cells of this unit
        my @cand2 = grep { $unit->get_Cand_count($_) == 2 } ( 1 .. 9 );
        next if @cand2 < 2;

        # collect the 2 cells for each of those digits
        my @digit_info = map { [ $_, _cand_cells( $_, $unit, 2 ) ] } @cand2;

        # Look for 2 of those cells that have the same digits
        # No other digits are possible in this pair of cells
        foreach my $idx1 ( 0 .. $#digit_info - 1 ) {
            my $info1 = $digit_info[$idx1];
            foreach my $idx2 ( $idx1 + 1 .. $#digit_info ) {
                my $info2 = $digit_info[$idx2];
                next
                  if ( $info1->[1] != $info2->[1]
                    or $info1->[2] != $info2->[2] );

                # ignore if no candidates to exclude
                next
                  if (  $info1->[1]->cands_count == 2
                    and $info1->[2]->cands_count == 2 );

                # exclude all candidates of both cells except the 2 digits
                my $ok_digits = $info1->[0] . $info2->[0];
                my @exclude_info;
                foreach my $idx ( 1, 2 ) {
                    my $cands = $info1->[$idx]->Candidates;

                    # ignore if no candidates to exclude in this cell
                    next
                      if length($cands) == 2;
                    $cands = _chars_p1_notin_p2( $cands, $ok_digits );
                    push( @exclude_info, $info1->[$idx]->Cell_num . "-$cands" );
                }
                my @clues = ( $unit, $ok_digits, $info1->[1], $info1->[2] );
                return [ 'Hidden Pair', 'exclude', \@clues, \@exclude_info ];
            }
        }
    } ## end foreach...
    return;
} ## end sub _hidden_pair

sub _hidden_single {
    foreach my $unit (@units) {
        foreach my $digit ( 1 .. 9 ) {

            # check for hidden single
            next if ( $unit->get_Cand_count($digit) != 1 );

            # find last cell in this unit that can hold this digit
            my ($last_cell) = _cand_cells( $digit, $unit, 1 );
            my @result = ( $digit, $last_cell );
            my @clues  = ( $unit,  @result );
            return [ 'Hidden Single', 'insert', \@clues, \@result ];
        }
    }
    return;
}

sub _line_block_interaction {
    return _BLIandLBI('Line-Block Interaction');
}

sub _naked_pair {
    foreach my $unit (@units) {

        # collect all cells in this unit that have exactly 2 candidates
        my @all_pairs = _collect_2cands($unit);

        # Look for 2 of those cells that have the same candidates
        # These candidates can be excluded in all other cells
        while ( $#all_pairs > 0 ) {
            my ( $cell1, $cell1_2cands ) = @{ $all_pairs[0] };
            foreach my $i ( 1 .. $#all_pairs ) {
                my ( $cell2, $cell2_2cands ) = @{ $all_pairs[$i] };
                next if ( $cell1_2cands != $cell2_2cands );    # cands differ
                my $hitcands = $cell1_2cands;

                # is there something to exclude in this unit?
                next
                  if (  $unit->get_Cand_count( substr( $hitcands, 0, 1 ) ) == 2
                    and $unit->get_Cand_count( substr( $hitcands, 1, 1 ) ) ==
                    2 );

            # Are both cells in the same block? If so, we can settle them
            # here on the fly.
            # Otherwise they would get caught later by one (sometimes two) LBIs.
				my $unittype = ref $unit;
				$unittype =~ s/.*::(\w+)$/$1/;
                my $units_par =    # units-parameter for sub _excl_cands_exept
                  ( $unittype ne 'Block'
                      and $cell1->Block_num == $cell2->Block_num )
                  ? [ $unit, $blocks[ $cell1->Block_num ] ]
                  : $unit;
                my @clues = ( $unit, $hitcands, $cell1, $cell2 );
                my $exclude_ref =
                  _excl_cands_exept( $units_par, $hitcands,
                    ( $cell1, $cell2 ) );
                return [ 'Naked Pair', 'exclude', \@clues, $exclude_ref ];
            }
            shift @all_pairs;
        }
    } ## end foreach...
    return;
} ## end sub _naked_pair

sub _naked_single {
    foreach my $cell ( @cells[ 1 .. $#cells ] ) {
        my $cell_cand = $cell->Candidates;
        next if ( length($cell_cand) != 1 );
        my @result = ( $cell_cand, $cell );
        my @clues = @result;
        return [ 'Naked Single', 'insert', \@clues, \@result ];
    }
    return;
}

sub _skyscraper {
    my @line_infos;
    foreach my $digit ( 1 .. 9 ) {

        # collect all lines that have this digit as cand. in exactly 2 cells
        my @cand2_lines = _map_filtered( "\$_->get_Cand_count($digit) == 2",
            "[\$_, [_cand_cells( $digit, \$_, 2 )]]", @lines );
        next if @cand2_lines < 2;

        # for each of these lines add all infos that are needed
        # to find a skyscraper
        foreach my $cand_ref (@cand2_lines) {
            my (%line_info);
            $line_info{line}            = $cand_ref->[0];
            @line_info{qw/cella cellb/} = @{ $cand_ref->[1] };
            $line_info{digit}           = $digit;
            my $linetype = ref $line_info{line};
			$linetype =~ s/.*::(\w+)$/$1/;
            # the index of the cell in the containing row or column
            my $cell_idx = $linetype eq 'Row' ? 'Col_num' : 'Row_num';
            @line_info{qw/posa posb/} =
              map { $_->$cell_idx } ( @line_info{qw/cella cellb/} );
            push @line_infos, \%line_info;
        }
    }

    # search for 2 candidate lines that have exactly 1 of these cells
    # in the same position
    # these cells are the bottom cells of the skyscraper
    # the others are the roof cells - find them
    my ( %line1, %line2 );
    while ( my $cand_ref1 = shift @line_infos ) {
        %line1 = %$cand_ref1;
        my $digit = $line1{digit};
        foreach my $cand_ref2 (@line_infos) {
            %line2 = %$cand_ref2;
            next if ( $line2{digit} != $digit );    # need same digit
                                                    # need parallel lines
            next if ( ref $line1{line} ne ref $line2{line} );

            my $linetype = ref $line1{line};
			$linetype =~ s/.*::(\w+)$/$1/;
            # the index of the cell in the containing row or column
            my $cell_idx = $linetype eq 'Row' ? 'Col_num' : 'Row_num';

            use List::MoreUtils qw(uniq firstidx);
            my @allpos = ( @line1{qw/posa posb/}, @line2{qw/posa posb/} );
            my @uniqpos = uniq @allpos;
            next if @uniqpos != 3;

            # there are roof cells - find them
            my @roof_pos = _chars_notcommon( "$line1{posa}$line1{posb}",
                "$line2{posa}$line2{posb}" );
            my %pos_cells;
            @pos_cells{@allpos} =
              ( @line1{qw/cella cellb/}, @line2{qw/cella cellb/} );
            my @roof_cells = map { $pos_cells{$_} } @roof_pos;

            # collect all common siblings of the roof cells
            my @excl_cells = Games::Sudoku::Trainer::Cell->common_sibs(@roof_cells);
            next unless @excl_cells;    # no common siblings
                 # extract those siblings that have this digit as a cand.
            my @have_cand = _cand_cells( $digit, @excl_cells );
            next unless @have_cand;    # sorry - no cand.s to exclude

            my @clues = (
                $line1{line},  $line2{line},  $digit, $line1{cella},
                $line1{cellb}, $line2{cella}, $line2{cellb}
            );
            my @exclude_info =
              map { $_->Cell_num . "-$digit" } @have_cand;
            return [ 'Skyscraper', 'exclude', \@clues, \@exclude_info ];
        } ## end foreach...
    } ## end while...
    return;
} ## end sub _skyscraper

sub _turbot_fish {
    foreach my $digit ( 1 .. 9 ) {

        # collect all lines that have this digit as candidate in exactly 2 cells
        # my @cand2_lines =
        # map {my @hit = _cand_cells( $digit, $_, 2 ); [$_, \@hit]}
        # grep ({$_->get_Cand_count($digit) == 2} @lines);
        my @cand2_lines = _map_filtered( "\$_->get_Cand_count($digit) == 2",
            "[\$_, [_cand_cells( $digit, \$_, 2 )]]", @lines );

        # get the cross lines through the hit cells
        foreach my $cand_ref (@cand2_lines) {
            my ( $line, $hit_cell_ref ) = @$cand_ref;

            # the hit cells must be in different blocks
            next
              if ( $hit_cell_ref->[0]->Block_num ==
                $hit_cell_ref->[1]->Block_num );

            # get the cross lines through the hit cells
            my ( $cross1, $cross2 ) =
              map( { $line->crossline($_) } @$hit_cell_ref );

            # investigate the cross lines
            # both need at least 2 cells with this digit as candidate
            # (this check is needed in case that
            # Prio('Hidden Single') < Prio('Turbot Fish') )
            next
              if ( $cross1->get_Cand_count($digit) < 2
                or $cross2->get_Cand_count($digit) < 2 );

            my ( $chain_cell, $chain2_cell, $target_cell );
            my @cross_cells;

          TRYBOTH:
            foreach my $swap ( 0, 1 ) {
                if ($swap) {
                    ( $cross1, $cross2 ) = ( $cross2, $cross1 );
                    @$hit_cell_ref = reverse @$hit_cell_ref;
                }
                @cross_cells = _cand_cells( $digit, $cross1 );
                my $hitblock = $hit_cell_ref->[0]->Block_num;
                foreach my $cross_cell (@cross_cells) {
                    next if $cross_cell->Block_num == $hitblock;
                    my @block_cells =
                      _cand_cells( $digit, $blocks[ $cross_cell->Block_num ] );
                    next if @block_cells != 2;
                    $chain2_cell =
                        $block_cells[0] == $cross_cell
                      ? $block_cells[1]
                      : $block_cells[0];
					my $unittype = ref $line;
					$unittype =~ s/.*::(\w+)$/$1/;
                    $target_cell = $unittype eq 'Row'
                      ? Games::Sudoku::Trainer::Cell
					      ->by_pos( $chain2_cell->Row_num, $cross2->get_Index )
                      : Games::Sudoku::Trainer::Cell
					      ->by_pos( $cross2->get_Index, $chain2_cell->Col_num );
                    $chain_cell = $cross_cell;
                    last TRYBOTH if $target_cell->has_candidate($digit);
                }
            }
            next unless $target_cell and $target_cell->has_candidate($digit);

            my @clues = (
                $line, $cross1, $digit, reverse(@$hit_cell_ref),
                $chain_cell, $chain2_cell, $target_cell
            );
            my @exclude_info = $target_cell->Cell_num . "-$digit";
            return [ 'Turbot Fish', 'exclude', \@clues, \@exclude_info ];
        } ## end foreach...
    } ## end foreach...
    return;
} ## end sub _turbot_fish

sub _two_string_kite {
    foreach my $digit ( 1 .. 9 ) {

        # collect all rows that have this digit as candidate in exactly 2 cells
        my @rows2 =
          grep ( { $_ and $_->get_Cand_count($digit) == 2 } @rows );
        next unless @rows2;

        # collect all columns that have this digit as cand. in exactly 2 cells
        my @cols2 =
          grep ( { $_ and $_->get_Cand_count($digit) == 2 } @cols );
        next unless @cols2;

        # find a row and a column that have 1 of those cells in the same block
        foreach my $row (@rows2) {
            my @rowcells = _cand_cells( $digit, $row, 2 );
            my @rowblocknums = map( { $_->Block_num } @rowcells );

            # both cells of the row must be in different blocks
            next if $rowblocknums[0] == $rowblocknums[1];
            foreach my $col (@cols2) {
                my @colcells = _cand_cells( $digit, $col, 2 );
                my @colblocknums = map( { $_->Block_num } @colcells );

                # both cells of the col must be in different blocks
                next
                  if $colblocknums[0] == $colblocknums[1];
                my $linecross = $row->crosssection($col);

                # the lines may not cross at a candidate cell
                next
                  if $linecross->has_candidate($digit);

                my $crossblocknum = $linecross->Block_num;

                # both lines must have one candidate cell in the cross block
                next
                  if grep ( { ( $_->Block_num ) == $crossblocknum }
                    ( @rowcells, @colcells ) ) != 2;

                # pick up the 2 cells outside the cross block.
                # The lines through them cross at the crosscell.
                my $rowcell =
                    $rowblocknums[0] == $crossblocknum
                  ? $rowcells[1]
                  : $rowcells[0];
                my $colcell =
                    $colblocknums[0] == $crossblocknum
                  ? $colcells[1]
                  : $colcells[0];
                my $crosscell =
                  Games::Sudoku::Trainer::Cell->by_pos( $colcell->Row_num,
                    $rowcell->Col_num );

                # are there cand.s to exclude?
                next
                  unless $crosscell->has_candidate($digit);    # sorry

                my @clues = ( $row, $col, $digit, @rowcells, @colcells );
                return [
                    'Two-String Kite', 'exclude',
                    \@clues, [ $crosscell->Cell_num . "-$digit" ]
                ];
            } ## end foreach...
        } ## end foreach...
    } ## end foreach...
    return;
} ## end sub _two_string_kite

sub _unique_rectangle_type_1 {
    foreach my $row (@rows) {
        next unless $row;    # skip index 0
             # collect all cells in this row that have exactly 2 candidates
        my @all_pairs = _collect_2cands($row);

        # Look for 2 of those cells that have the same candidates
        while ( $#all_pairs > 0 ) {
            my $pair1_ref = $all_pairs[0];
            foreach my $i ( 1 .. $#all_pairs ) {
                my $pair2_ref = $all_pairs[$i];
                next if ( $pair1_ref->[1] != $pair2_ref->[1] );   # cands differ
                     # the 2 cand.s of the searched rect type 1
                my $rectcands = $pair1_ref->[1];

                # investigate the 2 columns that pass these cells
                # both should have another cell with these candidates
                # one of them should have another cell
                # with exactly these candidates
                my @pass_cols = map( { $row->crossline($_) }
                    ( $pair1_ref->[0], $pair2_ref->[0] ) );

                my @passmembers = $pass_cols[0]->active_Members;
                my @pass_pairs  = map( {
                        my $cands = $_->Candidates;
                          my $hitcount =
                          _count_chars_p1_common_p2( $cands, $rectcands );
                          $hitcount > 1 ? $_ : ();
                } @passmembers );
                next if $#pass_pairs == 0;   # another cell not found in 1st col

                # look in the same row of the 2nd column for the 4th cell
                # (because the 4 cells must form a rectangle)
                my $cell3;
                foreach my $cell (@pass_pairs) {
                    next if ( $cell == $pair1_ref->[0] );
                    $cell3 = $cell;
                    my $rownum = $cell3->Row_num();
                    my $cell4  = $pass_cols[1]->get_Member( $rownum - 1 );
                    my $cands  = $cell4->Candidates;
                    my $hitcount =
                      _count_chars_p1_common_p2( $cands, $rectcands );
                    next if ( $hitcount < 2 );    # not both cand.s in 4th cell
                    next
                      unless (
                        length( $cell3->Candidates ) == 2 xor length($cands) ==
                        2 );

                    # found type 1
                    my @clues = (
                        $row, $pass_cols[0], $rectcands,
                        $pair1_ref->[0], $pair2_ref->[0], $cell3, $cell4
                    );
                    my $cell = length($cands) == 2 ? $cell3 : $cell4;
                    $cands = $cell->Candidates;

                    return [
                        'Unique Rectangle Type 1',
                        'exclude', \@clues, [ $cell->Cell_num . "-$rectcands" ]
                    ];
                } ## end foreach...
            } ## end foreach...
            shift @all_pairs;
        } ## end while...
    } ## end foreach...
    return;
} ## end sub _unique_rectangle_type_1

sub _unique_rectangle_type_2 {
    foreach my $line (@lines) {

        # collect all cells in this line that have exactly 2 candidates
        my @all_pairs = _collect_2cands($line);

        # Look for 2 of those cells that have the same candidates
        while ( my $pair1_ref = shift @all_pairs ) {
            foreach my $i ( 0 .. $#all_pairs ) {
                my $pair2_ref = $all_pairs[$i];
                next if ( $pair1_ref->[1] != $pair2_ref->[1] );   # cands differ

                # investigate the 2 cross lines that pass these cells
                # both should have another cell with these candidates
                # plus one additional candidate
                # both should have the same additional candidate
                # $rectcands holds the 2 common candidates of the
                # (searched) rectangle
                my ( $cell1, $rectcands ) = @$pair1_ref;
                my $cross1       = $line->crossline($cell1);
                my @crossmembers = $cross1->active_Members;
                my @crosspairs   = map( {
                        my $cands = $_->Candidates;
                          my $hitcount =
                          _count_chars_p1_common_p2( $cands, $rectcands );
                          $hitcount == 2 && length($cands) == 3 ? $_ : ();
                } @crossmembers );
                next if $#crosspairs < 0;   # another cell not found in 1st line

                # for each possible 3rd cell compare with the corresp. 4th cell
                foreach my $cell3 (@crosspairs) {
                    my $rownum = $cell3->Row_num();
                    my $cell2  = $pair2_ref->[0];
					my $unittype = ref $line;
					$unittype =~ s/.*::(\w+)$/$1/;
                    my $cell4 =
                       $unittype eq 'Row'
                      ? Games::Sudoku::Trainer::Cell->by_pos( $cell3->Row_num,
                        $cell2->Col_num )
                      : Games::Sudoku::Trainer::Cell->by_pos( $cell2->Row_num,
                        $cell3->Col_num );
                    next if $cell3->Candidates ne $cell4->Candidates;

                    # $exclcand gets the candidate to be excluded
                    my $exclcands = $cell3->Candidates;
                    $exclcands = _chars_p1_notin_p2( $exclcands, $rectcands );

                    my @clues = (
                        $line, $cross1, $rectcands, $cell1, $cell2,
                        $cell3, $cell4
                    );
                    my @cont3 = $cell3->get_Containers;
                    my @cont4 = $cell4->get_Containers;
                    my @common_units =
                      map { $cont3[$_] == $cont4[$_] ? $cont3[$_] : () } 0 .. 2;
                    my $exclude_ref =
                      _excl_cands_exept( \@common_units, $exclcands, $cell3,
                        $cell4 );
                    next unless @$exclude_ref;
                    return [ 'Unique Rectangle Type 2',
                        'exclude', \@clues, $exclude_ref ];
                } ## end foreach...
            } ## end foreach...
        } ## end while...
    } ## end foreach...
    return;
} ## end sub _unique_rectangle_type_2

sub _x_wing {
    foreach my $digit ( 1 .. 9 ) {
        my ( $lineref, $cross_getter ) = ( \@rows, 'Col_num' );
        foreach ( 1, 2 ) {
            my @cand2_lines;

            # collect all lines that have this digit as candidate
            # in exactly 2 cells
            @cand2_lines = _map_filtered( "\$_->get_Cand_count($digit) == 2",
                "[\$_, _cand_cells( $digit, \$_, 2 )]", @$lineref );
            next if @cand2_lines < 2;

            # search for 2 candidate lines that have the 2 cells
            # in the same position, thus forming a rectangle
            while ( my $cand_ref1 = shift @cand2_lines ) {
                my ( @hit_cells1, @hit_cells2 );
                ( my $line1, @hit_cells1 ) = @$cand_ref1;
                my @cross1 =
                  map( { $_->$cross_getter } @hit_cells1 )
                  ;    # the indices of the cross lines
                $lineref =
                  $cross_getter =~ /Row/
                  ? \@rows
                  : \@cols;    # the type array of the cross lines (row or col)
                foreach my $cand_ref2 (@cand2_lines) {
                    ( my $line2, @hit_cells2 ) = @$cand_ref2;
                    my @cross2 =
                      map( { $_->$cross_getter } @hit_cells2 )
                      ;        # the indices of the cross lines
                    next
                      if ( $cross1[0] != $cross2[0]
                        or $cross1[1] != $cross2[1] ); # not the same crosslines

# we found an x-wing structure - are there cand.s to exclude in the cross lines?
                    next
                      if ( $lineref->[ $cross1[0] ]->get_Cand_count($digit) == 2
                        and $lineref->[ $cross1[1] ]->get_Cand_count($digit) ==
                        2 );

                    # sorry

                    my @clues =
                      ( $line1, $line2, $digit, @hit_cells1, @hit_cells2 );
                    my $exclude_ref =
                      _excl_cands_exept(
                        [ $lineref->[ $cross1[0] ], $lineref->[ $cross1[1] ] ],
                        $digit, @hit_cells1, @hit_cells2 );
                    return [ 'X Wing', 'exclude', \@clues, $exclude_ref ];
                } ## end foreach...
            } ## end while...
            ( $lineref, $cross_getter ) = ( \@cols, 'Row_num' );
        } ## end foreach...
    } ## end foreach...
    return;
} ## end sub _x_wing

sub _xy_wing {

    # collect all cells that have exactly 2 candidates
    my @all_pairs = _collect_2cands( @cells[ 1 .. 81 ] );

    foreach my $i ( 0 .. $#all_pairs - 2 ) {
        my ( $cell1, $cands1 ) = @{ $all_pairs[$i] };
        foreach my $j ( $i + 1 .. $#all_pairs - 1 ) {
            my ( $cell2, $cands2 ) = @{ $all_pairs[$j] };
            ( my $match1 ) = ( $cands2 =~ /([$cands1]+)/ ) || '';
            next unless length($match1) == 1;    # not 1 common cand.
            foreach my $k ( $j + 1 .. $#all_pairs ) {
                my ( $cell3, $cands3 ) = @{ $all_pairs[$k] };
                next if ( $cands3 eq $cands1 or $cands3 eq $cands2 );
                my $nomatch =
                  _count_chars_p1_notin_p2( $cands3, $cands1 . $cands2 );
                next if $nomatch > 0;            # more than 3 cand.s total
                my @chain = _chain_of( $cell1, $cell2, $cell3 );
                next unless @chain;

                my $excl = $chain[0]->Candidates;
                my $keep = $chain[1]->Candidates;

                # get the cand to be excluded
                $excl = _chars_p1_notin_p2( $excl, $keep );
                my @excl_cells =
                  Games::Sudoku::Trainer::Cell->common_sibs( $chain[0], $chain[2] );
                next unless @excl_cells;         # no common siblings
                my @have_cand = _cand_cells( $excl, @excl_cells );
                next unless @have_cand;          # sorry - no cand to exclude

                my @clues = ( @chain, "$keep$excl" );
                my @exclude_info = map { $_->Cell_num . "-$excl" } @have_cand;
                return [ 'XY Wing', 'exclude', \@clues, \@exclude_info ];
            }
        }
    } ## end foreach...
    return;
} ## end sub _xy_wing

# form a chain from all given cells
#   support routine for sub _xy_wing
#	@chain = _chain_of(list_of_unsorted_cells);
#	returns undef on no success
#
sub _chain_of {
    my @rand = @_;
    my @chain;

    push @chain, pop @rand;
    my $last_link = $chain[-1];                   # last chainlink found so far
    my @lastconts = $last_link->get_Containers;
    my $last_cont_idx = -1;    # index (~ type) of last chaining container
    my $first_cont_idx;        # index (~ type) of 1st chaining container

    while (@rand) {

        # find next chainlink
        my $currsize = @rand;
      TRY_IDX:
        for my $try_idx ( 0 .. $#rand )
        {                      # we need the index on success for splice
            my $cell     = $rand[$try_idx];
            my @newconts = $cell->get_Containers;

            # if no success with the last chainlink, reverse the partial chain
            for my $reversed ( 0, 1 ) {

                # try chaining in all containers of the last chainlink

                # must chain in different containers
                foreach my $j ( 0 .. 2 ) {
                    next
                      if $j == $last_cont_idx;
                    next unless $newconts[$j] == $lastconts[$j];

                    # found chainlink
                    @chain == 1 and $first_cont_idx = $j;
                    @lastconts     = @newconts;
                    $last_link     = $cell;
                    $last_cont_idx = $j;
                    push @chain, $cell;
                    splice @rand, $try_idx, 1;
                    last TRY_IDX;
                }
                if ( $reversed or @chain == 1 )
                {    # cell doesn't fit here, try next
                    next TRY_IDX;
                }

                # reverse the partial chain to try connect to the
                # currently 1st chainlink
                @chain     = reverse @chain;
                $last_link = $chain[-1];
                @lastconts = $last_link->get_Containers;
                ( $first_cont_idx, $last_cont_idx ) =
                  ( $last_cont_idx, $first_cont_idx );
            }
        } ## end for...
        return if $currsize == @rand;    # broken chain
    } ## end while...
    return @chain;
} ## end sub _chain_of

#==============================================================================
#==============================================================================
# Exclude candidates from most cells in a unit or list of units
#   _excl_cands_exept(unit-info, $exclcands, @cells_retain);
#       unit-info:     $unit or ref to list of units
#       $exclcands:    string of candidates to be excluded
#       @cells_retain: list of cells that shall keep their candidates
#   returns ref to list of cands to be excluded
#   (format: cell-number . "-$exclcands")
#
sub _excl_cands_exept {
    my ( $hit_unit, $exclcands, @have_cand ) = @_;
    my @hit_units = ref $hit_unit eq 'ARRAY' ? @$hit_unit : ($hit_unit);

    my @total_members;    # all members of all units
    my @cands = split( '', $exclcands );
    foreach my $hit_unit (@hit_units) {
        my @hit_cells = map { _cand_cells( $_, $hit_unit ) } @cands;

        # all members with these cand. in the hit unit
        my %all_members;
        @all_members{@hit_cells} = (@hit_cells);

        # keep the members in the cross section
        delete @all_members{@have_cand};
        push( @total_members, values %all_members );
    }
    my @exclude_info = map { $_->Cell_num . "-$exclcands" } @total_members;
    return \@exclude_info;
}

# Extract all cells from the list that have this digit as a candidate
# @have_cand = _cand_cells($digit, @cell_list, $expect_count);
# ...        = _cand_cells($digit, $unit, $expect_count);
# uses the members of the unit
#   $expect_count: expected count of hit cells (optional)
#   dies if expected count differs from actual count (code error)
#
sub _cand_cells {
    my ( $digit, @cell_list ) = @_;

    use File::Basename;

    @cell_list or do {
        my @trace = caller(0);
        die "3\nProblem in file ", basename( $trace[1] ), " at line $trace[2]",
          "\nNo cell list passed to sub _cand_cells\n";
    };

    my $expect_count = pop @cell_list unless ref $_[-1];
    my $unit;
    my @found;
    if ( @cell_list == 1 and $cell_list[0]->isa('Games::Sudoku::Trainer::Unit') ) {
        $unit      = $cell_list[0];
        @cell_list = @{ $unit->{Cand_cells}[$digit] };
        @found     = @cell_list;
    }
    else {
		my $unittype = ref $cell_list[0];
		$unittype =~ s/.*::(\w+)$/$1/;
        $unittype eq 'Cell'  or  die "3\n$cell_list[0] must be a cell";
        @found = grep { $_->has_candidate($digit) } @cell_list;
    }

    return @found if !defined $expect_count or @found == $expect_count;
    my @trace = caller(0);
    die "3\nProblem in file ", basename( $trace[1] ), " at line $trace[2]",
      "\nExpected $expect_count cells with candidate $digit in ",
      defined $unit ? 'unit ' . $unit->Name
     	            : Games::Sudoku::Trainer::GUI::names(@cell_list),
      ', found ', scalar @found, "\n";
}

# collect all cells from a list that have exactly 2 candidates
#	my @all_twins = _collect_2cands(@cell_list);
#	my @all_twins = _collect_2cands($unit);      # uses the members of the unit
#		returns list of refs to 2-element arrays:
#         [cell-obj, string of the 2 cand.s in this cell
#
sub _collect_2cands {
    my @cell_list = @_;
    if ( @cell_list == 1 and $cell_list[0]->isa('Games::Sudoku::Trainer::Unit') ) {
        @cell_list = $cell_list[0]->active_Members;
    }

    return _map_filtered( 'length($_->Candidates) == 2',
        '[$_, $_->Candidates]', @cell_list );
}

# filter a list, then map to a new list and return this
#   my @result =
#     _map_filtered($filtercode_string, $mapcode_string, @sourcelist);
#
sub _map_filtered {
    my ( $filter, $mapblock, @liste ) = @_;
    @liste = grep { $_ } @liste;    # skip index 0, if required (undef)
    return () unless @liste;

    my @res = eval "map {$mapblock} grep ({$filter} \@liste)";
#    $@  and  do {
    if ($@) {
          my $msg = "    Filter:       $filter\n    Mapblock: $mapblock\n";
          die "3\nEval error: $@$msg ";    # final ' ' adds trace info
         };
    return @res;
}

#-----------------------------------------------------------------------
# Set operations on characters in strings
#-----------------------------------------------------------------------

# return all chars in $p1 that are not in $p2 (non-symmetric diff)
#     $rest_p1 = _chars_p1_notin_p2($p1, $p2);
#
sub _chars_p1_notin_p2 {
    my ( $p1, $p2 ) = @_;
    $p1 =~ s/[$p2]//g;    # remove common chars
    return $p1;
}

# return count of chars in $p1 that are not in $p2 (non-symmetric diff)
#     $count_excl = _count_chars_p1_notin_p2($p1, $p2);
#
sub _count_chars_p1_notin_p2 {
    my ( $p1, $p2 ) = @_;
    my $count_notin = $p1 =~ s/[^$p2]//g;    # remove not common chars
    return $count_notin;
}

# return all chars in $p1 that are also in $p2 (intersection)
#     $common_chars = _chars_p1_common_p2($p1, $p2);
#
sub _chars_p1_common_p2 {
    my ( $p1, $p2 ) = @_;
    $p1 =~ s/[^$p2]//g;    # remove not common chars
    return $p1;
}

# return count of chars in $p1 that are also in $p2 (intersection)
#     $count_common = _count_chars_p1_common_p2($p1, $p2);
#
sub _count_chars_p1_common_p2 {
    my ( $p1, $p2 ) = @_;
    my $count_common = $p1 =~ s/[$p2]//g;    # remove common chars
    return $count_common;
}

# return all chars that are not common (symmetric diff)
#     ($rest_p1, $rest_p2) = _chars_p1_notin_p2($p1, $p2);
# Caution: Returns () if $p1 and $p2 have no common char
#
sub _chars_notcommon {
    my ( $p1, $p2 ) = @_;
    my $comm = $p1;
    $comm =~ s/[^$p2]//g;    # remove not common chars
    return () unless $comm;  # no common chars
    $p1 =~ s/[$comm]//g;     # remove common chars
    $p2 =~ s/[$comm]//g;     # remove common chars
    return ( $p1, $p2 );
}

# return string of all chars found in given strings (union)
#    $sorted_chars = _allchars{@strings};
#
sub _allchars {
    my @strings = @_;
    my %union;

    foreach my $string (@strings) {
        $union{$_} = undef foreach split '', $string;
    }
    return join '', sort keys %union;
}

1;
