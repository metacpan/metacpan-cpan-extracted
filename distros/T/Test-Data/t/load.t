use Test::More;

my @modules = qw( Test::Data Test::Data::Array Test::Data::Function
	Test::Data::Hash Test::Data::Function );

foreach $module ( @modules ) {
	use_ok( $module );

	my $var = '$' . $module . '::VERSION';
	my $ver = 0 + eval $var;
	no warnings qw(numeric);
	cmp_ok( $ver, '>', 0 );
	}

done_testing();
