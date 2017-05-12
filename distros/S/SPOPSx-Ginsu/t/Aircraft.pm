package Aircraft;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.11 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ Vehicle /;
	$CONF = {
		AircraftAlias => {
			class			=> 'Aircraft',
			isa				=> \@ISA,
			field			=> [ qw/ id ceiling / ],
			as_string_order => [ qw/ id class name owner ceiling / ],
			base_table		=> 'Aircraft',
			id_field		=> 'id',
			skip_undef		=> [ qw/ ceiling / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Aircraft (
	id		 int(11) PRIMARY KEY,
	ceiling	 int(11)
)
SQL
}

use Vehicle;

sub pre_flight_check {
	my $self = shift;
	print "Preflight check of Aircraft: " . $self->{name} . " ... done.\n";
}

__PACKAGE__->config_and_init;

1;
