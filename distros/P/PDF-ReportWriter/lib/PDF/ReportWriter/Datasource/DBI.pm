# vim: ts=8 sw=8 tw=0 ai nu noet
#
# PDF::ReportWriter::Datasource::DBI
#
# See COPYRIGHT file for full license
# See 'perldoc PDF::ReportWriter::Datasource' for documentation
#
# $Id: DBI.pm 14 2006-03-27 16:48:43Z cosimo $

package PDF::ReportWriter::Datasource::DBI;
$VERSION = '1.0';
use strict;
use Carp;
use base q(PDF::ReportWriter::Datasource);
# ? Impose a reasonably new version of DBI? (1.3x?)
use DBI;

sub connect
{
	my $self   = $_[0];
	my $ds_def = $self->definition;
	my $dsn    = $ds_def->{dsn};
	my $user   = $ds_def->{user} || undef;
	my $pass   = $ds_def->{pass} || undef;
	my $attr   = $ds_def->{attr} || {PrintError=>1,RaiseError=>1};

	my $dbh    = DBI->connect($dsn, $user, $pass, $attr);
	
	if( ! $dbh )
	{
		croak 'PDF::ReportWriter::Datasource::DBI: could not connect to '.$dsn;
	}

	return($dbh);
}

sub get_data
{
	my $self = $_[0];
	my $input_values = $self->{input};

	my $ds_def = $self->definition;
	my $dsn    = $ds_def->{dsn};

	# Placeholders ($1, $2, ...) are considered input values
	# to be fed in the query when running the report
	my $sql = $ds_def->{sql};

	# Interpolate all `?' placeholders in SQL query
	# (NOTE: this is not necessary if placeholders are a
	#$self->replace_input_values(\$sql, $input_values);

	# Try to execute the SQL query as is
	my $dbh = $self->connect();
	my $ok  = 0;
	my $sth;
	my $data;

	if( $sth = $dbh->prepare($sql) )
	{
		# XXX `input_values' should be given according to 
		#     sql query placeholders, or this is going to fail...
		if( $ok = $sth->execute(@$input_values) )
		{
			$data = $sth->fetchall_arrayref();
		}
		$sth->finish();
	}

	# Check results
	if( ! $ok || $@ )
	{
		croak 'PDF::ReportWriter::Datasource::DBI: error ' . $dbh->err() . ' executing query (' . $dbh->errstr() . ')';
		return undef;
	}

	return $data;
}

1;


=head1 NAME

PDF::ReportWriter::Datasource::DBI

=head1 DESCRIPTION

Custom Datasource class that allows access to a generic DBI DSN.

=head1 USAGE

Example of code fragment to include in your xml report:

	<report>
	...
	   <data>
	   ...
	   	<datasource name="customer">
			<type>DBI</type>
			<dsn>DBI:Pg:dbname=accounting</dsn>
			<user>postgres</user>
			<pass>postgres</pass>
			<sql>SELECT * FROM customers WHERE id=?</sql>
			<attr>
				<ChopBlanks>1</ChopBlanks>
				<PrintError>1</PrintError>
				<RaiseError>1</RaiseError>
			</attr>
		</datasource>
	   </data>
        ...
	</report>

=head1 ISSUES

Currently I don't know why with CSV driver this does not work.
Probably it's necessary to tweak the csv_tables or csv_csv structure?

=head1 AUTHORS

=over 4

=item Cosimo Streppone <cosimo@cpan.org>

=back

=cut

