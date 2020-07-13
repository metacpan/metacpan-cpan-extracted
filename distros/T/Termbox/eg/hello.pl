#!/usr/bin/perl
use strictures 2;
use Termbox qw[:all];
use experimental 'signatures';
use Data::Dump;
#

my @chars = split //, 'hello, world!';
my $code  = tb_init();
die sprintf "termbox init failed, code: %d\n", $code if $code;
tb_select_input_mode(TB_INPUT_ESC);
tb_select_output_mode(TB_OUTPUT_NORMAL);
tb_clear();
my @rows = (
    [ TB_WHITE,   TB_BLACK ],
    [ TB_BLACK,   TB_DEFAULT ],
    [ TB_RED,     TB_GREEN ],
    [ TB_GREEN,   TB_RED ],
    [ TB_YELLOW,  TB_BLUE ],
    [ TB_MAGENTA, TB_CYAN ]
);

for my $colors ( 0 .. $#rows ) {
    my $j = 0;
    for my $char (@chars) {
        tb_change_cell( $j, $colors, $char, @{ $rows[$colors] } );
        $j++;
    }
}
tb_present();
while (1) {
    my $ev = Termbox::Event->new();
    tb_poll_event($ev);
    if ( $ev->key == TB_KEY_ESC ) {
        tb_shutdown();
        exit 0;
    }
}
