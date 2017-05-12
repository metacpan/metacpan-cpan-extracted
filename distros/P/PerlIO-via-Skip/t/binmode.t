use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $Data = do { local $/=undef ; <DATA> };

sub work (;$) {
        my ($maxlines) = @_ ;
	$ENV{ viaSKIP } = { maxlines=> $maxlines } ;
	open my $i , '<' , \$Data      or die $!   ;
	binmode $i, ':via(Skip)'       or die $!   ;
	join '',<$i>;
}

is work (2)      , "apple\norange\n"                ;
is work (1)      , "apple\n"                        ;

__END__
apple
orange
melon
grapes
