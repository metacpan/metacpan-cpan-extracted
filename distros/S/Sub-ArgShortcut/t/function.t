use strict; use warnings;

use Test::More;
use Sub::ArgShortcut;

sub original() { 'original' }
sub modified() { 'modified' }

my $test = argshortcut { $_ = modified for @_ };

plan tests => my $num_tests;

{
	local $_ = original;
	$test->();
	is( $_, modified, 'in-place on $_' );
	BEGIN { $num_tests += 1 }
}

{
	local $_ = original;
	my $res = $test->();
	is( $_,   original, 'nondestructive from $_' );
	is( $res, modified, '...returned correctly' );
	BEGIN { $num_tests += 2 }
}

{
	my $num = 10;
	my @original = ( original ) x $num;
	my @modified = ( modified ) x $num;
	$test->( my @data = @original );
	is_deeply( \@data, \@modified, 'in-place on params' );
	BEGIN { $num_tests += 1 }
}

{
	my $num = 10;
	my @original = ( original ) x $num;
	my @modified = ( modified ) x $num;
	my @res = $test->( my @data = @original );
	is_deeply( \@data, \@original, 'non-destructive from params' );
	is_deeply( \@res,  \@modified, '...returned correctly' );
	BEGIN { $num_tests += 2 }
}
