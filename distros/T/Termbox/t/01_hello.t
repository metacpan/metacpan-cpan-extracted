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
diag tb_strerror(tb_last_errno) if $code;
tb_clear();
my @rows = (
    [ TB_WHITE,   TB_BLACK ],
    [ TB_BLACK,   TB_DEFAULT ],
    [ TB_RED,     TB_GREEN ],
    [ TB_GREEN,   TB_RED ],
    [ TB_YELLOW,  TB_BLUE ],
    [ TB_MAGENTA, TB_CYAN ]
);
for my $row ( 0 .. $#rows ) {
    for my $col ( 0 .. $#chars ) {
        tb_set_cell( $col, $row, $chars[$col], @{ $rows[$row] } );
    }
}
tb_present();
diag 'Hold it for a few seconds...';
sleep 3;
tb_shutdown();
pass 'That works!';
done_testing;
