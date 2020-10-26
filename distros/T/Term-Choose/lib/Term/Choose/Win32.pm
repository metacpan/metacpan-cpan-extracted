package Term::Choose::Win32;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.712';


use Encode qw( decode );

use Encode::Locale qw();
use Win32::Console qw( STD_INPUT_HANDLE ENABLE_MOUSE_INPUT ENABLE_PROCESSED_INPUT STD_OUTPUT_HANDLE
                       RIGHT_ALT_PRESSED LEFT_ALT_PRESSED RIGHT_CTRL_PRESSED LEFT_CTRL_PRESSED SHIFT_PRESSED
                       FOREGROUND_INTENSITY BACKGROUND_INTENSITY );

use Win32::Console::PatchForRT33513 qw();
use Term::Choose::Constants         qw( :win32 :keys );
use Term::Choose::Screen            qw( hide_cursor show_cursor normal );


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
                return ord decode( 'console_in', chr( $char & 0xff ) );
            }
        }
        else{
            if ( $ctrl_key_state & SHIFTED_MASK ) {
                return NEXT_get_key;
            }
            elsif ( $v_key_code == VK_CODE_PAGE_UP )   { return VK_PAGE_UP }
            elsif ( $v_key_code == VK_CODE_PAGE_DOWN ) { return VK_PAGE_DOWN }
            elsif ( $v_key_code == VK_CODE_END )       { return VK_END }
            elsif ( $v_key_code == VK_CODE_HOME )      { return VK_HOME }
            elsif ( $v_key_code == VK_CODE_LEFT )      { return VK_LEFT }
            elsif ( $v_key_code == VK_CODE_UP )        { return VK_UP }
            elsif ( $v_key_code == VK_CODE_RIGHT )     { return VK_RIGHT }
            elsif ( $v_key_code == VK_CODE_DOWN )      { return VK_DOWN }
            elsif ( $v_key_code == VK_CODE_INSERT )    { return VK_INSERT }
            elsif ( $v_key_code == VK_CODE_DELETE )    { return VK_DELETE }
            else                                       { return NEXT_get_key }
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
        return [ $button, $x, $y ];
    }
    else {
        return NEXT_get_key;
    }
}


sub __set_mode {
    my ( $self, $config ) = @_;
    $self->{hide_cursor} = $config->{hide_cursor};
    $self->{input} = Win32::Console->new( STD_INPUT_HANDLE );
    $self->{old_in_mode} = $self->{input}->Mode();
    if ( $config->{mouse} ) {
        $self->{input}->Mode( !ENABLE_PROCESSED_INPUT|ENABLE_MOUSE_INPUT );
    }
    else {
        $self->{input}->Mode( !ENABLE_PROCESSED_INPUT );
    }
    if ( $self->{hide_cursor} ) {
        print hide_cursor();
    }
    return $config->{mouse};
}


sub __reset_mode {
    my ( $self ) = @_;
    if ( defined $self->{input} ) {
        if ( defined $self->{old_in_mode} ) {
            $self->{input}->Mode( $self->{old_in_mode} );
            delete $self->{old_in_mode};
        }
        $self->{input}->Flush;
    }
    print normal();
    if ( delete $self->{hide_cursor} ) {
        print show_cursor();
    }
}


sub __get_cursor_row {
    #my ( $self ) = @_;
    my $abs_cursor_y = ( Win32::Console->new( STD_OUTPUT_HANDLE )->Cursor() )[1];
    return $abs_cursor_y || 1;
}





# 1.642: Last version which uses Win::Console to create all methods.
#        Since 1.643 Win32::Console::ANSI and ANSI escapes are used.













1;

__END__
