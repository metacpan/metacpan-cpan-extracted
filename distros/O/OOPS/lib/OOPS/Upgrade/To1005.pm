
package OOPS::Upgrade::To1005;

use OOPS::Setup;
use strict;
use warnings;

sub upgrade
{
	my ($oldversion, %args) = @_;

	if ($oldversion ne '1004') {
		require OOPS::Upgrade::To1004;
		OOPS::Upgrade::To1004::upgrade($oldversion, %args);
	}

	print STDERR "# Schema upgrade to 1005...\n" if $OOPS::debug_upgrade;

	my $dbo = OOPS::DBO->dboconnect(%args);

	my (@r) = $dbo->db_domany(<<END, args => \%args, commit => 1);
			
		ALTER TABLE TP_object 
		ADD COLUMN gcgeneration INT DEFAULT 1;

		INSERT INTO TP_attribute values (2, 'GC GENERATION', '2', '0');

		INSERT INTO TP_object values ($OOPS::gc_overflow_id, $OOPS::gc_overflow_id, 'HASH', 'H', 'V', '0', '0', 0, 1, 1, 2);

		INSERT INTO TP_attribute values (2, 'gc extra todo', '$OOPS::gc_overflow_id', 'R');

		UPDATE TP_object
		SET alen = 1005
		WHERE id = 1;

		UPDATE TP_attribute	
		SET pval = '$OOPS::VERSION'
		WHERE id = 2 AND pkey = 'VERSION';

		UPDATE TP_attribute
		SET pval = '$OOPS::SCHEMA_VERSION'
		WHERE id = 2 AND pkey = 'SCHEMA_VERSION';

END
}

1;
