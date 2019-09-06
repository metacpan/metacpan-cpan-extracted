package # hide from PAUSE
Term::TablePrint::ProgressBar;

use strict;
use warnings;
use 5.008003;

use Term::Choose::Constants qw( WIDTH_CURSOR );
use Term::Choose::Util      qw( get_term_width );


sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    my $count_cells = $self->{row_count} * $self->{col_count};
    if ( $self->{threshold} && $self->{threshold} < $count_cells ) {
        print "\rComputing: ";
        $self->{times} = 3;
        if ( $count_cells / $self->{threshold} > 50 ) {
            $self->{type} = 'multi';
            $self->{total} = $self->{row_count};
        }
        else {
            $self->{type} = 'single';
            $self->{total} = $self->{row_count} * $self->{times};
        }
    }
    return $self;
}


sub set_progress_bar {
    my ( $self ) = @_;
    if (! $self->{type} ) {
        return;
    }
    my $term_w = get_term_width();
    if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
        $term_w += WIDTH_CURSOR;
    }
    if ( $self->{type} eq 'multi' ) {
        $self->{fmt} = "\rComputing: (" . $self->{times}-- . ") %3d%% [%s]";
    }
    else {
        $self->{fmt} = "\rComputing: %3d%% [%s]";
    }
    if ( $term_w < 25 ) {
        $self->{short_print} = 1;
    }
    else {
        $self->{short_print} = 0;
    }
    $self->{bar_w} = $term_w - length( sprintf $self->{fmt}, 100, '' ) + 1; # +1: lenght("\r") == 1
    $self->{step} = int( $self->{total} / $self->{bar_w} || 1 );
    my $count;
    if ( $self->{type} eq 'multi' ) {
        $count = 0;
        $self->{next_update} = $self->{step};
    }
    else {
        $count = $self->{so_far} || 0;
        $self->{next_update} ||= $self->{step};
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
    if ( $self->{times} < 1 ||  $self->{type} eq 'multi' ) {
        $self->update_progress_bar( $self->{total} );
    }
    else {
        $self->{so_far} = $count;
    }
}









1;

__END__
