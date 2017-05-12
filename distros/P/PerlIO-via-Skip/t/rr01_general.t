use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data  = do { local $/=undef ; <DATA> };

sub work  {
        my ($Rstart, $Rend, $Rcount, $Wstart, $Wend, $Wcount, $eol) = @_ ;
	my ($Two, @Result);
	local ($/, $\); $/ =  $\ = $eol||"\n";

	$ENV{ viaSKIP} = { start=>$Rstart, end=>$Rend};
	open  my $ONE , '<:via(Skip)', \$Data  or die $!;
	$Two .= <$ONE>                      for 1..($Rcount||1) ;

	$ENV{ viaSKIP} = { start=>$Wstart, end=>$Wend };
	open  my $TWO , '<:via(Skip)', \$Two  or die $!;

        push @Result,  (scalar <$TWO>)||''  for 1..($Wcount||1) ;
	join '',@Result;
}


is work( grapes  =>  plum    => 8  =>
         orange  =>  plum    => 4  =>  "_"  ) ,  ''    ;
is work( apple   =>  plum    => 8  =>
         grapes  =>  undef    , 4  =>  "_"  ) , "grapes_pear_plum_"   ;
is work( undef   ,   orange => 8  => 
         orange  =>   melon  => 3  =>  "_"  ) , "orange_"             ;
is work( apple   =>  grapes => 8  =>
         orange  =>  undef   , 4  =>  "_"  ) , "orange_melon_grapes_" ;
is work( orange  =>  plum   => 8  =>
         melon   =>  grapes => 2  =>  "_"  ) , "melon_grapes_"        ;
is work( grapes  =>  plum    => 8  =>
         undef    ,  plum    => 4  =>  "_"  ) , "grapes_pear_plum_"    ;

__DATA__
apple_orange_melon_grapes_pear_plum_
