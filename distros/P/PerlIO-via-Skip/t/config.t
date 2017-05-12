use Test::More qw(no_plan);
use PerlIO::via::Skip;
BEGIN { eval 'use Test::Exception' }

my $data = do { local $/=undef ; <DATA> };


sub work  {
	$ENV{ viaSKIP } = { start=>'apple', end=>'melon', after=>1 };
	open my $i , '<:via(Skip)',  \$data                or die $!;
}
sub noSKIP  {
	$ENV{ junk } = { start=>'apple', end=>'melon', after=>0 };
	open my $i , '<:via(Skip)',  \$data                or die $!;
	my $a=<$i>;
}


is   noSKIP() , "apple\n"  ;

SKIP: {
	skip 'because no Test::Exception', 1   unless $INC{'Test/Exception.pm'};
	lives_ok {  work() };
}

__END__
apple
orange
melon
grapes
