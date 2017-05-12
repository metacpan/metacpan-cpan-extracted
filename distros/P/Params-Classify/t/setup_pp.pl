require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for Params::Classify"
		if ($_[0] || "") eq "Params::Classify";
	goto &$orig_load;
};

1;
