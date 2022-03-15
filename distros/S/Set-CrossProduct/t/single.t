use strict;
no warnings;

use Test::More 0.95;

my $Class = 'Set::CrossProduct';
use_ok( $Class );

subtest warnings_off => sub {
	no warnings;
	open my $fh, '>', \my $string;
	my $cross = do {
		local *STDERR = $fh;
		Set::CrossProduct->new( [ [1,2,3] ] );
		};
	ok( ! defined $cross,  "A single set returns undef" );
	string_not_empty_or_undef( $string, "There is no warning when warnings are not enabled (good)" );
	};

subtest warnings_on => sub {
	use warnings;
	open my $fh, '>', \my $string;
	my $cross = do {
		local *STDERR = $fh;
		Set::CrossProduct->new( [ [1,2,3] ] );
		};
	ok( ! defined $cross,  "A single set returns undef" );
	string_not_empty_or_undef( $string, "There is a warning when warnings are enabled (good)" );
	};

subtest not_array_refs => sub {
	use warnings;
	open my $fh, '>', \my $string;
	my $cross = do {
		local *STDERR = $fh;
		Set::CrossProduct->new( [ qw(a b) ] );
		};
	ok( ! defined $cross,  "A single set returns undef" );
	string_not_empty_or_undef( $string, "There is a warning when warnings are enabled (good)" );
	like $string, qr/needs to be an array reference/, 'Warning matches the expected pattern';
	};

# Perl might autovivify the value in a string filehandle's target, so
# even with no output, it might turn from undef to the empty string
#
sub string_not_empty_or_undef {
	my $rc = ( ! defined $_[0] ) || ( 0 < length $_[0] );
	ok( $rc, $_[1] );
	}

done_testing();
