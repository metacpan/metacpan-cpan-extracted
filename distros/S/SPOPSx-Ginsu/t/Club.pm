package Club;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.14 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyBaseObject /;
	$CONF = {
		ClubAlias => {
			class			=> 'Club',
			isa				=> \@ISA,
			field			=> [ qw/ club_id name / ],
			as_string_order => [ qw/ club_id class name / ],
			base_table		=> 'Club',
			id_field		=> 'club_id',
			skip_undef		=> [ qw/ name / ],
			links_to		=> { 'Person' => 'ClubMembers' },
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Club (
	club_id	 int(11) PRIMARY KEY,
	name	char(255)
)
SQL
}

use MyBaseObject;
use Person;

sub list_members {
	my $self = shift;
	foreach (@{ $self->PersonAlias }) {
		print $_->name . "\n";
	}
	return;
}

__PACKAGE__->config_and_init;

1;
