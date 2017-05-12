package SQL::Exec::ODBC;
use strict;
use warnings;
use Exporter 'import';
use DBI;
use List::MoreUtils 'any';
use SQL::Exec '/.*/', '!connect', '!test_driver';

our @ISA = ('SQL::Exec');

our @EXPORT_OK = ('list_available_DB', 'test_driver', @SQL::Exec::EXPORT_OK);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub test_driver {
	return SQL::Exec::test_driver('ODBC');
}

# cette fonction est appelé par build_connect_args qui peut être appelé avec
# le nom de la classe au lieu d'un objet, donc ici on récupère le default_handle
# donc test_driver est résolu incorrectement si on ne fait pas attention.
sub list_available_DB {
	my $c = &SQL::Exec::check_options;
	if (!test_driver()) {
		$c->error("You must install the DBD::ODBC Perl module");
		return;
	}
	return map {m/dbi:ODBC:(.*)/; $1} DBI->data_sources('ODBC');
}

# dsn est le DSN au sens ODBC.
# par exemple 'DSN=dcn' (nom enregistré)
# sinon:  'DBCNAME=hostname' ou 'Host=1.2.3.4;Port=1000;'
sub build_connect_args {
	my $c = shift @_;
	
	my $driver = shift @_; # this is used as the DSN

	if (any { $_ eq $driver } $c->list_available_DB()) {
		my ($user, $pwd, @opt) = @_;
		return ("dbi:ODBC:DSN=$driver", $user, $pwd, @_);
	}
	
	my ($param, $user, $pwd, @opt) = @_;
	return ("dbi:ODBC:DRIVER=${driver};${param}", $user, $pwd, @opt);	

}

# Inutile, mais ça permet de ne pas l'oublier
sub get_default_connect_option {
	my $c = shift;
	return $c->SUPER::get_default_connect_option();
}

sub connect {
	my $c = &check_options;

	if (not $c->isa(__PACKAGE__)) {
		bless $c, __PACKAGE__;
	}

	return $c->__connect($c->build_connect_args(@_));
}


1;

=encoding utf-8

=head1 NAME

SQL::Exec::ODBC - Specific support for the DBD::ODBC DBI driver in SQL::Exec

=head1 SYNOPSIS

  use SQL::Exec::ODBC;
  
  SQL::Exec::ODBC::connect($dsn, $user, $password);
  SQL::Exec::ODBC::connect($driver, $param, $user, $password);

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-puresql@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-PureSQL>.

=head1 SEE ALSO

L<SQL::Exec>, L<DBD::ODBC> and L<DBD::ODBC::FAQ>

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


