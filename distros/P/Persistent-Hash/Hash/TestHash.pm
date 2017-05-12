#!/usr/bin/perl
package Persistent::Hash::TestHash;

use strict;
use Carp qw(croak);

use base qw(Persistent::Hash);

use constant STORABLE => 1;
use constant INFO_TABLE => 'phash_tests_info';

use constant DATA_TABLE => 'phash_tests_data';
use constant DATA_FIELDS => ['tk1','tk2','tk3','blow','explosion','bomb','reason'];

use constant INDEX_TABLE => 'phash_tests_index';
use constant INDEX_FIELDS => ['itk1','itk2','itk3'];

use constant STRICT_FIELDS => 1;

sub STORAGE_MODULE { return 'Persistent::Hash::Storage::'.$Persistent::Hash::Tests::STORAGE_MODULE; }

sub DatabaseHandle
{
	my $self = shift;
	my $dbh = $Persistent::Hash::Tests::DBH;

	if(not $dbh)
	{
		$dbh = DBI->connect(
			$Persistent::Hash::Tests::DSN, 
			$Persistent::Hash::Tests::DB_USER, 
			$Persistent::Hash::Tests::DB_PW
		);
		$Persistent::Hash::Tests::DBH = $dbh;
	}
	return $dbh;
}

666;
