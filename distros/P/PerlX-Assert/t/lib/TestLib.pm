require Test::More;
Test::More::plan( skip_all => "broken by PerlX::Assert's change to decision logic" );

package main;

no warnings qw(void);

BEGIN {
	$ENV{AUTHOR_TESTING} = $ENV{PERL_STRICT} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
};

#line 0 02kwapi.t
{
	package Foo;
	use PerlX::Assert;
	sub go {
		my $self = shift;
		my ($x) = @_;
		assert { $x < 5 };
		return 1;
	}
}
	
die("Could not compile class Foo: $@") if $@;

ok( 'Foo'->go(6), 'class compiled with no relevant environment variables; assertions are ignored' );
ok( 'Foo'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{PERL_STRICT} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{AUTHOR_TESTING} = 1;
	};
	
#line 0 02kwapi.t
	{
		package Foo_AUTHOR;
		use PerlX::Assert;
		sub go {
			my $self = shift;
			my ($x) = @_;
			assert { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_AUTHOR'->go(6) },
		qr{^Assertion failed at 02kwapi.t line 6},
		"class compiled with \$ENV{AUTHOR_TESTING}; assertions are working",
	);
	ok( 'Foo_AUTHOR'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{PERL_STRICT} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{PERL_STRICT} = 1;
	};
	
#line 0 02kwapi.t
	{
		package Foo_AUTOMATED;
		use PerlX::Assert;
		sub go {
			my $self = shift;
			my ($x) = @_;
			assert { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_AUTOMATED'->go(6) },
		qr{^Assertion failed at 02kwapi.t line 6},
		"class compiled with \$ENV{PERL_STRICT}; assertions are working",
	);
	ok( 'Foo_AUTOMATED'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{PERL_STRICT} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{EXTENDED_TESTING} = 1;
	};
	
#line 0 02kwapi.t
	{
		package Foo_EXTENDED;
		use PerlX::Assert;
		sub go {
			my $self = shift;
			my ($x) = @_;
			assert { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_EXTENDED'->go(6) },
		qr{^Assertion failed at 02kwapi.t line 6},
		"class compiled with \$ENV{EXTENDED_TESTING}; assertions are working",
	);
	ok( 'Foo_EXTENDED'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{PERL_STRICT} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
		$ENV{RELEASE_TESTING} = 1;
	};
	
#line 0 02kwapi.t
	{
		package Foo_RELEASE;
		use PerlX::Assert;
		sub go {
			my $self = shift;
			my ($x) = @_;
			assert { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_RELEASE'->go(6) },
		qr{^Assertion failed at 02kwapi.t line 6},
		"class compiled with \$ENV{RELEASE_TESTING}; assertions are working",
	);
	ok( 'Foo_RELEASE'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

{
	BEGIN {
		$ENV{AUTHOR_TESTING} = $ENV{PERL_STRICT} = $ENV{EXTENDED_TESTING} = $ENV{RELEASE_TESTING} = 0;
	};
	
#line 0 02kwapi.t
	{
		package Foo_EXPLICIT;
		use PerlX::Assert -check;
		sub go {
			my $self = shift;
			my ($x) = @_;
			assert { $x < 5 };
			return 1;
		}
	}
	
	like(
		exception { 'Foo_EXPLICIT'->go(6) },
		qr{^Assertion failed at 02kwapi.t line 6},
		"class compiled with -check; assertions are working",
	);
	ok( 'Foo_EXPLICIT'->go(4), '... and a dummy value that should not cause assertion to fail anyway' );
}

done_testing;

1;
