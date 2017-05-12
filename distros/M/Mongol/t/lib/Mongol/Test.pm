package Mongol::Test;

use Moose;
use Moose::Exporter;

use Test::More;
use Test::Moose;

use MongoDB;

Moose::Exporter->setup_import_methods(
	as_is => [ qw( check_mongod ) ],
);

sub check_mongod {
	my $mongo = undef;

	eval {
		$mongo = MongoDB->connect( $ENV{MONGOL_URL} || 'mongodb://localhost' );
		$mongo->db( 'test' )
			->run_command( [ ping => 1 ] );
	};

	plan skip_all => 'Cannot connect to mongo!'
		if( $@ );

	return $mongo;
}

__PACKAGE__->meta()->make_immutable();

1;

__END__
