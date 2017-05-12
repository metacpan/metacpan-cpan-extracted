use PPM::Repositories qw(get list used_archs);

for my $arch (used_archs()) {
    print "$arch\n";
    for my $name (list($arch)) {
	my %repo = get($name, $arch);
	next unless $repo{packlist};
	print "  $name\n";
	for my $field (sort keys %repo) {
	    printf "    %-12s %s\n", $field, $repo{$field};
	}
    }
}
