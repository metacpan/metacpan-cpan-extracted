package Puzzle::DBIx::Iterator;

our $VERSION = '0.02';

use base 'Class::DBI::Iterator';


sub as_loop {
	my $rec			= shift;
	my $ret			= [];
	while (my $row = $rec->next) {
		my @columns = $row->columns;
		push @$ret ,{map {$_ => $row->$_} @columns}; 
	}
	$rec->reset;
	return $ret;
}

1;
