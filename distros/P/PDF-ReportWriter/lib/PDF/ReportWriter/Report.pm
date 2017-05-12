# vim: ts=8 sw=8 tw=0 ai nu noet
#
# PDF::ReportWriter::Report
#
# (C) Daniel Kasak: dan@entropy.homelinux.org ...
#  ... with contributions from Bill Hess and Cosimo Streppone
#      ( see the changelog for details )
#
# See COPYRIGHT file for full license
#
# See 'perldoc PDF::ReportWriter::Report',
#     'perldoc PDF::ReportWriter' for full documentation
#

package PDF::ReportWriter::Report;
use strict;
use XML::Simple;
use PDF::ReportWriter::Datasource;

BEGIN {
        $PDF::ReportWriter::Report::VERSION = '1.0';
}

sub new {
        
        my ( $class, $opt ) = @_;
        $class = ref($class) || $class;
        
        # Make $opt a hashref if it isn't already
        # Passing a string with report filename should work.
        if( ! ref $opt ) {
                if( ( defined $opt ) && ( $opt ne '' ) ) {
                        $opt = { report => $opt };
                } else {
                        $opt = {};
                }
        }
        
        my $self = { %$opt };
        my $file;
        
        if( exists $self->{report} ) {
                $file = $self->{report};
        }
        
        if( defined $file && ! -e $file )
        {
                return(undef);
        }
        
        bless $self, $class;
        
}

#
# Returns current filename of xml report
#
sub file {
        my $self = $_[0];
        return $self->{report};
}

#
# Loads xml report definition
#
sub load {
        my $self = shift;
        my $file = shift || $self->file();
        my $cfg  = $self->config();
        
        # Return already loaded configuration instead of
        # reloading from scratch
        return $cfg if $cfg;
        
        my $xml = XML::Simple->new(
                
                # Don't create group name keys
                #
                # FIXME Is there a way to avoid `name' hash keys creation,
                #       without issuing warnings about nonexistent `_' key?
                
                KeyAttr => {
                        group => '_',
                        field => '_',
                },
                
                GroupTags => {
                        header => 'cell',
                        footer => 'cell',
                        groups => 'group',
                        fields => 'field',
                },
                
                Variables => $self->get_macros(),
                
        );
        
        $cfg = $xml->XMLin( $file );
        
        if( ! ref( $cfg ) )
        {
                warn qq(Can't read from xml file $file);
                return ( undef );
        }
        
        $self->_adjust_struct( $cfg );
        
        # Store configuration inside object
        $self->config( $cfg );
        
        return ( $cfg );
        
}

#
# Returns all available data sources found in xml file
# There should be one `detail' data source at least
#
sub data_sources
{
        my $self = $_[0];
        my $ds   = $self->config->{data}->{datasource};
        my %ds;
        
        if ( ref $ds eq 'HASH' ) {
                $ds = [ $ds ];
        }
        
        for( @$ds )
        {
                $ds{$_->{name}} = $_;
        }
        
        return(\%ds);
}

#
# Report's get_data() passes the work to PDF::ReportWriter::Datasource objects
#
{
        # Main cache for datasources actual data, to avoid
        # useless repeated calls to get_data()
        my %ds_cache;
        
        sub get_data
        {
                my $self   = $_[0];
                my $dsname = $_[1] || 'detail';
                
                # Check if cached data already exists
                # Here we assume that while report is generating, data does not change
                if( exists $ds_cache{$dsname} )
                {
                        return $ds_cache{$dsname};
                }
                
                # Get all available d.s.
                my $ds = $self->data_sources();
                
                # Datasource does not exists, return blank data
                if( ! exists $ds->{$dsname} )
                {
                        #warn 'Data source '.$dsname.' does not exist';
                        return ();
                }
                
                # Try to create a P::R::Datasource object
                my $ds_obj = PDF::ReportWriter::Datasource->new($ds->{$dsname});
                
                if( ! defined $ds_obj )
                {
                        warn 'Data source '.$dsname.' not available!';
                        return ();
                }
                
                # Ok, datasource object loaded, call get_data() on it
                return ( $ds_cache{$dsname} = $ds_obj->get_data($self) );
        }
        
}

#
# Default implementation for get_macros() returns nothing.
# Get variables should be used for search&replace in the XML file.
# before loading.
#
sub get_macros {
        return undef;
}

#
# Returns (or modifies) current report configuration (profile)
#
sub config {
        my $self = shift;
        
        # If passed a parameter, change config member to that
        if( @_ ) {
                $self->{_config} = $_[0];
        }
        
        return ( $self->{_config} );
}

#
# Sanity checks and adjustments on data structures
#
# TODO 1: here XML::Simple does magic but not enough to simply
# pass the data structure plainly as read.
#
# TODO 2: Should we avoid at all this thing?
#         Probably modifying PDF::ReportWriter to handle
#         all the different cases (HASH, ARRAY, ...)
#
sub _adjust_struct {
        
        my ( $self, $config ) = @_;
        my $data = $config->{data};
        local $_;
        
        # Force `fields' to be an array even with 1 element
        if( ref ( $data->{fields} ) eq 'HASH' ) {
                $data->{fields} = [ $data->{fields} ];
        }
        
        if( ref ( $data->{groups} ) eq 'HASH' ) {
                $data->{groups} = [ $data->{groups} ];
        }
        
        # Now for `groups' section
        for(@{ $data->{groups} }) {
                
                # Remove empty header/footer sections
                # Force header/footer to array even if they have 1 element
                if( ref ( $_->{header} ) eq 'HASH' ) {
                        if( keys %{$_->{header}} ) {
                                $_->{header} = [ $_->{header} ];
                        } else {
                                delete $_->{header};
                        }
                }
                
                if( ref ( $_->{footer} ) eq 'HASH' ) {
                        if( keys %{$_->{footer}} ) {
                                $_->{footer} = [ $_->{footer} ];
                        } else {
                                delete $_->{footer};
                        }
                }
        }
        
        # Same as above for `page' structure
        my $page = $data->{page};
        if( ref ( $page->{header} ) eq 'HASH' ) {
                $page->{header} = [ $page->{header} ];
        }
        if( ref ( $page->{footer} ) eq 'HASH' ) {
                $page->{footer} = [ $page->{footer} ];
        }
        
        # Same as above for font structure
        if( ! ref $config->{definition}->{font} )
        {
                $config->{definition}->{font} = [ $config->{definition}->{font} ];
        }
        
        return ( $config );
}

#
# ->save( \%config [, filename] )
#
# Saves the report back to XML format.
# This is mainly an experiment. Don't know if it works correctly,
# even if the test suite seems to say so.
#
# %config = (
#
#    definition => {
#        ...,
#        info => { ... },
#        ...,
#    },
#
#    page   => {
#        header => [ ],
#        footer => [ ],
#    },
#
#    data   => {
#        fields => ...,
#        groups => ...,
#        ...
#    },
# )
#
sub save
{
        
        my($self, $cfg, $file) = @_;
        
        # $cfg is a hash:
        # $cfg = {
        #               data            ... the 'data' part of the PDF::ReportWriter object
        #               definition      ... the top-level part of the PDF::ReportWriter object ( minus data )
        
        $file ||= $self->file();
        
        my $xml = XML::Simple->new(
                AttrIndent => 1,
                ForceArray => 1,
                KeepRoot   => 1,
                NoAttr     => 1,
                NoSort     => 1,
                RootName   => 'report',
                XMLDecl    => 1,
        );
        
        my $xml_stream = $xml->XMLout($cfg);
        my $ok = 0;
        
        #warn 'opening file '.$file;
        
        if( open(XML_REPORT, '>' . $file) )
        {
                #warn 'opened file';
                $ok = print XML_REPORT $xml_stream;
                #warn 'printed '.$ok.' on it';
                $ok &&= close(XML_REPORT);
                #warn 'closed '.$ok;
        }
        
        # Report saved?
        return($ok);
        
}


1;

=head1 NAME

PDF::ReportWriter::Report

=head1 DESCRIPTION

PDF::ReportWriter::Report is a PDF::ReportWriter class that represents a single report.
It handles the conversions from/to XML to PDF::ReportWriter correct data structures,
and can provide the data to be used in the report.
XML::Simple module is used for data structures serialization to XML and restore.

This class is designed in a way that should be simple to be overloaded,
and thus provide alternative classes that load reports in a totally different way,
or supply data connecting automatically to a DBI DSN, or who knows...

=head1 USAGE

The most useful usage for this class is through the C<PDF::ReportWriter::render_report()>
call. If you really want an example of usage of standalone Report object, here it is:

        # Create a blank report object
        my $report = PDF::ReportWriter::Report->new();
        my $config;

        # Load XML report definition
        eval { $config = $report->load('/home/cosimo/myreport.xml') };
        if( $@ ) {
            # Incorrect xml file!
            print 'Error in XML report:', $@, "\n";
        }

        # Now save the report object to xml file
        my $ok = $report->save($config);
        my $ok = $report->save($config, 'Copy of report.xml');

=head1 METHODS

=head2 new( options )

Creates a new C<PDF::ReportWriter::Report> object. C<options> is a hash reference.
Its only required key is C<report>, which is the xml filename of the report definition.
It is stored inside the object, allowing to later B<save> your report in that filename.

=head2 get_data( ds_name )

The only parameter required is the datasource name C<ds_name>.
If no data is supplied to the C<PDF::ReportWriter::render_report()> call,
this method checks for all available data sources defined in your xml
report. They must be included in the C<data> section.
Check out the examples.

The main data source that provides the data for report main table must
be called C<detail>, or you get an empty report.
Additional data sources can be defined, as in the following (fake) example:

    <report>
        ...
        <data>
            ...
            <datasource name="ldapdirectory">
                    <hostname>192.168.0.1</hostname>
                <port>389</port>
                <rootdn>o=Users,dc=domain,dc=com</rootdn>
                <binddn>cn=DirectoryManager,dc=domain,dc=com</binddn>
                <password>secret</password>
            </datasource>
            ...
        </data>
        ...
    </report>

=head2 get_macros()

Should be used to return all text macros that must be searched and replaced inside
the XML content before converting it into the C<PDF::ReportWriter> profile.
Example:

    ...
    <!-- Xml report -->
    <report>
        <definition>
            <name>My Report</name>
            <info>
                <Author>${AUTHOR}</Author>
                ...

A corresponding C<get_macros> method should return:

    sub get_macros {
        return { 'AUTHOR' => 'Isaac Asimov' };
    }

The default implementation returns no macro.

=head2 load( [xml_file] )

Loads the report definition from C<xml_file>. No, don't be afraid! This is a friendly
and nice xml file, not those ugly monsters that populate JavaLand. :-)
Return value is an hashref with complete report profile.

        my $report  = PDF::ReportWriter::Report->new();
        my $profile = $report->load('myreport.xml');
        if( ! $profile ) {
                print "Something wrong in the XML?";
        }

=head2 save( config [, xml_file ] )

Saves the report profile passed in C<config> parameter (as a hashref)
to the file defined in C<new()> or to C<xml_file> if supplied.

The result won't be exactly equal to the source xml file, but should
be equivalent when loading the data structures to build your final report.

=head1 CUSTOM REPORT CLASSES

The design of C<PDF::ReportWriter::Report> allows one to build a custom class
that provides alternative behavior for C<load()> and C<get_data()> methods.

C<load()> method can do anything, but it must return a complete report
data structure to be fed into C<PDF::ReportWriter> object. That consists
into several hashrefs:

=over *

=item definition

All high-level report properties, such as C<paper>,
C<destination>, ...

=item page

Page header and footer list of cells. See xml report samples in
the C<examples> folder.

=item data

The main section which defines C<fields> and C<groups>.
Check out the examples and use Data::Dumper on results
of C<load()> method. Sorry. :-)

=back

=head1 TODO

=over *

=item Complete documentation?

=back

=head1 AUTHORS

=over 4

=item Dan <dan@entropy.homelinux.org>

=item Cosimo Streppone <cosimo@cpan.org>

=back

=head1 Other cool things you should know about:

=over 4

This module is part of an umbrella project, 'Axis Not Evil', which aims to make
Rapid Application Development of database apps using open-source tools a reality.
The project includes:

Gtk2::Ex::DBI                 - forms

Gtk2::Ex::Datasheet::DBI      - datasheets

PDF::ReportWriter             - reports

All the above modules are available via cpan, or for more information, screenshots, etc, see:
http://entropy.homelinux.org/axis_not_evil

=back

=cut
