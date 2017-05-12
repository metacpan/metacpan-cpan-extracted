package DBIx::SystemCatalog::Pg;

use strict;
use DBI;
use DBIx::SystemCatalog;
use vars qw/$VERSION @ISA/;

$VERSION = '0.03';
@ISA = qw/DBIx::SystemCatalog/;

1;

sub _relkind2type {
	my ($obj,$relkind) = @_;

	if (defined $relkind) {
		return SC_TYPE_TABLE if $relkind eq 'r';
		return SC_TYPE_VIEW if $relkind eq 'v';
	}
	return SC_TYPE_UNKNOWN
}

sub schemas {
	my $obj = shift;

#	return $obj->{dbi}->{Name};
	return ();
}

sub tables {
	my $obj = shift;

	my $d = $obj->{dbi}->selectall_arrayref("SELECT relname FROM pg_class WHERE relkind IN ('r','v')");
	return () unless defined $d and @$d;
	return map { $_->[0] } @$d;
}

sub table_type {
	my $obj = shift;
	my $table = shift;

	my $d = $obj->{dbi}->selectall_arrayref("SELECT relkind FROM pg_class WHERE relname = ?",{},$table);

	return $obj->_relkind2type($d->[0]->[0]) if defined $d and @$d;
	return SC_TYPE_UNKNOWN;
}

sub tables_with_types {
	my $obj = shift;
	my $d = $obj->{dbi}->selectall_arrayref("SELECT relname,relkind FROM pg_class WHERE relkind IN ('r','v')");
	return () unless defined $d and @$d;
	return map { { name => $_->[0], type => $obj->_relkind2type($_->[1]) }; } @$d;
}

sub primary_keys {
	my $obj = shift;
	my $table = shift;

	return () unless $table;

	my $d = $obj->{dbi}->selectall_arrayref(q!SELECT pg_index.indkey FROM pg_class,pg_index WHERE pg_class.relname = ? AND pg_class.oid = pg_index.indrelid AND pg_index.indisprimary!,{},$table);
	if (defined $d and @$d) {
		my $sloupce = $d->[0]->[0];
		$sloupce =~ tr/ /,/;
		$d = $obj->{dbi}->selectall_arrayref(qq!SELECT pg_attribute.attname FROM pg_class,pg_attribute WHERE pg_class.relname = ? AND pg_attribute.attrelid = pg_class.oid AND pg_attribute.attnum IN ($sloupce)!,{},$table);

		return map { $_->[0] } @$d if defined $d and @$d;
	}
	return ();
}

sub relationships {
	my $obj = shift;

	my $d = $obj->{dbi}->selectall_arrayref(q!SELECT st.relname,dt.relname,COALESCE(NULLIF(tgconstrname,'<unnamed>'),tgname),tgargs FROM pg_trigger,pg_class st,pg_class dt WHERE tgfoid = 1644 AND st.oid = tgrelid AND dt.oid = tgconstrrelid!);

	return map { 
		my @args = split /\x0/,$_->[3]; 
		my $f = 1;  my @cols1 = ();  my @cols2 = ();
		for (@args[4..$#args]) { 
			if ($f) { push @cols1,$_; $f = 0; } else { push @cols2,$_; $f = 1; } 
		}; 
		{ from_table => $_->[0], to_table => $_->[1], name => $_->[2], 
		  from_columns => [ map { { table => $args[1], column => $_ } } @cols1 ], 
		  to_columns => [ map { { table => $args[2], column => $_ } } @cols2 ] } 
	    } @$d if defined $d and @$d;
	return ();
}

# For Ludek:
# What we will need to add to DBIx::SystemCatalog::Pg in near future:
#	- schema support (now I see all tables together, but I want to
#		separate tables from one schema (database in PgSQL terminology)
#		and from another schema
#	- I remade _rel2kind to OOP version - please respect OOP in all methods
