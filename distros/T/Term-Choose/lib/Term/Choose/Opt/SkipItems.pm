package Term::Choose::Opt::SkipItems;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';

use Term::Choose::Constants qw( :all );


sub __key_skipped {
    my ( $self ) = @_;
    my $pressed_key = $self->{pressed_key};
    if ( ! defined $pressed_key ) {
        return;
    }
    elsif ( $pressed_key == VK_DOWN || $pressed_key == KEY_j ) {
        my $new_row = $self->Term::Choose::Opt::SkipItems::__next_valid_down();
        if ( defined $new_row ) {
            if ( $new_row > $self->{last_page_row} ) {
                $self->__set_cell( $self->{rc2idx}[$new_row][$self->{pos}[COL]] );
                $self->__wr_screen();
            }
            else {
                my $old_row = $self->{pos}[ROW];
                $self->{pos}[ROW] = $new_row;
                $self->__wr_cell( $old_row,          $self->{pos}[COL] );
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
            }
            return;
        }
        else {
            return VK_UP;
        }
    }
    elsif ( $pressed_key == VK_UP || $pressed_key == KEY_k ) {
        my $new_row = $self->Term::Choose::Opt::SkipItems::__next_valid_up();
        if ( defined $new_row ) {
            if ( $new_row < $self->{first_page_row} ) {
                $self->__set_cell( $self->{rc2idx}[$new_row][$self->{pos}[COL]] );
                $self->__wr_screen();
            }
            else {
                my $old_row = $self->{pos}[ROW];
                $self->{pos}[ROW] = $new_row;
                $self->__wr_cell( $old_row,          $self->{pos}[COL] );
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
            }
            return;
        }
        else {
            return VK_DOWN;
        }
    }
    elsif ( $pressed_key == VK_RIGHT || $pressed_key == KEY_l ) {
        my $new_col = $self->Term::Choose::Opt::SkipItems::__next_valid_right();
        if ( defined $new_col ) {
            my $old_col = $self->{pos}[COL];
            $self->{pos}[COL] = $new_col;
            $self->__wr_cell( $self->{pos}[ROW], $old_col );
            $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
        }
        else {
            return VK_LEFT;
        }
    }
    elsif ( $pressed_key == VK_LEFT || $pressed_key == KEY_h ) {
        my $new_col = $self->Term::Choose::Opt::SkipItems::__next_valid_left();
        if ( defined $new_col ) {
            my $old_col = $self->{pos}[COL];
            $self->{pos}[COL] = $new_col;
            $self->__wr_cell( $self->{pos}[ROW], $old_col );
            $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
        }
        else {
            return VK_RIGHT;
        }
    }
    elsif ( $pressed_key == KEY_TAB || $pressed_key == CONTROL_I ) {
        my ( $new_row, $new_col ) = $self->Term::Choose::Opt::SkipItems::__next_valid_right_down();
        if ( defined $new_row && defined $new_col ) {
            if ( $new_row > $self->{last_page_row} ) {
                $self->__set_cell( $self->{rc2idx}[$new_row][$new_col] );
                $self->__wr_screen();
            }
            else {
                my $old_row = $self->{pos}[ROW];
                my $old_col = $self->{pos}[COL];
                $self->{pos}[ROW] = $new_row;
                $self->{pos}[COL] = $new_col;
                $self->__wr_cell( $old_row         , $old_col          );
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
            }
        }
        else {
            return KEY_BSPACE;
        }
    }
    elsif ( $pressed_key == KEY_BSPACE || $pressed_key == CONTROL_H || $pressed_key == KEY_BTAB ) {
        my ( $new_row, $new_col ) = $self->Term::Choose::Opt::SkipItems::__next_valid_left_up();
        if ( defined $new_row && defined $new_col ) {
            if ( $new_row < $self->{first_page_row} ) {
                $self->__set_cell( $self->{rc2idx}[$new_row][$new_col] );
                $self->__wr_screen();
            }
            else {
                my $old_row = $self->{pos}[ROW];
                my $old_col = $self->{pos}[COL];
                $self->{pos}[ROW] = $new_row;
                $self->{pos}[COL] = $new_col;
                $self->__wr_cell( $old_row         , $old_col          );
                $self->__wr_cell( $self->{pos}[ROW], $self->{pos}[COL] );
            }
        }
        else {
            return KEY_TAB;
        }
    }
    elsif ( $pressed_key == VK_PAGE_DOWN || $pressed_key == CONTROL_F ) {
        my $id = $self->Term::Choose::Opt::SkipItems::__next_valid_id_up_or_down();
        if ( ! defined $id ) {
            $id = $self->Term::Choose::Opt::SkipItems::__closest_valid_id_within_page();
        }
        if ( ! defined $id ) {
            $id = $self->Term::Choose::Opt::SkipItems::__next_valid_id_from_next_page_to_end_page();
        }
        if ( defined $id ) {
            $self->__set_cell( $id );
            $self->__wr_screen();
            return
        }
        $self->__beep();
        return VK_PAGE_UP;
    }
        elsif ( $pressed_key == VK_PAGE_UP || $pressed_key == CONTROL_B ) {
        my $id = $self->Term::Choose::Opt::SkipItems::__next_valid_id_up_or_down();
        if ( ! defined $id ) {
            $id = $self->Term::Choose::Opt::SkipItems::__closest_valid_id_within_page();
        }
        if ( ! defined $id ) {
            $id = $self->Term::Choose::Opt::SkipItems::__next_valid_id_from_previous_page_to_first_page();
        }
        if ( defined $id ) {
            $self->__set_cell( $id );
            $self->__wr_screen();
            return
        }
        $self->__beep();
        return VK_PAGE_DOWN;
    }
    elsif ( $pressed_key == VK_HOME || $pressed_key == CONTROL_A ) {
        my $id = $self->Term::Choose::Opt::SkipItems::__first_valid_id();
        if ( defined $id ) {
            $self->__set_cell( $id );
            $self->__wr_screen();
            return
        }
        $self->__beep();
        return;
    }
    elsif ( $pressed_key == VK_END || $pressed_key == CONTROL_E ) {
        my $id = $self->Term::Choose::Opt::SkipItems::__last_valid_id();
        if ( defined $id ) {
            $self->__set_cell( $id );
            $self->__wr_screen();
            return
        }
        $self->__beep();
        return;
    }
    return;
}


sub __next_valid_down {
    my ( $self ) = @_;
    my $last_row = $#{$self->{rc2idx}};
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL];
    if ( $col > $self->{idx_of_last_col_in_last_row} ) {
        $last_row--;
    }
    while ( ++$row <= $last_row ) {
        if ( $self->{list}[$self->{rc2idx}[$row][$col]] !~ /$self->{skip_items}/ ) {
            return $row;
        }
    }
    return;
}


sub __next_valid_up {
    my ( $self ) = @_;
    my $first_row = 0;
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL];
    while ( --$row >= $first_row ) {
        if ( $self->{list}[$self->{rc2idx}[$row][$col]] !~ /$self->{skip_items}/ ) {
            return $row;
        }
    }
    return;
}


sub __next_valid_right {
    my ( $self ) = @_;
    my $last_col = $#{$self->{rc2idx}[$self->{pos}[ROW]]};
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL];
    while ( ++$col <= $last_col ) {
        if ( $self->{list}[$self->{rc2idx}[$row][$col]] !~ /$self->{skip_items}/ ) {
            return $col;
        }
    }
    return;
}


sub __next_valid_left {
    my ( $self ) = @_;
    my $first_col = 0;
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL];
    while ( --$col >= $first_col ) {
        if ( $self->{list}[$self->{rc2idx}[$row][$col]] !~ /$self->{skip_items}/ ) {
            return $col;
        }
    }
    return;
}


sub __next_valid_right_down {
    my ( $self ) = @_;
    my $last_row = $#{$self->{rc2idx}};
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL] + 1;
    while ( $row <= $last_row ) {
        my $last_col = $#{$self->{rc2idx}[$row]};
        while ( $col <= $last_col ) {
            if ( $self->{list}[$self->{rc2idx}[$row][$col]] !~ /$self->{skip_items}/ ) {
                return $row, $col;
            }
            ++$col;
        }
        ++$row;
        $col = 0;
    }
    return;
}


sub __next_valid_left_up {
    my ( $self ) = @_;
    my $first_row = 0;
    my $first_col = 0;
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL] - 1;
    while ( $row >= $first_row ) {
        while ( $col >= $first_col ) {
            if ( $self->{list}[$self->{rc2idx}[$row][$col]] !~ /$self->{skip_items}/ ) {
                return $row, $col;
            }
            --$col;
        }
        --$row;
        $col = $#{$self->{rc2idx}[$row]};
    }
    return;
}


sub __next_valid_id_up_or_down {
    my ( $self ) = @_;
    my $begin = $self->{first_page_row};
    my $end = $self->{last_page_row};
    my $row = $self->{pos}[ROW];
    my $col = $self->{pos}[COL];
    if ( $end == $#{$self->{rc2idx}} && $col > $self->{idx_of_last_col_in_last_row} ) {
        $end--;
    }
    my ( $row_up, $row_down ) = ( $row, $row );
    while ( 1 ) {
        --$row_up;
        ++$row_down;
        if ( $row_up >= $begin ) {
            my $id = $self->{rc2idx}[$row_up][$col];
            if ( $self->{list}[$id] !~ /$self->{skip_items}/ ) {
                return $id;
            }
        }
        elsif ( $row_down <= $end ) {
            my $id = $self->{rc2idx}[$row_down][$col];
            if ( $self->{list}[$id] !~ /$self->{skip_items}/ ) {
                return $id;
            }
        }
        else {
            return;
        }
    }
}


sub __closest_valid_id_within_page {
    my ( $self ) = @_;
    return $self->Term::Choose::Opt::SkipItems::__next_valid_id(
        $self->{rc2idx}[$self->{first_page_row}][ 0               ],
        $self->{rc2idx}[$self->{last_page_row} ][-1               ],
        $self->{rc2idx}[$self->{pos}[ROW]]      [$self->{pos}[COL]]
    );
}


sub __next_valid_id_from_next_page_to_end_page {
    my ( $self ) = @_;
    for my $row ( $self->{last_page_row} + 1 .. $#{$self->{rc2idx}} ) {
        for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
            my $id = $self->{rc2idx}[$row][$col];
            if ( $self->{list}[$id] !~ /$self->{skip_items}/ ) {
                return $id;
            }
        }
    }
    return;
}


sub __next_valid_id_from_previous_page_to_first_page {
    my ( $self ) = @_;
    for my $row ( reverse( 0 .. $self->{first_page_row} - 1 ) ) {
        for my $col ( reverse( 0 .. $#{$self->{rc2idx}[$row]} ) ) {
            my $id = $self->{rc2idx}[$row][$col];
            if ( $self->{list}[$id] !~ /$self->{skip_items}/ ) {
                return $id;
            }
        }
    }
    return; #
}


sub __first_valid_id {
    my ( $self ) = @_;
    for my $id ( 0 .. $#{$self->{list}} ) {
        if ( $self->{list}[$id] !~ /$self->{skip_items}/ ) {
            return $id;
        }
    }
    return;
}


sub __last_valid_id {
    my ( $self ) = @_;
    for my $id ( reverse( 0 .. $#{$self->{list}} ) ) {
        if ( $self->{list}[$id] !~ /$self->{skip_items}/ ) {
            return $id;
        }
    }
    return;
}


sub __next_valid_id {
    my ( $self, $begin, $end, $id ) = @_;
    my ( $id_up, $id_down ) = ( $id, $id );
    while ( 1 ) {
        --$id_up;
        ++$id_down;
        if ( $id_up >= $begin ) {
            return $id_up if $self->{list}[$id_up] !~ /$self->{skip_items}/;
        }
        elsif ( $id_down <= $end ) {
            return $id_down if $self->{list}[$id_down] !~ /$self->{skip_items}/;
        }
        else {
            return;
        }
    }
}


sub __prepare_default {
    my ( $self ) = @_;
    if ( $self->{list}[$self->{default} || 0] =~ /$self->{skip_items}/ ) {
        $self->{default} = $self->Term::Choose::Opt::SkipItems::__next_valid_id(
            0,
            $#{$self->{list}},
            $self->{default} || 0
        );
    }
}


sub __unmark_skip_items {
    my ( $self ) = @_;
    for my $row ( 0 .. $#{$self->{rc2idx}} ) {
        for my $col ( 0 .. $#{$self->{rc2idx}[$row]} ) {
            if ( $self->{marked}[$row][$col] && $self->{list}[ $self->{rc2idx}[$row][$col] ] =~ /$self->{skip_items}/ ) {
                $self->{marked}[$row][$col] = 0;
            }
        }
    }
}




1;

__END__
