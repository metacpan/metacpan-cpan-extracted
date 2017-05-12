package SQL::Exec::SQLite;
use strict;
use warnings;
use Exporter 'import';
use SQL::Exec '/.*/', '!connect', '!test_driver';

our @ISA = ('SQL::Exec');

our @EXPORT_OK = ('test_driver', @SQL::Exec::EXPORT_OK);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub test_driver {
	return SQL::Exec::test_driver('SQLite');
}

sub build_connect_args {
	my ($class, $file, @opt) = @_;

	return ("dbi:SQLite:dbname=$file", undef, undef, @opt);
}

sub get_default_connect_option {
	my $c = shift;
	return (
		$c->SUPER::get_default_connect_option(),
		sqlite_see_if_its_a_number => 1,
		sqlite_use_immediate_transaction => 1,
		Callbacks => { connected => sub { $_[0]->do("PRAGMA foreign_keys = ON"); return } },
	);
}

sub connect {
	my $c = &SQL::Exec::check_options;

	if (!test_driver()) {
		$c->error("You must install the DBD::SQLitee Perl module");
		return;
	}

	if (not $c->isa(__PACKAGE__)) {
		bless $c, __PACKAGE__;
	}

	return $c->__connect($c->build_connect_args(@_));
}

1;


=encoding utf-8

=head1 NAME

SQL::Exec::SQLite - Specific support for the DBD::SQLite DBI driver in SQL::Exec

=head1 SYNOPSIS

  use SQL::Exec::SQLite;
  
  SQL::Exec::SQLite::connect('/tmp/my.db');

=head1 DESCRIPTION

The C<SQL::Exec::SQLite> package is an extension of the L<C<SQL::Exec>|SQL::Exec>
package. This mean that in an OO context C<SQL::Exec::SQLite> is a sub-classe
of C<SQL::Exec> (so all methods of the later can be used in the former). Also, in
a functionnal context, all functions of C<SQL::Exec> can be accessed through
C<SQL::Exec::SQLite>.

=head1 CONSTRUCTOR

  my $c = SQL::Exec::SQLite->new(file);
  my $c = SQL::Exec::SQLite->new(file, opts);

The C<new> constructor of this package takes only a single argument which is the
name of the file to use as a database. The constructor can also takes an optionnal
argument wich contains option to apply to the created database handle, either as
a hash or as a reference to a hash.

The database file is created automatically if it does not already exist. Also
you may use the special file name C<':memory'> to use a in-memory database. In
that case, all your data will be destroyed when you close the database handle.

=head1 FUNCTIONS

The function described here are either functions specific to this database driver
or special version of a C<SQL::Exec> function adapted for the database driver.

However, all the function of C<SQL::Exec> are accessible in this package, either
with the object oriented interface or with the functionnal one. This package can
also exports all the function of the C<SQL::Exec> package and the C<:all> tag
contains all exportable functions from both C<SQL::Exec> and this package.

=head2 connect

  connect(file);
  $c->connect(file);

As the L<C<connect>|SQL::Exec/"connect"> function in C<SQL::Exec> this function
will either connect the default handle of the library or connect a specific
handle that is already created.

This function takes the same arguments as the C<new> constructor, except that
the optionnal options hash must be given as a hash reference and that it applies
only for the duration of the call (this is the same as the
L<C<connect>|SQL::Exec/"connect"> function in C<SQL::Exec>).

=head2 test_driver

  my $t = test_driver();

This function returns a boolean value indicating if the C<DBD::SQLite> database
driver is installed.

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-exec@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Exec>.

=head1 SEE ALSO

For the main documentation of this module ond for a list of all available functions,
please check the C<L<SQL::Exec>> module.

For details about the SQLite database driver, you should check the documentation for
C<L<DBD::SQLite>>

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


