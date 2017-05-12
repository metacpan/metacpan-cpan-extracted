package Demo::Chain;

use Cwd;

my %hash;

sub chain_test {
	my $cut = shift;
	push @{$hash{chain_list}}, $cut;
	$hash{chain_cut}++;
	return $hash{chain_cut};
}

sub chain_1 {
	my $cut = shift;
	push @{$hash{chain_list}}, $cut;
	push @{$hash{chain_sub_list}}, (caller(0))[3];
	$hash{chain_cut}++;
	return $hash{chain_cut};
}

sub chain_2 {
	my $cut = shift;
	push @{$hash{chain_list}}, $cut;
	push @{$hash{chain_sub_list}}, (caller(0))[3];
	$hash{chain_cut}++;
	return ;
}


sub get {
	return \%hash;
}

1;
