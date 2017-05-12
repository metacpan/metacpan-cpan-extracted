package SQL::Exec::ODBC::Teradata;
use strict;
use warnings;
use Exporter 'import';
use DBI;
use SQL::Exec::ODBC '/.*/', '!connect', '!table_exists';
use List::MoreUtils 'any';

our @ISA = ('SQL::Exec::ODBC');

our @EXPORT_OK = @SQL::Exec::ODBC::EXPORT_OK;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# dsn est le DSN au sens ODBC.
# par exemple 'DSN=dcn' (nom enregistré)
# sinon:  'DBCNAME=hostname' ou 'Host=1.2.3.4;Port=1000;'
sub build_connect_args {
	my ($c, $server, $user, $pwd, @opt) = @_;

	if (any { $_ eq $server } $c->list_available_DB()) {
		return ("dbi:ODBC:DSN=${server}", $user, $pwd, @opt);
	} else {
		return ("dbi:ODBC:DRIVER=Teradata;DBCNAME=${server}", $user, $pwd, @opt);	
	}
}

# Inutile, mais ça permet de ne pas l'oublier
sub get_default_connect_option {
	my $c = shift;
	return $c->SUPER::get_default_connect_option();
}

sub connect {
	my $c = &SQL::Exec::check_options;

	if (not $c->isa(__PACKAGE__)) {
		bless $c, __PACKAGE__;
	}

	return $c->__connect($c->build_connect_args(@_));
}

sub table_exists {
	my $c = &SQL::Exec::check_options;
	$c->check_conn() or return;
	my ($base, $table) = @_;

	$base = $c->__replace($base);
	if (not defined $table) {
		if ($base =~ m/^(.*)\.([^.]*)$/) {
			$base = $1;
			$table = $2;
		} else {
			$c->error('You must supply a base and a table name');
		}
	} else {
		$table = $c->__replace($table);
	}

	return $c->__count_lines("select * from DBC.Tables where DatabaseName = '$base' and TableName = '$table'") == 1;
}

=for comments

sub get_table_from_base {
	my $req = send_request( "SELECT TableName FROM DBC.TablesX WHERE DatabaseName = '$_[0]' AND TableKind = 'T'");
	my @tables = map {${$_}[0]} @{$req->fetchall_arrayref([0])};
	map {s/ *$//} @tables;
	return @tables;
}

=cut

1;


=encoding utf-8

=head1 NAME

SQL::Exec::ODBC::Teradata - Specific support for the Teradata ODBC driver in SQL::Exec

=head1 SYNOPSIS

  use SQL::Exec::ODBC::Teradata;
  
  SQL::Exec::ODBC:Teradata::connect($server, $user, $password);

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-puresql@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-PureSQL>.

=head1 SEE ALSO

L<SQL::Exec> and L<SQL::Exec::ODBC>

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

