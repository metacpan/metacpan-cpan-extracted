
package OOPS::Upgrade::To1003;

use OOPS::Setup;
use strict;
use warnings;

sub upgrade
{
	my ($oldversion, %args) = @_;

	die unless $oldversion eq '1001';

	print STDERR "# Schema upgrade to 1003...\n" if $OOPS::debug_upgrade;

	my $dbo = OOPS::DBO->dboconnect(%args);
	my $dbh = $dbo->{dbh};
	my $prefix = $dbo->{table_prefix};

	if ($dbo->{dbms} eq 'mysql') {
		$dbo->db_domany(<<END, args => \%args);
			
			ALTER TABLE TP_attribute 
			MODIFY COLUMN pkey VARCHAR(255) BINARY;

			ALTER TABLE TP_big
			MODIFY COLUMN pkey VARCHAR(255) BINARY;
END
		$dbo->commit();
	}
	$dbo->db_domany(<<END, args => \%args);

		UPDATE TP_object
		SET alen = 1003
		WHERE id = 1;

END
	$dbo->commit();
}

1;
