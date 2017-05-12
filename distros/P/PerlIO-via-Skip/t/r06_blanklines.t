use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $data = do { local $/=undef ; <DATA> };


sub work ($;$) {
        my ($skipblanklines, $count) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { skipblanklines=> $skipblanklines } ;
	open my $i , "<:via(Skip)",  \$data                    ;
        my $a;
        $a .= <$i>    for 1..($count||1) ;
        $a;
}

is work (1 => 1)         ,   "apple\n"                        ;
is work (0 => 1)         ,   "     \n"                        ;
is work (undef ,  1)     ,   "     \n"                        ;

__END__
     
apple
			
orange

melon
grapes

