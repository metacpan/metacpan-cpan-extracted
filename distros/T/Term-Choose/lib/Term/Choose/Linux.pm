package Term::Choose::Linux;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.622';

use Term::Choose::Constants qw( :screen :linux );


my $Term_ReadKey; # declare but don't assign a value!
BEGIN {
    if ( eval { require Term::ReadKey; 1 } ) {
        $Term_ReadKey = 1;
    }
}
my $Stty = '';


sub new {
    return bless {}, $_[0];
}


sub _getc_wrapper {
    my ( $timeout ) = @_;
    if ( $Term_ReadKey ) {
        return Term::ReadKey::ReadKey( $timeout );
    }
    else {
        return getc();
    }
}


sub __get_key_OS {
    my ( $self, $mouse ) = @_;
    my $c1 = _getc_wrapper( 0 );
    return if ! defined $c1;
    if ( $c1 eq "\e" ) {
        my $c2 = _getc_wrapper( 0.10 );
        if    ( ! defined $c2 ) { return KEY_ESC; } # unused
        #elsif ( $c3 eq 'A' ) { return VK_UP; }     vt 52
        #elsif ( $c3 eq 'B' ) { return VK_DOWN; }
        #elsif ( $c3 eq 'C' ) { return VK_RIGHT; }
        #elsif ( $c3 eq 'D' ) { return VK_LEFT; }
        #elsif ( $c3 eq 'H' ) { return VK_HOME; }
         elsif ( $c2 eq 'O' ) {
            my $c3 = _getc_wrapper( 0 );
            if    ( $c3 eq 'A' ) { return VK_UP; }
            elsif ( $c3 eq 'B' ) { return VK_DOWN; }
            elsif ( $c3 eq 'C' ) { return VK_RIGHT; }
            elsif ( $c3 eq 'D' ) { return VK_LEFT; }
            elsif ( $c3 eq 'F' ) { return VK_END; }
            elsif ( $c3 eq 'H' ) { return VK_HOME; }
            elsif ( $c3 eq 'Z' ) { return KEY_BTAB; }
            else {
                return NEXT_get_key;
            }
        }
        elsif ( $c2 eq '[' ) {
            my $c3 = _getc_wrapper( 0 );
            if    ( $c3 eq 'A' ) { return VK_UP; }
            elsif ( $c3 eq 'B' ) { return VK_DOWN; }
            elsif ( $c3 eq 'C' ) { return VK_RIGHT; }
            elsif ( $c3 eq 'D' ) { return VK_LEFT; }
            elsif ( $c3 eq 'F' ) { return VK_END; }
            elsif ( $c3 eq 'H' ) { return VK_HOME; }
            elsif ( $c3 eq 'Z' ) { return KEY_BTAB; }
            elsif ( $c3 =~ m/^[0-9]$/ ) {
                my $c4 = _getc_wrapper( 0 );
                if ( $c4 eq '~' ) {
                    if    ( $c3 eq '2' ) { return VK_INSERT; }
                    elsif ( $c3 eq '3' ) { return VK_DELETE; }
                    elsif ( $c3 eq '5' ) { return VK_PAGE_UP; }
                    elsif ( $c3 eq '6' ) { return VK_PAGE_DOWN; }
                    else {
                        return NEXT_get_key;
                    }
                }
                elsif ( $c4 =~ m/^[;0-9]$/ ) { # response to "\e[6n"
                    my $abs_curs_y = $c3;
                    my $ry = $c4;
                    while ( $ry =~ m/^[0-9]$/ ) {
                        $abs_curs_y .= $ry;
                        $ry = _getc_wrapper( 0 );
                    }
                    return NEXT_get_key if $ry ne ';';
                    my $abs_curs_x = '';
                    my $rx = _getc_wrapper( 0 );
                    while ( $rx =~ m/^[0-9]$/ ) {
                        $abs_curs_x .= $rx;
                        $rx = _getc_wrapper( 0 );
                    }
                    if ( $rx eq 'R' ) {
                        #$self->{abs_cursor_x} = $abs_curs_x; # unused
                        $self->{abs_cursor_y} = $abs_curs_y;
                    }
                    return NEXT_get_key;
                }
                else {
                    return NEXT_get_key;
                }
            }
            # http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
            elsif ( $c3 eq 'M' && $mouse ) {
                my $event_type = ord( _getc_wrapper( 0 ) ) - 32;
                my $x          = ord( _getc_wrapper( 0 ) ) - 32;
                my $y          = ord( _getc_wrapper( 0 ) ) - 32;
                my $button = $self->__mouse_event_to_button( $event_type );
                return NEXT_get_key if $button == NEXT_get_key;
                return [ $self->{abs_cursor_y}, $button, $x, $y ];
            }
            elsif ( $c3 eq '<' && $mouse ) {  # SGR 1006
                my $event_type = '';
                my $m1;
                while ( ( $m1 = _getc_wrapper( 0 ) ) =~ m/^[0-9]$/ ) {
                    $event_type .= $m1;
                }
                return NEXT_get_key if $m1 ne ';';
                my $x = '';
                my $m2;
                while ( ( $m2 = _getc_wrapper( 0 ) ) =~ m/^[0-9]$/ ) {
                    $x .= $m2;
                }
                return NEXT_get_key if $m2 ne ';';
                my $y = '';
                my $m3;
                while ( ( $m3 = _getc_wrapper( 0 ) ) =~ m/^[0-9]$/ ) {
                    $y .= $m3;
                }
                return NEXT_get_key if $m3 !~ m/^[mM]$/;
                my $button_released = $m3 eq 'm' ? 1 : 0;
                return NEXT_get_key if $button_released;
                my $button = $self->__mouse_event_to_button( $event_type );
                return NEXT_get_key if $button == NEXT_get_key;
                return [ $self->{abs_cursor_y}, $button, $x, $y ];
            }
            else {
                return NEXT_get_key;
            }
        }
        else {
            return NEXT_get_key;
        }
    }
    else {
        return ord $c1;
    }
};


sub __mouse_event_to_button {
    my ( $self, $event_type ) = @_;
    my $button_drag = ( $event_type & 0x20 ) >> 5;
    return NEXT_get_key if $button_drag;
    my $button;
    my $low_2_bits = $event_type & 0x03;
    if ( $low_2_bits == 3 ) {
        $button = 0;
    }
    else {
        if ( $event_type & 0x40 ) {
            $button = $low_2_bits + 4; # 4,5
        }
        else {
            $button = $low_2_bits + 1; # 1,2,3
        }
    }
    return $button;
}


sub __set_mode {
    my ( $self, $mouse, $hide_cursor ) = @_;
    if ( $mouse ) {
        if ( $mouse == 3 ) {
            my $return = binmode STDIN, ':utf8';
            if ( $return ) {
                print SET_ANY_EVENT_MOUSE_1003;
                print SET_EXT_MODE_MOUSE_1005;
            }
            else {
                $mouse = 0;
                warn "binmode STDIN, :utf8: $!\n";
                warn "mouse-mode disabled\n";
            }
        }
        elsif ( $mouse == 4 ) {
            my $return = binmode STDIN, ':raw';
            if ( $return ) {
                print SET_ANY_EVENT_MOUSE_1003;
                print SET_SGR_EXT_MODE_MOUSE_1006;
            }
            else {
                $mouse = 0;
                warn "binmode STDIN, :raw: $!\n";
                warn "mouse-mode disabled\n";
            }
        }
        else {
            my $return = binmode STDIN, ':raw';
            if ( $return ) {
                print SET_ANY_EVENT_MOUSE_1003;
            }
            else {
                $mouse = 0;
                warn "binmode STDIN, :raw: $!\n";
                warn "mouse-mode disabled\n";
            }
        }
    }
    if ( $Term_ReadKey ) {
        Term::ReadKey::ReadMode( 'ultra-raw' );
    }
    else {
        $Stty = `stty --save`;
        chomp $Stty;
        system( "stty -echo raw" ) == 0 or die $?;
    }
    print HIDE_CURSOR if $hide_cursor;
    return $mouse;
};


sub __reset_mode {
    my ( $self, $mouse, $hide_cursor ) = @_;
    print SHOW_CURSOR if $hide_cursor;
    if ( $mouse ) {
        binmode STDIN, ':encoding(UTF-8)' or warn "binmode STDIN, :encoding(UTF-8): $!\n";
        print UNSET_EXT_MODE_MOUSE_1005     if $mouse == 3;
        print UNSET_SGR_EXT_MODE_MOUSE_1006 if $mouse == 4;
        print UNSET_ANY_EVENT_MOUSE_1003;
    }
    $self->__reset();
    if ( $Term_ReadKey ) {
        Term::ReadKey::ReadMode( 'restore' );
    }
    else {
        if ( $Stty ) {
            system( "stty $Stty" ) == 0 or die $?;
        }
        else {
            system( "stty sane" ) == 0 or die $?;
        }
    }
}


sub __get_term_size {
    #my ( $self ) = @_;
    my ( $width, $height ) = ( 0, 0 );
    if ( $Term_ReadKey ) {
        ( $width, $height ) = ( Term::ReadKey::GetTerminalSize() )[ 0, 1 ];
    }
    else {
        my $size = `stty size`;
        if ( defined $size && $size =~ /(\d+)\s(\d+)/ ) {
            $width  = $2;
            $height = $1;
        }
    }
    return $width - WIDTH_CURSOR, $height;
}




sub __get_cursor_position {
    my ( $self ) = @_;
    #$self->{abs_cursor_x} = 0; # unused
    $self->{abs_cursor_y} = 0;
    print GET_CURSOR_POSITION;
}


sub __clear_screen {
    #my ( $self ) = @_;
    print CLEAR_SCREEN;
}


sub __clear_to_end_of_screen {
    #my ( $self ) = @_;
    print CLEAR_TO_END_OF_SCREEN;
}


sub __bold_underline {
    #my ( $self ) = @_;
    print BOLD_UNDERLINE;
}


sub __reverse {
    #my ( $self ) = @_;
    print REVERSE;
}


sub __reset {
    #my ( $self ) = @_;
    print RESET;
}


sub __up {
    #my ( $self ) = @_;
    print "\e[${_[1]}A";
}


sub __left {
    #my ( $self ) = @_;
    print "\e[${_[1]}D";
}


sub __right {
    #my ( $self ) = @_;
    print "\e[${_[1]}C";
}


sub __beep {
    my ( $self, $beep ) = @_;
    print BEEP if $beep;
}



1;

__END__
