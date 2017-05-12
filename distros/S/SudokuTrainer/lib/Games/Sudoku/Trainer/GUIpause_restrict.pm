use strict;
use warnings;
#use feature qw( say );

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;    # cell objects		(1 .. 81)
our @rows;     # row objects		(1 .. 9)

package
    Games::Sudoku::Trainer::GUIpause_restrict;

use version; our $VERSION = qv('0.01');    # PBP

use Tk;

# globals of module Games::Sudoku::Trainer::GUIpause_restrict
my $mw;                                     # main window
my $display_mode_restrict;                  # for display of mode restriction

sub _config_disp_mode_restrict {
    my $restrict_lb = shift;

    $mw = $restrict_lb->toplevel;
    $restrict_lb->configure( -textvariable => \$display_mode_restrict );
    return;
}

#-----------------------------------------------------------------------
# pause mode restriction
#-----------------------------------------------------------------------

{

    # Dialog to ask for a unit name
    # Used when restricting pause mode 'Value found' to a unit
    #
    sub enter_unitname {
        $mw or _config_disp_mode_restrict(shift);

        my $pause_restrict;    # temp. pause mode restriction

        _kill_tracewindow();
        require Tk::DialogBox;
        my $db = $mw->DialogBox(
            -title          => 'Restrict pause mode',
            -buttons        => [qw/Ok Cancel/],
            -default_button => 'Ok',
            -cancel_button  => 'Cancel'
        );
        $db->Label( -text => "Restrict pause mode 'Value found'"
              . " to a unit\n(e. g. b5 for the center block)" )->pack();
        my $en = $db->add(
            'Entry',
            -width        => 2,
            -textvariable => \$pause_restrict,
            -validate     => 'key'
        )->pack();
        $en->configure( -validatecommand => [ \&_validate_unit, $en ] );
        $en->selectionRange( 0, 'end' );
        $db->configure( -focus => $en );
        my $answer = $db->Show();

        if ( $answer eq 'Cancel' or $pause_restrict !~ /^(r|c|b)[1-9]$/ ) {
            Games::Sudoku::Trainer::GUI::set_pause_mode('default');
            return;
        }
        my $unit  = Games::Sudoku::Trainer::Unit->by_name($pause_restrict);
        my $count = $unit->active_Members;
        if ( $unit->active_Members <= 1 ) {
            Games::Sudoku::Trainer::Run::user_err(
			  "All values of $pause_restrict already found");
            Games::Sudoku::Trainer::GUI::set_pause_mode('default');
        }
        $display_mode_restrict = $pause_restrict;
        Games::Sudoku::Trainer::Pause->setMode_restriction($pause_restrict);
        return;
    } ## end sub enter_unitname

    sub _validate_unit {
        my $en = shift;
        my ( $unit_name, undef, undef, undef, $action ) = @_;

        if ( $action > 1 ) { $action -= 7 }
        ;    # repair a bug in ActivePerl
        if ( $action != 1 ) { return 1 }
        ;    # wait for action 'insert'
        if ( $unit_name =~ /^(r|c|b)$/ ) {
            return 1;    # wait for 2nd char
        }
        if ( $unit_name !~ /^(r|c|b)[1-9]$/ ) {
            Games::Sudoku::Trainer::Run::user_err(
                "Invalid unit name $unit_name,"
                  . " format is 'unit type - unit number'",
                "\n(unit type: 'r' for row, 'c' for column, 'b' for block)"
            );
            $en->focusForce();
            return 0;
        }
        return 1;
    }
}

{

    # Dialog to ask for a cell name
    # Used for pause mode 'Trace a cell'
    # and when restricting pause mode 'Value found' to a cell
    #
    sub enter_cellname {
        $mw or _config_disp_mode_restrict(shift);

        my $pause_restrict;    # temp. pause mode restriction

        require Tk::DialogBox;
        my $db = $mw->DialogBox(
            -title          => 'Enter cell name',
            -buttons        => [qw/Ok Cancel/],
            -default_button => 'Ok',
            -cancel_button  => 'Cancel'
        );
        $db->Label( -text =>
              "Enter the cell name\n(e. g. r1c9 for the upper right cell)" )
          ->pack();
        my $en = $db->add(
            'Entry',
            -width        => 4,
            -textvariable => \$pause_restrict,
            -validate     => 'key'
        )->pack();
        $en->configure( -validatecommand => [ \&_validate_cell, $en ] );
        $en->selectionRange( 0, 'end' );
        $db->configure( -focus => $en );
        my $answer = $db->Show();

        $pause_restrict = lc($pause_restrict);
        if ( $answer eq 'Cancel' or $pause_restrict !~ /^r[1-9]c[1-9]$/ ) {
            Games::Sudoku::Trainer::GUI::set_pause_mode('default');
            return;
        }
        my $cell      = Games::Sudoku::Trainer::Cell->by_name($pause_restrict);
        my $candcount = $cell->cands_count;

        # check if we are just inserting this value
        my $pause_info_ref = Games::Sudoku::Trainer::Pause->Info_ref;
        if (    $candcount > 0
            and defined $pause_info_ref
            and $pause_info_ref->[1] eq 'insert'
            and $pause_info_ref->[3]->[1] == $cell )
        {
            $candcount = 0;
        }
        if ( $candcount == 0 ) {
            Games::Sudoku::Trainer::Run::user_err(
			  "Value of $pause_restrict already found");
            Games::Sudoku::Trainer::GUI::set_pause_mode('default');
            return;
        }
        $display_mode_restrict = $pause_restrict;
        Games::Sudoku::Trainer::Pause->setMode_restriction($pause_restrict);
        return;
    } ## end sub enter_cellname

    # validate cell name
    #
    sub _validate_cell {
        my $en = shift;
        my ( $cell_name, undef, undef, undef, $action ) = @_;

        if ( $action > 1 ) { $action -= 7 };    # repair a bug in ActivePerl
        if ( $action != 1 ) { return 1 };    # wait for action 'insert'
        if ( $cell_name =~ /^r[1-9]?c?[1-9]?$/i ) {
            return 1;    # (still) ok
        } else {
            Games::Sudoku::Trainer::Run::user_err(
                "Invalid cell name $cell_name, format is\n",
                '"r" - row number - "c" - column number'
            );
            $en->focusForce();
            return 0;
        }
    }
}

# Clear current pause mode restriction
#
sub norestrict_pause {
    my $menubar = shift;

    my $pause_restriction =
      $display_mode_restrict;    # current pause mode restriction

    $pause_restriction or return;
    length($pause_restriction) == 4 and _kill_tracewindow();
    $pause_restriction or return;

    # now must be a 'Value found' restriction
    my $pausemode_menu = $menubar->entrycget( 'Pause Mode', -menu );
    my $valfound = $pausemode_menu->entrycget( 'Value found', -menu );
    my $anywhere = $valfound->entrycget( 'anywhere', -variable );
    $$anywhere             = 'anywhere';
    $display_mode_restrict = '';
    Games::Sudoku::Trainer::Pause->setMode_restriction('');
    return;
}

#-----------------------------------------------------------------------
# view trace window
#-----------------------------------------------------------------------

{

    my $pause_restriction;    # current pause mode restriction
    my $tracewindow;          # Toplevel widget
    my $canv;                 # Canvas widget of trace window
    my $tracestatus;          # status text

    sub build_tracewindow {
        my ( $candsize, $cellsize ) = @_;

        $pause_restriction =
          $display_mode_restrict;    # current pause mode restriction

        $pause_restriction or return;

        # if the user selected 'trace a cell' while 'trace a cell' is
        # already active, the old trace window must be destroyed
        if ( Exists($tracewindow) ) {
            $tracewindow->destroy;
        }
        $tracewindow = $mw->Toplevel();
        $tracewindow->overrideredirect(1);    # no window frame
                                              # separator
        $tracewindow->Frame( -height => 1, -bg => 'black' )
          ->pack( -pady => 4, -expand => 1, -fill => 'x' );
        $tracewindow->Label( -text => "Trace of cell $pause_restriction" )
          ->pack( -pady => 4 );

        $canv =
          $tracewindow->Canvas( -borderwidth => 2, -relief => 'groove' )
          ->pack( -anchor => 'w' );
        $tracewindow->Label( -textvariable => \$tracestatus )->pack();
        Games::Sudoku::Trainer::GUI::build_candsquares( $canv,
            Games::Sudoku::Trainer::Cell->by_name($pause_restriction) );
        $canv->move( 'new', 2, 2 );
        $canv->itemconfigure(
            'black',
            -fill    => 'black',
            -outline => 'black',
            -state   => 'normal'
        );
        $canv->itemconfigure(
            'red',
            -fill    => 'red',
            -outline => 'red',
            -state   => 'normal'
        );

        # frame the cand.s squares collection
        $canv->createRectangle(
            0, 0,
            $cellsize + 1,
            $cellsize + 1,
            -tags => 'new'
        );
        $canv->scale( 'new', 0, 0, 1.5, 1.5 );
        $canv->dtag('new');

        # legend
        my $pointfac = 1 / $canv->fpixels('1p');
        my $legendx  = $cellsize + 30;
        my $legendy  = 3;
        my %legend_values =
          ( qw/black Active   red Excluded/, 'orange' => 'Just excluded' );
        foreach my $key ( keys %legend_values ) {
            $canv->createRectangle(
                $legendx, $legendy, $legendx + $candsize - 1,
                $legendy + $candsize - 1,
                -fill    => $key,
                -outline => $key,
            );
            $canv->createText(
                $legendx + 10, $legendy + $candsize / 2 - 1,
                -anchor => 'w',
                -text   => $legend_values{$key}
            );
            $legendy += 20 * $pointfac;    # linespace 20 points
        }
        $canv->configure( -scrollregion => [ $canv->bbox('all') ] );
        my ( $x_ul, $y_ul, $x_lr, $y_lr ) = $canv->bbox('all');
        $canv->configure(
            -height => $y_lr - $y_ul - 1,
            -width  => $x_lr - $x_ul - 1
        );
        $tracewindow->resizable( 0, 1 );    # freeze window width

        # follow the main window when it moves
        $mw->bind(
            '<Configure>' => sub {
                $mw->after(
                    200 => sub {
                        $tracewindow or return;
                        $tracewindow->state ne 'normal' and return;
                        $tracewindow->withdraw;
                        $tracewindow->Popup(
                            -overanchor => 'sw',
                            -popanchor  => 'nw'
                        );
                    }
                );
            }
        );

        # nothing to update directly after presetting
        # (the pause directly after presetting doesn't set
        # Games::Sudoku::Trainer::Pause::Info_ref)
        my $pause_info_ref = Games::Sudoku::Trainer::Pause->Info_ref;
        $pause_info_ref and update_tracewindow($pause_info_ref);
        $tracewindow->Popup(
            -popover    => $mw,
            -overanchor => 'sw',
            -popanchor  => 'nw'
        );
        return;
    } ## end sub build_tracewindow

    # update the colors of the candidate squares in the trace window,
    # then pause until the user hits the Run button.
    # called from Games::Sudoku::Trainer::Check_pause::check_pause
    # also called from show_tracewindow to initialize the colors (doesn't pause)
    #
    sub update_tracewindow {
        my $found_info_ref = shift;

        $tracestatus = '';
        if ( $found_info_ref->[1] eq 'insert' ) {
            my $cell = $found_info_ref->[3]->[1];
            if ( $cell->Name eq $pause_restriction ) {
                $tracestatus =
                    "Value found for the trace cell\nby strategy "
                  . Games::Sudoku::Trainer::Pause->Strat
                  . ".\nEnd of trace mode";
                Games::Sudoku::Trainer::GUI::set_pause_mode('default');
                Games::Sudoku::Trainer::Check_pause::pause();

                # don't kill the tracewindow if the user created a new one
                # during the pause
                _kill_tracewindow()
                  if ( Games::Sudoku::Trainer::Pause->Mode ne 'Trace a cell' );
                return;
            }
            else {
                my @trace_units =
                  Games::Sudoku::Trainer::Cell->by_name($pause_restriction)
                  ->get_Containers();
                my @cell_units = $cell->get_Containers();

                # the trace cell may be in the same block _and_ in a same line
                # as the cell with the just found value. In this case a
                # duplicate pause is avoided in sub _change_color
                foreach ( 0 .. 2 ) {
                    next if ( $cell_units[$_] != $trace_units[$_] );
                    _change_color( $found_info_ref->[3]->[0] );
                }
            }
        }
        else {    # exclude cand.
            my $exclude_info_ref = $found_info_ref->[3];

            # get freshly excluded cand.s
            my @trace_this = map {
                $_ =~ /(\d+)-(\d)/;
                my $cellname = $cells[$1]->Name;
                my $cand     = $2;
                $cellname =~ /$pause_restriction/ ? ($cand) : ()
            } @$exclude_info_ref;
            _change_color(@trace_this);
        }
        return;
    } ## end sub update_tracewindow

    # change color of freshly excluded cand.s
    # color goes from black to orange, then after the pause to red
    #	_change_color(freshly-excluded_list);
    #
    sub _change_color {

        # digits freshly excluded as cand.s for the trace cell
        my @trace_this = @_;
        my $fresh;    # count of fresh squares

        foreach my $digit (@trace_this) {
            my ($square) =
              $canv->find( withtag => $pause_restriction . "&&d$digit" );
            next unless $square;

            # avoid to confuse the user by pausing twice on a square
            grep ( $_ =~ 'black', $canv->gettags($square) ) or next;
            $canv->dtag( $square, 'black' );
            $canv->addtag( 'fresh',
                withtag => $pause_restriction . "&&d$digit" );
            $fresh++;
        }
        $fresh or return;
        $canv->itemconfigure(
            'fresh',
            -fill    => 'orange',
            -outline => 'orange'
        );
        $tracestatus =
          "$fresh candidates excluded by strategy "
          . Games::Sudoku::Trainer::Pause->Strat . ".\n";

        # if the trace window isn't popped up yet, we are currently in a pause
        $canv->ismapped or return;
        Games::Sudoku::Trainer::Check_pause::pause();
        if ( !Tk::Exists($canv) ) {
            return;    # user terminated trace mode
        }
        $canv->itemconfigure( 'fresh', -fill => 'red', -outline => 'red' );
        my @fresh = $canv->find( withtag => 'fresh' );
        $canv->addtag( 'red', withtag => 'fresh' );
        $canv->dtag('fresh');
        $tracewindow->update();
        return;
    } ## end sub _change_color

    # kill the trace window
    #
    sub _kill_tracewindow {
        $tracewindow or return;
        $tracewindow->destroy;
        $tracewindow           = undef;
        $display_mode_restrict = '';
        Games::Sudoku::Trainer::Pause->setMode_restriction('');
        return;
    }

}

1;
