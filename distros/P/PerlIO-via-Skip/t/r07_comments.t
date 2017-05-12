use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $data = do { local $/=undef ; <DATA> };

sub work ($;$) {
        my ($skipcomments, $count) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { skipcomments=> $skipcomments } ;
	open my $i , "<:via(Skip)",  \$data                ;
        my $a;
        $a .= <$i>    for 1..($count||1) ;
        $a;
}

is work (1   => 1)         ,   "apple\n"                        ;
is work (0   => 1)         ,   "    # comment \n"               ;
is work (undef, 1)         ,   "    # comment \n"               ;

__END__
    # comment 
apple
		#comment		
orange
#comment
melon
grapes
#comment
