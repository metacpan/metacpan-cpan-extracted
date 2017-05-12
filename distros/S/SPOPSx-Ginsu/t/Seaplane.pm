package Seaplane;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.14 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ Boat FixedWing /;
	$CONF = {
		SeaplaneAlias => {
			class			=> 'Seaplane',
			isa				=> \@ISA,
			field			=> [ qw/ id max_wave_height / ],
			as_string_order => [ qw/ id class name owner ceiling wingspan max_wave_height min_depth anchor / ],
			base_table		=> 'Seaplane',
			id_field		=> 'id',
			skip_undef		=> [ qw/ max_wave_height / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Seaplane (
	id				int(11) PRIMARY KEY,
	max_wave_height int(11)
)
SQL
}

use FixedWing;
use Boat;

sub land_on_water {
	my $self = shift;
	print "Splash! Seaplane: " . $self->{name} . " ... lands on water.\n";
}

__PACKAGE__->config_and_init;

1;
