package Helicopter;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.12 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ Aircraft /;
	$CONF = {
		HelicopterAlias => {
			class			=> 'Helicopter',
			isa				=> \@ISA,
			field			=> [ qw/ id lift_capacity / ],
			as_string_order => [ qw/ id class name owner ceiling lift_capacity / ],
			base_table		=> 'Helicopter',
			id_field		=> 'id',
			skip_undef		=> [ qw/ lift_capacity / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Helicopter (
	id				int(11) PRIMARY KEY,
	lift_capacity	int(11)
)
SQL
}

use Aircraft;

sub hover {
	my $self = shift;
	print "Helicopter: " . $self->{name} . " ... hovers.\n";
}

__PACKAGE__->config_and_init;

1;
