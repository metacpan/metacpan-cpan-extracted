package Demo::Relay;

use Cwd;

my %hash;

sub relay_test {
	my $cut = shift;
	push @{$hash{relay_list}}, $cut;
	$hash{relay_cut}++;
	return 'relay_1', $hash{relay_cut};
}

sub relay_1 {
	my $cut = shift;
	push @{$hash{relay_list}}, $cut;
	push @{$hash{relay_sub_list}}, (caller(0))[3];
	$hash{relay_cut}++;
	return 'relay_2', $hash{relay_cut};
}

sub relay_2 {
	my $cut = shift;
	push @{$hash{relay_list}}, $cut;
	push @{$hash{relay_sub_list}}, (caller(0))[3];
	$hash{relay_cut}++;
	return 'relay_3', $hash{relay_cut};
}

sub relay_3 {
	my $cut = shift;
	push @{$hash{relay_list}}, $cut;
	push @{$hash{relay_sub_list}}, (caller(0))[3];
	$hash{relay_cut}++;
	return 'relay_stop', $hash{relay_cut};
}

sub relay_stop {
	my $cut = shift;
	push @{$hash{relay_list}}, $cut;
	push @{$hash{relay_sub_list}}, (caller(0))[3];
	$hash{relay_cut}++;
	return ;
}

sub get {
	#my %h = %hash;
	#return \%h;
	return \%hash;
}

1;
