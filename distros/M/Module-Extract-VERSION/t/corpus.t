use strict;
use warnings;

use File::Spec;

use Test::More 1.0;

my $class  = 'Module::Extract::VERSION';
my $method = 'parse_version_safely';

my %Corpus = (
	'Easy.pm'        => 3.01,
	'RCSKeywords.pm' => 1.23,
	'Underscore.pm'  => "0.10_01",
	'ToTk.pm'        => undef,
	'QV.pm'          => '7.4.2',
	'QV_single.pm'   => '8.5.2',
	'QV_double.pm'   => '73.8.5552',
	'version-declare.pm'   => '2.1.5',
	'version-declare-v.pm'   => '1.3.7',
	);

if( $] >= 5.012 ) {
	$Corpus{ 'Easy_5_12.pm' } = '3.01';
	$Corpus{ 'Dotted_5_12.pm' } = 'v0.10.01';
	}

if( $] >= 5.014 ) {
	$Corpus{ 'Easy_5_14_braces.pm' } = '3.01';
	$Corpus{ 'Dotted_5_14_braces.pm' } = 'v0.10.01';
	}

subtest basics => sub {
	use_ok $class or BAIL_OUT "$class did not compile! $@";
	can_ok $class, $method;
	};

foreach my $file ( sort keys %Corpus ) {
	subtest $file => sub {
		my $path = File::Spec->catfile( 'corpus', $file );
		ok -e $path, "Corpus file <$path> exists";
		my $version = eval{ $class->$method( $path ) };

		is( $version, $Corpus{$file}, "Works for $file" );
		};
	}

done_testing();
