#!perl

# Compare:
#
# perl -Ilib bin/benchmark.pl
# perl -Ilib -MSpecioX::XS bin/benchmark.pl
#

use Benchmark;

timethis( -3, q{
	use Specio::Library::Builtins;
	my $type = t( 'ArrayRef', of => t( 'HashRef', of => t( 'Str' ) ) );
	my $arr  = [ map { foo => $_ }, 1 .. 100 ];
	for ( 0 .. 100 ) {
		$type->check( $arr ) or die;
	}
} );
