use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $Data = do { local $/=undef ; <DATA> };
my $Result;

sub work ($;$) {
        my ($skipcomments, $count) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { skipcomments=> $skipcomments } ;
	open \*DATA, '<',  \$Data    or  die $!; 
	open my $o , '>:via(Skip)', \$Result   or  die $!;
        print $o  scalar <DATA>    for 1..($count||1) ;
        $Result;
}

is work (1 => 2)         ,   "apple\n"                        ;
is work (0 => 1)         ,   "    # comment \n"               ;
is work ( undef, 1)      ,   "    # comment \n"               ;

__END__
    # comment 
apple
		#comment		
orange
#comment
melon
grapes
#comment
