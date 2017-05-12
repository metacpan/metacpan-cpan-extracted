#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Spec::Functions;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class = 'MyCPAN::Indexer';
my $method = 'extract_module_namespaces';
use_ok( $class );
can_ok( $class, $method );

my $indexer = $class->new;
isa_ok( $indexer, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my @tests = (
    #     file                  primary     other packages
	[qw( Test-Pod.pm            Test::Pod Test::Pod::_parser ) ],
	[qw( Chemistry-Elements.pm  Chemistry::Elements          ) ],
	);

foreach my $test ( @tests )
	{
	my $file = catfile( 'test-corpus', shift @$test );
	ok( -e $file, "$file exists" );
	
	my $hash = {};
	$indexer->$method( $file, $hash );
	
	ok( exists $hash->{packages}, "'packages' key is in the result hash" );
	is( ref $hash->{packages}, ref [], "'packages' value is an array ref" );

	ok( exists $hash->{primary_package}, "'primary_package' key is in the result hash" );
	is( $hash->{primary_package}, $test->[0], "'primary_package' value is has the right value [$test->[0]]" );
	
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


__END__


sub extract_module_namespaces
	{
	my( $self, $file, $hash ) = @_;

	require Module::Extract::Namespaces;

	my @packages = Module::Extract::Namespaces->from_file( $file );

	$logger->warn( "Didn't find any packages in $file" ) unless @packages;

	$hash->{packages} = [ @packages ];

	$hash->{module_name_from_file_guess} = $self->get_package_name_from_filename( $file );

	$hash->{primary_package} = $self->guess_primary_package;

	1;
	}
