use strict;
use warnings;

use File::Spec;

use Test::More 0.95;

use_ok( 'Module::Extract::VERSION' );
can_ok( 'Module::Extract::VERSION', qw(parse_version_safely) );

my %Corpus = (
	'Easy.pm'        => 3.01,
	'RCSKeywords.pm' => 1.23,
	'Underscore.pm'  => "0.10_01",
	'ToTk.pm'        => undef,
	);

if ($] >= 5.012) {
	$Corpus{ 'Easy_5_12.pm' } = '3.01';
	$Corpus{ 'Dotted_5_12.pm' } = 'v0.10.01';
}

if ($] >= 5.014) {
	$Corpus{ 'Easy_5_14_braces.pm' } = '3.01';
	$Corpus{ 'Dotted_5_14_braces.pm' } = 'v0.10.01';
}
	
foreach my $file ( sort keys %Corpus )
	{
	my $path = File::Spec->catfile( 'corpus', $file );
	ok( -e $path, "Corpus file [ $path ] exists" );

	my $version =
		eval{ Module::Extract::VERSION->parse_version_safely( $path ) };

	is( $version, $Corpus{$file}, "Works for $file" );

	}

done_testing();
