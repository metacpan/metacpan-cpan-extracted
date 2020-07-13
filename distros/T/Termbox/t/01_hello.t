use strict;
use warnings;
use Test::More 0.98;
use lib '../lib', 'lib';
#
use Termbox qw[:all];
#

my @chars = split //, 'hello, world!';
my $code  = tb_init();
ok !$code, 'termbox init';

ok tb_select_input_mode(TB_INPUT_ESC);
ok tb_select_output_mode(TB_OUTPUT_NORMAL);
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
        tb_change_cell( $j, $colors, ord $char, @{ $rows[$colors] } );
        $j++;
    }
}
tb_present();
diag 'Hold it for a second...';
sleep 1;
tb_shutdown();
pass 'That works!';
done_testing;
