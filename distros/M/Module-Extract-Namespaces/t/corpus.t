use strict;
use warnings;

use File::Spec::Functions qw(catfile);

use Test::More 'no_plan';

my $class  = 'Module::Extract::Namespaces';
my $method = 'from_file';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #	
# Test with files that exist
{
my %Corpus = (
	'None.pm'              => [],   # Perl code but no package
	'Empty.pm'             => [],   # nothing in the file
	'DifferentLines.pm'    => [ 'Foo::Comment', 'Foo::Newline' ],
	'Multiple.pm'          => [ map "Foo::$_", qw(First Second Third) ],
	'Duplicates.pm'        => [ map "Foo::$_", qw(First Second Third First) ],
	'NewPackageSyntax.pm'  => [ qw(Mimi Buster Roscoe Addy) ],
	);

foreach my $file ( sort keys %Corpus ) {
	my $path = catfile( 'corpus', $file );
	ok( -e $path, "Corpus file [ $path ] exists" );

	my $namespaces = [ $class->$method( $path ) ];
	ok( ! $class->error, "No error from good file [$file]");
	is_deeply( $namespaces, $Corpus{$file}, "Extracts right namespaces for $file" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #	
# Test with a Perl 5.12 file
{
my %Corpus = (
	'NewPackageSyntax.pm'  => [
		[ qw(Mimi 4.56)     ],
		[ qw(Buster), undef ],
		[ qw(Roscoe v1.0.1) ],
		[ qw(Addy), undef   ],
		],
	);

foreach my $file ( sort keys %Corpus ) {
	my $path = catfile( 'corpus', $file );
	ok( -e $path, "Corpus file [ $path ] exists" );

	my $namespaces = [ $class->$method( $path, 1 ) ];
	ok( ! $class->error, "No error from good file [$file]");
	is_deeply( $namespaces, $Corpus{$file}, "Extracts right namespaces for $file" );
	}
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with a file that doesn't exist
{
my $file = "foobarbazquux.html.gz.pm";
ok( ! -e $file, "File [$file] is properly missing" );

my $namespaces = [ $class->$method( $file ) ];
like( $class->error, qr/does not exist/, "Trying to parse missing file sets right error" );
is_deeply( $namespaces, [], "No modules extracted from missing file" );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #	
# Test with a file that does exist, but isn't Perl
my $file = catfile( qw(corpus not_perl.txt) );
ok( -e $file, "Non Perl file [$file] exists" );

my $rc = eval {  $class->$method( $file ) };
my $at = $@;
ok( ! defined $rc,  "$method returns undef for non-Perl file [$file]" );
