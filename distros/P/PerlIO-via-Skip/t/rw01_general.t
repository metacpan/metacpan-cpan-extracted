use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data = do { local $/=undef ; <DATA> };
my $Result;

sub work  {
        my ($Rstart, $Rend, $Rcount, $Wstart, $Wend, $Wcount, $eol) = @_ ;
	local ($/, $\); $/ =  $\ = $eol||"\n";
	$ENV{ viaSKIP} = { start=>$Rstart, end=>$Rend};
	open I ,'<:via(Skip)', \$Data      or die $!;
	$ENV{ viaSKIP} = { start=>$Wstart, end=>$Wend };
	open O ,'>:via(Skip)', \$Result    or die $!;
	my @a;
	push @a, <I>            for 1..($Rcount||1) ;
	chomp @a; 
	print O shift@a||''   for 1..($Wcount||1) ;
	$Result;
}

is work( undef   ,   orange => 8  => 
         orange =>   melon  => 3  =>  "_"  ) , "orange__"             ;
is work( apple   =>  melon  => 8  => 
         orange  =>  undef   , 4  =>  "_"  ) , "orange_melon__"       ;
is work( apple   =>  grapes => 8  => 
         orange  =>  undef   , 4  =>  "_"  ) , "orange_melon_grapes_" ;
is work( orange  =>  plum   => 8  => 
         melon   =>  grapes => 2  =>  "_"  ) , "melon_"               ;

__DATA__
apple_orange_melon_grapes_pear_plum_
