use strict;
use warnings;
#use feature qw( say );

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;    # cell objects		(1 .. 81)
our @rows;     # row objects		(1 .. 9)

# To reduce the size of this file, the code of some dialogs has been moved
# to subordinate modules. These are loaded at their first usage, so this
# will hopefully speed up a bit the startup time of the application.

package
    Games::Sudoku::Trainer::GUI;

use version; our $VERSION = qv('0.02');    # PBP

use Tk;
use Tk::ErrorDialog;
use File::Basename;
use Encode;

# globals of package GUI

# global widgets
my $mw;             # main window
my $run_bt;         # Run-button widget
my $details_bt;    # the Show details Button
my $cv;             # Canvas widget as sudoku board
my $restrict_lb;    # Label to display pause mode restriction
my $file_en;        # Entry widget for display of file name
my $menubar;        # Menu widget for menu bar

# others
my $pause_mode;     # current pause mode
my $pause_strat;    # strategy that caused this pause
my $initfile;       # input file of initial puzzle
my $values_count = 0;    # count of found values
my $status;              # text in status bar
my $preset_count;        # preset counter
my $noop_sub = sub { };

# global constants
my $candsize  = 7;                         # size of a cand. square (pixels)
my $cellsize  = 3 * ( $candsize + 3 ) - 1; # size of a sudoku cell
my @all_types = qw/units cands cells/;     # all clue type names

$mw = MainWindow->new(-title => 'SudokuTrainer');
$mw->withdraw;
_build_GUI();
$details_bt->bind( '<Visibility>' 
    => sub { Games::Sudoku::Trainer::Run::initialize_and_start() } );
$mw->deiconify;

set_pause_mode('default');

sub _build_GUI {
    _build_menubar();

    # pause bar
    my $run_fr = $mw->Frame()->pack( -anchor => 'w' );
    $run_fr->Label( -text => 'Current pause mode: ' )->pack( -side => 'left' );
    $run_fr->Label(
        -width        => 20,
        -background   => 'white',
        -textvariable => \$pause_mode,
        -anchor       => 'w',
    )->pack( -side => 'left' );
    $run_fr->Label( -text => '  in' )->pack( -side => 'left' );
    $restrict_lb = $run_fr->Label(
        -width      => 4,
        -background => 'white',
    )->pack( -side => 'left', -padx => 4 );
    $run_bt = $run_fr->Button(
        -text => 'Run',
        -command =>
          sub { set_status(''); Games::Sudoku::Trainer::Check_pause::endpause() },
        -state => 'disabled',
    )->pack( -side => 'right' );

    # current strategy bar
    my $strat_fr = $mw->Frame()->pack( -anchor => 'w', -fill => 'x' );
    $strat_fr->Label( -text => 'Successful strategy: ' )
      ->pack( -side => 'left' );
    $strat_fr->Label( -textvariable => \$pause_strat )->pack( -side => 'left' );
    $details_bt = $strat_fr->Button(
        -text  => 'Show details',
        -command => sub {
                         require Games::Sudoku::Trainer::GUIdetails;
#                         my $btnref = \$details_bt;
#                         Games::Sudoku::Trainer::GUIdetails::build_strat_details($btnref);
                         Games::Sudoku::Trainer::GUIdetails::build_strat_details(\$details_bt);
                        },
        -state => 'disabled',
    )->pack( -side => 'right' );

    _build_sudoku_board();

    # file info bar
    my $fileinfo_fr = $mw->Frame()->pack( -anchor => 'w', -fill => 'x' );
    $fileinfo_fr->Label( -text => 'File name' )->pack( -side => 'left' );
    $file_en = $fileinfo_fr->Entry(
        -textvariable => \$initfile,
        -bg           => 'white',
        -state        => 'readonly'
    )->pack( -side => 'left', -expand => 1, -fill => 'x' );
    $fileinfo_fr->Label( -text => 'preset values' )->pack( -side => 'right' );
    $fileinfo_fr->Label(
        -textvariable => \$preset_count,
        -width        => 4,
        -anchor       => 'e'
    )->pack( -side => 'right' );

    # status bar
    my $status_fr = $mw->Frame()->pack( -anchor => 'w', -fill => 'x' );
    $status_fr->Label( -textvariable => \$status )->pack( -side => 'left' );
    $status_fr->Label( -text => 'values found' )->pack( -side => 'right' );
    $status_fr->Label( -textvariable => \$values_count )
      ->pack( -side => 'right' );

    $mw->resizable( 0, 0 );    # freeze window size

    # Prevent the perl process from hanging when the user clicks on the
    # File/Quit button or on the kill button near the right edge of the
    # title bar:
    # Change the noop sub to ref of sub quit, then terminate the pause.
    # Note: Has been $mw->OnDestroy before.
    $mw->protocol( 'WM_DELETE_WINDOW',
        sub { $noop_sub = \&quit; Games::Sudoku::Trainer::Check_pause::endpause() } );
    return;
} ## end sub _build_GUI

#-----------------------------------------------------------------------
# Menubar
#-----------------------------------------------------------------------

sub _build_menubar {
    $mw->configure( -menu => $menubar = $mw->Menu );
    $menubar->cascade( -label => '~File', -menuitems => _file_menuitems() );
    $menubar->cascade(
        -label     => '~Pause Mode',
        -menuitems => _pausemode_menuitems()
    );
    $menubar->cascade(
        -label     => '~Priorities',
        -menuitems => [
            [
                qw/command ~Change -command/ => sub {
                    require Games::Sudoku::Trainer::GUIprio;
                    Games::Sudoku::Trainer::GUIprio::change_prios($mw);
                  }
            ]
        ],
    );

    $menubar->cascade(
        -label     => '~History',
        -menuitems => [
            [
                qw/command ~Summary -command/ =>
                  sub { Games::Sudoku::Trainer::GUIhist::hist_summary($mw) },
            ],
            [
                qw/command ~Overview -command/ =>
                  sub { Games::Sudoku::Trainer::GUIhist::hist_overview($mw) },
            ],
            [
                qw/command ~Details -command/ =>
                  sub { Games::Sudoku::Trainer::GUIhist::hist_details($mw) },
            ],
        ],
    );
    $menubar->cascade(
        -label     => '~View',
        -menuitems => [
            [
                'checkbutton',
                'active candidates',
                -command => [ \&_show_candsquares, 'active candidates' ]
            ],
            [
                'checkbutton',
                'excluded candidates',
                -command => [ \&_show_candsquares, 'excluded candidates' ]
            ],
        ],
    );

    # set the init. state of the 'excluded' checkbutton to 'off'
    # required for sub exclude_cand
    my $view_menu = $menubar->entrycget( 'View', -menu );
    my $state_ref = $view_menu->entrycget( 'excluded candidates', -variable );
    $$state_ref = 0;
    return;
} ## end sub _build_menubar

sub _file_menuitems {
    return [
        [ qw/command ~Save  -command/ => \&_result_save ],
        [
            qw/command/, "S~ave as",
            qw/-command/ => [ \&_sudoku_save_as, 'current' ]
        ],
        '',
        [
            qw/command/,
            "Save ~initial puzzle",
            qw/-command/ => [ \&_sudoku_save_as, 'initial' ]
        ],
        '',
        [
            qw/command/, "Save ~priority list", qw/-command/ => \&_prio_save_as
        ],
        [ qw/command/, "Load p~riority list", qw/-command/ => \&_prio_load ],
        '',
        [ qw/command ~Quit  -command/ => \&quit ],
    ];
}

sub _pausemode_menuitems {
    return [
        map ( [
                'radiobutton', $_,
                -variable => \$pause_mode,
                -value    => $_,
                -command  => [ \&set_pause_mode, $_ ]
            ],
            qw/single-step non-stop/ ),
        '',
        [
            qw/cascade Strategy -menuitems/ => [
                map ( [
                        'radiobutton', $_,
                        -variable => \$pause_mode,
                        -command  => [ \&set_pause_mode, $_ ]
                    ],
                    (
                        sort 'Full House',
                        Games::Sudoku::Trainer::Priorities->copy_strats()
                    ) ),
            ],
        ],
        '',
        [
            'cascade',
            'Value found',
            -menuitems => [
                # This group of radiobuttons is unusual (but still legal), since
                # it doesn't have the '-variable' option. The internal variable
                # '$Tk::selectedButton' is used instead.
                # In addition, in '$Tk::selectedButton' the radiobutton label is
                # used as the value, so we don't need the '-value' option.
                [
                    'radiobutton', 'anywhere',
                    -command => sub { set_pause_mode('value found') }
                ],
                [
                    'radiobutton',
                    'in a unit',
                    -command => sub {
                        set_pause_mode('value found');
                        require Games::Sudoku::Trainer::GUIpause_restrict;
                        Games::Sudoku::Trainer::GUIpause_restrict::enter_unitname(
                            $restrict_lb);
                      }
                ],
                [
                    'radiobutton',
                    'at a cell',
                    -command => sub {
                        set_pause_mode('value found');
                        require Games::Sudoku::Trainer::GUIpause_restrict;
                        Games::Sudoku::Trainer::GUIpause_restrict::enter_cellname(
                            $restrict_lb);
                      }
                ],
            ],
        ],
        [
            'radiobutton',
            'Trace a cell',
            -variable => \$pause_mode,
            -command  => sub {
                set_pause_mode('Trace a cell');
                require Games::Sudoku::Trainer::GUIpause_restrict;
                Games::Sudoku::Trainer::GUIpause_restrict::enter_cellname(
                    $restrict_lb);
                Games::Sudoku::Trainer::GUIpause_restrict::build_tracewindow(
                    $candsize, $cellsize );
              }
        ],
    ];
} ## end sub _pausemode_menuitems

#-----------------------------------------------------------------------
# sudoku board
#-----------------------------------------------------------------------

sub _build_sudoku_board {
    my $boardsize = 9 * ( $cellsize + 1 ) + 2;    # size of the sudoku board
    $cv = $mw->Canvas(
        -scrollregion => [ 0, 0, $boardsize - 1, $boardsize - 1 ],
        -height       => $boardsize - 1,
        -width        => $boardsize - 1,
        -bg           => 'white',
    )->pack();

    # draw cell separator lines
    foreach my $pos ( 1 .. 8 ) {
        next unless $pos % 3;
        my $where = $pos * ( $cellsize + 1 );
        $cv->createLine( $where, 1, $where, $boardsize - 2, -fill => 'gray' );
        $cv->createLine( 1, $where, $boardsize - 2, $where, -fill => 'gray' );
    }
    foreach my $pos ( 0 .. 3 ) {
        my $where = 3 * $pos * ( $cellsize + 1 );
        $cv->createLine( $where, 0, $where, $boardsize - 1, -fill => 'black' );
        $cv->createLine( 0, $where, $boardsize - 1, $where, -fill => 'black' );
    }

    # create the rectangle that frames the freshly found value
    $cv->createRectangle( -999, -999, -888, -888, -tags => 'fresh' );

    # create the rectangle that frames the previously found value
    $cv->createRectangle(
        -999, -999, -888, -888,
        -tags    => 'previous',
        -outline => 'gray'
    );
    return;
}

# add a cell value to the Sudoku board
#   display_cellvalue($cellrow, $cellcol, $cellvalue, $strategy)
#   Called from the big loop (sub Run::_run_puzzle)
#   Also called from sub Run::_insert_presets (displays value in blue)
#
sub display_cellvalue {
    my ( $row, $col, $value, $strategy ) = @_;

    my $tx = $cv->createText(
        _cvpos($col) + $cellsize / 2,
        _cvpos($row) + $cellsize / 2,
        -text => $value
    );

    # display preset values in blue and bold
    if ( $strategy eq 'preset' ) {

        if ( !defined $mw->fontNames )
        {    # caveat: works if we use only one fontname
            my $txfont = $cv->itemcget( $tx, -font );
            my $font_family = $mw->fontActual( $txfont, '-family' );
            $mw->fontCreate(
                'presetfontname',
                -family => $font_family,
                -weight => 'bold'
            );
        }
        $cv->itemconfigure( $tx, -font => 'presetfontname', -fill => 'blue' );
        $preset_count++;
    }

    _delete_cands("r${row}c$col");    # delete cand. squares of this cell
    return if $strategy eq 'preset';
    $values_count++;

    # move the "previous" frame to the old "fresh" cell
    if ( $values_count > 1 ) {
        $cv->coords( 'previous', $cv->coords('fresh') );
    }

    # frame the new value
    # the frame is created in sub _build_sudoku_board
    # move the frame to the cell
    my ( $basex, $basey );
    $basex = _cvpos($col);
    $basey = _cvpos($row);
    $cv->coords(
        'fresh', $basex + 4, $basey + 4,
        $basex + $cellsize - 3,
        $basey + $cellsize - 3
    );
    return;
} ## end sub display_cellvalue

sub get_initialpuzzle {
    my @game;

    require Tk::DialogBox;
    my $db = $mw->DialogBox(
        -title          => 'Initial puzzle',
        -buttons        => [qw/Ok Cancel/],
        -default_button => 'Cancel',
        -cancel_button  => 'Cancel'
    );
    $db->add( 'Listbox', -selectmode => 'single', -height => 3, -width => 0 )
      ->pack();
    my $lb = $db->Subwidget('listbox');
    $lb->insert(
        'end',
        'Read from file',
        'Insert manually',
        'Read example file'
    );
    $lb->bind( '<Double-Button-1>' => sub { $db->Subwidget('B_Ok')->invoke } );
    $db->configure( -popover => $mw );
    my $answer = $db->Show();
    exit if $answer eq 'Cancel';
    my ($sel_idx) = $lb->curselection;

    if ( $sel_idx == 0) {   # Read from file
        my $initfile = name_in();
        return unless $initfile;
        open( my $SUDO, '<', $initfile )
          or do { Games::Sudoku::Trainer::Run::user_err("can't open $initfile:\n$!"); return };
        @game = <$SUDO>;
        close($SUDO);
        show_filename($initfile);
    }
    elsif ( $sel_idx == 1 ) {   # Insert manually
        @game = do { require FindBin; qx"perl $FindBin::Bin/enter_presets.pl" };
    }
    elsif ( $sel_idx == 2 ) {   # Read example file
        use File::Basename;
        my $sampledir = dirname(__FILE__) . '/examples';
        $sampledir or die "0\nExamples not properly installed\n";
		my $options_ref = [-initialdir => $sampledir];
        $initfile = name_in($options_ref);
        return unless $initfile;
        open( my $SUDO, '<', $initfile )
          or do { Games::Sudoku::Trainer::Run::user_err("can't open $initfile:\n$!"); return };
        @game = <$SUDO>;
        close($SUDO);
        show_filename($initfile);
    }
    return @game;
} ## end sub get_initialpuzzle

sub show_filename {
    $initfile = shift;

    # if path in $initfile doesn't fit in Entry widget, show the end of it
    my ( $left, $right ) = $file_en->xview();
    if ( $right < 1 ) { $file_en->xviewMoveto(1.0) }
    return;
}

#=======================================================================
# Menubar callbacks
#=======================================================================

#-----------------------------------------------------------------------
# view candidate squares
#-----------------------------------------------------------------------

{

    my $have_candsquares;    # undef if never displayed until now

    # change the visibility of candidate squares
    # callback for the "view ... cand.s" checkbuttons
    #   labeltext: text of clicked checkbutton
    #              ('active candidates' or 'excluded candidates')
    #
    sub _show_candsquares {
        my $checklabel = shift;    # label of clicked checkbutton

        if ( not $have_candsquares ) {
            foreach my $cell ( @cells[ 1 .. 81 ] ) {
                next if $cell->Value;
                build_candsquares( $cv, $cell );
                _move_candsquares( $cv, $cell );
            }
            $have_candsquares = 1;
        }

        my $view_menu = $menubar->entrycget( 'View', -menu );
        my $state_ref = $view_menu->entrycget( $checklabel, -variable )
          ;    # ref to the current state of the checkbutton
        my $tag = $checklabel =~ /^active /i ? 'black' : 'red';
        $cv->itemconfigure( $tag,
            -state => ( $$state_ref ? 'normal' : 'hidden' ) );
        return;
    }

    # build the cand. squares of a cell
    # called from sub _show_candsquares and sub build_tracewindow
    #	build_candsquares($canv, $cell);
    #
    sub build_candsquares {
        my ( $canv, $cell ) = @_;

        # key: tag name, value: color constant (gray resp. light red)
        my %colors = ( 'black' => '#7f7f7f', 'red' => '#ff7f7f' );

        my $digit = 1;
        foreach my $r ( 0 .. 2 ) {
            my $y = $r * ( $candsize + 2 ) + 1;
            foreach my $c ( 0 .. 2 ) {
                my $x = $c * ( $candsize + 2 ) + 1;
                my $coltag = $cell->has_candidate($digit) ? 'black' : 'red';
                $canv->createRectangle(
                    $x, $y, $x + $candsize - 1, $y + $candsize - 1,
                    -fill    => $colors{$coltag},
                    -outline => $colors{$coltag},
                    -tags    => [ $coltag, $cell->Name, "d$digit", 'new' ],
                    -state   => 'hidden',
                );
                $digit++;
            }
        }
        return;
    }

    # move the new candidate squares to their position
    #	_move_candsquares($canv, $cell);
    #
    sub _move_candsquares {
        my ( $canv, $cell ) = @_;
        my ( $basex, $basey );

        my $row = $cell->Row_num;
        my $col = $cell->Col_num;
        $basex = _cvpos($col) + 2;
        $basey = _cvpos($row) + 2;
        $canv->move( 'new', $basex, $basey );
        $canv->dtag('new');
        return;
    }

    # exclude a digit from the cand.s display of a cell
    #	exclude_cand($cell, $digit);
    #
    sub exclude_cand {
        my ( $cell, $digit ) = @_;

        $have_candsquares or return;
        my ($square) = $cv->find( withtag => $cell->Name . "&&d$digit" );
        $square or return;
        $cv->dtag( $square, 'black' );
        $cv->addtag( 'red', withtag => $cell->Name . "&&d$digit" );

        # change color to a light red
        $cv->itemconfigure(
            $square,
            -fill    => '#ff7f7f',
            -outline => '#ff7f7f'
        );

        # update the visibility of excluded cand.s
        _show_candsquares('excluded candidates');
        return;
    }

    # delete all cand. squares of a cell
    # called from sub display_cellvalue
    #
    sub _delete_cands {
        my $cellname = shift;

        $have_candsquares or return;
        $cv->delete($cellname);
        return;
    }
}

#=======================================================================
# I/O dialogs
#=======================================================================

#-----------------------------------------------------------------------
# save sudoku puzzle
#-----------------------------------------------------------------------

{

    use File::Basename;

    my $lastfile;    # last filename used to save the current puzzle

    # ask for file name and write sudoku file
    # callback for File menu items "Save as" and "Save initial puzzle"
    # also called from sub _result_save
    #	_sudoku_save_as puzzle_state
    #		puzzle_state: 'current' or 'initial'
    #
    sub _sudoku_save_as {
        my $puzzle_state = shift;
        my $file;

        $file =
            $puzzle_state eq 'initial' ? undef
          : defined $lastfile          ? $lastfile
          : defined($initfile)         ? $initfile
          :                              undef;
        my ( $basename, $pathname ) =
          defined $file ? fileparse($file) : ( '', '.' );
        $file = $mw->getSaveFile(
            -title       => 'Sudoku output file',
            -initialdir  => $pathname,
            -initialfile => $basename,
            -filetypes => [
				[ 'Sudoku Files', '.sudo' ],
				[ 'Text Files', [ '.txt', '.text' ] ],
				[ 'All Files', ['*'] ],
			],
            -defaultextension => '.sudo',
        );
        return unless defined $file;
        use Encode;
        $file = encode( 'iso-8859-1', $file );

        if ( $puzzle_state eq 'current' ) {
            $lastfile = $file;
            Games::Sudoku::Trainer::Write_puzzle::write_result($file);
            $initfile or show_filename($file);
        }
        else {
            Games::Sudoku::Trainer::Write_puzzle::write_initial($file);
            show_filename($file);
        }
        return;
    }

    # write the current state of the sudoku puzzle to the current ouput file
    #	callback of the 'File / Save' menu item
    #	_result_save();
    #
    sub _result_save {
        if ( defined $lastfile ) {
            Games::Sudoku::Trainer::Write_puzzle::write_result($lastfile);
        }
        else {
            _sudoku_save_as('current');
        }
        return;
    }
}

#-----------------------------------------------------------------------

# Quit the trainer
# Remind if the initial puzzle hasn't been saved
#
sub quit {
    $initfile and Tk::exit();
    my $answer = $mw->messageBox(
        -title   => 'Reminder',
        -message => 'Save the initial puzzle?',
        -type    => 'YesNo',
        -icon    => 'question',
        -default => 'Yes'
    );
    $answer eq 'No' and Tk::exit();
    _sudoku_save_as('initial');
    Games::Sudoku::Trainer::Check_pause::endpause();
#    Tk::exit();
    exit();
}

#-----------------------------------------------------------------------
# save / load priority list
#-----------------------------------------------------------------------

sub _prio_save_as {
    my $types = [
        [ 'Priority Files', '.prio' ],
        [ 'Text Files', [ '.txt', '.text' ] ],
        [ 'All Files', ['*'] ],
    ];

    my $outfile = $mw->getSaveFile(
        -filetypes        => $types,
        -defaultextension => '.prio'
    );
    return unless defined $outfile;
    use Encode;
    $outfile = encode( 'iso-8859-1', $outfile );
    open( my $PRIO, '>', $outfile )
      or do { Games::Sudoku::Trainer::Run::user_err("Cannot open $outfile:\n$!"); return };
    print $PRIO join( "\n", Games::Sudoku::Trainer::Priorities::copy_strats() ), "\n";
    close($PRIO) or die "Cannot close $outfile: $!\n";
    return;
}

sub _prio_load {
    my $types = [
        [ 'Priority Files', '.prio' ],
        [ 'Text Files', [ '.txt', '.text' ] ],
        [ 'All Files', ['*'] ],
    ];

	my $options_ref = [
        -filetypes        => $types,
        -defaultextension => '.prio',
	];
    my $infile = name_in($options_ref);
    return unless $infile;
    open( my $PRIO, '<', $infile )
      or do { Games::Sudoku::Trainer::Run::user_err("can't open $infile:\n$!"); return };
    my @strats = <$PRIO>;
    close($PRIO);
    chomp foreach @strats;
#TODO: chomp @strats;   _or_   my @strats = chomp <$PRIO>;
    Games::Sudoku::Trainer::Priorities::set_strats( \@strats );
    return;
}

#-----------------------------------------------------------------------
# GUI helpers
#-----------------------------------------------------------------------

# Set pause mode
#    set_pause_mode(<new mode>);
#    set_pause_mode('default');   # revert to default pause mode
#
sub set_pause_mode {
    my $new_mode = shift;
    $new_mode eq 'default' and $new_mode = 'single-step';

    # clear pause mode restriction
    if ( Games::Sudoku::Trainer::Pause->Mode ne 'Trace a cell' ) {
        require Games::Sudoku::Trainer::GUIpause_restrict;
        Games::Sudoku::Trainer::GUIpause_restrict::norestrict_pause($menubar);
    }
    $pause_mode = $new_mode;
    Games::Sudoku::Trainer::Pause->setMode($new_mode);
    return;
}

# Insert the message in the status line
#   GUI::set_status($message);
#
sub set_status {
    $status = shift;
    return;
}

# (de)activate a button
#	GUI::button_state(button_name, 'enable' or 'disable');
#		currently supported button names: 'Run', 'Details'
#
sub button_state {
    my ( $but, $new_state ) = @_;
    my %buttons = ( Run => $run_bt, Details => $details_bt );

    $buttons{$but}
      ->configure( -state => $new_state eq 'enable' ? 'normal' : 'disabled' );
    if ( $but eq 'Details' ) {
        $pause_strat =
          $new_state eq 'enable' ? Games::Sudoku::Trainer::Pause->Strat : '';
    }
    return;
}

# wait for change of a variable
#   GUI::wait($variable_ref);
#
sub wait {
    my $var_ref = shift;
    $mw->waitVariable($$var_ref);

    # see the comment at $mw->protocol( 'WM_DELETE_WINDOW', ...)
    # near the end of sub _build_GUI
    $mw->raise();
    &$noop_sub();
    return;
}

# call Check_pause::endpause no longer on a click of the kill button
#   reason: the game is over, we aren't in a pause
#
sub set_exit_on_delete {
    $mw->protocol( 'WM_DELETE_WINDOW', \&quit );
    return;
}

# compute the upper or left canvas coordinate of a sudoku cell
#	$upper = _cvpos($rownum)  resp.  $left = _cvpos($colnum)
#
sub _cvpos {
    return ( $_[0] - 1 ) * ( $cellsize + 1 );
}

# build clues hash from clues array
#   %clues = recode_clues(ref_to_clues_array);
#
sub recode_clues {
    my $clues_ref = shift;
    my %clues_all;
    my ( @clue_units, $clue_cands, @clue_cells );

    foreach my $clue (@$clues_ref) {
        if ( ref $clue and $clue->isa('Games::Sudoku::Trainer::Unit') ) {
            push( @clue_units, $clue );
        }
        elsif ( !ref $clue ) {
            defined $clue or $clue = '<undef>';
            if ($clue_cands) {
                $mw->messageBox(
                    -title => 'Code error',
                    -icon  => 'info',
                    -message => "Duplicate candidates clue $clue_cands"
                                . " and $clue ((hopefully) harmless)"
                );
            }
            $clue_cands .= $clue;    # ??
        }
        elsif ( ref $clue eq 'Games::Sudoku::Trainer::Cell' ) {
            push( @clue_cells, $clue );
        }
        else {
            die "3\nUnknown clue $clue";
        }
    }

    @clue_units and $clues_all{units} = names(@clue_units);

    # separate cand. digits by commas
    $clue_cands and ( $clues_all{cands} = $clue_cands ) =~ s/(\d)(?=\d)/$1,/g;
    @clue_cells and $clues_all{cells} = names(@clue_cells);
    return \%clues_all;
} ## end sub recode_clues

# ask user for input filename
#   $infile = name_in($opts_array_ref);
#
sub name_in {
	my $opts_ref = shift;

	my %opts = (
        -filetypes => [
			[ 'Sudoku Files', '.sudo' ],
			[ 'Text Files', [ '.txt', '.text' ] ],
			[ 'All Files', ['*'] ],
		],
        -defaultextension => '.sudo',
		# overwrite defaults (Modern Perl Chap. 3/Hash Idioms)
	    $opts_ref ? @$opts_ref : (),
	);
    my $file = $mw->getOpenFile(%opts);
    return unless $file;
    use Encode;
    $file = encode( 'iso-8859-1', $file );
    return $file;
}

# return the names of the given objects as a string
# This is a dev. tool to inspect the erroneous result
# of a strategy sub. Tries to help identify faulty
# parameters. May also be helpful for other lists.
#   $namestring = names(list of cells and/or units);
#
sub names {
    return join(
        ',',
        map {
               !ref $_            ? "$_"
              : ref $_ eq 'REF'   ? 'REF'
              : ref $_ eq 'ARRAY' ? 'ARRAY'
              : $_->can('Name')   ? $_->Name
              : '???'
        } @_
    );
}

# Show message in messageBox widget
#   showmessage(message_lines);
#
sub showmessage {
    $mw->messageBox(@_);
    return;
}

1;
