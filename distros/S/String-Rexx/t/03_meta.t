use Test::More  'no_plan';

eval 'use Test::CPAN::Meta';


SKIP: {
	skip 'Test::CPAN::Meta not installed', 1    if $@;
	push @_ , <../*.yml>, <*.yml>; 
	meta_spec_ok( shift @_  );
}

