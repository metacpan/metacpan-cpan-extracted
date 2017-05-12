use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data = do { local $/=undef ; <DATA> };
my $Result;


sub work ($$;$$) {
        my ($start, $end, $count, $after) = @_ ;

	$after=$after||0;
	$ENV{ viaSKIP} = { start=>$start, end=>$end,  after=>$after};
	open \*DATA , '<', \$Data  or die $!;
	open my $o ,  '>:via(Skip)', \$Result or die $!;
	my $a;
        print $o  scalar <DATA>      for 1..($count||1) ;
	$Result;
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
