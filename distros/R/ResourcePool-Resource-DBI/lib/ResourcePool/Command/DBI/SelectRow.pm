#*********************************************************************
#*** lib/ResourcePool/Command/DBI/SelectRow.pm
#*** Copyright (c) 2004 by Markus Winand <mws@fatalmind.com>
#*** $Id: SelectRow.pm,v 1.3 2004/05/02 07:48:55 mws Exp $
#*********************************************************************
package ResourcePool::Command::DBI::SelectRow;

use ResourcePool::Command;
use ResourcePool::Command::NoFailoverException;
use ResourcePool::Command::DBI::Select;
use strict;
use DBI;
use vars qw(@ISA $VERSION);

$VERSION = "1.0101";
push @ISA, qw(ResourcePool::Command::DBI::Select);

sub execute($$@) {
	my ($self, $dbh, @args) = @_; 
	
	my $sth = $self->SUPER::execute($dbh, @args);

	my (@ret, $rc);
	eval {
		@ret = $sth->fetchrow_array();
		$rc = $sth->err;
	};
	my $ex = $@;
	my $rcstr = $sth->errstr;

	eval {
		$sth->finish();
	}; # irgnore errors

	if ((! $rc) && (! $ex)) {
		return (@ret); # this list might be empty
	} else {
		# test if failover should occure
		my $rc2;
		eval {
			$rc2 = $dbh->ping();
		};
		my $sql = $self->getSQLfromargs(\@args);
		if ($rc2 && !$@) {
			die ref($self) . ': Execution of "' . $sql . '" failed: ' . $ex . "(" . $rc . ")\n";
		} else {
			die ResourcePool::Command::NoFailoverException->new(
				ref($self) . ': Execution of "' . $sql . '" failed: ' . $ex . "(" . $rc . ")\n"
			);
		}
	}
}


1;
