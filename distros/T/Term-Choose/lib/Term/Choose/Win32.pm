package Term::Choose::Win32;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.511';

use Win32::Console qw( STD_INPUT_HANDLE ENABLE_MOUSE_INPUT ENABLE_PROCESSED_INPUT STD_OUTPUT_HANDLE
                       RIGHT_ALT_PRESSED LEFT_ALT_PRESSED RIGHT_CTRL_PRESSED LEFT_CTRL_PRESSED SHIFT_PRESSED
                       FOREGROUND_INTENSITY BACKGROUND_INTENSITY );

use Term::Choose::Constants qw( :win32 );


sub SHIFTED_MASK () {
      RIGHT_ALT_PRESSED
    | LEFT_ALT_PRESSED
    | RIGHT_CTRL_PRESSED
    | LEFT_CTRL_PRESSED
    | SHIFT_PRESSED
}



sub new {
    return bless {}, $_[0];
}


sub __get_key_OS {
    my ( $self, $mouse ) = @_;
    my @event = $self->{input}->Input;
    my $event_type = shift @event;
    return NEXT_get_key if ! defined $event_type;
    if ( $event_type == 1 ) {
        my ( $key_down, $repeat_count, $v_key_code, $v_scan_code, $char, $ctrl_key_state ) = @event;
        return NEXT_get_key if ! $key_down;
        if ( $char ) {
            if ( $char == 32 && $ctrl_key_state & ( RIGHT_CTRL_PRESSED | LEFT_CTRL_PRESSED ) ) {
                return CONTROL_SPACE;
            }
            else {
                return $char;
            }
        }
        else{
            if ( $ctrl_key_state & SHIFTED_MASK ) {
                return NEXT_get_key;
            }
            elsif ( $v_key_code == VK_PAGE_UP )   { return VK_PAGE_UP }
            elsif ( $v_key_code == VK_PAGE_DOWN ) { return VK_PAGE_DOWN }
            elsif ( $v_key_code == VK_END )       { return VK_END }
            elsif ( $v_key_code == VK_HOME )      { return VK_HOME }
            elsif ( $v_key_code == VK_LEFT )      { return VK_LEFT }
            elsif ( $v_key_code == VK_UP )        { return VK_UP }
            elsif ( $v_key_code == VK_RIGHT )     { return VK_RIGHT }
            elsif ( $v_key_code == VK_DOWN )      { return VK_DOWN }
            elsif ( $v_key_code == VK_INSERT )    { return VK_INSERT } # unused
            elsif ( $v_key_code == VK_DELETE )    { return VK_DELETE } # unused
            else                                  { return NEXT_get_key }
        }
    }
    elsif ( $mouse && $event_type == 2 ) {
        my( $x, $y, $button_state, $control_key, $event_flags ) = @event;
        my $button;
        if ( ! $event_flags ) {
            if ( $button_state & LEFTMOST_BUTTON_PRESSED ) {
                $button = 1;
            }
            elsif ( $button_state & RIGHTMOST_BUTTON_PRESSED ) {
                $button = 3;
            }
            elsif ( $button_state & FROM_LEFT_2ND_BUTTON_PRESSED ) {
                $button = 2;
            }
            else {
                return NEXT_get_key;
            }
        }
        elsif ( $event_flags & MOUSE_WHEELED ) {
            $button = $button_state >> 24 ? 5 : 4;
        }
        else {
            return NEXT_get_key;
        }
        return [ $self->{abs_cursor_y}, $button, $x, $y ];
    }
    else {
        return NEXT_get_key;
    }
}


sub __set_mode {
    my ( $self, $mouse, $hide_cursor ) = @_;
    $self->{input} = Win32::Console->new( STD_INPUT_HANDLE );
    $self->{old_in_mode} = $self->{input}->Mode();
    $self->{input}->Mode( !ENABLE_PROCESSED_INPUT )                    if ! $mouse;
    $self->{input}->Mode( !ENABLE_PROCESSED_INPUT|ENABLE_MOUSE_INPUT ) if   $mouse;
    $self->{output} = Win32::Console->new( STD_OUTPUT_HANDLE );
    $self->{def_attr} = $self->{output}->Attr();
    $self->{fg_color} = $self->{def_attr} & 0x7;
    $self->{bg_color} = $self->{def_attr} & 0x70;
    $self->{inverse}  = ( $self->{bg_color} >> 4 ) | ( $self->{fg_color} << 4 );
    $self->{output}->Cursor( -1, -1, -1, 0 ) if $hide_cursor;
    return $mouse;
}


sub __reset_mode {
    my ( $self, $mouse, $hide_cursor ) = @_;  # no use for $mouse on win32
    if ( defined $self->{input} ) {
        if ( defined $self->{old_in_mode} ) {
            $self->{input}->Mode( $self->{old_in_mode} );
            delete $self->{old_in_mode};
        }
        $self->{input}->Flush;
        # workaround Bug #33513:
        delete $self->{input}{handle};
        #
    }
    if ( defined $self->{output} ) {
        $self->__reset;
        $self->{output}->Cursor( -1, -1, -1, 1 ) if $hide_cursor;
        #$self->{output}->Free();
        delete $self->{output}{handle}; # ?
    }
}


sub __get_term_size {
    my ( $self ) = @_;
    my ( $term_width, $term_height ) = Win32::Console->new()->Size();
    return $term_width - 1, $term_height;
}


sub __get_cursor_position {
    my ( $self ) = @_;
    ( $self->{abs_cursor_x}, $self->{abs_cursor_y} ) = $self->{output}->Cursor();
}

sub __set_cursor_position {
    my ( $self, $col, $row ) = @_;
    $self->{output}->Cursor( $col, $row );
}


sub __clear_screen {
    my ( $self ) = @_;
    $self->{output}->Cls( $self->{def_attr} );
}


sub __clear_to_end_of_screen {
    my ( $self ) = @_;
    my ( $width, $height ) = $self->{output}->Size();
    $self->__get_cursor_position();
    $self->{output}->FillAttr(
            $self->{bg_color} | $self->{bg_color},
            $width * $height,
            $self->{abs_cursor_x}, $self->{abs_cursor_y} );
}


sub __bold_underline {
    my ( $self ) = @_;
    $self->{output}->Attr( $self->{def_attr} | FOREGROUND_INTENSITY | BACKGROUND_INTENSITY  );
}


sub __reverse {
    my ( $self ) = @_;
    $self->{output}->Attr( $self->{inverse} );
}


sub __reset {
    my ( $self ) = @_;
    $self->{output}->Attr( $self->{def_attr} );
}


sub __up {
    #my ( $self, $rows_up ) = @_;
    my ( $col, $row ) = $_[0]->__get_cursor_position;
    $_[0]->__set_cursor_position( $col, $row - $_[1] );
}

sub __left {
    #my ( $self, $cols_left ) = @_;
    my ( $col, $row ) = $_[0]->__get_cursor_position;
    $_[0]->__set_cursor_position( $col - $_[1], $row );
}

sub __right {
    #my ( $self, $cols_right ) = @_;
    my ( $col, $row ) = $_[0]->__get_cursor_position;
    $_[0]->__set_cursor_position( $col + $_[1], $row );
}

1;

__END__
