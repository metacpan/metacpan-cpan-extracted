package Anchor;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.14 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyBaseObject /;
	$CONF = {
		AnchorAlias => {
			class			=> 'Anchor',
			isa				=> \@ISA,
			field			=> [ qw/ id weight / ],
			as_string_order => [ qw/ id class weight / ],
			base_table		=> 'Anchor',
			id_field		=> 'id',
			skip_undef		=> [ qw/ weight / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Anchor (
	id		 int(11) PRIMARY KEY,
	weight	int(11)
)
SQL
}

use MyBaseObject;

sub drop {
	my $self = shift;
	print "Drop " . $self->{weight} . " lb. anchor.\n";
}

__PACKAGE__->config_and_init;

1;
