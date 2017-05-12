use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $data = do { local $/=undef ; <DATA> };


sub work ($$;$$) {
        my ($start, $end, $count, $after) = @_ ;

	$after=$after||0;
	$ENV{ viaSKIP} = { start=>$start, end=>$end,  after=>$after};
	open my $i , '<:via(Skip)', \$data  or die $!;
	my $a;
	$a .= <$i>    for 1..($count||1) ;
	$a;
}


is work( apple =>  melon  => 3 => 1  ) , "orange\nmelon\n" ;
is work( apple =>  melon  => 3 => 2  ) , "melon\n" ;
is work( apple =>  melon  => 3 => 3  ) , '' ;
is work( apple =>  melon  => 3 => 4  ) , '' ;
__DATA__
apple
orange
melon
grapes
