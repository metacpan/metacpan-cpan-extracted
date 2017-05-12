#!perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'MyCPAN::Indexer';
my $method = 'guess_primary_package';
use_ok( $class );
can_ok( $class, $method );

my $indexer = $class->new;
isa_ok( $indexer, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test the case where there is a private package (starts with _)
{
my $file     = 'blib/lib/Pod.pm'; 
my @packages = qw(Test::Pod::_parser Test::Pod);
my $primary_package = $class->$method( \@packages, $file );
is( $primary_package, 'Test::Pod', 'Gets right package for Test::Pod' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test the case where there are special packages
{
my $file     = 'blib/lib/Foo/Bar.pm'; 
my @packages = qw(bytes main DB Foo::Bar::Baz Foo::Bar );
my $primary_package = $class->$method( \@packages, $file );
is( $primary_package, 'Foo::Bar', 'Gets right package for Foo::Bar' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test the case where the package and filename don't align
{
my $file     = 'blib/lib/Quux.pm'; 
my @packages = qw( Blah );
my $primary_package = $class->$method( \@packages, $file );
is( $primary_package, 'Blah', 'Gets right package for Quux' );
}

__END__
sub guess_primary_package
	{
	my( $self, $packages, $file ) = @_;

	my $module = $self->get_package_name_from_filename( $file );
	
	my @matches = grep { $_ eq $module } @$packages;

	# ignore packages that start with an underscore
	my $packages = grep { ! /^_/ } @$packages;
	
	my $primary_package = $matches[0] || $packages->[0];

	return $primary_package;	
	}
