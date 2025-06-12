package Term::Choose::Opt::Mouse;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';

use Term::Choose::Constants qw( :all );


sub __mouse_info_to_key {
    my ( $self, $button, $mouse_x, $mouse_y ) = @_;
    if ( $button == 4 ) {
        return VK_PAGE_UP;
    }
    elsif ( $button == 5 ) {
        return VK_PAGE_DOWN;
    }
    # ..._y, ..._x: absolute position, one-based index
    my $mouse_row = $mouse_y - 1 - $self->{offset_rows};
    my $mouse_col = $mouse_x - 1;
    if ( $mouse_row < 0 || $mouse_row > $#{$self->{rc2idx}} ) {
        return NEXT_get_key;
    }
    my $matched_col;
    my $begin_this_col = 0;
    my $row = $mouse_row + $self->{first_page_row};

    COL: for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
        my $begin_next_col;
        if ( $self->{current_layout} == -1 ) {
            my $idx = $self->{rc2idx}[$row][$col];
            $begin_next_col = $begin_this_col + $self->{width_elements}[$idx] + $self->{pad};
        }
        else {
            $begin_next_col = $begin_this_col + $self->{col_width_plus};
        }
        if ( $col == 0 ) {
            $begin_next_col -= int( $self->{pad} / 2 );
        }
        if ( $col == $#{$self->{rc2idx}[$row]} && $begin_next_col > $self->{avail_width} ) {
            $begin_next_col = $self->{avail_width};
        }
        if ( $mouse_col >= $begin_this_col && $mouse_col < $begin_next_col ) {
            $matched_col = $col;
            last COL;
        }
        $begin_this_col = $begin_next_col;
    }
    if ( ! defined $matched_col ) {
        return NEXT_get_key;
    }
    if ( defined $self->{skip_items} ) {
        my $idx = $self->{rc2idx}[$row][$matched_col];
        if ( $self->{list}[$idx] =~ /$self->{skip_items}/ ) {
            return NEXT_get_key;
        }
    }
    if ( $button == 1 ) {
        $self->{pos}[ROW] = $row;           # writes to $self
        $self->{pos}[COL] = $matched_col;   # writes to $self
        return LINE_FEED;
    }
    if ( $row != $self->{pos}[ROW] || $matched_col != $self->{pos}[COL] ) {
        my $not_pos = $self->{pos};
        $self->{pos} = [ $row, $matched_col ];   # writes to $self
        $self->__wr_cell( $not_pos->[0], $not_pos->[1] );
        $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
    }
    if ( $button == 3 ) {
        return KEY_SPACE;
    }
    else {
        return NEXT_get_key;
    }
}







1;

__END__
