#!/usr/bin/perl
use strictures 2;
use Termbox qw[:all];
use experimental 'signatures';

# Partly based on http://electronictoofree.blogspot.com/2018/03/text-based-user-interface-termbox_25.html
my @chars = split //, 'Hello, world!';
my $code  = tb_init();
die sprintf "termbox init failed, code: %d\n", $code if $code;
#
tb_select_input_mode( TB_INPUT_ESC | TB_INPUT_MOUSE );
tb_select_output_mode(TB_OUTPUT_256);
my $ev = Termbox::Event->new();
tb_clear();

sub draw_key ( $text, $fg, $bg ) {
    for my $pos ( 1 .. length $text ) {
        tb_change_cell( $pos + 3, 5, substr( $text, $pos - 1, 1 ), $fg, $bg );
    }
}
for my $k ( 0 .. 4 ) {
    for my $j ( 0 .. $#chars ) {
        tb_change_cell( $j, $k, $chars[$j], 32 + $j, 231 - $k );
    }
}
draw_key( 'ESC', TB_WHITE, TB_BLUE );
tb_present();
while (1) {
    my $mx = -1;
    my $my = -1;
    my $t  = tb_poll_event($ev);
    if ( $t == -1 ) {
        tb_shutdown();
        die 'termbox poll event error';
    }
    if ( $t == TB_EVENT_KEY ) {
        if ( $ev->key == TB_KEY_ESC ) {
            tb_shutdown();
            exit 0;
        }
    }
    elsif ( $t == TB_EVENT_MOUSE ) {
        if ( $ev->key == TB_KEY_MOUSE_LEFT ) {
            $mx = $ev->x;
            $my = $ev->y;
            if ( ( $mx >= 4 && $mx <= 6 ) && $my == 5 ) {    # Silly but effective
                tb_shutdown();
                exit 0;
            }
        }
    }
}
