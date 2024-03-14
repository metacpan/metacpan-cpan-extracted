use strict; use warnings;

use Test::More;

my @module = qw(
	Plack::App::File::Precompressed
	Plack::Middleware::Static::Precompressed
);

diag "Testing on Perl $] at $^X";

for my $module ( @module ) {
	use_ok( $module ) or BAIL_OUT "Cannot load module '$module'";
	no warnings 'uninitialized';
	diag "Testing $module @ " . $module->VERSION;
}

done_testing;
