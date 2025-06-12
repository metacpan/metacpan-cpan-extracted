package Term::Choose::Win32;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';


use Encode qw( decode );

use Encode::Locale qw();
use Win32::Console qw( STD_INPUT_HANDLE ENABLE_PROCESSED_INPUT ENABLE_LINE_INPUT ENABLE_ECHO_INPUT ENABLE_MOUSE_INPUT
                       STD_OUTPUT_HANDLE
                       RIGHT_ALT_PRESSED LEFT_ALT_PRESSED RIGHT_CTRL_PRESSED LEFT_CTRL_PRESSED SHIFT_PRESSED
                       FOREGROUND_INTENSITY BACKGROUND_INTENSITY );

use Win32::Console::PatchForRT33513 qw();
use Term::Choose::Constants         qw( :all );
use Term::Choose::Screen            qw( hide_cursor show_cursor normal );


use constant {
    MOUSE_WHEELED                => 0x0004,
    LEFTMOST_BUTTON_PRESSED      => 0x0001,
    RIGHTMOST_BUTTON_PRESSED     => 0x0002,
    FROM_LEFT_2ND_BUTTON_PRESSED => 0x0004,

    VK_CODE_PAGE_UP   => 33,
    VK_CODE_PAGE_DOWN => 34,
    VK_CODE_END       => 35,
    VK_CODE_HOME      => 36,
    VK_CODE_LEFT      => 37,
    VK_CODE_UP        => 38,
    VK_CODE_RIGHT     => 39,
    VK_CODE_DOWN      => 40,
    VK_CODE_INSERT    => 45,
    VK_CODE_DELETE    => 46,
    VK_CODE_F1        => 112,
    VK_CODE_F2        => 113,
    VK_CODE_F3        => 114,
    VK_CODE_F4        => 115,
};


sub SHIFTED_MASK () {
      RIGHT_ALT_PRESSED     # 0x0001
    | LEFT_ALT_PRESSED      # 0x0002
    | RIGHT_CTRL_PRESSED    # 0x0004
    | LEFT_CTRL_PRESSED     # 0x0008
    | SHIFT_PRESSED         # 0x0010
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
            elsif ( $v_key_code == VK_CODE_F1 )        { return VK_F1 }
            elsif ( $v_key_code == VK_CODE_F2 )        { return VK_F2 }
            elsif ( $v_key_code == VK_CODE_F3 )        { return VK_F3 }
            elsif ( $v_key_code == VK_CODE_F4 )        { return VK_F4 }
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
    $self->{input} = Win32::Console->new( STD_INPUT_HANDLE );
    $self->{old_in_mode} = $self->{input}->Mode();
    if ( $config->{mouse} ) {
        # To make the mouse mode work, QUICK_EDIT_MODE has to be disabled.
        # https://docs.microsoft.com/en-us/windows/console/setconsolemode:
        # To disable this mode (QUICK_EDIT_MODE), use ENABLE_EXTENDED_FLAGS (0x0080) without this flag (QUICK_EDIT_MODE).
        $self->{input}->Mode( !ENABLE_PROCESSED_INPUT|ENABLE_MOUSE_INPUT|0x0080 );
    }
    else {
        $self->{input}->Mode( !ENABLE_PROCESSED_INPUT );
    }
    if ( $config->{hide_cursor} ) {
        print hide_cursor();
    }
    return $config->{mouse};
}


sub __reset_mode {
    my ( $self, $config ) = @_;
    my $fallback_resetmode = ENABLE_PROCESSED_INPUT|ENABLE_LINE_INPUT|ENABLE_ECHO_INPUT;
    if ( defined $self->{input} ) {
        if ( defined $self->{old_in_mode} ) {
            $self->{input}->Mode( $self->{old_in_mode} );
            # old_in_mode == 503 == 0x0001|0x0002|0x0004|0x0010|0x0020|0x0040|0x0080|0x0100
            delete $self->{old_in_mode};
        }
        else {
            $self->{input}->Mode( $fallback_resetmode );
        }
        $self->{input}->Flush;
    }
    else {
        my $input = Win32::Console->new( STD_INPUT_HANDLE );
        $input->Mode( $fallback_resetmode );
        $input->Flush;
    }
    print normal();
    if ( $config->{hide_cursor} ) {
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



# ENABLE_PROCESSED_INPUT        = 0x0001    win32::Console
# ENABLE_LINE_INPUT             = 0x0002    Win32::Console
# ENABLE_ECHO_INPUT             = 0x0004    Win32::Console
# ENABLE_WINDOW_INPUT           = 0x0008    Win32::Console
# ENABLE_MOUSE_INPUT            = 0x0010    Win32::Console
# ENABLE_INSERT_MODE            = 0x0020
# ENABLE_QUICK_EDIT_MODE        = 0x0040
# ENABLE_EXTENDED_FLAGS         = 0x0080
# ENABLE_AUTO_POSITION          = 0x0100    ?
# ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200










1;

__END__
