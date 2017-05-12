use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $data = do { local $/=undef ; <DATA> };

sub work ($$;$$) {
        my ($start, $end, $count, $eol) = @_ ;

	local $/=$eol||"\n";
	$ENV{ viaSKIP} = { start=>$start, end=>$end};
	open my $i ,'<:via(Skip)', \$data  or die $!;
	my $a;
	$a .= <$i>    for 1..($count||1) ;
	$a;
}

is  work( an =>  melon  => 1               ) , "an b _ for _ the\n"      ;
is  work( an =>  melon  => 1  => "\n" =>   ) , "an b _ for _ the\n"      ;
is  work( an =>  melon  => 1  =>   _  =>   ) , 'an b _'                  ;
is  work( an =>  melon  => 2  =>   _  =>   ) , 'an b _ for _'            ;
is  work( an =>  melon  => 2  =>   _  =>   ) , 'an b _ for _'            ;
is  work( an =>  and    => 2  =>   _  =>   ) , 'an b _ for _'            ;
is  work( an =>  and    => 3  =>   _  =>   ) , "an b _ for _ the\nab _"  ;
is  work( an =>  for    => 2  =>   _  =>   ) , 'an b _ for _'            ;
is  work( an =>  for    => 3  =>   _  =>   ) , 'an b _ for _'            ;
is  work( an =>  for    => 6  =>   _  =>   ) , 'an b _ for _'            ;

__DATA__
an b _ for _ the
ab _ and_ 
melon __ done _
