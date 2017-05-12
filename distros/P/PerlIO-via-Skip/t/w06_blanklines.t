use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $Data = do { local $/=undef ; <DATA> };
my $Result;


sub work ($;$) {
        my ($skipblanklines, $count) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { skipblanklines=> $skipblanklines } ;
        open \*DATA , '<', \$Data  or die $!;
        open my $o ,  '>:via(Skip)', \$Result or die $!;
        my $a;
        print $o  scalar <DATA>      for 1..($count||1) ;
        $Result;
}

is work (1 => 2)         ,   "apple\n"                        ;
is work (0 => 1)         ,   "     \n"                        ;
is work (undef ,  1)     ,   "     \n"                        ;

__END__
     
apple
			
orange

melon
grapes

