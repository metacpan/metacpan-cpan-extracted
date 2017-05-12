package FixedWing;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.12 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ Aircraft /;
	$CONF = {
		FixedWingAlias => {
			class			=> 'FixedWing',
			isa				=> \@ISA,
			field			=> [ qw/ id wingspan / ],
			as_string_order => [ qw/ id class name owner ceiling wingspan / ],
			base_table		=> 'FixedWing',
			id_field		=> 'id',
			skip_undef		=> [ qw/ wingspan / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS FixedWing (
	id		  int(11) PRIMARY KEY,
	wingspan  int(11)
)
SQL
}

use Aircraft;

sub deice_wings {
	my $self = shift;
	print "Deice wings of FixedWing: " . $self->{name} . " ... done.\n";
}

__PACKAGE__->config_and_init;

1;
