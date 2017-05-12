package Slip;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.13 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyBaseObject /;
	$CONF = {
		SlipAlias => {
			class			=> 'Slip',
			isa				=> \@ISA,
			field			=> [ qw/ id number boat boatyard / ],
			as_string_order => [ qw/ id class number boat boatyard / ],
			base_table		=> 'Slip',
			id_field		=> 'id',
			has_a			=> {	'Boat'		=> [ 'boat' ],
									'Boatyard'	=> [ 'boatyard' ]	},
			skip_undef		=> [ qw/ number boat boatyard / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Slip (
	id		 int(11) PRIMARY KEY,
	number	 int(11),
	boat	 int(11),
	boatyard int(11)
)
SQL
}

use MyBaseObject;
use Boat;
use Boatyard;

__PACKAGE__->config_and_init;

1;
