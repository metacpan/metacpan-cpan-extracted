package Term::Choose::Linux;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.712';

use Term::Choose::Constants qw( :linux :keys TERM_READKEY );
use Term::Choose::Screen    qw( hide_cursor show_cursor normal );


my $Stty = '';


sub new {
    return bless {}, $_[0];
}


sub _getc_wrapper {
    my ( $timeout ) = @_;
    if ( TERM_READKEY ) {
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
        elsif ( $c2 eq 'A' ) { return VK_UP; }     #vt 52
        elsif ( $c2 eq 'B' ) { return VK_DOWN; }
        elsif ( $c2 eq 'C' ) { return VK_RIGHT; }
        elsif ( $c2 eq 'D' ) { return VK_LEFT; }
        elsif ( $c2 eq 'H' ) { return VK_HOME; }
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
                    # 1 = VK_HOME
                    if    ( $c3 eq '2' ) { return VK_INSERT; }
                    elsif ( $c3 eq '3' ) { return VK_DELETE; }
                    # 4 = VK_END
                    elsif ( $c3 eq '5' ) { return VK_PAGE_UP; }
                    elsif ( $c3 eq '6' ) { return VK_PAGE_DOWN; }
                    else {
                        return NEXT_get_key;
                    }
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
                return [ $button, $x, $y ];
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
                return [ $button, $x, $y ];
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
    my ( $self, $config ) = @_;
    $self->{mouse}       = $config->{mouse};        # so options passed with $config are
    $self->{hide_cursor} = $config->{hide_cursor};  # also available in __reset_mode
    if ( $self->{hide_cursor} ) {
        print hide_cursor();
    }
    my $mode_stty;
    if ( ! $config->{mode} ) {
        die "No mode!";
    }
    elsif ( $config->{mode} eq 'ultra-raw' ) {
        $mode_stty = 'raw';
    }
    elsif ( $config->{mode} eq 'cbreak' ) {
        $mode_stty = 'cbreak';
    }
    else {
        die "Invalid mode!";
    }
    if ( TERM_READKEY ) {
        Term::ReadKey::ReadMode( $config->{mode} );
    }
    else {
        $Stty = qx(stty --save);
        chomp $Stty;
        system( "stty -echo $mode_stty" ) == 0 or die $?;
    }
    if ( $self->{mouse} ) {
        my $return = binmode STDIN, ':raw';
        if ( $return ) {
            print SET_ANY_EVENT_MOUSE_1003;
            print SET_SGR_EXT_MODE_MOUSE_1006;
        }
        else {
            $self->{mouse} = 0;
            warn "binmode STDIN, :raw: $!\nmouse-mode disabled\n";
        }
    }
    return $self->{mouse};
};


sub __reset_mode {
    my ( $self ) = @_;
    if ( $self->{mouse} ) {
        binmode STDIN, ':encoding(UTF-8)' or warn "binmode STDIN, :encoding(UTF-8): $!\n";
        print UNSET_SGR_EXT_MODE_MOUSE_1006;
        print UNSET_ANY_EVENT_MOUSE_1003;
    }
    print normal();
    if ( TERM_READKEY ) {
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
    if ( $self->{hide_cursor} ) {
        print show_cursor();
    }
}


sub __get_cursor_row {
    #my ( $self ) = @_;
    my $abs_curs_y;
    print "\e[6n";
    my $c1 = _getc_wrapper( 0 );
    if ( defined $c1 && $c1 eq "\e" ) {
        my $c2 = _getc_wrapper( 0.10 );
        if ( defined $c2 && $c2 eq '[' ) {
            my $c3 = _getc_wrapper( 0 );
            if ( $c3 =~ m/^[0-9]$/ ) {
                my $c4 = _getc_wrapper( 0 );
                if ( $c4 =~ m/^[;0-9]$/ ) {
                    my $curs_y = $c3;
                    my $ry = $c4;
                    while ( $ry =~ m/^[0-9]$/ ) {
                        $curs_y .= $ry;
                        $ry = _getc_wrapper( 0 );
                    }
                    if ( $ry eq ';' ) {
                        my $curs_x = ''; # unused
                        my $rx = _getc_wrapper( 0 );
                        while ( $rx =~ m/^[0-9]$/ ) {
                            $curs_x .= $rx;
                            $rx = _getc_wrapper( 0 );
                        }
                        if ( $rx eq 'R' ) {
                            $abs_curs_y = $curs_y;
                        }
                    }
                }
            }
        }
    }
    return $abs_curs_y || 1;
}








1;

__END__
