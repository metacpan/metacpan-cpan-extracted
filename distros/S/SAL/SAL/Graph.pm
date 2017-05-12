package SAL::Graph;

# This module is licensed under the FDL (Free Document License)
# The complete license text can be found at http://www.gnu.org/copyleft/fdl.html
# Contains excerpts from various man pages, tutorials and books on perl
# GRAPHING MODULE

use strict;
use DBI;
use Carp;
use Data::Dumper;
use GD;
use GD::Graph::lines;
use GD::Graph::bars;
use GD::Graph::linespoints;
use GD::Graph::lines3d;
use GD::Graph::bars3d;
use GD::Graph::Data;
use GD::Graph::colour qw(:colours :lists :files :convert);


BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = '3.03';
	@ISA = qw(Exporter);
	@EXPORT = qw();
	%EXPORT_TAGS = ();
	@EXPORT_OK = qw();
}
our @EXPORT_OK;

END { }

=pod

=head1 Name

SAL::Graph - Graphing abstraction for SAL::DBI database objects

=head1 Synopsis

 # Derived from salgraph.cgi in the samples directory
 use CGI;
 use SAL::DBI;
 use SAL::Graph;

 my $send_mime_headers = 1;

 my $q = new CGI;
 my $self_url = $q->script_name();

 my $graph_obj = new SAL::Graph;
 my $dbo_factory = new SAL::DBI;
 my $dbo_data = $dbo_factory->spawn_sqlite(':memory:');

 # Build a sample database...
 my $report_query = qq[create table ReportData (dfm varchar(255), name varchar(255), purchases int(11), sort int(11))];
 $dbo_data->do($report_query);

 # Obviously not optimized...
 $report_query = qq[insert into ReportData values('Data Formatting Markup Tags','Customer','Purchases','0')];
 $dbo_data->do($report_query);
 $report_query = qq[insert into ReportData values(' ','Morris','30','1')];
 $dbo_data->do($report_query);
 $report_query = qq[insert into ReportData values(' ','Albert','22','1')];
 $dbo_data->do($report_query);

 my $graph_query = 'SELECT name, purchases FROM ReportData WHERE (sort > 0) and (sort < 998) ORDER BY sort, name';
 my ($w, $h) = $dbo_data->execute($graph_query);

 my @legend = qw(a b);
 $graph_obj->set_legend(@legend);
 $graph_obj->{image}{width} = '400';
 $graph_obj->{image}{height} = '300';
 $graph_obj->{formatting}{title} = "Customer Purchases";
 $graph_obj->{formatting}{'y_max_value'} = 50;
 $graph_obj->{formatting}{'y_min_value'} = 0;
 $graph_obj->{formatting}{'x_label'} = 'Customer';
 $graph_obj->{formatting}{'y_label'} = 'Purchases';
 $graph_obj->{formatting}{'y_tick_number'} = 10;
 $graph_obj->{formatting}{'boxclr'} = '#EEEEFF';
 $graph_obj->{formatting}{'long_ticks'} = '1';
 $graph_obj->{formatting}{'line_types'} = [(1,3,4)];
 $graph_obj->{formatting}{'line_width'} = '2';
 $graph_obj->{formatting}{'markers'} = [(7,5,1,8,2,6)];
 $graph_obj->{type}='bars3d';

 my $graph = $graph_obj->build_graph($send_mime_headers, $dbo_data, $graph_query);
 print $graph;

=head1 Eponymous Hash

This section describes some useful items in the SAL::_ eponymous hash.  Arrow syntax is used here for readability, 
but is not strictly required.

Note: Replace $SAL::Graph with the name of your database object... eg. $graph->{datasource} = $dbo_data

=over 1

=item Datasource

 $SAL::Graph->{datasource} should be a SAL::DBI object (currently unused.  see build_graph() method.)

=item Image Attributes

 $SAL::Graph->{image}{width} should be set to the desired output width. Default: 400px
 $SAL::Graph->{image}{height} should be set to the desired output height.  Default: 400px

=item Legend and Formatting

 $SAL::Graph->{type} should be set to the GD::Graph or GD::Graph3d graph-type.  (eg. linespoints, bar3d, etc)
 $SAL::Graph->{legend} should be set to a list containing entries to show in the graph's legend.
 $SAL::Graph->{formatting} should be a hash containing GD::Graph and/or GD::Graph3d formatting options.

=back

=cut

our %Graph = (
######################################
 'datasource'	=> '',
######################################
 'type'		=> '',
######################################
 'legend'	=> [],
######################################
 'image'	=> {},
######################################
 'formatting'	=> {},
######################################
 'out'		=> '',
######################################
 'dump'		=> '',
######################################
);

# Setup accessors via closure (from perltooc manpage)
sub _classobj {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	no strict "refs";
	return \%$class;
}

for my $datum (keys %{ _classobj() }) {
	no strict "refs";
	*$datum = sub {
		my $self = shift->_classobj();
		$self->{$datum} = shift if @_;
		return $self->{$datum};
	}
}

##########################################################################################################################
# Constructors (Public)

=pod

=head1 Constructors

=head2 new()

Prepares a new Graph object.

=cut

sub new {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	my $self = {};

	bless($self, $class);

	$self->{'type'} = 'lines';
	$self->{'out'} = 'png';

	$self->{legend}->[0] = 'Legend not defined.';
	$self->{legend}->[1] = 'Legend not defined.';

	$self->{'image'}{'width'}			= 400;
	$self->{'image'}{'height'}			= 400;
	$self->{'formatting'}{'x_label'}		= 'X Label';
	$self->{'formatting'}{'x_label_skip'}		= 1;
	$self->{'formatting'}{'x_labels_vertical'}	= 1;
	$self->{'formatting'}{'y_label'}		= 'Y Label';
	$self->{'formatting'}{'title'}			= 'Graph Title';
	$self->{'formatting'}{'box_axis'}		= 1;
	$self->{'formatting'}{'long_ticks'}		= 0;
	$self->{'formatting'}{'show_values'}		= 0;
	$self->{'formatting'}{'values_vertical'}	= 0;
	$self->{'formatting'}{'text_space'}		= 8;
	$self->{'formatting'}{'axis_space'}		= 10;
	$self->{'formatting'}{'fgclr'}			= '#AAAAAA';
	$self->{'formatting'}{'boxclr'}			= '#FFFFFF';
	$self->{'formatting'}{'labelclr'}		= 'black';
	$self->{'formatting'}{'axislabelclr'}		= 'black';
	$self->{'formatting'}{'textclr'}		= 'black';
	$self->{'formatting'}{'valuesclr'}		= 'black';
	$self->{'formatting'}{'shadowclr'}		= 'dgray';
	$self->{'formatting'}{'shadow_depth'}		= '4';
	$self->{'formatting'}{'transparent'}		= 1;

	my @plot_colors = ('#598F94','#980D36','#4848FF','#DDDD00');
	$self->{formatting}{'dclrs'} = \@plot_colors;

	return $self;
}

##########################################################################################################################
# Destructor (Public)
sub destruct {
	my $self = shift;

}

##########################################################################################################################
# Public Methods

=pod

=head1 Methods

=head2 $graph = build_graph($send_mime_headers, $datasource, $query, @params)

Generate a graph by running the sql $query (and @params if provided) against $datasource (a SAL::DBI object).

If you're generating a graph on the fly to be displayed on the web, set $send_mime_headers to a non-zero value.

=cut

sub build_graph {
	my ($self, $send_mime, $datasource, $query, @params) = @_;

	GD::Graph::colour::add_colour('#AAAAAA');
	GD::Graph::colour::add_colour('#1F9DC2');

	my $data = new GD::Graph::Data;

	if ($datasource) {
		# do dbi
		my ($w, $h) = $datasource->execute($query, @params);

		$datasource->clean_times(0);
		$datasource->short_dates(0);

		for (my $record = 0; $record < $h; $record++) {
			my @row = $datasource->get_row($record);
			$data->add_point(@row);
		}
	} else {
		croak("No datasource set\n");
	}

	my $graph;
	my $gtype = $self->{'type'};
	my $gpkg = "GD::Graph::$gtype"; 

	$graph = $gpkg->new($self->{image}{width}, $self->{image}{height});

	my @colour_names = GD::Graph::colour::colour_list(8);

	$graph->set( %{$self->{formatting}} )        or die $graph->error;

	my @legend  = @{$self->{legend}};
	$graph->set_legend(@legend);

	$graph->plot($data) or die $graph->error;

	my $result;

	# If the caller requested the mime type, add it to the results...
	if ($send_mime) {
		if ($self->{out} eq 'png') {
			$result = "Content-type: image/png\n\n";
		}
	}

	# Put the graph in the results...
	if ($self->{out} eq 'png') {
		$result .= $graph->gd->png;
	}

	# And return them
	return $result;
}

sub set_legend {
	my ($self, @legend) = @_;

	my $index = 0;
	foreach my $entry (@legend) {
		$self->{legend}[$index] = $entry;
		$index++;
	}
}

=pod

=head1 Author

Scott Elcomb <psema4@gmail.com>

=head1 See Also

SAL, SAL::DBI, SAL::WebDDR, SAL::WebApplication, GD::Graph, GD::Graph3d

=cut

1;
