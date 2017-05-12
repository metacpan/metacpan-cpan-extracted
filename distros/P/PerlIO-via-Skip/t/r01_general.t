use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data = do { local $/=undef ; <DATA> };

sub work  {
        my ($start, $end, $count) = @_ ;

	$ENV{ viaSKIP} = { start=>$start, end=>$end};
	open my $i ,'<:via(Skip)', \$Data  or die $!;
	my $a;
	$a .= <$i>    for 1..($count||1) ;
	$a;
}


is  work( apple =>  melon  => 1       ) , "apple\n" ;
is  work( apple =>  melon  => 3       ) , "apple\norange\nmelon\n" ;
is  work( apple =>  melon  => 4       ) , "apple\norange\nmelon\n" ;
is  work( apple =>  melon  => 2       ) , "apple\norange\n" ;
is  work( apple =>  melon  =>         ) , "apple\n" ;
is  work( melon =>  grapes => 4       ) , "melon\ngrapes\n" ;
is  work( undef ,   orange => 2       ) , "apple\norange\n" ;
is  work( apple =>  undef  ,  2       ) , "apple\norange\n" ;

__DATA__
apple
orange
melon
grapes
