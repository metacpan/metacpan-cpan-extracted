package # hide from PAUSE
Term::TablePrint::ProgressBar;

use strict;
use warnings;
use 5.10.0;

use Term::Choose::Constants qw( WIDTH_CURSOR );
use Term::Choose::Screen    qw( clear_screen );
use Term::Choose::Util      qw( get_term_width );


sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    my $count_cells = $self->{data_row_count} * $self->{col_count};
    if ( $self->{threshold} && $self->{threshold} < $count_cells ) {
        print clear_screen;
        print "\rComputing: ";
        if ( $count_cells / $self->{threshold} > 50 ) {
            $self->{merge_progress_bars} = 0;
            $self->{total} = $self->{data_row_count};
        }
        else {
            $self->{merge_progress_bars} = 1;
            $self->{total} = $self->{data_row_count} * $self->{count_progress_bars};
        }
    }
    else {
        $self->{count_progress_bars} = 0;
    }
    return $self;
}


sub set_progress_bar {
    my ( $self ) = @_;
    if ( ! $self->{count_progress_bars} ) {
        return;
    }
    my $term_w = get_term_width();
    if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
        $term_w += WIDTH_CURSOR;
    }
    if ( $self->{merge_progress_bars} ) {
        $self->{fmt} = "\rComputing: %3d%% [%s]";
    }
    else {
        $self->{fmt} = "\rComputing: (" . $self->{count_progress_bars} . ") %3d%% [%s]";
    }
    $self->{short_print} = $term_w < 25 ? 1 : 0;
    $self->{bar_w} = $term_w - length( sprintf $self->{fmt}, 100, '' ) + 1; # +1: lenght("\r") == 1
    $self->{step} = int( $self->{total} / $self->{bar_w} || 1 );
    my $count;
    if ( $self->{merge_progress_bars} ) {
        $count = $self->{so_far} || 0;
        $self->{next_update} ||= $self->{step};
    }
    else {
        $count = 0;
        $self->{next_update} = $self->{step};
    }
    return $count;
}


sub update_progress_bar {
    my ( $self, $count ) = @_;
    my $multi = int( $count / ( $self->{total} / $self->{bar_w} ) ) || 1;
    if ( $self->{short_print} ) {
        print "\r" . ( '=' x $multi ) . ( ' ' x $self->{bar_w} - $multi );
    }
    else {
        printf $self->{fmt}, ( $count / $self->{total} * 100 ), ( '=' x $multi ) . ( ' ' x ( $self->{bar_w} - $multi ) );
    }
    $self->{next_update} = $self->{next_update} + $self->{step};
}


sub last_update_progress_bar {
    my ( $self, $count ) = @_;
    if ( $self->{count_progress_bars} &&  $self->{merge_progress_bars} ) {
        $self->{so_far} = $count;
    }
    else {
        $self->update_progress_bar( $self->{total} );
    }
    $self->{count_progress_bars}--;
}









1;

__END__
