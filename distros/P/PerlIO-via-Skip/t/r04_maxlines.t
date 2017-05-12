use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $Data = do { local $/=undef ; <DATA> };


sub work (;$) {
        my ($maxlines) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { maxlines=> $maxlines } ;
	open my $i , "<:via(Skip)",  \$Data        ;
	join '',<$i>;
}

is work (0)      , ''                               ;
is work (1)      , "apple\n"                        ;
is work ()       , "apple\norange\nmelon\ngrapes\n" ;
is work (undef)  , "apple\norange\nmelon\ngrapes\n" ;
is work (2)      , "apple\norange\n"                ;
is work (3)      , "apple\norange\nmelon\n"         ;
is work (4)      , "apple\norange\nmelon\ngrapes\n" ;
is work (5)      , "apple\norange\nmelon\ngrapes\n" ;

__END__
apple
orange
melon
grapes
