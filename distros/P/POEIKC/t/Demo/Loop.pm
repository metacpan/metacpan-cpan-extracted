package Demo::Loop;

use Cwd;

my %hash;
#use Cache::FastMmap::Tie;
#my $fc = tie my %hash, 'Cache::FastMmap::Tie', (
#        share_file => "t-loop",
#        cache_size => "1k",
#        expire_time=> "1m",
#);

sub loop_test {
	my $cut = shift;
	push @{$hash{loop_list}}, $cut;
	#push @{$hash{loop_time}}, scalar localtime;
	$hash{loop_cut}++;
	return $hash{loop_cut};
}

sub get {
	#my %h = %hash;
	#return \%h;
	return \%hash;
}

1;
