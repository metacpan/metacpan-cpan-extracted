package ClubMembers;

use strict;

## NOTE: This is not an actual SPOPS or Ginsu object (never initialized),
## it only uses the $CONF and $TABLE_DEF variables to drop and recreate the table.

use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyDBI /;
	$CONF = {
		ClubMembersAlias => {
			class        => 'ClubMembers',
			isa          => \@ISA,
			base_table   => 'ClubMembers',
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS ClubMembers (
	person_id  int(11),
	club_id    int(11)
)
SQL
}

use MyDBI;

1;
