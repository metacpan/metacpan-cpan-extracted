#!/usr/bin/perl
use strictures 2;
use Termbox qw[:all];
use experimental 'signatures';
#
my @chars = split //, 'Hello, world!';
my $code  = tb_init();
END { tb_shutdown(); }
die sprintf "termbox init failed, code: %d\n", $code if $code;
#
tb_select_input_mode( TB_INPUT_ESC | TB_INPUT_MOUSE );
my $curCol  = 1;
my $curRune = 1;
my %backbuf;
my ( $bbw, $bbh );
#
my @runes = (
    0x20,      # ' '
    0x2591,    # '░'
    0x2592,    # '▒'
    0x2593,    # '▓'
    0x2588,    # '█'
);
my @colors = ( TB_BLACK, TB_RED, TB_GREEN, TB_YELLOW, TB_BLUE, TB_MAGENTA, TB_CYAN, TB_WHITE );
#
sub updateAndDrawButtons ( $current, $x, $y, $mx, $my, $n, $attrFunc ) {
    my $lx = $x;
    my $ly = $y;
    for ( my $i = 0; $i < $n; $i++ ) {
        if ( $lx <= $mx && $mx <= $lx + 3 && $ly <= $my && $my <= $ly + 1 ) {
            $$current = $i;    # set $current in parent
        }
        my ( $r, $fg, $bg ) = $attrFunc->($i);
        tb_change_cell( $lx + 0, $ly + 0, $r, $fg, $bg );
        tb_change_cell( $lx + 1, $ly + 0, $r, $fg, $bg );
        tb_change_cell( $lx + 2, $ly + 0, $r, $fg, $bg );
        tb_change_cell( $lx + 3, $ly + 0, $r, $fg, $bg );
        tb_change_cell( $lx + 0, $ly + 1, $r, $fg, $bg );
        tb_change_cell( $lx + 1, $ly + 1, $r, $fg, $bg );
        tb_change_cell( $lx + 2, $ly + 1, $r, $fg, $bg );
        tb_change_cell( $lx + 3, $ly + 1, $r, $fg, $bg );
        $lx += 4;
    }
    $lx = $x;
    $ly = $y;
    for ( my $i = 0; $i < $n; $i++ ) {
        if ( $$current == $i ) {
            my $fg = TB_RED | TB_BOLD;
            my $bg = TB_DEFAULT;
            tb_change_cell( $lx + 0, $ly + 2, '^', $fg, $bg );
            tb_change_cell( $lx + 1, $ly + 2, '^', $fg, $bg );
            tb_change_cell( $lx + 2, $ly + 2, '^', $fg, $bg );
            tb_change_cell( $lx + 3, $ly + 2, '^', $fg, $bg );
        }
        $lx += 4;
    }
}

sub updateAndRedrawAll ( $mx, $my ) {
    tb_clear();
    if ( $mx != -1 && $my != -1 ) {
        $backbuf{$mx}{$my} = Termbox::Cell->new( ch => $runes[$curRune], fg => $colors[$curCol] );
    }
    for my $col ( keys %backbuf ) {
        for my $row ( keys %{ $backbuf{$col} } ) {
            tb_put_cell( $col, $row, $backbuf{$col}{$row} );
        }
    }
    my $w = tb_width();
    my $h = tb_height();
    updateAndDrawButtons(
        \$curRune,
        0, 0, $mx, $my,
        scalar(@runes),
        sub ($i) {
            $runes[$i], $colors[$curCol], TB_DEFAULT;
        }
    );
    updateAndDrawButtons(
        \$curCol,
        0,
        $h - 3,
        $mx, $my,
        scalar(@colors),
        sub ($i) {
            ' ', TB_DEFAULT, $colors[$i];
        }
    );
    tb_present();
}

sub reallocBackBuffer ( $w, $h ) {
    $bbw = $w;
    $bbh = $h;
}
tb_select_input_mode( TB_INPUT_ESC | TB_INPUT_MOUSE );
#
reallocBackBuffer( tb_width(), tb_height() );
updateAndRedrawAll( -1, -1 );
#
my $ev = Termbox::Event->new();
while (1) {
    my $mx = -1;
    my $my = -1;
    #
    my $t = tb_poll_event($ev);
    if ( $t == -1 ) {
        die 'termbox poll event error';
    }
    if ( $t == TB_EVENT_KEY ) {
        if ( $ev->key == TB_KEY_ESC ) {
            exit 0;
        }
    }
    elsif ( $t == TB_EVENT_MOUSE ) {
        if ( $ev->key == TB_KEY_MOUSE_LEFT ) {
            $mx = $ev->x;
            $my = $ev->y;
        }
    }
    elsif ( $t == TB_EVENT_RESIZE ) {
        reallocBackBuffer( $ev->w, $ev->h );
    }
    updateAndRedrawAll( $mx, $my );
}
