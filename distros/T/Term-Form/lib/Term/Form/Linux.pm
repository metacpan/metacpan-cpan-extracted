package # hide from PAUSE
Term::Form::Linux;

use warnings;
use strict;
use 5.008003;

our $VERSION = '0.315';

use Term::ReadKey  qw( GetTerminalSize ReadKey ReadMode );

use Term::Form::Constants qw( :linux );


sub new {
    return bless {}, $_[0];
}



sub __set_mode {
    my ( $self, $hide_cursor ) = @_;
    ReadMode( 'cbreak' );
    print "\e[?25l" if $hide_cursor;
};



sub __reset_mode {
    my ( $self, $hide_cursor ) = @_;
    print "\e[?25h" if $hide_cursor;
    ReadMode( 'restore' );
}


sub __term_buff_size {
    #my ( $self ) = @_;
    my ( $term_width, $term_height ) = GetTerminalSize();
    return $term_width, $term_height;
}


sub __get_key {
    #my ( $self ) = @_;
    my $c1 = ReadKey( 0 );
    return if ! defined $c1;
    if ( $c1 eq "\e" ) {
        my $c2 = ReadKey( 0.10 );
        if ( ! defined $c2 ) {
            return  NEXT_get_key; # KEY_ESC
        }
        elsif ( $c2 eq 'O' ) {
            my $c3 = ReadKey( 0 );
               if ( $c3 eq 'A' ) { return VK_UP; }
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
            my $c3 = ReadKey( 0 );
               if ( $c3 eq 'A' ) { return VK_UP; }
            elsif ( $c3 eq 'B' ) { return VK_DOWN; }
            elsif ( $c3 eq 'C' ) { return VK_RIGHT; }
            elsif ( $c3 eq 'D' ) { return VK_LEFT; }
            elsif ( $c3 eq 'F' ) { return VK_END; }
            elsif ( $c3 eq 'H' ) { return VK_HOME; }
            elsif ( $c3 eq 'Z' ) { return KEY_BTAB; }
            elsif ( $c3 =~ /^[0-9]$/ ) {
                my $c4 = ReadKey( 0 );
                if ( $c4 eq '~' ) {
                       if ( $c3 eq '3' ) { return VK_DELETE; }
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


sub __up    {
    return if ! $_[1];
    print "\e[${_[1]}A";
}

sub __down  {
    return if ! $_[1];
    print "\e[${_[1]}B";
}

sub __left  {
    return if ! $_[1];
    print "\e[${_[1]}D"; }

sub __right {
    return if ! $_[1];
    print "\e[${_[1]}C";
}

sub __reverse { print "\e[7m"; }

sub __reset   { print "\e[0m"; }

sub __mark_current { print "\e[4m"; } # "\e[1m\e[4m";

sub __clear_screen { print "\e[H\e[J"; }

sub __clear_lines_to_end_of_screen { print "\r\e[0J"; }

sub __clear_line { print "\r\e[K"; }

sub __beep {
#    print "\a";
}

1;

__END__
