use Test::More;

use File::Spec::Functions qw(catfile);

my $class  = 'PPI::App::ppi_version::BDFOY';
my $method = 'get_version';

use_ok( $class );
can_ok( $class, $method );

subtest 'our' => sub {
	my $file = catfile( qw(corpus our.pm) );
	my @rc = $class->$method( $file );
	ok( $rc[0], "$method returns true for $file" );
	};
	
subtest 'vars' => sub {
	my $file = catfile( qw(corpus vars.pm) );
	my @rc = $class->$method( $file );	
	ok( $rc[0], "$method returns true for $file" );
	};

done_testing();
