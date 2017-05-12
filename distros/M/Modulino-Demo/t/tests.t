use Test::More;

my @classes = qw(
	Modulino::Demo
	Modulino::Demo2
	Modulino::Base
	Modulino::Test
	Modulino::TestWithBase
	);
	
foreach my $class ( @classes ) {
	subtest $class => sub {
		ok( eval "require $class", "Loading $class" ) 
			or warn "$class $@";
		};
	}

done_testing();
