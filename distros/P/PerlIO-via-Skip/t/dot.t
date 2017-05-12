use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $data = do { local $/=undef ; <DATA> };

sub work ($$;$$) {
        my ($start, $end, $count, $after) = @_ ;

	$after=$after||0;
	$ENV{ viaSKIP} = { start=>$start, end=>$end,  after=>$after};
	open my $i ,'<:via(Skip)', \$data  or die $!;
	my $a;
	$a .= <$i>    for 1..($count||1) ;
	$.;
}
is work( apple =>  melon  => 2        ) ,  2 ;
is work( apple =>  melon  => 1        ) ,  1 ;
is work( apple =>  melon  => 3        ) ,  3 ;
is work( apple =>  melon  => 2  => 1  ) ,  2 ;
is work( apple =>  melon  => 2  => 2  ) ,  1 ;
is work( apple =>  melon  => 2  => 3  ) ,  0 ;
is work( apple =>  melon  => 2  => 5  ) ,  0 ;
is work( apple =>  melon  => 3  => 2  ) ,  1 ;
is work( apple =>  melon  => 4  => 2  ) ,  1 ;
is work( apple =>  melon  => 4  => 3  ) ,  0 ;
is work( apple =>  melon  => 4  => 4  ) ,  0 ;
is work( apple =>  melon  => 3  => 0  ) ,  3 ;
is work( apple =>  melon  => 4  => 0  ) ,  3 ;

__DATA__
apple
orange
melon
grapes
