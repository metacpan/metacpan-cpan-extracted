use Perlmazing;

sub main {
	my @res;
	my $seen = {};
	for my $class (@_) {
		next if $seen->{$class};
		$seen->{$class} = 1;
		$class = ref($class) if is_blessed $class;
		no strict 'refs';
		push @res, $class;
		for my $i (main(@{"$class\::ISA"})) {
			next if $seen->{$i};
			$seen->{$i} = 1;
			push @res, $i;
		}
	}
	push @res, 'UNIVERSAL' unless caller eq __PACKAGE__;
	@res;
}

1;
