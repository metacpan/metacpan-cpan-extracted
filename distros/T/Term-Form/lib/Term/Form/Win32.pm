package # hide from PAUSE
Term::Form::Win32;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.316';

use Encode qw( decode );

use Encode::Locale qw();
use Win32::Console qw( STD_INPUT_HANDLE ENABLE_PROCESSED_INPUT STD_OUTPUT_HANDLE
                       RIGHT_ALT_PRESSED LEFT_ALT_PRESSED RIGHT_CTRL_PRESSED LEFT_CTRL_PRESSED SHIFT_PRESSED
                       FOREGROUND_INTENSITY BACKGROUND_INTENSITY );

use Term::Form::Constants qw( :win32 );


sub new {
    return bless {}, $_[0];
}


sub __set_mode {
    my ( $self, $hide_cursor ) = @_;
    $self->{input} = Win32::Console->new( STD_INPUT_HANDLE );
    $self->{old_in_mode} = $self->{input}->Mode();
    $self->{input}->Mode( ENABLE_PROCESSED_INPUT );
    $self->{output} = Win32::Console->new( STD_OUTPUT_HANDLE );
    $self->{def_attr}  = $self->{output}->Attr();
    $self->{bg_color}  = $self->{def_attr} & 0x70;
    $self->{fill_attr} = $self->{bg_color} | $self->{bg_color};
    $self->{output}->Cursor( -1, -1, -1, 0 ) if $hide_cursor;
}


sub __reset_mode {
    my ( $self, $hide_cursor ) = @_;
    if ( defined $self->{input} ) {
        if ( defined $self->{old_in_mode} ) {
            $self->{input}->Mode( $self->{old_in_mode} );
            delete $self->{old_in_mode};
        }
        $self->{input}->Flush;
        # workaround Bug #33513:
        delete $self->{input}{handle};
    }
    if ( defined $self->{output} ) {
        $self->{output}->Cursor( -1, -1, -1, 1 ) if $hide_cursor;
        delete $self->{output}{handle}; # ?
    }
}


sub SHIFTED_MASK () {
      RIGHT_ALT_PRESSED
    | LEFT_ALT_PRESSED
    | RIGHT_CTRL_PRESSED
    | LEFT_CTRL_PRESSED
    | SHIFT_PRESSED
}

sub __get_key {
    my ( $self ) = @_;
    my @event = $self->{input}->Input;
    my $event_type = shift @event;
    return NEXT_get_key if ! defined $event_type;
    if ( $event_type == 1 ) {
        my ( $key_down, $repeat_count, $v_key_code, $v_scan_code, $char, $ctrl_key_state ) = @event;
        return NEXT_get_key if ! $key_down;
        if ( $char ) {
            return ord decode( 'console_in', chr( $char & 0xff ) );
        }
        else{
            if ( $ctrl_key_state & SHIFTED_MASK ) {
                return NEXT_get_key;
            }
            elsif ( $v_key_code == VK_CODE_END )       { return VK_END }
            elsif ( $v_key_code == VK_CODE_HOME )      { return VK_HOME }
            elsif ( $v_key_code == VK_CODE_LEFT )      { return VK_LEFT }
            elsif ( $v_key_code == VK_CODE_UP )        { return VK_UP }
            elsif ( $v_key_code == VK_CODE_DOWN )      { return VK_DOWN }
            elsif ( $v_key_code == VK_CODE_RIGHT )     { return VK_RIGHT }
            elsif ( $v_key_code == VK_CODE_PAGE_UP )   { return VK_PAGE_UP }
            elsif ( $v_key_code == VK_CODE_PAGE_DOWN ) { return VK_PAGE_DOWN }
            elsif ( $v_key_code == VK_CODE_DELETE )    { return VK_DELETE }
            else {
                return NEXT_get_key;
            }
        }
    }
    else {
        return NEXT_get_key;
    }
}


sub __term_buff_size {
    my ( $self ) = @_;
    my ( $term_width, $term_height ) = $self->{output}->MaxWindow();
    return $term_width - 1, $term_height;
}

sub __get_cursor_position {
    my ( $self ) = @_;
    my ( $col, $row ) = $self->{output}->Cursor();
    return $col, $row;
}

sub __set_cursor_position {
    my ( $self, $col, $row ) = @_;
    $self->{output}->Cursor( $col, $row );
}

sub __up {
    my ( $self, $rows_up ) = @_;
    return if ! $rows_up;
    my ( $col, $row ) = $self->__get_cursor_position;
    $self->__set_cursor_position( $col, $row - $rows_up  );
}

sub __down {
    my ( $self, $rows_down ) = @_;
    return if ! $rows_down;
    my ( $col, $row ) = $self->__get_cursor_position;
    $self->__set_cursor_position( $col, $row + $rows_down  );
}

sub __left {
    my ( $self, $cols_left ) = @_;
    return if ! $cols_left;
    my ( $col, $row ) = $self->__get_cursor_position;
    $self->__set_cursor_position( $col - $cols_left, $row  );
}

sub __right {
    my ( $self, $cols_right ) = @_;
    return if ! $cols_right;
    my ( $col, $row ) = $self->__get_cursor_position;
    $self->__set_cursor_position( $col + $cols_right, $row  );
}

sub __clear_screen {
    my ( $self ) = @_;
    $self->{output}->Cls( $self->{def_attr} );
}

sub __clear_lines_to_end_of_screen {
    my ( $self ) = @_;
    my ( $width, $height ) = $self->{output}->Size(); #
    my ( $col, $row ) = $self->__get_cursor_position();
    $self->__set_cursor_position( 0, $row  );
    $self->{output}->FillAttr(
            $self->{fill_attr},
            $width * $height, #
            0, $row );
}

sub __clear_line {
    my ( $self ) = @_;
    my ( $width, $height ) = $self->{output}->Size(); #
    my ( $col, $row ) = $self->__get_cursor_position();
    $self->__set_cursor_position( 0, $row  );
    $self->{output}->FillAttr(
            $self->{fill_attr},
            $width,
            0, $row );
}

sub __reverse {
    my ( $self ) = @_;
    $self->{output}->Attr( $self->{inverse} );
}

sub __reset {
    my ( $self ) = @_;
    $self->{output}->Attr( $self->{def_attr} );
}

sub __mark_current {
    my ( $self ) = @_;
    $self->{output}->Attr( $self->{def_attr} | FOREGROUND_INTENSITY | BACKGROUND_INTENSITY  );
}

sub __beep {}



1;

__END__
