package SAL::WebDDR;

# This module is licensed under the FDL (Free Document License)
# The complete license text can be found at http://www.gnu.org/copyleft/fdl.html
# Contains excerpts from various man pages, tutorials and books on perl
# FUNCTIONAL, BUT NOT TERRIBLY EASY TO FOLLOW. LOTS OF THINGS TO FIX AND CLEAN OUT.

use strict;
use DBI;
use Carp;
use Data::Dumper;

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

SAL::WebDDR - Web-based reporting abstraction for SAL::DBI database objects

=head1 Synopsis

 use CGI;
 use CGI::Carp qw(fatalsToBrowser);
 use SAL::DBI;
 use SAL::WebDDR;

 my $dbo_factory = new SAL::DBI;
 my $dbo_data = $dbo_factory->spawn_odbc('REPORTING_DSN',$report_user, $report_pass);
    $dbo_data->execute("sp_FinancialResults 'Q3'");

 my $report = new SAL::WebDDR;
    $report->{datasource} = $dbo_data;
    $report->{dfm_column} = '0';			# Data Formatting Markup is in column 0
    $report->{skip_fields} = 's 0 1 12 14 15 16 s';	# Do not display columns specified between the s's

 print "Content-type: text/html\n\n";
 my $canvas = $report->build_report();

 print qq[
 <html>
 <head>
 <title>SampleCorp: Financial Results for Q3 2005</title>
 </head>
 <body>
 $canvas
 </body>
 </html>
 ];

=head1 Eponymous Hash

This section describes some useful items in the SAL::WebDDR eponymous hash.  Arrow syntax is used here for readability, 
but is not strictly required.

Note: Replace $SAL::WebDDR with the name of your database object... eg. $report->{datasource} = $dbo_data

=over 1

=item Datasource

 $SAL::WebDDR->{datasource} is a reference to a SAL::DBI object

=item Formatting Control

 $SAL::WebDDR->{dfm_column} tells SAL::WebDDR where to look for DFM (Data Formatting Markup) tags
 $SAL::WebDDR->{skip_fields} specifies columns you want to skip in the reports output.

=back

=cut

our %WebDDR = (
######################################
 'datasource'		=> '',
######################################
 'data' => {
	'th'		=> '',
	'td'		=> '',
	'table'		=> '',
  },
######################################
 'window' => {
	'border'	=> '',
	'titlebar'	=> '',
	'statusbar'	=> '',
	'canvas'	=> '',
	'decoration'	=> '',
  },
######################################
 'misc' => {
	'ucfirst'	=> '',
	'highlight'	=> '',
	'negatives'	=> '',

	'dfm_column'		=> '',
	'num_skip_fields'	=> '',
	'skip_fields'		=> (),
	'pf_flag'		=> '',
	'page_table_html'	=> '',
	'global_number_fields'	=> '',
	'global_number_records'	=> '',
	'first_page_break'	=> '',
	'default_font_style'	=> '',

	'block_commify'		=> '',
  },
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

Builds a data-driven reporting object.

=cut

sub new {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	my $self = {};

	bless($self, $class);

	$self->{data}{table} = 'background-color: #fff;';
	$self->{data}{th} = 'background-color: #ddd; border: 2px outset #fff; text-align: center; font-size: 12px;';
	$self->{data}{td} = 'background-color: #fff; border-right: 1px solid #aaa; border-bottom: 1px solid #aaa; font-size: 10px;';

	$self->{window}{border} = '';
	$self->{window}{titlebar} = 'background-color: #337; border: 2px outset #fff; background-image: url(/images/window_top.png); background-repeat: no-repeat;';
	$self->{window}{canvas} = 'background-color: #fff; border: 2px inset #fff;';
	$self->{window}{statusbar} = 'background-color: #eee; border: 1px solid #aaa;';
	$self->{window}{decoration} = 'background-color: #337; background-image: url(/images/window_side.png); background-repeat: repeat-x;';

	$self->{misc}{highlight} = 'background-color: #aa0;';
	$self->{misc}{negatives} = '#FF0000';

	$self->{dfm_column} = '0',
	$self->{num_skip_fields} = '0',
	$self->{skip_fields} = qw(),
	$self->{pf_flag} = '0',
	$self->{page_table_html} = '<table cellspacing=0 width=100% border=0>',
	$self->{global_number_fields} = '',
	$self->{global_number_records} = '',
	$self->{first_page_break} = '1',
	$self->{default_font_style} = 'font-size: 10px;',

	# Update formatting at the field level
	my $w = $self->{datasource}->{internal}{width};
	my $h = $self->{datasource}->{internal}{height};

	for (my $field = 0; $field < $w; $field++) {
		$self->{datasource}->{fields}[$field]{'precision'} = '2';
		$self->{datasource}->{fields}[$field]{'commify'} = '1';
	}

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

=head2 $canvas = build_window($titlebar, $canvas, $statusbar, $width)

Builds a window-like html table using 3 scalars: $titelbar, $canvas, $statusbar.  $width is optional.

=cut

sub build_window {
	my ($self, $titlebar, $canvas, $statusbar, $width) = @_;
	if (! $width) { $width = '100%'; }

	my $content = qq[
<center>
<table width=$width border=0 cellspacing=0 cellpadding=2 style="border: 3px outset #fff;">
<td width=32 style="$self->{window}{decoration}"> </td>
<td>
 <table width=100% border=0 cellpadding=5 cellspacing=0 style="$self->{window}{border}">
  <tr>
   <td style="$self->{window}{titlebar}">$titlebar</td>
  </tr>
  <tr>
   <td style="$self->{window}{canvas}">$canvas</td>
  </tr>
  <tr>
   <td style="$self->{window}{statusbar}">$statusbar</td>
  </tr>
 </table>
</td>
</tr>
</table>
</center>
];

	return $content;
}

=pod

=head2 $canvas = build_scroll_window($titlebar, $canvas, $statusbar, $width)

Same as build_window() but uses an iframe for the main window content ($canvas).  JScript is used to copy the contents 
of $canvas into the iframe.

=cut

sub build_scroll_window {
	my ($self, $titlebar, $canvas, $statusbar, $width) = @_;
	if (! $width) { $width = '100%'; }

	my @scrolling_content = split(/\n/, $canvas);

	my $content = qq[
<center>
<table width=$width border=0 cellspacing=0 cellpadding=2 style="border: 3px outset #fff;">
<td width=32 style="$self->{window}{decoration}"> </td>
<td>
 <table width=100% border=0 cellpadding=5 cellspacing=0 style="$self->{window}{border}">
  <tr>
   <td style="$self->{window}{titlebar}">$titlebar</td>
  </tr>
  <tr>
   <td><iframe width=100% height=350 frameborder=1 marginwidth=2 marginheight=2 name="canvas">$canvas</iframe></td>
  </tr>
  <tr>
   <td style="$self->{window}{statusbar}">$statusbar</td>
  </tr>
 </table>
</td>
</tr>
</table>
</center>
<!-- Copy canvas content into iframe -->
<script language="JavaScript">
<!--
document.frames[0].document.open();
document.frames[0].document.write('<html>');
document.frames[0].document.write('<head>');
document.frames[0].document.write('<title>Query Results</title>');
document.frames[0].document.write('</head>');
document.frames[0].document.write('<body>');
];

	foreach my $line (@scrolling_content) {
		$content .= "document.frames[0].document.write('$line');\n";
	}

	$content .= qq[
document.frames[0].document.write('</body>');
document.frames[0].document.write('</html>');
document.frames[0].document.close();
//--></script>
];

	return $content;
}

=pod

=head2 $canvas = build_iframe_window($titlebar, $url, $statusbar, $width)

Same as build_scroll_window() but the embedded iframe retrieves it's content from $url.

=cut

sub build_iframe_window {
	my ($self, $titlebar, $url, $statusbar, $width) = @_;
	if (! $width) { $width = '100%'; }

	my $content = qq[
<center>
<table width=$width border=0 cellspacing=0 cellpadding=2 style="border: 3px outset #fff;">
<td width=32 style="$self->{window}{decoration}"> </td>
<td>
 <table width=100% border=0 cellpadding=5 cellspacing=0 style="$self->{window}{border}">
  <tr>
   <td style="$self->{window}{titlebar}">$titlebar</td>
  </tr>
  <tr>
   <td><iframe width=100% height=350 frameborder=1 marginwidth=2 marginheight=2 src="$url" name="canvas"><a href="$url">$url</a></iframe></td>
  </tr>
  <tr>
   <td style="$self->{window}{statusbar}">$statusbar</td>
  </tr>
 </table>
</td>
</tr>
</table>
</center>
];

	return $content;
}

=pod

=head2 $canvas = build_data_table($datasource, $commify, $highlight_negatives, $width)

Build's a simple spreadsheet-like table using $datasource (a SAL::DBI object).

B<NOTE:> This method B<does not> use it's internal datasource connection.  (~fixme)

If you want your numbers with commas, set $commify to a non-zero value.

If you'd like negative numbers highlighted, set $highlight_negatives to a non-zero value.

$width is optional, defaulting to 100%

=cut

sub build_data_table {
	my ($self, $dbo, $commify, $highlight_negatives, $width) = @_;

	if (! $width) { $width = '100%'; }

	my $w = $dbo->{internal}{width};
	my $h = $dbo->{internal}{height};

	my $content = qq[<table border=0 width=$width cellpadding=5 cellspacing=0 style="$self->{data}{table}"><tr>];

	for (my $field = 0; $field <= $w; $field++) {

		my $field_name = $dbo->{fields}->[$field]->{name};

		# If the gui's misc setting for ucfirst is set, make sure all headers start with an uppercase letter
		if ($self->{misc}{ucfirst}) { $field_name = ucfirst($field_name); }

		# If the field is defined as being visible...
		if ($dbo->{fields}->[$field]->{visible}) {

			# And if the field's header is defined as being visible
			if ($dbo->{fields}->[$field]->{header}) {
				# Then display the header
				$content .= qq[<td style="$self->{data}{th}">$field_name</td>\n];
			} else {
				# Otherwise, add a blank cell
				$content .= qq[<td> </td>\n];
			}
		}
	}

	$content .= qq[</tr>];

	for (my $record = 0; $record < $h; $record++) {
		$content .= qq[<tr>];
		for (my $field = 0; $field <= $w; $field++) {

			# Skip this field if it is defined as not being visible
			if (! $dbo->{fields}->[$field]->{visible}) {
				next;
			}

			my $cell_align = 'left';
			my $cell_data = $dbo->{data}->[$record][$field];
			my $cell_type = $dbo->{fields}->[$field]->{type};
			my $cell_style = $self->{data}{td};

			# Fix blank cells
			if (! $cell_data) {
				if ($cell_type =~ /char/i) {
					$cell_data = ' ';
				} else {
					$cell_data = '0';
				}
			}

			# Remove any 00:00:00 times
			if ($cell_data =~ /(.*)\s+00:00:00/) {
				$cell_data = $1;
			}

			# Set cell to right-aligned if cell data is numerical
			if ($cell_type !~ /char/i) {
				$cell_align = 'right';
			}

			# If the commify flag is set and the cell is numeric, commify the number
			if ($commify) {
				if (($cell_type !~ /time/i) or ($cell_type !~ /date/i)) {
					$cell_data = commify($cell_data);
				}
			}

			# If a precision size was defined for this field, set the displayed precision
			my $precision = $dbo->{fields}->[$field]->{precision};
			if ($precision) {
				if (($cell_type !~ /char/i) and ($cell_type !~ /date/i)) {
					$cell_data = sprintf('%.' . $precision . 'f', $cell_data);
				}
			}

			# highlight negatives if the flag was passed
			if ($highlight_negatives) {
				if ($cell_data =~ /^-\d(.*)/) {
					$cell_data = qq[<font color="$self->{misc}{negatives}">$cell_data</font>];
				}
			}

			$content .= qq[<td align=$cell_align style="$cell_style">$cell_data</td>];
		}
		$content .= "</tr>\n";
	}

	$content .= qq[</table>];

	return $content;
}

=head2 $canvas = build_report()

Build's a data driven report.  Please see the file 'salreport.cgi' in the samples directory.

=cut

sub build_report {
	my $self = shift;

	my $content;
	my $current_report_page = '1';
	my $record_html;

	if(! $self->{global_number_fields}) {
		$self->{global_number_fields} = $self->{datasource}->{internal}->{width};
		$self->{global_number_records} = $self->{datasource}->{internal}->{height};
	}

	# open the first table
	$content .= "$self->{page_table_html}\n";

	# We need to pass the current report page back through this loop
	for (my $index = 0; $index <= $self->{global_number_records}; $index++) {
		($record_html, $current_report_page) = $self->build_record_html($index, $current_report_page);
		$content .= $record_html;
	}

	# close the last table
	$content .= "</table>\n";

	return $content;
}

##########################################################################################################################
# Private Methods

sub build_record_html {
	my $self = shift;

	my $record = shift || '0';
	my $current_report_page = shift;
	my $previous_report_page;

	my $totals_flag = 0;
	my $span_flag = 0;
	my $spacer_underline_flag = 0;
	my $spacer_flag = 0;
	my $pre_spacer_flag = 0;
	my $page_flag = 0;
	my $headers_flag = 0;
	my $hnum_flag = 0;
	my $span_interface_flag = 1;
	my $zero2space_flag = 0;

	my $content;

	if ($record ne '(undefined)') {
		# reset flags
		$totals_flag = 0;
		$span_flag = 0;
		$spacer_flag = 0;
		$pre_spacer_flag = 0;
		$page_flag = 0;
		$headers_flag = 0;
		$hnum_flag = 0;
		$span_interface_flag = 1;
		$zero2space_flag = 0;
		$spacer_underline_flag = 0;

		# page control
		$previous_report_page = $current_report_page;

		if ($current_report_page ne $previous_report_page) {
			$pre_spacer_flag = 1;
			$page_flag = 1;
		}

		# currently, formatting tags are in column 2 (0-index)
		my $dfm_tags;
		my $formatting = $self->{datasource}->{data}->[$record][$self->{dfm_column}];

		if ($formatting =~ /totals/i) {
			$totals_flag = 1;

			# test ahead, does next line have another totals in it?
			my $next_record = $record + 1;
			my $next_record_keys = $self->{datasource}->{data}->[$next_record][$self->{dfm_column}];

			if ($next_record_keys !~ /totals/i) {
				# if not, force a spacer
				$spacer_flag = 1;
			}
			if ($next_record_keys =~ /h\d/i) {
				$spacer_underline_flag = 0;
			}
		}

		if ($formatting =~ /\[(.*)\]/) {

			# extract the dfm tags
			$formatting = $1;
			$dfm_tags = $formatting;

			# set any special record-wide display flags;

			# headers
			if ($formatting =~ /h(\d)/) {

				# key first page col headers on h4 tag
				if ($1 == '4') {
					$headers_flag = 1;
				}
				$span_flag = 1;
				$spacer_flag = 1;
#				$hnum_flag = 1;		# put line over headers
# headers
#				$headers_flag = 1;
			}

			# linefeeds
# NOTE: Possible new dfm tag
			if ($formatting =~ /line/i) {
				$spacer_flag = 1;
# headers?
#				$headers_flag = 1;
			}

			# pagefeeds
			if ($formatting =~ /page/i) {
				$spacer_flag = 1;
				$page_flag = 1;
			}

			# get the style html tag
			$formatting = $self->build_format_string($formatting);
			if ($hnum_flag) {
				$formatting =~ s/"$/border-top: 2px solid black;"/;
			}
		} else {
			$formatting = "style=\"$self->{default_font_style}\"";
		}

		# handle pre-spacer (leading page-breaks)
		if ($pre_spacer_flag) {
			my $formatting;

			if ($page_flag) {
# page
#				$formatting = 'style="page-break-after: always;"';
			} else {
# dots
				$formatting = 'style="border-top: 2px solid #000; border-bottom: 1px dotted #aaa;"';
			}

			$span_interface_flag = 0;
			$content .= '<tr>' . build_spanned_field_html(" ",$formatting, $span_interface_flag) . "</tr>\n";
# headers
			if ($page_flag) {
				$content .= "</table>\n" . $self->{page_table_html} . $self->do_page_break();
				$page_flag = 0;
			}
		}

# cells
		# open tr html tag
		$content .= "<tr>";

		if (! $span_flag) {
			for (my $index = 0; $index <= $self->{global_number_fields}; $index++) {
				# only display the column if it is not in the exclusion list
				if ($self->{skip_fields} !~ /\s$index\s/) {

					if (($totals_flag) and ($formatting !~ /border-top/)) {
						$formatting =~ s/"$//;		# remove trailing quote
						$formatting .= " border-top: 1px dotted #000;\"";
					}
# zero2space - remove?
					# if the record is being formatted on a h? dfm tag
					if ($dfm_tags =~ /h\d/) {
						$zero2space_flag = 1;
					}

					$content .= $self->build_field_html($record, $index, $formatting, $zero2space_flag);
				}
			}
		} else {
			# do table-wide colspan for headers
			$content .= $self->build_spanned_field_html($self->{datasource}->{data}->[$record][$self->{dfm_column}], $formatting, $span_interface_flag);
		}

	} else {
		# simulate/display error record
		$content .= "<!-- record was not passed -->\n";
	}

	$content .= "</tr>\n";

	# add a spacer line after the record we just built
	if ($spacer_flag) {
		my $formatting;

		if ($page_flag) {
			if ($spacer_underline_flag) {
				$formatting = 'style="border-top: 2px solid #000;"';
			} else {
				$formatting = 'style=""';
			}
		} else {
# dots
			if ($spacer_underline_flag) {
				$formatting = 'style="border-top: 2px solid #000; border-bottom: 1px dotted #aaa;"';
			} else {
				$formatting = 'style="border-top: 2px solid #000;"';
			}
		}
		$content .= '<tr>' . $self->build_spanned_field_html(" ",$formatting, 0) . "</tr>\n";

# headers
#		if ($page_flag) { $content .= "</table>\n" . $self->{page_table_html} . $self->do_page_break(); }
		if ($page_flag) { $content .= "</table>\n" . $self->{page_table_html}; }

	}

	# add a page headers line after the record we just built.
	if ($headers_flag) {
# headers
		$content .= $self->do_page_break();
	}

	# a better way would be to have $current_report_page declared a local static
	# or global variable.  need to find out how it's done in perl...
	#
	# we need to return $current_report_page to the caller, so that
	# the caller can let us know what the last page processed was
	# during the next iteration.
	return ($content, $current_report_page);
}

sub build_field_html {				# No parameter checking....
	my $self = shift;

	my $record = shift;
	my $field = shift;
	my $formatting = shift;
	my $zero2space_flag = shift;

	my $cell_width = 0;

	my $field_data = $self->{datasource}->{data}->[$record][$field];
	my $field_type = $self->{datasource}->{fields}->[$field]->{type};

	if (! $field_data) { $field_data = ' '; }
	if ($field_data =~ /NULL/i) { $field_data = ' '; }

	if ($field_data =~ /^\[.*\](.*)/) {
		$field_data = $1;
	}

	if ($field_data =~ /^(.*)\s+00:00:00/) {
		$field_data = $1;
	}

	if (! $self->{pf_flag}) {
		# color negative values red if device is not printer
		if ($field_data =~ /^\-/) { $field_data = "<font color=#FF0000>$field_data</font>"; }
	}


	# Test the data - if it contains /[a-zA-Z][a-zA-Z][a-zA-Z]\s+\d+\s+\d\d\d\d/ set it to a date type
	if ($field_data =~ /[a-zA-Z][a-zA-Z][a-zA-Z]\s+\d+\s+\d\d\d\d/) {
		$field_type = 'datetime';
	}

	# A commify flag needs to be in the gui properties...  should be tested here.
	if ($field_type !~ /date/i) {
		if ($field_data !~ /[a-zA-Z]/) {
			if($self->{misc}{block_commify} < 1) {
				if($self->{datasource}->{fields}[$field]{commify} > 0) {
					$field_data = $self->commify($field_data);
				}
			}
		}
	}

	# If a precision size was defined for this field, set the displayed precision
	my $precision = $self->{datasource}->{fields}->[$field]->{precision};
	if ($precision) {
		if ($field_data !~ /[a-zA-Z]/) {
			$field_data = sprintf('%.' . $precision . 'f', $field_data);
		}
	}

	# If a prefix string  was defined for this field, prepend it
	my $prefix = $self->{datasource}->{fields}->[$field]->{prefix};
	if ($prefix) {
		if ($field_data =~ / /) {
			$field_data = $prefix . $field_data;
		}
	}

	# If a postfix string  was defined for this field, append it
	my $postfix = $self->{datasource}->{fields}->[$field]->{postfix};
	if ($postfix) {
		if ($field_data =~ / /) {
			$field_data .= $postfix;
		}
	}

	# If an alignment was defined for this field, set it
	if ($formatting !~ /align/) {
		my $align = $self->{datasource}->{fields}->[$field]->{align};
		if ($align) {
			$formatting =~ s/"$//;
			$formatting .= " text-align: $align;\"";
		}
	}

	my $content;
	if ($cell_width) {
		$content = "<td width=$cell_width valign=top $formatting>$field_data</td>";
	} else {
		$content = "<td valign=top $formatting>$field_data</td>";
	}

	return $content;
}

sub build_spanned_field_html {
	my $self = shift;

	my $field_data = shift;
	my $formatting = shift;
	my $interface_control = shift;

	if (! $field_data) { $field_data = ' '; }
	if ($field_data =~ /NULL/i) { $field_data = ' '; }

	if ($field_data =~ /^\[.*\](.*)/) {
		$field_data = $1;
	}

	if ($interface_control) {
#		$field_data .= "<br/>\n<a href=\"#interface\">( Options )</a>\n";
	}

	# force left aligned text
	$formatting =~ s/"$//;				# remove the trailing quote
	$formatting .= " text-align: left;\"";		# add text-align and trailing quote
	my $content = "<td colspan=" . (($self->{global_number_fields} + 1) - $self->{num_skip_fields}) . " $formatting>$field_data</td>";

	return $content;
}

sub do_page_break {
	my $self = shift;

	my $content;

	$content = "<tr>";

	for (my $index = 0; $index <= $self->{global_number_fields}; $index++) {

		my $cell_width = 50;

		# only display the column label if it is not in the exclusion list
		if ($self->{skip_fields} !~ /\s+$index\s+/) {

			my $label = $self->{datasource}->{column_info}->[$index]->{label};
			$label = ucfirst($label);

			if ($index == 2) {
				$label = ' ';
			}

			my $align;
			if ($index == 2) {
				$align = 'left';
				$cell_width = 255;
			} else {
				$align = 'right';
			}

			if ($self->{first_page_break}) {
# fix this :(
				if ($index == 2) {
					$content .= "<td width=$cell_width style=\"text-align: $align;\">$label</td>";
				} else {
					$content .= "<td width=$cell_width style=\"text-align: $align; border-bottom: 1px dotted #000;\">$label</td>";
				}
			} else {
# fix this :(
				if ($index == 2) {
					$content .= "<td width=$cell_width style=\"page-break-before: always; text-align: $align;\">$label</td>";
				} else {
					$content .= "<td width=$cell_width style=\"page-break-before: always; text-align: $align; border-bottom: 1px dotted #000;\">$label</td>";
				}
			}
		} else {
			# skip
		}
	}

	$content .= "</tr>\n";

	if ($self->{first_page_break}) { $self->{first_page_break} = 0; }	# clear 1st pgbreak flag

	return $content;
}

sub build_format_string {
	my $self = shift;

	my $formatting = shift || '(undefined)';
	my @tags = split(/\s+/, $formatting);
	my $num_tags = $#tags;
	my $fstring;

	my %tag_styles = (
		'italics'	=> 'font-style: italic',
		'cite'		=> 'font-style: italic',
		'bold'		=> 'font-weight: bold',
		'strong'	=> 'font-weight: bold',
		'fgcolor'	=> 'color',
		'bgcolor'	=> 'background-color',
		'fg'		=> 'color',			# short-form for fgcolor
		'bg'		=> 'background-color',		# short-form for bgcolor
		'h1'		=> 'font-size: 32px',		# largest heading
		'h2'		=> 'font-size: 24px',		
		'h3'		=> 'font-size: 18px',		
		'h4'		=> 'font-size: 16px',		
		'h5'		=> 'font-size: 12px',		# smallest heading

# new 09/13/2004
		'solid_under'	=> 'border-bottom: 1px solid #000',	# line under cells
		'solid_over'	=> 'border-top: 1px solid #000',	# line over cells
		'dashed_under'	=> 'border-bottom: 1px dashed #000',	# line under cells
		'dashed_over'	=> 'border-top: 1px dashed #000',	# line over cells
		'double_under'	=> 'border-bottom: 3px double #000',	# line under cells
		'double_over'	=> 'border-top: 3px double #000',	# line over cells
	);

# quick-search: index-lists
	my $device_excludes;					# simpler exclusion list
	if ($self->{pf_flag}) {					#  than the columns since
		$device_excludes = 's bg fg s';			#  we don't need to know
	}							#  how many items are in
								#  the list.
	if ($formatting ne '(undefined)') {

		# open the style html tag segment
		$fstring = 'style="';

		# build the css settings
		for (my $index = 0; $index <= $num_tags; $index++) {
			my $current_tag = $tags[$index];
			next if ($device_excludes =~ /\s+$current_tag\s+/);

			if ($current_tag =~ /=/) {
				# tag has associated value
				my ($tmp_tag, $tmp_value) = split(/=/, $current_tag);
				next if ($device_excludes =~ /\s+$tmp_tag\s+/);
				$fstring .= $tag_styles{$tmp_tag} . ': ' . $tmp_value . '; ';
			} else {
				# tag does not have assoc value
				$fstring .= $tag_styles{$current_tag} . '; ';
			}
		}

		# if no heading dfm tag was found, we need to append default text size
		if ($fstring !~ /font\-size/) {
			$fstring .= $self->{default_font_style};
		}

		# clean up the trailing space
		$fstring =~ s/\s$//;

		# close the style html tag segment
		$fstring .= '"';
	} else {

		# the formatting string was undefined, set to default
		$fstring = "style=\"$self->{default_font_style}\"";
	}

	return $fstring;
}

sub commify {
	my $self = shift;

	my $number = reverse $_[0];
	$number =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $number;
}

=pod

=head1 Author

Scott Elcomb <psema4@gmail.com>

=head1 See Also

SAL, SAL::DBI, SAL::Graph, SAL::WebApplication

=cut

1;
