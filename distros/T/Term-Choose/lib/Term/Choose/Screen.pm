package Term::Choose::Screen;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.712';

use Exporter qw( import );

our @EXPORT_OK = qw( down up left right clear_screen clear_to_end_of_screen clear_to_end_of_line
                     reverse_video bold underline bold_underline normal show_cursor hide_cursor bell
                     get_term_size
                );

our %EXPORT_TAGS = (
    all => [ qw( down up left right clear_screen clear_to_end_of_screen clear_to_end_of_line
                 reverse_video bold underline bold_underline normal show_cursor hide_cursor bell
                 get_term_size
            )
        ]
);

use Term::Choose::Constants qw( WIDTH_CURSOR TERM_READKEY );


my (
    @up, @down, @right, @left,
    $reverse, $bold, $underline, $bold_underline, $normal,
    $bell,
    $clear_screen, $clr_to_bot, $clr_to_eol,
    $show_cursor, $hide_cursor,
);


BEGIN {
    if ( $^O eq 'MSWin32' || $ENV{TC_ANSI_ESCAPES} || ! qx(tput cuu 2>/dev/null) ) {
        @up    = ( "\e[", "A" );
        @down  = ( "\e[", "B" );
        @right = ( "\e[", "C" );
        @left  = ( "\e[", "D" );

        $reverse   = "\e[7m";
        $bold      = "\e[1m";
        $underline = "\e[4m";
        $normal    = "\e[0m";

        $bell = "\a";

        $clear_screen = "\e[H\e[J";
        $clr_to_bot = "\e[0J";
        $clr_to_eol = "\e[K";

        $show_cursor = "\e[?25h";
        $hide_cursor = "\e[?25l";
    }
    else {
        @up    = split( '107', qx(tput cuu 107) );
        @down  = split( '107', qx(tput cud 107) );
        @right = split( '107', qx(tput cuf 107) );
        @left  = split( '107', qx(tput cub 107) );

        $reverse   = qx(tput rev);
        $bold      = qx(tput bold);
        $underline = qx(tput smul);
        $normal    = qx(tput sgr0);

        $bell = qx(tput bel);

        $clear_screen = qx(tput clear);
        $clr_to_bot = qx(tput ed);
        $clr_to_eol = qx(tput el);

        $show_cursor = qx(tput cnorm);
        $hide_cursor = qx(tput civis);
    }
}


sub down  { return  $down[0] . $_[0] . $down[1]  }
sub   up  { return    $up[0] . $_[0] . $up[1]    }
sub left  { return  $left[0] . $_[0] . $left[1]  }
sub right { return $right[0] . $_[0] . $right[1] }

sub clear_screen           { return $clear_screen }
sub clear_to_end_of_screen { return $clr_to_bot   }
sub clear_to_end_of_line   { return $clr_to_eol   }

sub reverse_video { return $reverse }
#sub bold { return $bold }
#sub underline { return $underline }
sub bold_underline { return $bold . $underline }
sub normal { return $normal }

sub show_cursor { return $show_cursor }
sub hide_cursor { return $hide_cursor }

sub bell { return $bell }


sub get_term_size {
    my ( $width, $height ) = ( 0, 0 );
    if ( TERM_READKEY ) {
        ( $width, $height ) = ( Term::ReadKey::GetTerminalSize() )[ 0, 1 ];
    }
    elsif( $^O eq 'MSWin32' ) {
        require Win32::Console;
        ( $width, $height ) = Win32::Console->new()->Size();
    }
    else {
        my $size = qx(stty size);
        if ( defined $size && $size =~ /(\d+)\s(\d+)/ ) {
            $width  = $2;
            $height = $1;
        }
    }
    return $width - WIDTH_CURSOR, $height;
}





1;
