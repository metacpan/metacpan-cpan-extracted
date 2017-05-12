package BoatNoSaveAnchor;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ Boat /;
}

sub e_has_a {
	return	{
				anchor => {
					class  => 'Anchor',
					fetch  => {	type => 'auto', nosave => 1	},
					remove => {	type => 'auto'	},
				}
			};
}

use Boat; 

1;
