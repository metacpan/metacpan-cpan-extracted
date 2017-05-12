package SQLite::VirtualTable;

our $VERSION = '0.09';

use strict;
use warnings;

use SQLite::VirtualTable::Util qw(unescape);

sub _CREATE_OR_CONNECT {
    # warn "_CONNECT";
    my $self = shift;
    my $method = shift;
    my $class = unescape splice @_, 3, 1;
    $class =~ /\w+(?:::\w+)*/
        or die "invalid package name";
    # warn "loading $class\n";
    eval "require $class";
    $@ and die "Can't load package $class: $@";
    $class->$method(@_);
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $class = ref $self || $self;
    my $args = join(', ', @_);
    $@ = "method $AUTOLOAD is not implemented (call: $class->$AUTOLOAD($args))\n";
    warn $@;
    die;
}

sub _do_nothing {}

*BEGIN_TRANSACTION = \&_do_nothing;
*SYNC_TRANSACTION = \&_do_nothing;
*COMMIT_TRANSACTION = \&_do_nothing;
*ROLLBACK_TRANSACTION = \&_do_nothing;

sub RENAME { 1 }

1;
__END__

=head1 NAME

SQLite::VirtualTable - Create SQLite Virtual Table extensions in Perl.

=head1 SYNOPSIS

on Perl:

  package MyVirtualTable;
  use base 'SQLite::VirtualTable';

  sub CREATE {
    ...

and then from your preferred SQLite application or language, as for
instance, the C<sqlite3> shell:

  $ sqlite3
  sqlite> .load perlvtab.so
  sqlite> CREATE VIRTUAL TABLE foo USING perl ("MyVirtualTable", foo, bar, ...);
  sqlite> SELECT * FROM foo WHERE col1 AND col1 > 34;
  ...


=head1 DESCRIPTION

L<Virtual tables|http://www.sqlite.org/cvstrac/wiki?p=VirtualTables>
are a new feature in SQLite (currently still only available from the
development version on CVS) that allows you to create tables using
custom backends to access (read and change) their contents instead of
being stored in the database file.

The C<SQLite::VirtualTable> module allows you to create these backends
in Perl embbeding a perl interpreter as a SQLite extension.

Note that extensions written using this module can be used from
any SQLite application and programming language (C, Java, PHP, Perl,
etc.).


=head1 API

In order to provide a new backend, a Perl module derived from
SQLite::VirtualTable has to be created and a set of methods defined.

These methods are just the Perl equivalents of the C callbacks defined
on the SQLite Virtual Table specification available from
L<http://www.sqlite.org/cvstrac/wiki?p=VirtualTableMethods>.

To indicate failure they should C<die>.

=over 4

=item $class->CREATE($module, $dbname, $tablename, @args)

=item $class->CONNECT($module, $dbname, $tablename, @args)

These methods are called when the user enters the SQL C<CREATE VIRTUAL
TABLE> command or when the database containing the virtual table is
opened.

They have to return a new object representing the virtual table.

C<@args> contains the arguments included by the user on the SQL
statement after the module name. They can be quoted and you would
probably want to unquote them (see
L<SQLite::VirtualTable::Util/unquote>).

=item $vt->DECLARE_SQL()

This method is called just after the C<CREATE> or C<CONNECT> method
and has to return the SQL statement used to declare the columns and
types of the virtual table. For instance:

  sub DECLARE_SQL {
    my $self = shift;
    "CREATE TABLE $self->{name} (bar VARCHAR(10), doz INT)"
  }

The return value from this method is used when calling the C function
C<sqlite3_declare_vtab()> to register the virtual table.

=item $vt->DROP()

This method is called when the user runs the SQL C<DROP TABLE>
statement on the virtual table.

Note that the equivalent C callback is C<xDestroy> but C<DESTROY> was
already used in Perl for other purposes.

=item $vt->DISCONNECT()

This method is called when the database is closed.

=item $vt->BEST_INDEX($constraints, $orderbys)

The documentation for the C equivalent of this callback is available
from
L<http://www.sqlite.org/cvstrac/wiki?p=VirtualTableBestIndexMethod>.

The Perl method is called with two arguments representing the input
part of the C<sqlite3_index_info> C structure:

=over 4

=item $constraints

is an array of hashes describing the possible constraints on the WHERE clause.

Every hash contains the entries C<column>, C<operator> and C<usable>.

C<operator> entries can take the values C<eq>, C<gt>, C<ge>, C<lt>,
C<le> and C<match>.

This data structure is also used for output. The entries C<arg_index>
(note that it is not C<argv_index>) and C<omit> can be used to set the
corresponding slots on the C<sqlite3_index_info> C structure.

C<arg_index> indexes start at 0 while on the C version of the callback
they start at 1. An C<undef> value or just not creating the entry
indicates that the constraint is not going to be used on the filter.

=item $ordersby

is an array of hashes describing the possible C<ORDER BY> clauses on
the SQL statement.

On every hash the entries C<column> and C<direction> are defined.

C<direction> entries take the values 1 or -1 for ascending or
descending order respectively.

=back

This method has to return the four values corresponging to C<idxNum>,
C<idxStr>, C<orderByConsumed> and C<estimatedCost> on the
C<sqlite3_index_info> C structure.


=item $vt->OPEN

This method has to return an object representing a new cursor over the
virtual table.

=item $vt->CLOSE($cursor)

This method is called to release a cursor.

=item $vt->FILTER($cursor, $idxnum, $idxstr, @args)

This method is called to begin a search of a virtual table.

It has to initialize the cursor previously created on a C<OPEN> call.

C<$idsnum> and C<$idxstr> are the values returned by any of the
C<BEST_NODE> method calls previously performed. C<@args> are the
arguments to the WHERE constraints.

=item $vt->NEXT($cursor)

This method is called to advance the cursor to the next row.

=item $vt->EOF($cursor)

This method has to return a true value when the rows from the cursor
have been exhausted.

=item $vt->UPDATE($delete_rowid, $new_rowid, @values)

This method is called when C<INSERT>, C<UPDATE> and C<DELETE> actions
are carried over the virtual table.

See the docs for the equivalent C callback for the details.

=item $vt->BEGIN_TRANSACTION()

=item $vt->SYNC_TRANSACTION()

=item $vt->COMMIT_TRANSACTION()

=item $vt->ROLLBACK_TRANSACTION()

These methods are called on transaction related events.

The default implementations from C<SQLite::VirtualTable> do nothing.

=item $vt->RENAME($name)

Notification that the table will be given a new name. If a false value
is returned, the rename operation will be cancled.

Has a default implementation that returns always true.

=back

=head1 INSTALLATION

Before compiling you will have to ensure that the development files
for sqlite3 and the perl library are installed. For instance, in
Debian (and derivates as Ubuntu), you will have to install
C<libsqlite3-dev> and C<libperl-dev>.

Compile the module as usual:

  $ perl Makefile.PL
  $ make
  $ make test

Then, (maybe as root) install the Perl package:

  $ make install

And finally to make the SQLite dynamic extension (C<perlvtab.so>,
though the name extension can be different depending on your OS)
available to any SQLite application, you may want to copy the library
file C<blib/arch/auto/SQLite/VirtualTable/perlvtab.so> to some place
where your OS could find it, for instance C</usr/local/lib>.

Alternatively, you could use C<LD_LIBRARY_PATH> to make your OS look
for it at a different place. Read the documentation for your OS
dynamic linker/loader for the details (L<ld.so(8)> under Linux).

If your Perl virtual table backend packages are not installed on the
common places where the perl interpreter searchs for modules by
default, you would also need to set the C<PERL5LIB> variable
conveniently (see L<perlrun>).


=head1 USAGE FROM SQLITE

Once, the dynamic extension has been installed, you can use it on your
SQLite C applications with the C<sqlite3_load_extension()> function.

Or from the C<sqlite3> shell as:

  sqlite3> .load perlvtab.so

Or from SQL as

  SELECT load_extension('perlvtab.so');

Note that for security reasons, loading of dynamic extension could be
disabled on your SQLite application. Read the documentation about
dynamic extension available from the SQLite wiki
L<http://www.sqlite.org/cvstrac/wiki?p=LoadableExtensions> for the
details.

The SQL syntax to create virtual tables is:

  CREATE VIRTUAL TABLE table_name USING perl ("Perl::Backend", arg0, arg1, ...);

Where C<Perl::Backend> is the name of the module implementing the
desired virtual table functionality.

After the table has been created, it can be used as any regular table
from SQL.

=head1 USAGE FROM DBD::SQLite

SQLite::VirtualTable can also be used within perl scripts using DBD::SQLite.
Using SQLite::VirtualTable with DBD::SQLite requires using the alternate entry
point function C<dbd_sqlite_init_vtab_extension()>. Here is the syntax:

  $dbh->sqlite_enable_load_extension(1);
  $dbh->sqlite_load_extension('perlvtab.so','dbd_sqlite_init_vtab_extension');

=head1 SEE ALSO

SQLite website L<http://www.sqlite.org/>, including docs
L<http://www.sqlite.org/docs.html> and wiki
L<http://www.sqlite.org/cvstrac/wiki>.

The virtual table specification is currently available from
L<http://www.sqlite.org/cvstrac/wiki?p=VirtualTables>. The
specification for loadable modules is available from
L<http://www.sqlite.org/cvstrac/wiki?p=LoadableExtensions>.

The manual page for the sqlite3 aplication L<sqlite3(1)>.

For a sample backend, see the L<SQLite::VirtualTable::CSV> module that
adds support for CSV files.

=head1 BUGS

Method xFindFunction is not supported.

This is alpha software based on an experimental feature of SQLite,
lots of bugs are likely to appear.

The API could change in the future (well, actually, it is expected to
change!!!).

Only tested on Linux.

Send bugs, comments or any feedback directly to me by mail or use the
bug tracking system at L<http://rt.perl.org>.


=head1 AUTHOR

Salvador FandiE<ntilde>o (sfandino@yahoo.com).


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2009 by Qindel Formacion y Servicios, S. L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
