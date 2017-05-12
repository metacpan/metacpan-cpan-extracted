use Test::More qw(no_plan);
BEGIN { use_ok('PerlIO::via::Skip') };

my $data = do { local $/=undef ; <DATA> };

sub work ($$;$$) {
        my ($start, $end, $count, $after) = @_ ;

	$after=$after||0;
	$ENV{ viaSKIP} = { start=>$start, end=>$end,  after=>$after};
	open my $i ,'<:via(Skip)', \$data  or die $!;
	my $a;
	$a .= <$i>    for 1..($count||1) ;
	$a;
}

__DATA__
apple
orange
melon
grapes
