use Test::More qw(no_plan);
use PerlIO::via::Skip ;

my $Data = do { local $/=undef ; <DATA> };
my $Result;

sub manual  {
        my ( $eol, @data) = @_ ;
        local ($/, $\);
	$/ =  $\ =  $eol||"\n" ;
	open my $o ,  '>:via(Skip)', \$Result or die $!;
	print $o  @data ;
	$Result;
}

is  manual( "\n" => qw( a b ) =>  ) , "ab\n"           ;
is  manual(   _  => qw( a b ) =>  ) , 'ab_'            ;

__DATA__
an b _ f_
ab _i
melon r
done
