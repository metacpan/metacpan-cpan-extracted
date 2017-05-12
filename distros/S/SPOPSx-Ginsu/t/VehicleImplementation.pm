package VehicleImplementation;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyBaseObject /;
	$CONF = {
		VehicleImplementationAlias => {
			class			=> 'VehicleImplementation',
			isa				=> \@ISA,
			field			=> [ qw/ id name owner / ],
			as_string_order => [ qw/ id class name owner / ],
			base_table		=> 'Vehicle',
			id_field		=> 'id',
			has_a			=> { Person => [ 'owner' ] },
			skip_undef		=> [ qw/ name owner / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Vehicle (
	id		 int(11) PRIMARY KEY,
	name	 char(255),
	owner	 int(11)
)
SQL
}

use MyBaseObject; 
use Person;

__PACKAGE__->config_and_init;

1;
