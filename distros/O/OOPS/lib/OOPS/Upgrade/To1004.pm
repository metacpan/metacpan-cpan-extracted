
package OOPS::Upgrade::To1004;

use OOPS::Setup;
use strict;
use warnings;

sub upgrade
{
	my ($oldversion, %args) = @_;

	if ($oldversion ne '1003') {
		require OOPS::Upgrade::To1003;
		OOPS::Upgrade::To1003::upgrade($oldversion, %args);
	}

	print STDERR "# Schema upgrade to 1004...\n" if $OOPS::debug_upgrade;

	my $dbo = OOPS::DBO->dboconnect(%args);
	my $dbh = $dbo->{dbh};
	my $prefix = $dbo->{table_prefix};

	if ($dbo->{dbms} eq 'pg') {

		eval { $dbo->do("DROP TABLE ${prefix}temp;") };
		if ($@) {
			$dbo->disconnect();
			$dbo = $dbo->dboconnect(%args);
			$dbh = $dbo->{dbh};
		}


		my ($oldver) = $dbh->selectrow_array(<<END) or die $dbh->errstr;
			SELECT	alen
			FROM	${prefix}object
			WHERE	id = 1
END
		
		die "oldver=$oldver" unless $oldver eq '1003';

		$dbh->do(<<END) or die $dbh->errstr;
			CREATE TABLE ${prefix}temp AS
			SELECT	* FROM ${prefix}big;
END
		$dbh->do(<<END) or die $dbh->errstr;
			DROP TABLE ${prefix}big;
END

		$dbh->do(<<END) or die $dbh->errstr;
			CREATE TABLE ${prefix}big (
				id		BIGINT NOT NULL, 
				pkey		BYTEA,
				pval		BYTEA,
				PRIMARY KEY (id, pkey));
END
		
		my $count = $dbh->do(<<END) or die $dbh->errstr;
			INSERT	INTO ${prefix}big
			SELECT	id, pkey, DECODE(pval, 'escape')
			FROM	${prefix}temp;
END

		print STDERR "# Upgrading to scheema 1004, $count rows of ${prefix}big converted.\n"
			if $OOPS::debug_upgrade;

		$dbh->do(<<END) or die $dbh->errstr;
			DROP TABLE ${prefix}temp;
END
	}
		
	$dbh->do(<<END) or die $dbh->errstr;
		UPDATE ${prefix}object
		SET alen = 1004
		WHERE id = 1
END

	$dbh->commit() or die $dbh->errstr;
	$dbh->disconnect();
}

1;

