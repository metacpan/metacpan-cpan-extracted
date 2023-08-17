use Termbox qw[:all];
#
my @chars = split //, 'hello, world!';
my $code  = tb_init();
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
sleep 3;
tb_shutdown();
