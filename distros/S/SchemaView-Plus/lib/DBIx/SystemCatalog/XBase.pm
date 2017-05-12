package DBIx::SystemCatalog::XBase;

use strict;
use DBI;
use DBIx::SystemCatalog;
use vars qw/$VERSION @ISA/;

$VERSION = '0.01';
@ISA = qw/DBIx::SystemCatalog/;

1;


sub fs_ls {
	my $obj = shift;
	my $cwd = shift;

	if ($cwd eq '/') {		# all tables
		return map { '/'.$_; } sort $obj->tables;
	} else {			# unknown
		return ();
	}
}

1;

