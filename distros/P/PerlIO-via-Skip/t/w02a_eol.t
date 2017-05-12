use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data = do { local $/=undef ; <DATA> };
my $Result;

sub work  {
        my ($start, $end, $count, $eol, $after) = @_ ;

	local ($/,$\);
	$/ = $\ =  $eol||"\n" ;
	$ENV{ viaSKIP} = { start=>$start, end=>$end, after=>$after };
        open \*DATA , '<', \$Data  or die $!;
	open my $o ,  '>:via(Skip)', \$Result or die $!;
	print $o  scalar <DATA>    for 1..$count||1   ;
	$Result;
}

is   work( an =>  done   => 2  =>  _ =>  ) , 'an b __ f__'            ;
is   work( an =>  done   => 2  =>  "\n"  ) , "an b _ f_\n\nab _i\n\n" ;

__DATA__
an b _ f_
ab _i
melon r
done
