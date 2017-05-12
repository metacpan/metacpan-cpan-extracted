package Pye::SQL;

# ABSTRACT: Log with Pye into MySQL, PostgreSQL or SQLite

use warnings;
use strict;

use Carp;
use DBI;
use JSON::MaybeXS qw/JSON/;
use Role::Tiny::With;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

with 'Pye';

our %NOW = (
	mysql		=> 'NOW(6)',
	pgsql		=> 'NOW()',
	sqlite	=> 'strftime("%Y-%m-%d %H:%M:%f")'
);

=head1 NAME

Pye::SQL - Log with Pye into MySQL, PostgreSQL or SQLite

=head1 SYNOPSIS

	use Pye::SQL;

	my $pye = Pye::SQL->new(
		db_type => 'mysql', # or 'pgsql' or 'sqlite'
		database => 'my_log_database',
		table => 'myapp_logs'
	);

	# now start logging
	$pye->log($session_id, "Some log message", { data => 'example data' });

	# inspect the logs from the command line
	pye -b SQL -t mysql -d my_log_database -T myapp_logs

=head1 DESCRIPTION

This package provides a relational SQL backend for the L<Pye> logging system.
It currently supports MySQL, PostgreSQL and SQLite.

All of these database systems will require prior creation of the target database
and table. Read on for notes and suggestions for each supported database system.

=head2 USING THE pye COMMAND LINE UTILITY

The L<pye> command line utility used to inspect logs supports basic options that
are consistent across all backends. Anything else you provide is passed to the
L<new( %options )> constructor, 

=head2 MySQL

When creating a table for logs, use something like this:

	CREATE TABLE logs (
		session_id VARCHAR(60) NOT NULL,
		date DATETIME(6) NOT NULL,
		text TEXT NOT NULL,
		data TEXT
	);

	CREATE INDEX logs_per_session ON logs (session_id);

For the C<session_id> and C<text> columns, note that the data type definition is
purely a suggestion. Use your own judgment as to which data types to use, and
what lengths, according to your application.

=head2 PostgreSQL

It is recommended to use PostgreSQL version 9.3 and up, supporting JSON or JSONB
columns. When creating a table for logs, use something like this:

	CREATE TABLE logs (
		session_id VARCHAR(60) NOT NULL,
		date TIMESTAMP WITH TIME ZONE NOT NULL,
		text TEXT NOT NULL,
		data JSON
	);

	CREATE INDEX ON logs (session_id);

If using v9.4 or up, C<data> might better be a C<JSONB> column. As with MySQL,
use your own judgment for the data type and length of C<session_id> and C<text>,
according to your application.

If you're planning on running your own queries on the C<data> column, you will need to
create an index on it. Read PostgreSQL's online documentation on JSON data types for
more information.

=head2 SQLite

When using SQLite as a backend, create the following table structure:

	CREATE TABLE logs (
		session_id TEXT NOT NULL,
		date TEXT NOT NULL,
		text TEXT NOT NULL,
		data TEXT
	);

	CREATE INDEX logs_per_session ON logs (session_id);

Note that, as opposed to other database systems, SQLite will take the path to the
database file as the C<database> parameter, instead of a database name. You can also
provide C<:memory:> for an in-memory database.

=head1 CONSTRUCTOR

=head2 new( %options )

Create a new instance of this class. The following options are supported:

=over

=item * db_type - the type of database (C<mysql>, C<pgsql> or C<sqlite>), required

=item * database - the name of the database to connect to, defaults to "logs" (if using SQLite,
this will be the path to the database file)

=item * table - the name of the table to log into, defaults to "logs"

=back

The following options are supported by MySQL and PostgreSQL:

=over

=item * host - the host of the database server, defaults to C<127.0.0.1>

=item * port - the port of the database server, defaults to C<3306> for MySQL, C<5432> for PostgreSQL

=back

=cut

sub new {
	my ($class, %opts) = @_;

	croak "You must provide the database type (db_type), one of 'mysql' or 'pgsql'"
		unless $opts{db_type} &&
			_in($opts{db_type}, qw/mysql pgsql sqlite/);

	$opts{db_type} = lc($opts{db_type});

	return bless {
		dbh => DBI->connect(
			_build_dsn(\%opts),
			$opts{username},
			$opts{password},
			{
				AutoCommit => 1,
				RaiseError => 1
			}
		),
		json => JSON->new->allow_blessed->convert_blessed,
		db_type => $opts{db_type},
		table => $opts{table} || 'logs'
	}, $class;
}

=head1 OBJECT METHODS

The following methods implement the L<Pye> role, so you should refer to C<Pye>
for their documentation. Some methods, however, have some backend-specific notes,
so keep reading.

=head2 log( $session_id, $text, [ \%data ] )

If C<\%data> is provided, it will be encoded to JSON before storing in the database.

=cut

sub log {
	my ($self, $sid, $text, $data) = @_;

	$self->{dbh}->do(
		"INSERT INTO $self->{table} VALUES (?, ".$NOW{$self->{db_type}}.', ?, ?)',
		undef, "$sid", $text, $data ? $self->{json}->encode($data) : undef
	);
}

=head2 session_log( $session_id )

=cut

sub session_log {
	my ($self, $session_id) = @_;

	my $sth = $self->{dbh}->prepare("SELECT date, text, data FROM $self->{table} WHERE session_id = ? ORDER BY date ASC");
	$sth->execute("$session_id");

	my @msgs;
	while (my $row = $sth->fetchrow_hashref) {
		my ($d, $t) = $self->_format_datetime($row->{date});
		$row->{date} = $d;
		$row->{time} = $t;
		$row->{data} = $self->{json}->decode($row->{data})
			if $row->{data};
		push(@msgs, $row);
	}

	$sth->finish;

	return @msgs;
}

=head2 list_sessions( [ \%opts ] )

Takes all options defined by L<Pye>. The C<sort> option, however, takes a standard
C<ORDER BY> clause definition, e.g. C<id ASC>. This will default to C<date DESC>.

=cut

sub list_sessions {
	my ($self, $opts) = @_;

	$opts			||= {};
	$opts->{skip}	||= 0;
	$opts->{limit}	||= 10;
	$opts->{sort}	||= 'date DESC';

	my $sth = $self->{dbh}->prepare("SELECT session_id AS id, MIN(date) AS date FROM $self->{table} GROUP BY id ORDER BY $opts->{sort} LIMIT $opts->{limit} OFFSET $opts->{skip}");
	$sth->execute;

	my @sessions;
	while (my $row = $sth->fetchrow_hashref) {
		my ($d, $t) = $self->_format_datetime($row->{date});
		$row->{date} = $d;
		$row->{time} = $t;
		push(@sessions, $row);
	}

	$sth->finish;

	return @sessions;
}

sub _format_datetime {
	my ($self, $date) = @_;

	my ($d, $t) = split(/T|\s/, $date);
	$t = substr($t, 0, 12);

	return ($d, $t);
}

sub _remove_session_logs {
	my ($self, $session_id) = @_;

	$self->{dbh}->do("DELETE FROM $self->{table} WHERE session_id = ?", undef, "$session_id");
}

sub _build_dsn {
	my $opts = shift;

	if ($opts->{db_type} eq 'mysql') {
		'DBI:mysql:database='.
			($opts->{database} || 'logs').
				';host='.($opts->{host} || '127.0.0.1').
					';port='.($opts->{port} || 3306).
						';mysql_enable_utf8=1';
	} elsif ($opts->{db_type} eq 'pgsql') {
		'dbi:Pg:dbname='.
			($opts->{database} || 'logs').
				';host='.($opts->{host} || '127.0.0.1').
					';port='.($opts->{port} || 5432);
	} else {
		# sqlite
		'dbi:SQLite:dbname='.($opts->{database} || 'logs.db');
	}
}

sub _in {
	my $val = shift;

	foreach (@_) {
		return 1 if $val eq $_;
	}

	return;
}

=head1 CONFIGURATION AND ENVIRONMENT
  
C<Pye> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Pye> depends on the following CPAN modules:

=over

=item * L<Carp>

=item * L<DBI>

=item * L<JSON::MaybeXS>

=item * L<Role::Tiny>

=back

You will also need the appropriate driver for your database:

=over

=item * L<DBD::mysql> for MySQL

=item * L<DBD::Pg> for PostgreSQL

=item * L<DBD::SQLite> for SQLite

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Pye-SQL@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pye-SQL>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Pye::SQL

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pye-SQL>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Pye-SQL>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Pye-SQL>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Pye-SQL/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2015, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.
 
The full text of the license can be found in the
LICENSE file included with this module.
 
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
