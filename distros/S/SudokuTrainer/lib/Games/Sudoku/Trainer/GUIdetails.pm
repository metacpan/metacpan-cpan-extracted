use strict;
use warnings;
#use feature qw( say );

#-----------------------------------------------------------------------
# strategy details dialog
#-----------------------------------------------------------------------

package
    Games::Sudoku::Trainer::GUIdetails;

use version; our $VERSION = qv('0.03');    # PBP

my $details_bt;    # the Show details Button
my $details_db;     # DialogBox to show strategy details
my @clues_objs;

# global constants
my @all_types = qw/units cands cells/;    # all clue type names

# construct the strategy details dialog
#   build_strat_details(\$details_bt);
#
sub build_strat_details {
    $details_bt = ${ shift() };    # dereference par.
    require Tk::DialogBox;

    my %detail_typenames;
    @detail_typenames{@all_types} = qw/Units Candidates Cells/;
    $details_db = $details_bt->DialogBox(
        -title       => 'Strategy details',
        -showcommand => \&_fill_details,
    );
    $details_db->Label( -text => 'Success details of this strategy' )->pack();
    $details_db->Label( -text => "Uncover as few details as possible\n"
          . "to detect this strategy by yourself\n" )->pack();
    my $fr =
      $details_db->add( 'Frame', -borderwidth => 1, -relief => 'solid' )
      ->pack();

    foreach my $row ( 0 .. $#all_types ) {
        my $type = $all_types[$row];
        my $show_bt;      # the 'Show' Button for this type
        my $count;        # click count of this 'Show' Button
        my $uncovered;    # the textvar holding the names of uncovered clues
        $show_bt = $fr->Button(
            -text    => 'Show',
            -command => [ \&_show_more, \$clues_objs[$row] ]
        );
        $fr->Label( -text => $detail_typenames{$type} )->grid(
            $fr->Label(
                -textvariable => \$uncovered,
                -background   => 'yellow'
            ),
            $show_bt,
            -sticky => 'w',
        );
        $clues_objs[$row] = Games::Sudoku::Trainer::Clues->new(
		  Show_btn => $show_bt, Uncov_clues => \$uncovered 
		);
    }
    $details_db->resizable( 0, 0 );    # freeze window size
    $details_db->Show();
    return;
} ## end sub build_strat_details

# prepare the details dialog for display of the clues of the currrent strategy
#   Callback of the Details dialog
#
sub _fill_details {
    my $clues_all_ref =
      Games::Sudoku::Trainer::GUI::recode_clues(
 	    Games::Sudoku::Trainer::Pause->Info_ref->[2] );
    my %clues_all = %$clues_all_ref;
    foreach my $row ( 0 .. $#all_types ) {
        my $type      = $all_types[$row];
        my $clues_obj = $clues_objs[$row];
        my $show_btn  = $clues_obj->Show_btn;
        my $clues_all;    # all avail. clues for this clue type
        if ( exists( $clues_all{$type} ) ) {
            $clues_all = $clues_all{$type};
            $show_btn->configure( -text => 'Show', -state => 'active' );
        }
        else {
            $clues_all = '';
            $show_btn->configure( -text => 'Show', -state => 'disabled' );
        }
        $clues_obj->set_Clues_all($clues_all);
        $clues_obj->set_Uncov_clues('');    # clear uncovered text in col 1
        $clues_obj->clear_Uncov_count;
    }
    return;
}

# uncover one more clue of this type
#   callback of the corresponding "Show more" button
#   _show_more($clues_obj_ref);
#
sub _show_more {
    my $clues_obj = ${ shift() };    # dereference par.

 #    my $clues_obj = ${shift};   # Ambiguous use of ${shift} resolved to $shift
 #    my $clues_obj = $&{shift};  # ($clues_obj is undef)
 #    my $clues_obj = ${&shift};  # Undefined subroutine &GUI::shift called
 #    my $clues_obj = ${&CORE::shift};   # Undefined sub &CORE::shift called
 #    my $clues_obj = ${&Run::shift};    # Undefined sub &Run::shift called
    my $count = $clues_obj->incr_Uncov_count;
    my $all   = $clues_obj->Clues_all;
    $all =~ /^((\w+,?){$count})/;
    my $uncovered = $1 || $all;
    my $btn = $clues_obj->Show_btn;
    if ( $uncovered eq $all ) {
        $btn->configure( -state => 'disabled' );
    }
    elsif ( $btn->cget( -text ) eq 'Show' ) {
        $btn->configure( -text => 'Show more' );
    }
    $uncovered =~ s/,$//;    # some cosmetics
    $uncovered =~ s/,/, /g;

    # insert uncovered text in col 1
    $clues_obj->set_Uncov_clues($uncovered);
    return;
}

# Private class for module Games::Sudoku::Trainer::GUIdetails.
# Each Clues object holds the info for 1 row in the strategy details dialog,
# i.e. for 1 of the 3 clues types: units, cands, cells
#
package
    Games::Sudoku::Trainer::Clues;

sub new {    # constructor for Clues objects
    my $class = shift;
    my $self  = {@_};
    return bless $self, $class;
}

# Standard getters
sub Clues_all { return $_[0]->{Clues_all} }
sub Show_btn  { return $_[0]->{Show_btn} }

# set the Clues_all property of this clues type
sub set_Clues_all {
    my $self = shift;
    my ($new_val) = @_;
    $self->{Clues_all} = $new_val;
    return;
}

# set the uncovered clues of this clues type
sub set_Uncov_clues {
    my $self = shift;
    my ($new_text) = @_;
    ${ $self->{Uncov_clues} } = $new_text;
    return;
}

# clear the count of uncovered clues of this clues type
sub clear_Uncov_count {
    my $self = shift;
    $self->{Uncov_count} = 0;
    return;
}

# increment the count of uncovered clues of this clues type
# returns the new value
sub incr_Uncov_count {
    my $self = shift;
    return ++$self->{Uncov_count};
}

1;
