use Data::Integer 0.001;

if((Data::Integer::max_natint-2) % 2 != 1) {
	require Test::More;
	Test::More::plan(skip_all =>
		"pure Perl Scalar::Number can't work on this system");
}

require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for Scalar::Number"
		if ($_[0] || "") eq "Scalar::Number";
	goto &$orig_load;
};

1;
