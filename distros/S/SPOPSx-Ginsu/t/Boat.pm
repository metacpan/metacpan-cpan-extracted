package Boat;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF %HASA_CLASS);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.19 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ Vehicle /;
	$CONF = {
		BoatAlias => {
			class			=> 'Boat',
			isa				=> \@ISA,
			field			=> [ qw/ id min_depth anchor / ],
			as_string_order => [ qw/ id class name owner min_depth anchor / ],
			base_table		=> 'Boat',
			has_a			=> { 'Anchor' => [ 'anchor' ] },
			id_field		=> 'id',
			skip_undef		=> [ qw/ min_depth anchor / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Boat (
	id       int(11) PRIMARY KEY,
	min_depth numeric(10,2),
	anchor  int(11)
)
SQL
}

sub e_has_a {
	return	{
				anchor => {
					class  => 'Anchor',
					fetch  => {	type => 'auto'	},
					remove => {	type => 'auto'	},
				}
			};
}

use Vehicle;
use Anchor;

sub remove_barnacles {
	my $self = shift;
	print "Barnacles removed from " . $self->{name} . "\n"; 
}

__PACKAGE__->config_and_init;

1;
