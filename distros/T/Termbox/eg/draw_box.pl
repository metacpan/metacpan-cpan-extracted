#!/usr/bin/perl
use strictures 2;
use Termbox qw[:all];
use experimental 'signatures';

# Partly based on http://electronictoofree.blogspot.com/2018/03/text-based-user-interface-termbox_25.html
my @chars = split //, 'Hello, world!';
my $code  = tb_init();
die sprintf "termbox init failed, code: %d\n", $code if $code;
#
tb_select_input_mode(TB_INPUT_ESC);
tb_select_output_mode(TB_OUTPUT_NORMAL);
my $ev = Termbox::Event->new();

# Let's move it
for my $left ( 0 .. 10 ) {
    tb_clear();
    my ( $i, $j ) = ( 0, 0 );

    # print the text centered in the box
    for my $char (@chars) {
        tb_change_cell( $j + int( $left / 2 ) + 1, 1, $char, TB_WHITE, TB_DEFAULT );
        $j++;
    }

    # four corners
    tb_change_cell( 0,          0, 0x250C, TB_BLUE, TB_DEFAULT );
    tb_change_cell( 14 + $left, 0, 0x2510, TB_BLUE, TB_DEFAULT );
    tb_change_cell( 0,          2, 0x2514, TB_BLUE, TB_DEFAULT );
    tb_change_cell( 14 + $left, 2, 0x2518, TB_BLUE, TB_DEFAULT );

    # horizontal lines
    for my $i ( 1 .. 14 + $left - 1 ) {
        tb_change_cell( $i, 0, 0x2500, TB_BLUE, TB_DEFAULT );
        tb_change_cell( $i, 2, 0x2500, TB_BLUE, TB_DEFAULT );
    }

    # vertical lines
    for ( my $i = 1; $i < 2; ++$i ) {
        tb_change_cell( 0,          $i, 0x2502, TB_BLUE, TB_DEFAULT );
        tb_change_cell( 14 + $left, $i, 0x2502, TB_BLUE, TB_DEFAULT );
    }
    tb_present();
    #
    tb_peek_event( $ev, 30 );          # 30msec looks smooth on my box
    if ( $ev->key == TB_KEY_ESC ) {    # in case we want to kill it early
        tb_shutdown();
        exit;
    }
}
while (1) {                            # let it run
    tb_poll_event($ev);
    if ( $ev->key == TB_KEY_ESC ) {
        tb_shutdown();
        exit;
    }
}
