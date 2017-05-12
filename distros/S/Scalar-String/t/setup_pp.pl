require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for Scalar::String"
		if ($_[0] || "") eq "Scalar::String";
	goto &$orig_load;
};

1;
