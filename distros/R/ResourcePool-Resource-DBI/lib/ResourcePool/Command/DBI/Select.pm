#*********************************************************************
#*** lib/ResourcePool/Command/DBI/Select.pm
#*** Copyright (c) 2004 by Markus Winand <mws@fatalmind.com>
#*** $Id: Select.pm,v 1.4 2004/05/02 07:48:55 mws Exp $
#*********************************************************************
package ResourcePool::Command::DBI::Select;

use ResourcePool::Command;
use ResourcePool::Command::NoFailoverException;
use ResourcePool::Command::DBI::Common;
use strict;
use DBI;
use vars qw(@ISA $VERSION);

$VERSION = "1.0101";
push @ISA, qw(ResourcePool::Command::DBI::Common ResourcePool::Command);

sub execute($$@) {
	my ($self, $dbh, @args) = @_; 

    my $sql = $self->getSQLfromargs(\@args);
    my $sth = $self->prepare($dbh, $sql);

    $self->bind($sth, \@args);

	my $rc = 1;
	eval {
		$rc = $sth->execute();
	};

	if ($rc && ! $@) {
		return $sth;	
	} else {
		# test if failover should occure
		eval {
			$rc = $dbh->ping();
		};
		if ($rc && !$@) {
			die 'Execution of "' . $sql . '" failed: ' . $sth->errstr() . "\n";
		} else {
			die ResourcePool::Command::NoFailoverException->new(
				'Execution of "' . $sql . '" failed: ' . $sth->errstr() . "\n"
			);
		}
	}
}


1;
