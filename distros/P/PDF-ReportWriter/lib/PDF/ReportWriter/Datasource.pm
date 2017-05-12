# vim: ts=8 sw=8 tw=0 ai nu noet
#
# PDF::ReportWriter::Datasource
#
# See COPYRIGHT file for full license
# See 'perldoc PDF::ReportWriter::Datasource' for documentation
#
# $Id: Datasource.pm 13 2006-03-27 16:48:02Z cosimo $

package PDF::ReportWriter::Datasource;
$VERSION = '1.00';
use strict;

sub new
{
	my $class = $_[0];
	my $opt   = $_[1];
	my $self   = {};
	$class = ref($class) || $class;

	return undef unless ref ( $opt ) eq 'HASH';

	# Datasource can be specified in various ways. Mandatory keys are `type',
	# and then some depending on `type'.
	my $type = $opt->{type};

	# If package doesn't contain `::', we assume it is in the
	# PDF::ReportWriter::Datasource namespace. If it has one or more `::'
	# we take the `type' as the full package name, to allow maximum
	# flexibility and power (!)
	my $pkg  = index($type, '::') > 0 ? $type : $class . '::' . $type;

	$self->{_type} = $type;
	$self->{_def}  = $opt;

	if( eval "require $pkg" )
	{
	    # Ok, requested type is present. Create an object.
	    bless $self, $pkg;
	}
	else
	{
	    warn '***ERROR*** loading report ' . $type . ' datasource (package='.$pkg.')';
	    warn $@;
	}

	return($self);
}

sub definition
{
	my $self = $_[0];
	return $self->{_def};
}

#
# Default implementation searches for `?' placeholders
#
sub replace_input_values
{
	my ( $self, $r_sql, $input_values ) = @_;

	return unless ref $input_values eq 'ARRAY';

	# Make a copy of input values array
	my $val = [ @$input_values ];

	# Replace all `?' placeholders with elements of input_values array
	1 while( @$val && $r_sql =~ s/\?/shift @$val/e );

	return($r_sql);
}

sub type
{
	my $self = $_[0];
	return $self->{_type};
}

#
# Default implementation returns no data
#
sub get_data 
{
	#warn 'get_data() should be overridden for PDF::ReportWriter::Datasource to work properly.';
	return ();
}

# Default implementation does not declare input fields
sub input_fields
{
	#warn 'input_fields() should be overridden for PDF::ReportWriter::Datasource to work properly.';
	return ();
}

# Default implementation does nothing
sub process_data
{
	return ();
}

1;

=head1 NAME

PDF::ReportWriter::Datasource

=head1 DESCRIPTION

PDF::ReportWriter::Datasource is a PDF::ReportWriter class that represents a (mmh) data source.
Every Datasource class provides all needed information to extract data to be used in the report.
The interface it exposes, that obviously can be overloaded with subclasses, is composed of several
methods. The most important is the C<get_data()> method.

This class is designed in a way that should be simple to be overloaded,
and thus provide alternative classes that provide data for the report in a totally
different way.

An example of this concept is given in the C<PDF::Report::Datasource::DBI> class.

=head1 USAGE

There is really no usage for this class, because it is autoloaded and invoked
automatically by C<PDF::ReportWriter::Report> object when needed. If you really
want an example of usage, here it is:

	# Create a datasource object
	my $my_ds = PDF::ReportWriter::Datasource->new({
		type => 'DBI',
		dsn  => 'DBI:Pg:dbname=pdfrwtest',
		user => 'postgres',
		pass => 'postgres',
	});

	$my_ds->get_data();

=head1 METHODS

=head2 new( options )

Creates a new C<PDF::ReportWriter::Datasource> object. C<options> is a hash reference.
Its only required key is C<type>, which identifies the correct subclass name (for 
example, C<DBI>). Every subclass can have its own options that you need to pass
in order to make everything work as expected.
Typical usage of Datasource class is not through C<new()> constructor, but through
xml report definition. Including the following fragment of code in your xml report
in the C<data> section, automatically creates needed objects and uses them:

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

=head2 get_data()

Should be used to provide all actual data records to the report.
You can do anything you want with this. A typical use is to connect to a
B<DBI> data source and return the result of C<selectall_arrayref()>.
Check C<PDF::ReportWriter::Datasource::DBI> for actual code that does this.

The default implementation returns no record. If no datasource is defined
in your report, you can directly supply the optional C<data_records> parameter
to C<render_report()> method. See C<PDF::ReportWriter::render_report()>.

=head2 process_data()

It is called automatically just after C<get_data()>, to make additional
processing over raw data returned by Datasource. It is meant to allow
easy overloading of classes without rewriting of C<get_data()> method.
Example: converting all dates to a custom format not supported by
underlying database.

Default implementation does nothing.

=head2 replace_input_values()

Allows to replace placeholders. Check C<PDF::ReportWriter::Datasource::DBI>.

=head1 CUSTOM DATASOURCE CLASSES

The design of C<PDF::ReportWriter::Datasource> allows one to build a custom class
that provides alternative behavior for C<get_data()> method.

=head1 TODO

=over *

=item Document the C<replace_input_values()> mechanism.

=back

=head1 AUTHORS

=over 4

=item Cosimo Streppone <cosimo@cpan.org>

=back

=cut

