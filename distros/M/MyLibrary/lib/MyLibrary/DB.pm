package MyLibrary::DB;

use DBI;
use MyLibrary::Config;
use Carp qw(croak);
use strict;

my $dbh;

=head1 NAME

MyLibrary::DB

=head1 SYNOPSIS

	use MyLibrary::DB;

	my $dbh = MyLibrary::DB->dbh();

=head1 DESCRIPTION

This package connects to MyLibrary and returns the database handle.

=head1 FUNCTIONS

=head2 dbh()

Returns database handle to MyLibrary.

=head1 AUTHORS

Eric Lease Morgan <emorgan@nd.edu>
Robert Fox <rfox2@nd.edu>

=cut

sub dbh {

	if ($dbh) {
		return $dbh;
	}
	$dbh = DBI->connect($MyLibrary::Config::DATA_SOURCE, $MyLibrary::Config::USERNAME, $MyLibrary::Config::PASSWORD) || croak('Can\'t connect to database.');
	return $dbh;
}

sub nextID {

	my $self = shift;
	my $dbh = dbh();
	$dbh->do('UPDATE sequence SET id = id + 1');
	my ($id) = $dbh->selectrow_array('SELECT id FROM sequence');
	if ($id) {
		return $id;
	} else { # there was a problem
		return;
	}
}

1;
