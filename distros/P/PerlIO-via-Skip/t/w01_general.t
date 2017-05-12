use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data   = do { local $/=undef ; <DATA> };
my $Result ;

sub work ($$;$$) {
        my ($start, $end, $count) = @_ ;

	$ENV{ viaSKIP} = { start=>$start, end=>$end };
	open DATA, '<',  \$Data   or die $!;
	open my $o, '>:via(Skip)', \$Result or die $!;
	my $a;
	print $o  scalar <DATA>      for 1..($count||1) ;
	$Result;
}

is work( apple  =>  melon  => 4       ) , "apple\norange\nmelon\n" ;
is work( apple  =>  melon  => 1       ) , "apple\n" ;

is work( apple  =>  melon  => 3       ) , "apple\norange\nmelon\n" ;
is work( apple  =>  melon  => 2       ) , "apple\norange\n" ;
is work( apple  =>  melon  =>         ) , "apple\n" ;
is work( melon  =>  grapes => 3       ) , "melon\n" ;
is work( melon  =>  grapes => 4       ) , "melon\ngrapes\n" ;
__DATA__
apple
orange
melon
grapes
