use strict;
use warnings;
#use feature qw( say );

package
    Games::Sudoku::Trainer::GUIhist;

use version; our $VERSION = qv('0.01');    # PBP

my @history_raw;    # raw history of successful strategies

# add info about latest found to history
#   called from the main loop of the Sudoku trainer
#
sub add_history {
    push( @history_raw, shift );
}

#-----------------------------------------------------------------------
#  history dialog
#-----------------------------------------------------------------------

my $mw;    # main window

my $history_db;    # DialogBox to show strategy history

sub _build_history {
    $mw = shift;

    require Tk::ROText;

    $history_db = $mw->DialogBox();
    my $tx = $history_db->add(
        'ROText',
        -width  => 46,
        -wrap   => 'none',
        -relief => 'flat'
    )->pack( -expand => 1, -fill => 'x' );

    my $txfont = $tx->cget( -font );
    my $font_family = $mw->fontActual( $txfont, '-family' );
    $mw->fontCreate( 'histfontname', -family => $font_family, -size => 10 );
    $tx->configure( -font => 'histfontname' );
    $mw->fontDelete('histfontname');
    return;
}

sub hist_summary {
    $history_db or _build_history(shift);

    my %found_counts;    # counts of successful strategies
    my $tx = $history_db->Subwidget('rotext');
    $tx->delete( '1.0', 'end' );

    foreach my $found_info_ref (@history_raw) {
        my $strategy = $found_info_ref->[0];
        $found_counts{$strategy}++;
    }

    # sort by priority
    my $prios_ref = _build_stratprios();
    foreach my $strat (
        sort { $prios_ref->{$a} <=> $prios_ref->{$b} }
        keys %found_counts
      )
    {
        my $count = $found_counts{$strat};
        $tx->insert( 'end',
            'found ' . ( $count < 10 ? ' ' : '' ) . "$count '$strat'\n" );
    }

    $history_db->configure( -title => 'History summary' );
    $tx->configure( -height => scalar keys %found_counts );
    $history_db->Show();
    return;
}

# build the strategies priority hash
#
sub _build_stratprios {
    my %stratprios;    # key: strategy name, value: strategy priority

    my @strats = Games::Sudoku::Trainer::Priorities->copy_strats();
    @stratprios{ 'Full House', @strats } = ( 0 .. @strats );
    return \%stratprios;
}

sub hist_overview {
    my $curr_strat;
    my $count;
    my $valcount;
    my $strategy;

    @history_raw or return;
    $history_db  or _build_history(shift);

    my $tx = $history_db->Subwidget('rotext');
    $tx->delete( '1.0', 'end' );
    $curr_strat = $history_raw[0]->[0];
    my $action = $history_raw[0]->[1];    # 'insert' or 'exclude'
    foreach my $found_info_ref (@history_raw) {
        $strategy = $found_info_ref->[0];
        if ( $strategy eq $curr_strat ) {
            $count++;
        }
        else {
            if ( $action eq 'insert' ) {
                $valcount += $count;
                $tx->insert( 'end', sprintf "Value %2u   found %2u '%s'\n",
                    $valcount, $count, $curr_strat );
            }
            else {
                $tx->insert( 'end', sprintf "           found %2u '%s'\n",
                    $count, $curr_strat );
            }
            $curr_strat = $strategy;
            $count      = 1;
        }
        $action = $found_info_ref->[1];    # 'insert' or 'exclude'
    }
    if ( $action eq 'insert' ) {
        $valcount += $count;
        $tx->insert( 'end', sprintf "Value %2u   found %2u '%s'\n",
            $valcount, $count, $curr_strat );
    }
    else {
        $tx->insert( 'end', sprintf "           found %2u '%s'\n",
            $count, $curr_strat );
    }
    $history_db->configure( -title => 'History overview' );
    my $last = $tx->index('end');
    $last =~ s/\..*//;    # remove character part of position
    $tx->configure( -height => $last );
    $history_db->Show();
    return;
} ## end sub _hist_overview

sub hist_details {
    $mw = shift;
    require Tk::DialogBox;
    require Tk::HList;

    my $db = $mw->DialogBox( -title => 'History details' );
    my $hl = $db->Scrolled(
        'HList',
        -scrollbars => 'oe',
        -columns    => 5,
        -header     => 1,
        -takefocus  => 0,
        -height     => 30,
        -width      => 60
    )->pack( -expand => 1, -fill => 'both' );
    my @headers = (
        "Value\nnumber", "Strategy",
        "Clue\nunits",   "Clue\ncandidates",
        "Clue\ncells"
    );
    require Tk::ItemStyle;
    my $headstyle = $hl->ItemStyle( 'text', -anchor => 'center' );

    foreach my $col ( 0 .. 4 ) {
        $hl->columnWidth( $col, '' );
        $hl->headerCreate(
            $col,
            -text  => $headers[$col],
            -style => $headstyle
        );
    }
    my $value_count;
    foreach my $found_info_ref (@history_raw) {
        my $strategy      = $found_info_ref->[0];
        my $clues_all_ref = 
		  Games::Sudoku::Trainer::GUI::recode_clues( $found_info_ref->[2] );
        $hl->add($found_info_ref);
        $hl->itemCreate( $found_info_ref, 0,
            -text => $found_info_ref->[1] eq 'insert' ? ++$value_count : '' );
        $hl->itemCreate( $found_info_ref, 1, -text => "$strategy  " );
        $hl->itemCreate( $found_info_ref, 2, -text => $clues_all_ref->{units} );
        $hl->itemCreate( $found_info_ref, 3, -text => $clues_all_ref->{cands} );
        $hl->itemCreate( $found_info_ref, 4, -text => $clues_all_ref->{cells} );
    }
    $db->Show();
    $db->destroy;
    return;
} ## end sub _hist_details

1;
