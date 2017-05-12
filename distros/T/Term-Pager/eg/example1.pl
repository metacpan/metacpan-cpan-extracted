#! perl

use Term::Pager;

my $t = Term::Pager->new(
	 # change colors
	 MN => "\e[1;34;43m",
	 ML => "\e[7;32m",
);

for my $i (0 .. 100){
    $t->add_text( sprintf("%4d %s\n", $i, 'a' x (rand(70) + 30)) );
}

$t->add_func( 'p', \&printing );

$t->more();

sub printing {
    my $me = shift;

    my $t = $me->box_text( 'Printing...' );
    $me->disp_menu($t);
    # system( 'lpr', '/vmunix' );
    sleep 2;
    $me->remove_menu();
}

