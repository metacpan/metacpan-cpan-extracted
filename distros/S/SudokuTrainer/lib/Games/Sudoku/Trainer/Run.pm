use strict;
use warnings;
#use feature qw( say );

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @rows;      # row objects		(1 .. 9)
our @cols;      # col objects		(1 .. 9)
our @blocks;    # block objects		(1 .. 9)
our @units;     # all unit objects	(0 .. 26)  rows, columns, and blocks
our @lines;     # all line objects	(0 .. 17)  rows and columns

sub init_all {
    use Games::Sudoku::Trainer::Const_structs;
    use Games::Sudoku::Trainer::Priorities;
    use Games::Sudoku::Trainer::Found_info;
    use Games::Sudoku::Trainer::Strategies;
    use Games::Sudoku::Trainer::Pause;
    use Games::Sudoku::Trainer::GUI;
    use Games::Sudoku::Trainer::GUIhist;
    use Games::Sudoku::Trainer::Write_puzzle;
    use Games::Sudoku::Trainer::Check_pause;
}

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;    # cell objects		(1 .. 81)
#our @units;    # all unit objects	(0 .. 26)  rows, columns, and blocks

#package
#    Games::Sudoku::Trainer::Run;
package Games::Sudoku::Trainer::Run;

use version; our $VERSION = qv('0.04');    # PBP

use Getopt::Long;
use Carp;
use List::Util qw(first);

# globals of package Run
my $gamestring;    # the initial puzzle as a string of 81 char.s
my $testmode = 0;

# initialize the puzzle with the preset values, start the main loop,
# process eval errors.
# Called from package GUI when the main window is ready
#
sub initialize_and_start {
    _commandline_options();

    eval {
        _init_puzzle();
        _insert_presets();
        _verify_puzzle();
        $testmode and Games::Sudoku::Trainer::Pause->setMode('non-stop');
        $testmode or Games::Sudoku::Trainer::Check_pause::pause();
        Games::Sudoku::Trainer::GUI::set_status('');
        _run_puzzle();
    };
    if ($@) {
        my $eval_err = $@;
        $eval_err =~ s/^(\d)\n//;
        my ($err_type) = $1 || 0;
        if ( $err_type == 0 ) {    # unclassified error
            $eval_err =~ /_TK_EXIT_\(0\)/ and exit;
            if ( $eval_err =~ /^Undefined subroutine / ) {
                $err_type = 3;   # changed for 'Undefined subroutine xxx called'
            }
            else {
                $err_type = 9;    # unclassified error
                                  # code position on new line
                $eval_err =~ s/(?= at \S+ line \d+, <>)/\n/;
            }
        }

        my %cosmetics = (
#<<<  hands off, perltidy!
            # $err_type    $title        $icon
              1 => [       'Data error', 'warning'],
              2 => [       'User error', 'warning'],
              3 => [       'Code error', 'error'  ],
              9 => [       'Problem',    'error'  ],
#>>>
        );
        my ( $title, $icon ) = @{ $cosmetics{$err_type} };
        $title or do {
            ( $title, $icon ) = ( 'Error', 'error' );
            $eval_err .= "\n(unknown error type $err_type)";
        };
        if ($testmode) {
            $eval_err =~ s{\n(?=\w)}{ }g;
            print "$title: $eval_err";
            Tk::exit;
        }
        if ( $err_type != 2 ) {
            Games::Sudoku::Trainer::GUI::button_state( 'Run', 'disable' );
            Games::Sudoku::Trainer::GUI::set_exit_on_delete();
        }
        Games::Sudoku::Trainer::GUI::showmessage(
            -title   => $title,
            -icon    => $icon,
            -message => $eval_err,
        );
        return;
    } ## end if...

    $testmode and Tk::exit;
    return;
} ## end sub initialize_and_start

# process the command line options
# including the non-documented flag 'test' for automated test suites
#
sub _commandline_options {
    my $prio;
    my $trail = ",\noption prio will be ignored.";

    # catch warn to STDERR issued by GetOptions
    local $SIG{__WARN__} =
      sub { chomp( my $msg = $_[0] ); user_err("$msg$trail") };

    GetOptions(
        'prio=s' => \$prio,       # file name of priority list
         ## test flag for development (forces run mode 'non-stop')
        'test'   => \$testmode,
    );
    $prio or return;
    -f $prio or do {
        user_err( "File '$prio' doesn't exist", $trail );
        return;
    };
    open( my $PRI, '<', $prio )
      or do { user_err( "Cannot open file $prio: $!", $trail ); return };
    my @strats = <$PRI>;
    close $PRI or die "9\nCannot close file $prio: $!\n";
    chomp @strats;
    grep ( { $_ =~ $strats[0] } Games::Sudoku::Trainer::Priorities->copy_strats() )
      or do { user_err("File $prio is no priority list$trail"); return };
    Games::Sudoku::Trainer::Priorities::set_strats( \@strats );
    return;
}

# read the initial puzzle
# prepare insertion of the preset values into the Sudoku board
#
sub _init_puzzle {
    until ($gamestring) {
        my @game;
        if (@ARGV) {
            unless ( -f $ARGV[0] ) {
                user_err("File $ARGV[0] doesn't exist");
                undef @ARGV;
                next;
            }
            $#ARGV = 0;    # ignore all but first
            Games::Sudoku::Trainer::GUI::show_filename( $ARGV[0] );
            @game = <>;
            undef @ARGV;
        }
        else {
            @game = Games::Sudoku::Trainer::GUI::get_initialpuzzle();
            next unless @game;    # no file or empty file
        }

        unless (@game) {
            data_err('No data found');
            next;
        }

        # ignore preceeding comment lines
        while ( $game[0] =~ /^#/ ) { shift @game }
        $gamestring = join( '', @game );
        undef @game;

        # In case of error sub data_err is called directly
        # instead of using die.
        # So the user has the chance to select a different puzzle.
        #
        $gamestring =~ s/\n//g;    # ignore newlines

        # ignore whitespace
        if ( length($gamestring) > 81 ) { $gamestring =~ s/\s//g }
        my $l = length($gamestring);
        if ( $l == 0 ) {
            data_err('No puzzle found');
            undef $gamestring;
            next;
        }
        unless ( $l == 81 ) {
            data_err("Length of game string is $l, should be 81");
            undef $gamestring;
            next;
        }
        unless ( $gamestring =~ /[1-9]/ ) {
            data_err('No preset values found');
            undef $gamestring;
            next;
        }
        if ( $gamestring =~ /^[1-9]+$/ ) {
            data_err('Initial puzzle is solved already');
            undef $gamestring;
        }
    } ## end until...

    # Insert the preset values in @found
    # sub _insert_presets will insert them into the Sudoku board
    #
    for ( my $pos = 0 ; $pos < 81 ; $pos++ ) {
        my $char = substr( $gamestring, $pos, 1 );
        next unless $char =~ /[1-9]/;
        Games::Sudoku::Trainer::Found_info->new(
            [ $cells[ $pos + 1 ], $char, 'preset' ] );
    }
    return;
} ## end sub _init_puzzle

# Insert all preset values in the Sudoku board
#   _insert_presets();
#
sub _insert_presets {
    my ( $cell, $digit, $strategy );
    my $found_info_ref;

    # Inform class Cell that we are inserting preset values
    # This delays some error messages until verify
    Games::Sudoku::Trainer::Pause->setMode('in_preset');
    while (1) {
    	my $oldest = Games::Sudoku::Trainer::Found_info->oldest();
		last unless $oldest;
        $found_info_ref = $oldest;
        ( $cell, $digit, $strategy ) = @$found_info_ref;
        $cell->insert_digit($digit);
        Games::Sudoku::Trainer::GUI::display_cellvalue(
		    $cell->Row_num, $cell->Col_num, $digit, $strategy, 
		);
    }
    Games::Sudoku::Trainer::GUI::set_status("Done presetting values");
    Games::Sudoku::Trainer::Pause->setMode('single-step');

    # look for full house that is caused by presetting

    foreach my $unit (@units) {
        my @members = $unit->active_Members;
        next unless ( @members == 1 );
        Games::Sudoku::Trainer::Strategies::full_house( $members[0] );
    }
    return;
}

# look for obvious errors in the initial puzzle
#
sub _verify_puzzle {
    my $errhead = 'Error in preset data:';

    foreach my $unit (@units) {
        my @presets;
        my @members = $unit->get_Members;
        foreach my $member (@members) {
            my $preset = $member->Value;
            next unless $preset;
            ++$presets[$preset] > 1
              and die "1\n$errhead\nDuplicate value $preset in unit ",
              $unit->Name, "\n";
        }
    }

    foreach my $unit (@units) {
        my %check;
        my @presets;
        my @members = $unit->get_Members;
        foreach my $member (@members) {
            my $preset = $member->Value;
            ++$presets[$preset] if $preset;
            foreach my $cand ( split( '', $member->Candidates ) ) {
                ++$check{$cand};
            }
        }

        # each digit must either be preset as a value
        # or be a cand. in at least 1 cell
        foreach my $cand ( 1 .. 9 ) {
            $check{$cand}
              or $presets[$cand]
              or die "1\n$errhead\nNo cell left for candidate $cand in unit ",
              $unit->Name, "\n";
        }
    }

    foreach my $cell ( @cells[ 1 .. 81 ] ) {
        next if $cell->Value;
        $cell->Candidates
          or die "1\n$errhead\nNo candidate left for cell ", $cell->Name,
          "\n";
    }
    Games::Sudoku::Trainer::GUI::button_state( 'Run', 'enable' );
    return;
} ## end sub _verify_puzzle

# the main loop of SudokuTrainer
#
sub _run_puzzle {

    # fetch the oldest find from module Found_info
    # if no find returned
    #    call module Strategies to search in the puzzle
    #    terminate the main loop if nothing found
    # check whether a pause is requested at this state of the puzzle
    # if yes, pause until the user hits the "Run" button
    # update the internal structures and the displayed board
    # add the processed find to the history
    # 
    my $found_info_ref;
    my ( $cell, $digit, $strategy );

    while (1) {
        $found_info_ref = Games::Sudoku::Trainer::Found_info->oldest();
        unless ($found_info_ref) {
            Games::Sudoku::Trainer::Strategies::try_strategies();
		    $found_info_ref = Games::Sudoku::Trainer::Found_info->oldest();
            last unless $found_info_ref;
        }
        $strategy = $found_info_ref->[0];
        if ( $found_info_ref->[1] eq 'insert' ) {
            ( $digit, $cell ) = @{ $found_info_ref->[3] };
            next if ( $cell->Value );    # already found
            Games::Sudoku::Trainer::Check_pause::check_pause($found_info_ref);
            Games::Sudoku::Trainer::GUI::display_cellvalue( 
			    $cell->Row_num, $cell->Col_num,
                $digit, $strategy 
            );
            $cell->insert_digit($digit);
            Games::Sudoku::Trainer::Strategies::full_house($cell);

        } else {                           # exclude cand.s

            Games::Sudoku::Trainer::Check_pause::check_pause($found_info_ref);
            my @exclude_info = @{ $found_info_ref->[3] };
            foreach my $info (@exclude_info) {
                my ( $cell_num, $exclude_cands ) = split( '-', $info );
                $cell = $cells[$cell_num];
                foreach my $digit ( split( '', $exclude_cands ) ) {
                    $cell->exclude_candidate($digit);
                }
            }
        }
        Games::Sudoku::Trainer::GUIhist::add_history($found_info_ref);
    }
    # the main loop has terminated

    if ( ( my $valuecount = grep { $_->Value } @cells[ 1 .. 81 ] ) == 81 ) {
        Games::Sudoku::Trainer::GUI::set_status('Sudoku puzzle is solved');
        $testmode and print "found all\n";
    }
    else {
        Games::Sudoku::Trainer::GUI::set_status('Sorry - cannot find more');
        $testmode and print 'missing ', 81 - $valuecount, "\n";
    }
    # disable the Run button
    Games::Sudoku::Trainer::GUI::button_state( 'Run', 'disable' );
    Games::Sudoku::Trainer::GUI::set_exit_on_delete();
    return;
} ## end sub _run_puzzle

# return the initial puzzle as a sting
#   my $gamestring = initial_puzzle();
#
sub initial_puzzle {
    return $gamestring;
}

sub data_err {
    # disable the Run button
    Games::Sudoku::Trainer::GUI::button_state( 'Run', 'disable' );
    if ($testmode) { die "1\n@_\n" }
    Games::Sudoku::Trainer::GUI::showmessage(
        -title   => 'Data error',
        -message => "@_",
        -icon    => 'error'
    );
    return;
}

sub user_err {
    if ($testmode) { die "2\n@_\n" }
    Games::Sudoku::Trainer::GUI::showmessage(
        -title   => 'User error',
        -message => "@_",
        -icon    => 'warning'
    );
    return;
}

sub code_err {
    # disable the Run button
    Games::Sudoku::Trainer::GUI::button_state( 'Run', 'disable' );
    if ($testmode) { die "3\n@_\n" }
    Games::Sudoku::Trainer::GUI::showmessage(
        -title   => 'Code error',
        -message => "@_",
        -icon    => 'error'
    );
    return;
}

1;
