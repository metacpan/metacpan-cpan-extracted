package Person;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.14 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyBaseObject /;
	$CONF = {
		PersonAlias => {
			class			=> 'Person',
			isa				=> \@ISA,
			field			=> [ qw/ person_id name / ],
			as_string_order => [ qw/ person_id class name / ],
			base_table		=> 'Person',
			id_field		=> 'person_id',
			skip_undef		=> [ qw/ name / ],
			links_to		=> { 'Club' => 'ClubMembers' },
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Person (
	person_id	int(11) PRIMARY KEY,
	name		char(255)
)
SQL
}

use MyBaseObject;
use Club;

sub list_clubs {
	my $self = shift;
	foreach (@{ $self->ClubAlias }) {
		print $_->name . "\n";
	}
	return;
}

sub list_vehicles {
	my $self = shift;
	my @vehicles = @{ Vehicle->fetch_group({
						where	=> 'owner = ?',
						value	=> [ $self->id ]
					}) };
	foreach (@vehicles) {
		print $_->name . "\n";
	}
	return;
}

__PACKAGE__->config_and_init;

1;
