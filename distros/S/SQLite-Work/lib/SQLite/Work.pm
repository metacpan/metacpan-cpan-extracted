package SQLite::Work;
$SQLite::Work::VERSION = '0.1601';
use strict;
use warnings;

=head1 NAME

SQLite::Work - report on and update an SQLite database.

=head1 VERSION

version 0.1601

=head1 SYNOPSIS

    use SQLite::Work;

    my $rep = SQLite::Work->new(%new_args);

    if ($rep->do_connect())
    {
	if ($simple_report)
	{
	    $rep->do_report(%report_args);
	}
	elsif ($multi_page_report)
	{
	    $rep->do_multi_page_report(%report_args);
	}
	elsif ($split_report)
	{
	    $rep->do_split_report(%report_args);
	}
	$rep->do_disconnect();
    }

=head1 DESCRIPTION

SQLite::Work is a perl module for interfacing with an SQLite database.
It can be used to:

=over

=item *

generate I<nice> HTML (and non-HTML) reports, which

=over

=item *

have nested headers

=item *

have grouped data which clusters under the headers

=item *

can be sorted on multiple columns

=item *

can be customized with templates (both headers and body) which include
some simple formatting for column values, for example:

    simple HTMLize
    titles (Title,The becomes The Title)
    names (Nurk,Fred becomes Fred Nurk)
    month names
    truncation

(see L<Text::NeatTemplate>)

=item *

one can select the columns and their order even if one isn't using templates

=item *

default templates can be selected which present the data in tables,
in paragraphs (Column:Value) or in lists.

=item *

can be split into multiple HTML pages, with automatic index-page
generation; the split can be on the values of a given column, and/or by
number of rows

=back

=item *

use a generic search CGI script ("show.cgi" using SQLite::Work::CGI) which

=over
 
=item *

can search on all the fields in a table without having to hardcode the
column names (it just gets them from the table information)

=item *

uses most of the power of the report engine to give I<nice> search
results

=back

=item *

update the database with a CGI script ("edit.cgi" using SQLite::Work::CGI)

=item *

be able to mail reports to general addresses (such as a mailing list)
or to specific addresses (such as sending notifications to individuals
whose address is in the database). (using the sqlw_mail script)

=back

This generates HTML (and non-HTML) reports from an SQLite database,
taking care of the query-building and the report formatting.  This also
has methods for adding and updating the database.

The L<SQLite::Work::CGI> module has extra methods which deal with CGI using
the CGI module; the included "show.cgi" and "edit.cgi" are demonstration
CGI scripts which use the SQLite::Work::CGI module.  There is also the
"show.epl" demonstration Embperl script which has the necessary alterations
for using this with Embperl.

The L<sqlreport> script uses SQLite::Work to generate reports from the
command-line.

The L<sqlw_mail> script uses SQLite::Work::Mail to email reports.

=head2 Limitations

This only deals with single tables and views, and simple one-field,
two-table joins.  More complex joins should be dealt with by making
a view.

This only deals with one database at a time.

=cut

use DBI;
use POSIX;
use Text::NeatTemplate;

=head1 CLASS METHODS

=head2 new

my $rep = SQLite::Work->new(
    database=>$database_file,
    row_ids=>{
	    episodes=>'title_id',
	},
    join_cols=>{
	    'episodes+recordings'=>'title_id',
	    }
	},
    report_template=>$template,
    default_format=>{
	    'episodes' => {
		'title'=>'title',
		'series_title'=>'title',
	    }
	},
    use_package=>[qw(File::Basename MyPackage)],
    );

Make a new report object.

This takes the following arguments:

=over

=item database

The name of the SQLite database file.  This is required.

=item row_ids

The default column-name which identifies rows in SQLite is 'rowid', but
for tables which have a primary integer key, this doesn't work (even
though the documentation says it ought to).  Therefore it is necessary
to identify, for the given database, which tables need to use a
different column-name for this.  This gives a hash of table->column
names.

=item join_cols

This covers simple joins of two tables, by providing the name
of a commom column on which to join them.
This is only used for presenting two tables separately in one
report, not for a combined-table report; for that you are
required to create a view.

Presenting two tables separately in one report is only done when
only one row is being shown from the first table; then a second
section shows the matching rows from the other table (if a second
table has been asked for).  This is mainly used for editing
purposes (see L<SQLite::Work::CGI>).

=item report_template

Either a string containing a template, or string containing the name of
a template file.  The template variables are in the following format:

<!--sqlr_title-->

The following variables are set for the report:

=over

=item sqlr_title

Title (generally the table name).

=item sqlr_contents

The report itself.

=back

=item index_template

Similar to the report_template, but this is used for the index-pages
in multi-page and split reports.  It has the same format, but it
can be useful to have them as two separate templates as one may wish
to change the way the title is treated for indexes versus actual
reports.

=item default_format

This contains the default format to use for the given columns
in the given tables, when generating a row_template if a
row_template has not been given.
This is useful for things like CGI scripts where it isn't
possible to know beforehand what sort of row_template is needed.

=item use_package

This contains an array of package names of packages to "use".
This is mainly so that the {&funcname())} construct of
the templates (see L<Text::NeatTemplate>) can call
functions within these packages (using their fully-qualified
names).

=back

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = bless ({%parameters}, ref ($class) || $class);
    $self->{message} = '';
    if (!defined $self->{row_ids})
    {
	$self->{row_ids}  = {};
    }

    if (!defined $self->{join_cols})
    {
	$self->{join_cols}  = {};
    }

    $self->{report_template} ||=<<EOT;
<html>
<head><title><!--sqlr_title--></title>
</head>
<body>
<h1><!--sqlr_title--></h1>
<!--sqlr_contents-->
</body>
</html>
EOT
    $self->{index_template} ||=<<EOT;
<html>
<head><title><!--sqlr_title--></title>
</head>
<body>
<h1><!--sqlr_title--></h1>
<!--sqlr_contents-->
</body>
</html>
EOT

    # make the template object
    if ($parameters{use_package})
    {
	for my $pkg (@{$parameters{use_package}})
	{
	    eval "use $pkg" if $pkg;
	    die "invalid use $pkg: $@" if $@;
	}
    }
    $self->{_tobj} = Text::NeatTemplate->new(escape_html=>1);

    return ($self);
} # new

=head1 OBJECT METHODS

Methods in the SQLite::Work object interface

=head2 do_connect

$rep->do_connect();

Connect to the database.

=cut
sub do_connect {
    my $self = shift;

    my $database = $self->{database};
    if ($database)
    {
	my $dbh = DBI->connect("dbi:SQLite:dbname=$database", "", "");
	if (!$dbh)
	{
	    $self->print_message("Can't connect to $database: $DBI::errstr");
	    return 0;
	}
	$self->{dbh} = $dbh;
    }
    else
    {
	$self->print_message("No Database given.");
	return 0;
    }
} # do_connect

=head2 do_disconnect

$rep->do_disconnect();

Disconnect from the database.

=cut
sub do_disconnect {
    my $self = shift;

    $self->{dbh}->disconnect();
} # do_disconnect

=head2 do_report

    $rep->do_report(
	table=>$table,
	table2=>$table2,
	where=>\%where,
	not_where=>\%not_where,
	sort_by=>\@sort_by,
	show=>\@show,
	distinct=>0,
	headers=>\@headers,
	header_start=>1,
	groups=>\@groups,
	limit=>$limit,
	page=>$page,
	layout=>'table',
	row_template=>$row_template,
	outfile=>$outfile,
	report_style=>'full',
	table_border=>1,
	truncate_colnames=>0,
	title=>'',
    );

Select data from a table in the database, and make a HTML
report.

Arguments are as follows (in alphabetical order):

=over

=item distinct

If columns are given to show (see L<show>), then this will
ensure that rows with exactly the same values will not be
repeated.

=item groups

An array of group templates (or filenames of files containing
group templates).  A group template is a template for values
which are "grouped" under a corresponding header.  The first
group in the array is placed just after the first header in
the report, and so on.

See L<headers> for more information.

=item headers

An array of header templates (or filenames of files containing header
templates).  A header template lays out what values should be put
into headers rather than the body of the report.  The first header
template is given a H1 header, the second a H2 header, and so on.
Headers are shown only when the value(s) they depend on change,
but they get their values from each row in the report.  Therefore
the columns used in the headers should match the columns used in the
L<sort_by> array.

The column names are the variable names in this template.  This has
a different format to the L<report_template>; it is more sophisticated.

The format is as follows:

=over

=item {$colname}

A variable; will display the value of the column, or nothing if
that value is empty.

=item {?colname stuff [$colname] more stuff}

A conditional.  If the value of 'colname' is not empty, this will
display "stuff value-of-column more stuff"; otherwise it displays
nothing.

    {?col1 stuff [$col1] thing [$col2]}

This would use both the values of col1 and col2 if col1 is not
empty.

=item {?colname stuff [$colname] more stuff!!other stuff}

A conditional with "else".  If the value of 'colname' is not empty, this
will display "stuff value-of-column more stuff"; otherwise it displays
"other stuff".

This version can likewise use multiple columns in its display parts.

    {?col1 stuff [$col1] thing [$col2]!![$col3]}

=back

The same format is used for L<groups> and L<row_template>.

=item header_start

At what level the headers should start.  Default is 1 (H1).

=item layout

The layout of the report.  This determines both how rows are grouped,
and what is in the generated L<row_template> if no row_template is
given.

=over

=item table

The report is a (group of) tables, each row of the report is a row in
the table; a new table occurs after the heading(s).

=item para

The report is in paragraphs, each row of the report is one paragraph.

=item list

The report is a (group of) lists, each row of the report is an item in
the list; a new list occurs after the heading(s).

=item fieldval

The rows are not HTML-formatted.  The generated row_template is made up
of Field:Value pairs, one on each line.

=item none

The rows are not HTML-formatted.  The generated row_template is made up
of values, one on each line.

=back

=item limit

The maximum number of rows to display per page.  If this is zero,
then all rows are displayed in one page.

=item not_where

A hash containing the column names where the selection criteria
in L<where> should be negated.

=item outfile

The name of the output file.  If the name is '-' then the output
goes to STDOUT.

=item page

Select which page to generate, if limit is not zero.

=item report_style

The style of the report, especially as regards table layout.

=over

=item full

=item medium

=item compact

=item bare

=back

=item row_template

The template for each row.  This uses the same format as for L<headers>.
If none is given, then a default row_template will be generated,
depending on what L<layout> and which columns are going to be shown
(see L<show>).

Therefore it is important that if one provides a row_template, that
it matches the current layout.

Also note that if a column is given in a header, it will not be
displayed in a row, even if it is put into the row_template.

=item show

An array of columns to select; also the order in which they should
be shown when a L<row_template> has not been given.

=item sort_by

An array of column names by which the result should be sorted.
If the column name is prefixed with a "-", the sort order should
be reversed for that column.

=item table

The table to report on. (required)

=item table2

A second table to report on.  If this is given, and L<join_cols>
have been defined, and the result of the query on the first table
returns only one row (either because there's only one row, or because
L<limit> was set to 1), then a second, simpler, sub-report will
be done on this table, displaying all the rows which match
the join-value in the first table.

This is only really useful when doing editing with a CGI script.

=item table_border

For fine-tuning the L<report_style>; if the L<layout> is 'table',
then this overrides the default border-size of the table.

=item table_header

When the report layout is 'table' and the report_style is not 'bare',
then this argument can be used to customize the table-header
of the report table.  This must either contain the contents
of the table-header, or the name of a file which contains
the contents of the table-header.

If this argument is not given, the table-header will be constructed
from the column names of the columns to be shown.

=item title

The title of the report; if this is empty, a title will be generated.

=item truncate_colnames

For fine-tuning the L<report_style>; this affects the length of
column names given in layouts which use them, that is, 'table'
(for all styles except 'bare') and 'para'.  If the value is zero,
the column names are not truncated at all; otherwise they are
truncated to that number of characters.

=item where

A hash containing selection criteria.  The keys are the column names
and the values are strings suitable for using in a GLOB condition;
that is, '*' is a multi-character wildcard, and '?' is a
single-character wildcard.  All the conditions will be ANDed together.

Yes, this is limited and doesn't use the full power of SQL, but it's
useful enough for most purposes.

=back

=cut
sub do_report {
    my $self = shift;
    my %args = (
	table=>undef,
	command=>'Select',
	limit=>0,
	page=>1,
	table2=>'',
	headers=>[],
	header_start=>1,
	groups=>[],
	sort_by=>undef,
	not_where=>{},
	where=>{},
	show=>[],
	layout=>'table',
	row_template=>'',
	outfile=>'',
	report_style=>'full',
	title=>'',
	prev_file=>'',
	next_file=>'',
	@_
    );
    my $table = $args{table};
    my $command = $args{command};
    my @columns = (@{$args{show}}
	? @{$args{show}}
	: $self->get_colnames($table));

    my $total = $self->get_total_matching(%args);

    my ($sth1, $sth2) = $self->make_selections(%args,
	total=>$total);
    $self->print_select($sth1,
	$sth2,
	%args,
	message=>$self->{message},
	command=>$command,
	total=>$total,
	columns=>\@columns,
	);
} # do_report

=head2 do_multi_page_report

    $rep->do_multi_page_report(
	table=>$table,
	table2=>$table2,
	where=>\%where,
	not_where=>\%not_where,
	sort_by=>\@sort_by,
	show=>\@show,
	headers=>\@headers,
	groups=>\@groups,
	limit=>$limit,
	page=>$page,
	layout=>'table',
	row_template=>$row_template,
	prev_next_template=>$prev_next_template,
	multi_page_template=>$multi_page_template,
	outfile=>$outfile,
	table_border=>1,
	table_class=>'plain',
	truncate_colnames=>0,
	report_style=>'full',
	link_suffix=>'.html',
    );

Select data from a table in the database, and make a HTML
file for EVERY page in the report.

If the limit is zero, or the number of rows is less than the limit, or
the outfile is destined for STDOUT, then calls do_report to do a
single-page report.

If no rows match the criteria, does nothing and returns false.

Otherwise, it uses the 'outfile' name as a base upon which to build the
file-names for all pages in the report (basically appending the
page-number to the name), and generates a report file for each of them,
and an index-page file which is called the 'outfile' value.

The 'link_suffix' argument, if given, overrides the suffix given
in links to the other pages in this multi-page report; this is useful
if you're post-processing the files (and thus changing their extensions)
or are using something like Apache MultiViews to eliminate the need for
extensions in links.

See L<do_report> for information about the rest of the arguments.

=cut
sub do_multi_page_report {
    my $self = shift;
    my %args = (
	table=>undef,
	command=>'Select',
	limit=>0,
	page=>1,
	table2=>'',
	headers=>[],
	header_start=>1,
	groups=>[],
	sort_by=>undef,
	not_where=>{},
	where=>{},
	show=>[],
	layout=>'table',
	row_template=>'',
	prev_next_template=>'',
	multi_page_template=>'',
	outfile=>'',
	report_style=>'full',
	title=>'',
	verbose=>0,
	prev_file=>'',
	prev_label=>'',
	next_file=>'',
	next_label=>'',
	link_suffix=>undef,
	@_
    );
    
    # check if we just want a single page
    if ($args{limit} == 0
	or $args{outfile} eq ''
	or $args{outfile} eq '-')
    {
	return $self->do_report(%args);
    }

    my $total = $self->get_total_matching(%args);
    my $num_pages = ceil($total / $args{limit});
    # if there's only one page, do a single-page report also
    if ($num_pages == 1)
    {
	return $self->do_report(%args, limit=>0);
    }
    if ($num_pages == 0)
    {
	return 0;
    }
    print STDERR "About to generate $num_pages PAGES\n" if $args{verbose};
    # split the outfile into prefix and suffix
    $args{outfile} =~ m#(.*)(\.\w+)$#;
    my $outfile_prefix = $1;
    my $outfile_suffix = ($2 ? $2 : '.html');
    my $link_suffix = (defined $args{link_suffix} ? $args{link_suffix}
	: $outfile_suffix);
    # width of the page-id
    my $digits = ($num_pages < 10 ? 1
	: ($num_pages < 100 ? 2 : 3)
	);

    # stuff for the index page
    my $title_main = ($args{title} ? $args{title} : $args{table});
    # fix up random ampersands
    if ($title_main =~ / & /)
    {
	$title_main =~ s/ & / &amp; /g;
    }
    my $multi_page_template = ($args{multi_page_template}
		       ? $args{multi_page_template}
	    : '<li><a href="{$outfile_link}">{$title_main} ({$page})</a></li>
'
		      );
    my $ind_contents;
    $ind_contents = "<ul>";

    # make a report for each page
    for (my $page = 1; $page <= $num_pages; $page++)
    {
	my $outfile = sprintf("%s_%0*d%s",
	    $outfile_prefix, $digits, $page, $outfile_suffix);
	my $outfile_link = sprintf("%s_%0*d%s",
	    $outfile_prefix, $digits, $page, $link_suffix);
	my $prevfile = ($page > 1
			? sprintf("%s_%0*d%s",
				  $outfile_prefix, $digits,
				  $page - 1, $link_suffix)
			: sprintf("%s%s", $outfile_prefix, $link_suffix)
			);
	my $prevlabel = ($page > 1
			? sprintf("%s (%d)", $title_main, $page - 1)
			: sprintf("%s Index", $title_main));
	my $nextfile = ($page < $num_pages
			? sprintf("%s_%0*d%s",
				  $outfile_prefix, $digits,
				  $page + 1, $link_suffix)
			: $args{next_file});
	my $nextlabel = ($page < $num_pages
			? sprintf("%s (%d)", $title_main, $page + 1)
			: $args{next_label});
	$self->do_report(%args,
	    outfile=>$outfile,
	    prev_file=>$prevfile,
	    prev_label=>$prevlabel,
	    next_file=>$nextfile,
	    next_label=>$nextlabel,
	    page=>$page);
	print STDERR "$outfile\n" if $args{verbose};
	my %mp_hash = (
	    outfile_link=>$outfile_link,
	    title_main=>$title_main,
	    page=>$page,
	);
	my $mp_templ = $self->get_template($multi_page_template);
	my $mp_str = $self->{_tobj}->fill_in(data_hash=>\%mp_hash,
					     template=>$mp_templ);
	$ind_contents .= $mp_str;
    }
    $ind_contents .= "</ul>\n";

    # append the prev-next links, if any
    if ($args{prev_file} or $args{next_file})
    {
	my $prev_label = $args{prev_label};
	$prev_label =~ s/ & / &amp; /g;
	my $next_label = $args{next_label};
	$next_label =~ s/ & / &amp; /g;
	my %pn_hash = (
		       prev_file => $args{prev_file},
		       prev_label => $prev_label,
		       next_file => $args{next_file},
		       next_label => $next_label,
		      );
	my $pn_template = ($args{prev_next_template}
			   ? $args{prev_next_template}
			   : '<hr/>
			   <p>{?prev_file <a href="[$prev_file]">[$prev_label]</a>}
			   {?next_file <a href="[$next_file]">[$next_label]</a>}
			   </p>
			   '
			  );
	my $pn_templ = $self->get_template($pn_template);
	my $pn_str = $self->{_tobj}->fill_in(data_hash=>\%pn_hash,
					     template=>$pn_templ);
	$ind_contents .= $pn_str;
    }

    # and make the index page
    my $out = $self->get_template($self->{index_template});
    $self->{index_template} = $out;
    $out =~ s/<!--sqlr_title-->/$title_main/g;
    $out =~ s/<!--sqlr_contents-->/$ind_contents/g;
    my $fh;
    open($fh, ">", $args{outfile})
	or die "Could not open $args{outfile} for writing";
    print $fh $out;
    close($fh);

    return 1;
} # do_multi_page_report

=head2 do_split_report

    $rep->do_split_report(
	table=>$table,
	split_col=>$colname,
	split_alpha=>$n,
	command=>'Select',
	table2=>$table2,
	where=>\%where,
	not_where=>\%not_where,
	sort_by=>\@sort_by,
	show=>\@show,
	headers=>\@headers,
	header_start=>1,
	groups=>\@groups,
	limit=>$limit,
	page=>$page,
	layout=>'table',
	row_template=>$row_template,
	outfile=>$outfile,
	table_border=>1,
	table_class=>'plain',
	truncate_colnames=>0,
	report_style=>'full',
	link_suffix=>'.html',
    );

Build up a multi-file report, splitting it into different pages for each
distinct value of the 'split_col' column.  (If the outfile is destined
for STDOUT, then this will call do_report intead).

The filenames generated will use 'outfile' as a prefix, and
the column name and values as the rest; this calls in turn
L<do_multi_page_report> to break those into multiple pages
if need be.  An index-page is also generated, which will be
called I<outfile> + I<colname> + .html

If 'split_alpha' is also given and is not zero, then instead of
splitting on each distinct value in the 'split_col' column, the
split is done by the truncated values of that column; if 'split_alpha'
is 1, then the split is by the first letter, if it is 2, by the first
two letters, and so on.

The 'link_suffix' argument, if given, overrides the suffix given
in links to the other pages in this multi-page report; this is useful
if you're post-processing the files (and thus changing their extensions)
or are using something like Apache MultiViews to eliminate the need for
extensions in links.

See L<do_report> for information about the rest of the arguments.

=cut
sub do_split_report {
    my $self = shift;
    my %args = (
	table=>undef,
	split_col=>'',
	split_alpha=>0,
	filename_format=>'namedalpha',
	command=>'Select',
	limit=>0,
	page=>1,
	table2=>'',
	headers=>[],
	header_start=>1,
	groups=>[],
	sort_by=>undef,
	not_where=>{},
	where=>{},
	show=>[],
	layout=>'table',
	row_template=>'',
	split_ind_template=>'',
	outfile=>'',
	report_style=>'full',
	title=>'',
	verbose=>0,
	debug=>0,
	link_suffix=>undef,
	@_
    );
    
    # check for STDOUT destination
    if ($args{outfile} eq '-')
    {
	return $self->do_report(%args);
    }
    my $split_col = $args{split_col};
    my $split_alpha = $args{split_alpha};

    # split the outfile into prefix and suffix
    my $outfile_prefix = '';
    my $outfile_suffix = '.html';
    if ($args{outfile})
    {
	$args{outfile} =~ m/(.*)(\.\w+)$/;
	$outfile_prefix = $1;
	$outfile_suffix = ($2 ? $2 : '.html');
    }
    my $link_suffix = (defined $args{link_suffix} ? $args{link_suffix}
	: $outfile_suffix);

    my $total = $self->get_total_matching(%args);
    my @split_vals = $self->get_distinct_col(%args,
	colname=>$split_col);
    if ($split_alpha)
    {
	my %split_avals = ();
	foreach my $val (@split_vals)
	{
	    my $a1 = substr(($val||''), 0, ($split_alpha ? $split_alpha : 1));
	    $a1 = uc($a1);
	    $split_avals{$a1} = 1;
	}
	@split_vals = sort keys %split_avals;
    }

    my $two_level_ind = (($split_alpha or @split_vals < 15) ? 0 : 1);

    # stuff for the index page
    my $title_main = ($args{title} ? $args{title} : "$args{table} $split_col");
    my %page_links = ();

    my $si_template = ($args{split_ind_template}
		       ? $args{split_ind_template}
		       : '<a href="{$link}">{$label}</a>'
		      );
    my $si_templ = $self->get_template($si_template);

    # make a page for each split-value
    my %where = %{$args{where}};
    for (my $i = 0; $i < @split_vals; $i++)
    {
	my $val = $split_vals[$i];
	$val = '' if !$val;
	my $niceval = $val;
	$niceval = $self->{_tobj}->convert_value(value=>$val,
					format=>$self->{default_format}->
					{$args{table}}->{$split_col},
					name=>$split_col)
	    if ($self->{default_format}->{$args{table}}->{$split_col});

	my $valbase = $self->{_tobj}->convert_value(value=>$niceval,
	    format=>$args{filename_format}, name=>$split_col);
	warn "val=$val, niceval=$niceval, valbase=$valbase\n" if $args{debug};
	my $outfile = sprintf("%s%s%s",
	    $outfile_prefix, $valbase, $outfile_suffix);
	my $outfile_link = sprintf("%s%s%s",
	    $outfile_prefix, $valbase, $link_suffix);

	# previous values
	my $prev_val = '';
	my $prev_niceval = '';
	my $prev_file = '';
	if ($i > 0)
	{
	    $prev_val = $split_vals[$i-1];
	    $prev_niceval = $prev_val;
	    $prev_niceval = $self->{_tobj}->convert_value(value=>$prev_val,
						 format=>$self->{default_format}->
						 {$args{table}}->{$split_col},
						 name=>$split_col)
		if ($self->{default_format}->{$args{table}}->{$split_col});
	    my $prev_valbase = $self->{_tobj}->convert_value(value=>$prev_niceval,
						    format=>$args{filename_format},
						    name=>$split_col);
	    $prev_file = sprintf("%s%s%s",
				 $outfile_prefix,
				 $prev_valbase, $link_suffix);
	}

	# next values
	my $next_val = '';
	my $next_niceval = '';
	my $next_file = '';
	if ($i < (@split_vals - 1))
	{
	    $next_val = $split_vals[$i+1];
	    $next_niceval = $next_val;
	    $next_niceval = $self->{_tobj}->convert_value(value=>$next_val,
						 format=>$self->{default_format}->
						 {$args{table}}->{$split_col},
						 name=>$split_col)
		if ($self->{default_format}->{$args{table}}->{$split_col});
	    my $next_valbase = $self->{_tobj}->convert_value(value=>$next_niceval,
						    format=>$args{filename_format},
						    name=>$split_col);
	    $next_file = sprintf("%s%s%s",
				 $outfile_prefix,
				 $next_valbase,
				 $link_suffix);
	}

	if ($val and $args{split_alpha})
	{
	    # starts with the value
	    $where{$split_col} = $val . '*';
	}
	else
	{
	    $where{$split_col} = $val;
	}
	my $prev_label = "&lt; $prev_niceval";
	$prev_label =~ s/ & / &amp; /g;
	my $next_label = "$next_niceval -&gt;";
	$next_label =~ s/ & / &amp; /g;
	my $mtitle = "$split_col: $niceval";
	if ($args{split_titlefmt})
	{
	    $mtitle = $args{split_titlefmt};
	    $mtitle =~ s/SPLIT_COL/$split_col/g;
	    $mtitle =~ s/VALUE/$niceval/g;
	}
	if ($self->do_multi_page_report(%args,
	    outfile=>$outfile,
	    prev_file=>$prev_file,
	    prev_label=>$prev_label,
	    next_file=>$next_file,
	    next_label=>$next_label,
	    where=>\%where,
	    title=>$mtitle))
	{
	    print STDERR "$outfile\n" if $args{verbose};
	    if ($val)
	    {
		my $label = $val;
		if ($niceval ne $val)
		{
		    $label = $niceval;
		}
		if ($label =~ / & /)
		{
		    # filter out some HTML stuff
		    $label =~ s/ & / &amp; /g;
		}
		my %si_hash = (
		    link=>$outfile_link,
		    label=>$label,
		);
		$page_links{$val} =
		    $self->{_tobj}->fill_in(data_hash=>\%si_hash,
					    template=>$si_templ);
	    }
	    else
	    {
		my %si_hash = (
		    link=>$outfile_link,
		    label=>"$split_col (none)",
		);
		$page_links{''} =
		    $self->{_tobj}->fill_in(data_hash=>\%si_hash,
					    template=>$si_templ);
	    }
	}
    }

    #
    # build the index page
    #
    my $ind_contents = '';

    if ($two_level_ind)
    {
	# find out all the alphas in the links
	my %page_alphas = ();
	foreach my $val (keys %page_links)
	{
	    my $a1 = substr(($val||''), 0, ($split_alpha ? $split_alpha : 1));
	    $a1 = uc($a1);
	    $page_alphas{$a1} = 1;
	}
	$ind_contents .= "<p>";
	my @links = ();
	foreach my $a (sort keys %page_alphas)
	{
	    push @links, "<a href='#${a}'>$a</a>" if $a;
	}
	$ind_contents .= join(' | ', @links);
	$ind_contents .= "</p>\n<hr/>\n";
    }
    elsif ($split_alpha)
    {
	$ind_contents .= "<p>";
    }
    else
    {
	$ind_contents .= "<ul>";
    }
    my $prev_a = undef;
    foreach my $indval (sort keys %page_links)
    {
	my $link = $page_links{$indval};
	my $a1 = substr($indval, 0, 1);
	if ($two_level_ind and (!defined $prev_a or $a1 ne $prev_a))
	{
	    if (defined $prev_a)
	    {
		$ind_contents .= "</ul>\n";
	    }
	    $ind_contents .= "<h2 id='$a1'>$a1</h2>\n" if $a1;
	    $ind_contents .= "<ul>";
	    $prev_a = $a1;
	}
	$ind_contents .= ($split_alpha ? ' ' : '<li>');
	$ind_contents .= $link;
	$ind_contents .= ($split_alpha ? ' ' : "</li>\n");
    }
    $ind_contents .= ($split_alpha ? "</p>\n" : "</ul>\n");

    # and make the index page
    my $out = $self->get_template($self->{index_template});
    $self->{index_template} = $out;
    $out =~ s/<!--sqlr_title-->/$title_main/g;
    $out =~ s/<!--sqlr_contents-->/$ind_contents/g;
    my $index_file = sprintf("%s%s%s",
			  $outfile_prefix, $split_col, $outfile_suffix);
    my $fh;
    open($fh, ">", $index_file)
	or die "Could not open $index_file for writing";
    print $fh $out;
    close($fh);
    print STDERR "$index_file\n" if $args{verbose};

} # do_split_report

=head2 get_total_matching

    $rep->get_total_matching(
	table=>$table,
	where=>\%where,
	not_where=>\%not_where,
    );

Get the total number of rows which match the selection
criteria.

See L<do_report> for the meaning of the arguments.

=cut
sub get_total_matching {
    my $self = shift;
    my %args = (
	table=>undef,
	not_where=>{},
	where=>{},
	@_
    );
    my $table = $args{table};

    # build up the query data
    my @where = $self->build_where_conditions(%args,
	where=>$args{where}, not_where=>$args{not_where});
    
    my $total_query = "SELECT COUNT(*) FROM $table";
    if (@where)
    {
	$total_query .= " WHERE " . join(" AND ", @where);
    }
    # get total of the result as if there was no LIMIT
    my $tot_sth = $self->{dbh}->prepare($total_query);
    if (!$tot_sth)
    {
	$self->print_message("Can't prepare query $total_query: $DBI::errstr");
	return 0;
    }
    my $rv = $tot_sth->execute();
    if (!$rv)
    {
	$self->print_message("Can't execute query $total_query: $DBI::errstr");
	return 0;
    }
    my $total = 0;
    my @row;
    while (@row = $tot_sth->fetchrow_array)
    {
	$total = $row[0];
    }
    return $total;

} # get_total_matching

=head2 update_one_row

    if ($rep->update_one_field(
	table=>$table,
	row_id=>$row_id,
	field=>$field,
	update_values=>\%values,
    ))
    {
	...
    }

Update one row; either a single column, or the whole row.
Returns 0 if failure, or the constructed update query if
success (so that one can be informative).

Sets $rep->{message} with a success message if successful.

=cut
sub update_one_row {
    my $self = shift;
    my %args = (
	table=>'',
	command=>'Update',
	row_id=>undef,
	field=>'',
	update_values=>{},
	@_
    );

    my $table = $args{table};
    my $row_id_name = $self->get_id_colname($table);
    my $row_id = $args{row_id};
    if (!$row_id)
    {
	$self->print_message("Can't update table $table: row-id $row_id_name is NULL");
	return 0;
    }
    my $update_field = $args{field};
    my %update_values = %{$args{update_values}};

    my $update_query = "UPDATE $table SET ";
    my @assignments = ();
    foreach my $ufield (keys %update_values)
    {
	if ($update_values{$ufield} eq 'NULL')
	{
	    push @assignments, "$ufield = NULL";
	}
	elsif ($self->col_is_int(table=>$table, column=>$ufield))
	{
	    push @assignments, "$ufield = ".
		($update_values{$ufield} ? $update_values{$ufield} : '0');
	}
	else
	{
	    push @assignments, "$ufield = ". 
		$self->{dbh}->quote($update_values{$ufield});
	}
    }
    $update_query .= join(', ', @assignments);
    $update_query .= " WHERE $row_id_name = $row_id";
    
    # actual update
    my $rv = $self->{dbh}->do($update_query);
    if (!$rv)
    {
	$self->print_message("Can't execute update $update_query: $DBI::errstr");
	return 0;
    }
    $self->{message} = "SUCCESS: $update_query";
    return 1;

} # update_one_row

=head2 add_one_row

    if ($rep->add_one_row(
	table=>$table,
	add_values=>\%values)) { ...
    }

Add a row to a table.

Sets $rep->{message} with a success message if successful.

=cut
sub add_one_row {
    my $self = shift;
    my %args = (
	table=>'',
	add_values=>{},
	@_
    );

    my $table = $args{table};
    my %add_vals = %{$args{add_values}};
    my @columns = $self->get_colnames($table, do_rowid=>0);
    my $row_id_name = $self->get_id_colname($table);

    my $iquery = "INSERT INTO $table (";
    $iquery .= join(', ', @columns);
    $iquery .= ") VALUES (";
    my @vals = ();
    foreach my $col (@columns)
    {
	my $val = $add_vals{$col};
	if (!defined $val or $val eq 'NULL')
	{
	    push @vals, 'NULL';
	}
	elsif ($col eq $row_id_name)
	{
	    # if we are adding, this value needs to be null
	    push @vals, 'NULL';
	}
	else
	{
	    if ($self->col_is_int(table=>$table, column=>$col))
	    {
		push @vals, ($val ? $val : '0');
	    }
	    else
	    {
		# correct quotes
		push @vals, $self->{dbh}->quote($val);
	    }
	}
    }
    $iquery .= join(',', @vals);
    $iquery .= ")";
    
    # actual update
    my $rv = $self->{dbh}->do($iquery);
    if (!$rv)
    {
	$self->print_message("Can't execute insert $iquery: $DBI::errstr");
	return 0;
    }
    $self->{message} = "SUCCESS: " . $iquery;
    return 1;

} # add_one_row

=head2 delete_one_row

    if ($rep->delete_one_row(
	table=>$table,
	row_id=>$row_id)) { ...
    }

Delete a single row.

Sets $rep->{message} with a success message if successful.

=cut
sub delete_one_row {
    my $self = shift;
    my %args = (
	table=>'',
	row_id=>undef,
	@_
    );

    my $table = $args{table};
    my $row_id_name = $self->get_id_colname($table);
    my $row_id = $args{row_id};
    if (!$row_id)
    {
	$self->print_message("Can't delete from table $table: row-id $row_id_name is NULL");
	return 0;
    }
    my $dquery = "DELETE FROM $table WHERE $row_id_name = $row_id";
    
    # actual update
    my $rv = $self->{dbh}->do($dquery);
    if (!$rv)
    {
	$self->print_message("Can't execute update $dquery: $DBI::errstr");
	return 0;
    }
    $self->{message} = "SUCCESS: " . $dquery;
    return 1;

} # delete_one_row

=head2 do_import_fv

    if ($rep->do_import_fv(
	table=>$table,
	datafile=>$filename,
	row_delim=>"=")) { ...
    }

Import a field:value file into the given table.
Field names are taken from the table; rows not starting
with a field name "Field:" are taken to be a continuation
of the previous field value.

Rows are delimited by the given row_delim argument on a line
by itself.

Returns the number of records imported.

=cut
sub do_import_fv {
    my $self = shift;
    my %args = (
	table=>'',
	datafile=>'',
	row_delim=>"=",
	@_
    );

    my $table = $args{table};
    my $row_delim = $args{row_delim};
    my $datafile = $args{datafile};

    if (!-r $datafile)
    {
	warn "cannot read $datafile";
	return 0;
    }
    my $fh;
    open($fh, $datafile)
	or die "cannot open $datafile";

    my $count = 0;
    # get the legal column names
    my @columns = $self->get_colnames($table,
	do_rowid=>0);
    my %legal_cols = ();
    foreach my $col (@columns)
    {
	$legal_cols{$col} = 1;
    }

    my %vals = ();
    my $cur_field;
    while (<$fh>)
    {
	chomp;
	if (/^$row_delim$/)
	{
	    if (!$self->add_one_row(table=>$table,
				  add_values=>\%vals))
	    {
		warn "failed to add row -- aborting\n";
		return 0;
	    }
	    $count++;
	    %vals = ();
	}
	elsif (/^(\w+):(.*)/)
	{
	    my $fn = $1;
	    my $v1 = $2;
	    if ($legal_cols{$fn})
	    {
		# is a new value
		$cur_field = $fn;
		$vals{$cur_field} = $v1;
	    }
	    else
	    {
		# is continuation
		$vals{$cur_field} .= "\n$_";
	    }
	}
	else
	{
	    $vals{$cur_field} .= "\n$_";
	}
    }
    return $count;

} # do_import_fv

=head1 Helper Methods

Lower-level methods, generally just called from other methods,
but possibly suitable for other things.

=head2 print_message

Print an (error) message to the user.

$self->print_message($message); # error message

$self->print_message($message, 0); # non-error message

(here so that it can be overridden, say, for a CGI script)

=cut
sub print_message {
    my $self = shift;
    my $message = shift;
    my $is_error = (@_ ? shift : 1); # assume error message

    if ($is_error)
    {
	warn $message, "\n";
    }
    else
    {
	print $message, "\n";
    }
} # print_message

=head2 make_selections

    my ($sth1, $sth2) = $rep->make_selections(%args);

Make the selection(s) for the matching table(s).

=cut
sub make_selections {
    my $self = shift;
    my %args = (
	table=>undef,
	command=>'Select',
	limit=>0,
	page=>1,
	table2=>'',
	sort_by=>undef,
	not_where=>{},
	where=>{},
	show=>[],
	distinct=>0,
	@_
    );
    my $table = $args{table};
    my $command = $args{command};

    my @sort_by = (!defined $args{sort_by}
	? ()
	: (!ref $args{sort_by}
	    ? split(' ', $args{sort_by})
		: @{$args{sort_by}}));
    my @columns = (@{$args{show}}
	? @{$args{show}}
	: $self->get_colnames($table));
    my $limit = $args{limit};
    my $page = $args{page};
    my $table2 = $args{table2};

    my $row_id_name = $self->get_id_colname($table);
    my $offset = $limit * ($page - 1);
    $offset = 0 if $offset < 0;

    # build up the query data
    my @where = $self->build_where_conditions(%args,
	where=>$args{where}, not_where=>$args{not_where});
    
    my $jquery = '';
    my $join_col = $self->get_join_colname($table, $table2);
    $jquery = "SELECT DISTINCT $join_col FROM $table";
    my $query = "SELECT ";
    if (@columns)
    {
	$query .= "DISTINCT " if $args{distinct};
	$query .= join(", ", @columns);
    }
    else
    {
	$query .= "*";
    }
    $query .= " FROM $table";
    if (@where)
    {
	$query .= " WHERE " . join(" AND ", @where);
	$jquery .= " WHERE " . join(" AND ", @where);
    }
    if (@sort_by)
    {
	my @order_by = ();
	$query .= " ORDER BY ";
	$jquery .= " ORDER BY ";
	foreach my $col (@sort_by)
	{
	    if ($col =~ /^-(.*)/)
	    {
		push @order_by, "$1 DESC";
	    }
	    else
	    {
		push @order_by, $col;
	    }
	}
	$query .= join(', ', @order_by);
	$jquery .= join(', ', @order_by);
    }
    if ($limit)
    {
	$query .= " LIMIT $limit";
	$jquery .= " LIMIT $limit";
    }
    if ($offset)
    {
	$query .= " OFFSET $offset";
	$jquery .= " OFFSET $offset";
    }
    my $total = (defined $args{total}
	? $args{total}
	: $self->get_total_matching(%args));

    # actual query
    my $sth1;
    $sth1 = $self->{dbh}->prepare($query);
    if (!$sth1)
    {
	$self->print_message("Can't prepare query $query: $DBI::errstr");
	return 0;
    }
    my $rv = $sth1->execute();
    if (!$rv)
    {
	$self->print_message("Can't execute query $query: $DBI::errstr");
	return 0;
    }

    # make a "join-like" query of the second table
    # first figure out the correct value of the join field
    # then make the actual query
    my $sth2;
    my $t2query = '';
    if (($total == 1 or $limit == 1)
	and $table2)
    {
	my $sth_jq = $self->{dbh}->prepare($jquery);
	if (!$sth_jq)
	{
	    $self->print_message("Can't prepare query $jquery: $DBI::errstr");
	    return 0;
	}
	my $rv = $sth_jq->execute();
	if (!$rv)
	{
	    $self->print_message("Can't execute query $jquery: $DBI::errstr");
	    return 0;
	}
	my $join_val;
	my @row;
	while (@row = $sth_jq->fetchrow_array)
	{
	    $join_val = $row[0];
	}

	# make the query for the second table
	my @cols2 = $self->get_colnames($table2);
	$t2query = "SELECT ";
	$t2query .= join(', ', @cols2);
	$t2query .= " FROM $table2 ";
	if ($self->col_is_int(table=>$table2, column=>$join_col))
	{
	    $t2query .= "WHERE $join_col = $join_val";
	}
	else
	{
	    $t2query .= "WHERE $join_col = '$join_val'";
	}
	$sth2 = $self->{dbh}->prepare($t2query);
	if (!$sth2)
	{
	    $self->print_message("Can't prepare query $t2query: $DBI::errstr");
	    return 0;
	}
	$rv = $sth2->execute();
	if (!$rv)
	{
	    $self->print_message("Can't execute query $t2query: $DBI::errstr");
	    return 0;
	}
    }
    return ($sth1, $sth2);
} # make_selections

=head2 get_tables

my @tables = $self->get_tables();

my @tables = $self->get_tables(views=>0);

Get the names of the tables (and views) in the database.

=cut
sub get_tables {
    my $self = shift;
    my %args = (
	views=>1,
	@_
    );

    my @tables = ();
    my $query = "SELECT name from sqlite_master ";
    if ($args{views})
    {
	$query .= "WHERE type = 'table' OR type = 'view'";
    }
    else
    {
	$query .= "WHERE type = 'table'";
    }
    my $sth = $self->{dbh}->prepare($query);
    if (!$sth)
    {
	$self->print_message("Can't prepare query $query: $DBI::errstr");
	return 0;
    }
    my $rv = $sth->execute();
    if (!$rv)
    {
	$self->print_message("Can't execute query $query: $DBI::errstr");
	return 0;
    }
    my @row;
    while (@row = $sth->fetchrow_array)
    {
	push @tables, $row[0];
    }
    return @tables;
} # get_tables

=head2 get_colnames

my @columns = $self->get_colnames($table);

my @columns = $self->get_colnames($table, do_rowid=>0);

Get the column names of the given table.

=cut
sub get_colnames {
    my $self = shift;
    my $table = shift;
    my %args = (
	do_rowid=>1,
	@_
    );

    my @columns = ($args{do_rowid}
	? ($self->get_id_colname($table) eq 'rowid' ? qw(rowid) : () )
	: ());
    my $query = "PRAGMA table_info('$table')";
    my $sth = $self->{dbh}->prepare($query);
    if (!$sth)
    {
	$self->print_message("Can't prepare query $query: $DBI::errstr");
	return 0;
    }
    my $rv = $sth->execute();
    if (!$rv)
    {
	$self->print_message("Can't execute query $query: $DBI::errstr");
	return 0;
    }
    my $row_hash;
    while ($row_hash = $sth->fetchrow_hashref)
    {
	push @columns, $row_hash->{'name'};
    }

    return @columns;
} # get_colnames

=head2 get_distinct_col

    @vals = $rep->get_distinct_col(
	table=>$table,
	colname=>$colname,
	where=>\%where,
	not_where=>\%not_where,
    );

Get all the distinct values for the given column
(which match the selection criteria).

=cut
sub get_distinct_col {
    my $self = shift;
    my %args = (
	table=>undef,
	colname=>'',
	not_where=>{},
	where=>{},
	@_
    );
    my $table = $args{table};
    my $colname = $args{colname};

    # build up the query data
    my @where = $self->build_where_conditions(%args,
	where=>$args{where}, not_where=>$args{not_where});
    
    my $query = "SELECT DISTINCT $colname FROM $table";
    if (@where)
    {
	$query .= " WHERE " . join(" AND ", @where);
    }
    $query .= " ORDER BY $colname";
    my $sth = $self->{dbh}->prepare($query);
    if (!$sth)
    {
	$self->print_message("Can't prepare query $query: $DBI::errstr");
	return 0;
    }
    my $rv = $sth->execute();
    if (!$rv)
    {
	$self->print_message("Can't execute query $query: $DBI::errstr");
	return 0;
    }
    my @vals = ();
    my @row;
    while (@row = $sth->fetchrow_array)
    {
	push @vals, $row[0];
    }
    return @vals;
} # get_distinct_col

=head1 Private Methods

=head2 print_select

Print a selection result.

=cut
sub print_select {
    my $self = shift;
    my $sth = shift;
    my $sth2 = shift;
    my %args = (
	table=>'',
	title=>'',
	command=>'Search',
	prev_file=>'',
	prev_label=>'Prev',
	next_file=>'',
	next_label=>'Next',
	prev_next_template=>'',
	@_
    );
    my @columns = @{$args{columns}};
    my $table = $args{table};
    my $page = $args{page};

    # read the template
    my $template = $self->get_template($self->{report_template});
    $self->{report_template} = $template;

    my $num_pages = ($args{limit} ? ceil($args{total} / $args{limit}) : 1);
    # generate the HTML table
    my $count = 0;
    my $res_tab = '';
    ($count, $res_tab) = $self->format_report($sth,
	%args,
	table=>$table,
	table2=>$args{table2},
	columns=>\@columns,
	sort_by=>$args{sort_by},
	num_pages=>$num_pages,
	);
    my $main_title = ($args{title} ? $args{title}
	: "$table $args{command} result");
    my $title = ($args{limit} ? "$main_title ($page)"
	: $main_title);
    # fix up random apersands
    if ($title =~ / & /)
    {
	$title =~ s/ & / &amp; /g;
    }
    my @result = ();
    push @result, $res_tab;
    push @result, "<p>$count rows displayed of $args{total}.</p>\n"
	if ($args{report_style} ne 'bare'
	    and $args{report_style} ne 'compact');
    if ($args{limit} and $args{report_style} eq 'full')
    {
	push @result, "<p>Page $page of $num_pages.</p>\n"
    }
    if (defined $sth2)
    {
	my @cols2 = $self->get_colnames($args{table2});
	my $count2;
	my $tab2;
	($count2, $tab2) = $self->format_report($sth2,
						%args,
						table=>$args{table2},
						columns=>\@cols2,
						sort_by=>\@cols2,
						headers=>[],
						groups=>[],
						row_template=>'',
						num_pages=>0,
					       );
	if ($count2)
	{
	    push @result,<<EOT;
<h2>$args{table2}</h2>
$tab2
<p>$count2 rows displayed from $args{table2}.</p>
EOT
	}
    }

    # prepend the message
    unshift @result, "<p><i>$self->{message}</i></p>\n", if $self->{message};

    # append the prev-next links, if any
    if ($args{prev_file} or $args{next_file})
    {
	my $prev_label = $args{prev_label};
	my $next_label = $args{next_label};
	my %pn_hash = (
		       prev_file => $args{prev_file},
		       prev_label => $prev_label,
		       next_file => $args{next_file},
		       next_label => $next_label,
		      );
	my $pn_template = ($args{prev_next_template}
			   ? $args{prev_next_template}
			   : '<hr/>
			   <p>{?prev_file <a href="[$prev_file]">[$prev_label]</a>}
			   {?next_file <a href="[$next_file]">[$next_label]</a>}
			   </p>
			   '
			  );
	my $pn_templ = $self->get_template($pn_template);
	my $pn_str = $self->{_tobj}->fill_in(data_hash=>\%pn_hash,
					     template=>$pn_templ);
	push @result, $pn_str;
    }

    my $contents = join('', @result);
    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$contents/g;
    # Now print the page for the user to see...
    if (!defined $args{outfile} 
	or $args{outfile} eq ''
	or $args{outfile} eq '-')
    {
	print $out;
    }
    else
    {
	my $fh;
	open($fh, ">", $args{outfile})
	    or die "Could not open $args{outfile} for writing";
	print $fh $out;
	close($fh);
    }
} # print_select

=head2 get_template

my $templ = $self->get_template($template);

Get the given template (read if it's from a file)

=cut
sub get_template {
    my $self = shift;
    my $template = shift;

    if ($template !~ /\n/
	&& -r $template)
    {
	local $/ = undef;
	my $fh;
	open($fh, $template)
	    or die "Could not open ", $template;
	$template = <$fh>;
	close($fh);
    }
    return $template;
} # get_template

=head2 get_id_colname

$id_colname = $self->get_id_colname($table);

Get the name of the column which is used for row-identification.
(Most of the time it is just 'rowid')

=cut
sub get_id_colname {
    my $self = shift;
    my $table = shift;

    if (exists $self->{row_ids}->{$table}
	and defined $self->{row_ids}->{$table})
    {
	return $self->{row_ids}->{$table};
    }
    return 'rowid';
} # get_id_colname

=head2 get_join_colname

$join_col = $self->get_join_colname($table1, $table2);

Get the name of the column which is used to join these two tables.

=cut
sub get_join_colname {
    my $self = shift;
    my $table = shift;
    my $table2 = shift;

    my $key1 = "$table+$table2";
    my $key2 = "$table2+$table";
    if (exists $self->{join_cols}->{$key1}
	and defined $self->{join_cols}->{$key1})
    {
	return $self->{join_cols}->{$key1};
    }
    elsif (exists $self->{join_cols}->{$key2}
	and defined $self->{join_cols}->{$key2})
    {
	return $self->{join_cols}->{$key2};
    }
    return 'rowid';
} # get_join_colname

=head2 col_is_int

my $res = $self->col_is_int(table=>$table, column=>$column);

Checks the column type of the given column in the given table;
returns true if it is an integer type.

=cut
sub col_is_int {
    my $self = shift;
    my %args = (
	table=>'',
	column=>'rowid',
	@_
    );
    my $table = $args{table};
    my $column = $args{column};

    my $query = "PRAGMA table_info('$table')";
    my $sth = $self->{dbh}->prepare($query);
    if (!$sth)
    {
	$self->print_message("Can't prepare query $query: $DBI::errstr");
	return 0;
    }
    my $rv = $sth->execute();
    if (!$rv)
    {
	$self->print_message("Can't execute query $query: $DBI::errstr");
	return 0;
    }
    my $row_hash;
    while ($row_hash = $sth->fetchrow_hashref)
    {
	if ($row_hash->{name} eq $column)
	{
	    if ($row_hash->{type} =~ /character/)
	    {
		return 0;
	    }
	    elsif ($row_hash->{type} =~ /integer/)
	    {
		return 1;
	    }
	    elsif ($row_hash->{type} =~ /smallint/)
	    {
		return 1;
	    }
	}
    }

    return 0;
} # col_is_int

=head2 format_report

$my report = $self->format_report(
	table=>$table,
	command=>'Search',
	columns=>\@columns,
	force_show_cols=>\%force_show_cols,
	sort_by=>\@sort_by,
	headers=>\@headers,
	header_start=>1,
	table2=>$table2,
	layout=>'table',
	row_template=>$row_template,
	report_style=>'compact',
	table_header=>$thead,
	table_border=>1,
	table_class=>'plain',
	truncate_colnames=>0,
    );

Construct a HTML result table

=cut
sub format_report {
    my $self = shift;
    my $sth = shift;
    my %args = (
	table=>'',
	command=>'Search',
	layout=>'table',
	row_template=>'',
	report_style=>'full',
	table_header=>'',
	force_show_cols=>{},
	@_
    );
    my @columns = @{$args{columns}};
    my @sort_by = (!defined $args{sort_by}
	? ()
	: (!ref $args{sort_by}
	    ? split(' ', $args{sort_by})
		: @{$args{sort_by}}));
    my @headers = @{$args{headers}};
    my $header_start = $args{header_start} || 1;
    my @groups = @{$args{groups}};
    my %force_show_cols = %{$args{force_show_cols}};
    my $command = $args{command};
    my $table = $args{table};
    my $table2 = $args{table2};
    my $report_style = $args{report_style};
    my $table_border = $args{table_border};
    my $table_class = $args{table_class};
    my $truncate_colnames = $args{truncate_colnames};

    # change things depending on report_style
    if (!defined $table_border)
    {
	if ($report_style eq 'bare')
	{
	    $table_border = 0;
	}
	else
	{
	    $table_border = 1;
	}
    }
    if (!defined $table_class)
    {
	if ($report_style eq 'bare')
	{
	    $table_class = '';
	}
	else
	{
	    $table_class = 'plain';
	}
    }
    if (!defined $truncate_colnames)
    {
	if ($report_style eq 'full')
	{
	    $truncate_colnames = 0;
	}
	elsif ($report_style eq 'medium')
	{
	    $truncate_colnames = 6;
	}
	elsif ($report_style eq 'compact')
	{
	    $truncate_colnames = 4;
	}
	else
	{
	    $truncate_colnames = 0;
	}
    }

    my @out = ();
    my $count = 0;
    my $row_id_name = $self->get_id_colname($table);
    my $row_id_ind;
    # by default, show all columns
    my %show_cols = ();
    for (my $i = 0; $i < @columns; $i++)
    {
	$show_cols{$columns[$i]} = 1;
	if ($columns[$i] eq $row_id_name)
	{
	    $row_id_ind = $i;
	}
    }

    # make headers for all the headers
    # set the headers and entry columns
    my %prev_head = ();
    if (@sort_by and @headers)
    {
        for (my $i=0; $i < @headers && $i < @sort_by; $i++)
	{
	    $prev_head{$i} = '';
	    # read each header template if it's a file
	    $headers[$i] = $self->get_template($headers[$i]);
            # read each 'group' template if the template is a file
            if (@groups and exists $groups[$i] and defined $groups[$i])
            {
		$groups[$i] = $self->get_template($groups[$i]);
            }
        }

	# find out what fields are in the headers and groups
        my %in_header = ();
	my $all_headers = join('', @headers, @groups);
	while ($all_headers =~ m/{\$(\w+)[:\w]*}/)
	{
	    $in_header{$1} = 1;
	    $all_headers =~ s/{\$\w+[:\w]*}//;
	}
	while ($all_headers =~ m/\[\$(\w+)[:\w]*\]/)
	{
	    $in_header{$1} = 1;
	    $all_headers =~ s/\[\$\w+[:\w]*\]//;
	}
	for my $col (@columns)
	{
	    if ($in_header{$col} && !$force_show_cols{$col})
	    {
		$show_cols{$col} = 0;
	    }
	}
    }
    #
    # Set the nicer column name labels
    my %nice_cols = $self->set_nice_cols(truncate_colnames=>$truncate_colnames,
	columns=>\@columns);

    my $row_template = $self->get_row_template(
	table=>$table,
	row_template=>$args{row_template},
	layout=>$args{layout},
	report_style=>$args{report_style},
	columns=>\@columns,
	show_cols=>\%show_cols,
	nice_cols=>\%nice_cols);
    my $thead = $self->get_template($args{table_header});
    if (%nice_cols and !$thead)
    {
	$thead .= '<thead><tr>';
	foreach my $col (@columns)
	{
	    if ($show_cols{$col})
	    {
		my $nicecol = $nice_cols{$col};
		$thead .= "<th>$nicecol</th>";
	    }
	}
	$thead .= "</tr></thead>\n";
    }

    my $page = ((defined $args{num_pages} and $args{num_pages} > 1)
	? $args{page} : 0);
    # process the rows
    my $new_section = 1;
    my $row_hash;
    while ($row_hash = $sth->fetchrow_hashref)
    {
	# add the page-number to the data
	$row_hash->{_page} = $page;
	$row_hash->{_num_pages} = $args{num_pages};
	if (@headers)
	{
	    for (my $hi = 0; $hi < @headers; $hi++)
	    {
		my $hval = $headers[$hi];
		$hval = '' if !$hval;
		$hval =~ s/{([^}]+)}/$self->{_tobj}->do_replace(data_hash=>$row_hash,targ=>$1)/eg;
		my $gval = $groups[$hi];
		$gval = '' if !$gval;
		$gval =~ s/{([^}]+)}/$self->{_tobj}->do_replace(data_hash=>$row_hash,targ=>$1)/eg;
		if ($hval
		    and $hval ne $prev_head{$hi})
		{
		    if ($count != 0 && !$new_section)
		    {
			push @out, $self->end_section(type=>$args{layout});
			$new_section = 1;
		    }
		    # only make a header if it has content
		    push @out, sprintf("<h%d>%s</h%d>\n",
				       $hi + $header_start, $hval, $hi + $header_start)
					if $hval;
		    # and group content, if there is any
		    push @out, "<p>$gval</p>\n", if $gval;
		    $prev_head{$hi} = $hval;
		}
	    }
	}
	if ($new_section)
	{
	    push @out, $self->start_section(type=>$args{layout},
					  table_border=>$table_border,
                                          table_class=>$table_class);
	    if ($report_style ne 'bare'
		and $args{layout} eq 'table')
	    {
		push @out, $thead;
	    }
	    $new_section = 0;
	}
	my $rowstr = $row_template;
	$rowstr =~ s/{([^}]+)}/$self->{_tobj}->do_replace(data_hash=>$row_hash,show_names=>\%show_cols,targ=>$1)/eg;
	push @out, $rowstr;
	$count++;
    } # for each row
    push @out, $self->end_section(type=>$args{layout});

    my $out_str = join('', @out);
    return ($count, $out_str);
} # format_report

=head2 get_row_template

    $row_template = $self->get_row_template(
	table=>$table,
	row_template=>$rt,
	layout=>'table',
	columns=>\@columns,
	show_cols=>\%show_cols,
	nice_cols=>\%nice_cols,
    );

Get or set or create the row template.

=cut
sub get_row_template {
    my $self = shift;
    my %args = (
	table=>'',
	row_template=>'',
	layout=>'table',
	report_style=>'full',
	columns=>undef,
	show_cols=>undef,
	nice_cols=>undef,
	@_
    );

    my $row_template = $args{row_template};
    # read in the file if it's a file
    if ($row_template !~ /\n/ && -r $row_template)
    {
	my $fh;
	open($fh, $row_template)
	    or die "could not open $row_template: $!";
	local $/;
	$row_template = <$fh>;
	close($fh);
    }
    if (!$row_template)
    {
	my @rt = ();
	if ($args{layout} eq 'table')
	{
	    push @rt, "<tr>";
	    foreach my $col (@{$args{columns}})
	    {
		if ($args{show_cols}->{$col})
		{
		    push @rt, "<td>{?$col [\$$col";
		    push @rt, ':',
			$self->{default_format}->{$args{table}}->{$col}
			if ($self->{default_format}->{$args{table}}->{$col});
		    push @rt, "]!!&nbsp;}</td>\n";
		}
	    }
	    push @rt, "</tr>\n";
	}
	elsif ($args{layout} eq 'para')
	{
	    push @rt, "<p>";
	    foreach my $col (@{$args{columns}})
	    {
		if ($args{show_cols}->{$col})
		{
		    if ($args{report_style} ne 'bare')
		    {
			push @rt, "{?$col <strong>";
			push @rt, $args{nice_cols}->{$col};
			push @rt, ":</strong> ";
		    }
		    push @rt, "[\$";
		    push @rt, $col;
		    push @rt, ':',
			$self->{default_format}->{$args{table}}->{$col}
			if ($self->{default_format}->{$args{table}}->{$col});
		    push @rt, "]<br/>}\n";
		}
	    }
	    push @rt, "</p>\n";
	}
	elsif ($args{layout} eq 'list')
	{
	    push @rt, "<li>";
	    foreach my $col (@{$args{columns}})
	    {
		if ($args{show_cols}->{$col})
		{
		    push @rt, "{\$$col";
		    push @rt, ':',
			$self->{default_format}->{$args{table}}->{$col}
			if ($self->{default_format}->{$args{table}}->{$col});
		    push @rt, "}\n";
		}
	    }
	    push @rt, "</li>\n";
	}
	elsif ($args{layout} eq 'fieldval')
	{
	    # field:value
	    foreach my $col (@{$args{columns}})
	    {
		if ($args{show_cols}->{$col})
		{
		    push @rt, "$col:{\$$col";
		    push @rt, ':',
			$self->{default_format}->{$args{table}}->{$col}
			if ($self->{default_format}->{$args{table}}->{$col});
		    push @rt, "}\n";
		}
	    }
	    push @rt, "=\n";
	}
	elsif ($args{layout} eq '' or $args{layout} eq 'none')
	{
	    # one value on each line, no HTML
	    foreach my $col (@{$args{columns}})
	    {
		if ($args{show_cols}->{$col})
		{
		    push @rt, "{\$$col";
		    push @rt, ':',
			$self->{default_format}->{$args{table}}->{$col}
			if ($self->{default_format}->{$args{table}}->{$col});
		    push @rt, "}\n";
		}
	    }
	}
	$row_template = join('', @rt);
    }

    return $row_template;
} # get_row_template

=head2 set_nice_cols

    %nice_cols = $self->set_nice_cols(
	truncate_colnames=>0,
	columns=>\@columns);

=cut
sub set_nice_cols {
    my $self = shift;
    my %args = (
	columns=>[],
	truncate_colnames=>0,
	@_
    );
    my $truncate_colnames = $args{truncate_colnames};

    # Set the nicer column name labels
    my %nice_cols = ();
    foreach my $col (@{$args{columns}})
    {
	my $nicecol = $col;
	if ($truncate_colnames)
	{
	    my @colwords = split('_', $nicecol);
	    foreach my $cw (@colwords)
	    {
		$cw = $self->{_tobj}->convert_value(value=>$cw,
		    format=>"trunc${truncate_colnames}",
		    name=>$col);
		$cw = $self->{_tobj}->convert_value(value=>$cw,
		    format=>'proper',
		    name=>$col);
	    }
	    $nicecol = join(' ', @colwords);
	}
	else
	{
	    $nicecol =~ s/_/ /g;
	    $nicecol = $self->{_tobj}->convert_value(value=>$nicecol,
		format=>'proper', name=>$col);
	}
	$nice_cols{$col} = $nicecol;
    }
    return %nice_cols;
} # set_nice_cols

=head2 start_section

$sect = $self->start_section(type=>'table',
    table_border=>$table_border,
    table_class=>$table_class);

Start a new table/para/list
The 'table_border' option is the border-size of the table
if using table style
The 'table_class' option is the class of the table
if using table style

=cut
sub start_section {
    my $self = shift;
    my %args = (
	type=>'table',
	table_border=>1,
	@_
    );

    if ($args{type} eq 'table')
    {
        return sprintf('<table%s%s>',
                       ($args{table_border} ? ' border="' . $args{table_border} . '"' : ''),
                       ($args{table_class} ? ' class="' . $args{table_class} . '"' : ''));
    }
    elsif ($args{type} eq 'para')
    {
	return '';
    }
    elsif ($args{type} eq 'list')
    {
	return "<ul>\n";
    }
    '';
} # start_section

=head2 end_section

$sect = $self->end_section(type=>'table');

End an old table/para/list

=cut
sub end_section {
    my $self = shift;
    my %args = (
	type=>'table',
	@_
    );

    if ($args{type} eq 'table')
    {
	return "</table>\n";
    }
    elsif ($args{type} eq 'para')
    {
	return "\n";
    }
    elsif ($args{type} eq 'list')
    {
	return "\n</ul>\n";
    }
    '';
} # end_section

=head2 build_where_conditions

Take the %where, %not_where hashes and make an array of SQL conditions.

    @where = $self->build_where_conditions(where=>\%where,
	not_where=>\%not_where);

=cut
sub build_where_conditions {
    my $self = shift;
    my %args = (
	not_where=>{},
	where=>{},
	@_
    );

    my @where = ();
    while (my ($col, $val) = each(%{$args{where}}))
    {
	if (!defined $val or $val eq 'NULL')
	{
	    if ($args{not_where}->{$col})
	    {
		push @where, "$col IS NOT NULL";
	    }
	    else
	    {
		push @where, "$col IS NULL";
	    }
	}
	elsif (!$val or $val eq "''")
	{
	    if ($args{not_where}->{$col})
	    {
		push @where, "$col != ''";
	    }
	    else
	    {
		push @where, "$col = ''";
	    }
	}
	else
	{
	    if ($args{not_where}->{$col})
	    {
		push @where, "$col NOT GLOB " . $self->{dbh}->quote($val);
	    }
	    else
	    {
		push @where, "$col GLOB " . $self->{dbh}->quote($val);
	    }
	}
    }
    return @where;
} # build_where_conditions

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SQLite::Work
__END__
