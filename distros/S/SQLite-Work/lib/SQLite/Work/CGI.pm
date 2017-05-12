package SQLite::Work::CGI;
$SQLite::Work::CGI::VERSION = '0.1601';
use strict;
use warnings;

=head1 NAME

SQLite::Work::CGI - Report and update a SQLite database using CGI

=head1 VERSION

version 0.1601

=head1 SYNOPSIS

    use SQLite::Work::CGI;

    my $obj = SQLite::Work::CGI->new(%args);

=head1 DESCRIPTION

This module is an expansion of SQLite::Work suitable for use
in a CGI script to report and update a SQLite database.

=cut

use CGI;
use POSIX;
use SQLite::Work;

our @ISA = qw(SQLite::Work);

=head1 CLASS METHODS

=head2 new

my $obj = SQLite::Work->new(
    database=>$database_file,
    row_ids=>{
	    episodes=>'title_id',
	},
    join_cols=>{
	    'episodes+recordings'=>'title_id',
	    }
	},
    report_template=>$report_template,
    default_format=>{
	    'episodes' => {
		'title'=>'title',
		'series_title'=>'title',
	    }
	},
    input_format=>{
	    'reviews' => {
		'Review'=>{
		    type=>'textarea',
		    cols=>60,
		    rows=>4,
		}
	    }
    },
    max_sort_fields=>10,
    sort_label=>'Zsort',
    sort_reversed_prefix=>'Zsort_reversed_',
    headers_label=>'Zheader_',
    show_label=>'Zshow',
    where_prefix=>'Zwhere_',
    not_prefix=>'Znot_',
    );

Make a new report object.

Takes the same arguments as L<SQLite::Work>::new() plus the
following additions:

=over

=item input_format

This contains information about what style of input field
should be used for this particular column in this table.
This is used for the Edit and Add forms.

=item max_sort_fields

The maximum number of sort fields required (default: 10)

=item sort_label

Name of the sort parameter.

=item sort_reversed_prefix

Prefix of the sort-reversed parameters.

=item headers_label

Name of the headers parameter.

=item show_label

Name of the columns-to-show parameter.

=item where_prefix

Prefix of the 'where' parameters.

=item not_prefix

Prefix of the not-where parameters.

=back

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = SQLite::Work->new(%parameters);

    # CGI-related defaults
    $self->{max_sort_fields} = 10;
    $self->{max_headers} = 4;
    $self->{sort_label} ||= 'Zsort';
    $self->{sort_reversed_prefix} ||= 'Zsort_reversed_';
    $self->{headers_label} ||= 'Zheader';
    $self->{show_label} ||= 'Zshow';
    $self->{where_prefix} ||= 'Zwhere_';
    $self->{not_prefix} ||= 'Znot_';

    my $ldelim = $self->{ldelim};
    my $rdelim = $self->{rdelim};
    $self->{message} = '';

    # this creates a new CGI object which has already parsed the query
    $self->{cgi} = new CGI;
    bless ($self, ref ($class) || $class);
} # new

=head1 OBJECT METHODS

=head2 do_select

$obj->do_select($table,
    command=>'Search');

Select data from a table in the database.
Uses CGI to get most of the parameters.

The 'command' is 'Search' by default; if it is something else,
then the result generated has edit fields and buttons in it.

=cut
sub do_select {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Search',
	outfile=>'',
	@_
    );
    my $command = $args{command};

    my $where_prefix = $self->{where_prefix};
    my $not_prefix = $self->{not_prefix};
    my $show_label = $self->{show_label};
    my $sort_label = $self->{sort_label};
    my $sort_reversed_prefix = $self->{sort_reversed_prefix};
    my $headers_label = $self->{headers_label};
    my @columns = ();
    my %where = ();
    my %not_where = ();
    my @sort_by = ();
    my @sort_r = ();
    my %sort_reverse = ();
    my @headers = ();
    my $limit = $self->{cgi}->param('Limit');
    $limit = 0 if !$limit;
    my $page = $self->{cgi}->param('Page');
    $page = 1 if !$page;
    my $row_id_name = $self->get_id_colname($table);

    # build up the data
    foreach my $pfield ($self->{cgi}->param())
    {
	my $pval = $self->{cgi}->param($pfield);
	if ($pfield eq $show_label)
	{
	    my (@show) = $self->{cgi}->param($pfield);
	    foreach my $scol (@show)
	    {
		# only show non-empty values!
		if ($scol)
		{
		    push @columns, $scol;
		}
	    }
	}
	elsif ($pfield =~ /^${where_prefix}(.*)/o)
	{
	    my $colname = $1;
	    if ($pval)
	    {
		my $not_where_field = "${not_prefix}${colname}";
		$pval =~ m#([^`]*)#;
		my $where_val = $1;
		$where_val =~ s/\s$//;
		$where_val =~ s/^\s//;
		if ($where_val)
		{
		    $where{$colname} = $where_val;
		    if ($self->{cgi}->param($not_where_field))
		    {
			$not_where{$colname} = 1;
		    }
		}
	    }
	}
	elsif ($pfield eq 'Edit_Row')
	{
	    # show the row given in the Edit_Row value
	    if ($pval)
	    {
		$pval =~ m#Edit Row ([\d]+)#;
		my $where_val = $1;
		if ($where_val)
		{
		    $where{$row_id_name} = $where_val;
		}
	    }
	}
	elsif ($pfield eq $sort_label)
	{
	    my (@vals) = $self->{cgi}->param($pfield);
	    foreach my $val (@vals)
	    {
		# only non-empty values!
		if ($val)
		{
		    push @sort_by, $val;
		}
	    }
	}
	elsif ($pfield eq $headers_label)
	{
	    my (@vals) = $self->{cgi}->param($pfield);
	    foreach my $val (@vals)
	    {
		# only non-empty values!
		if ($val)
		{
		    push @headers, $val;
		}
	    }
	}
	elsif ($pfield =~ /^${sort_reversed_prefix}(.*)/o)
	{
	    my $ind = $1;
	    $sort_r[$ind] = ($pval ? 1 : 0);
	}
    }
    @columns = $self->get_colnames($table) if !@columns;
    if (@sort_by)
    {
	for (my $i=0; $i < @sort_r; $i++)
	{
	    if ($sort_r[$i])
	    {
		$sort_reverse{$sort_by[$i]} = 1;
	    }
	}
    }

    $self->do_report(
	table=>$table,
	table2=>($self->{cgi}->param('Table2')
		 ? $self->{cgi}->param('Table2') : ''),
	command=>$command,
	where=>\%where,
	not_where=>\%not_where,
	sort_by=>\@sort_by,
	sort_reversed=>\%sort_reverse,
	show=>\@columns,
	headers=>\@headers,
	limit=>$limit,
	page=>$page,
	report_style=>($self->{cgi}->param('ReportStyle')
	    ? $self->{cgi}->param('ReportStyle') : 'compact'),
	layout=>($self->{cgi}->param('ReportLayout')
		 ? $self->{cgi}->param('ReportLayout') : 'table'),
	outfile=>$args{outfile},
    );

} # do_select

=head2 do_single_update

Update a single column in a single row, or all columns
in a single row.

=cut
sub do_single_update {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Update',
	@_
    );

    my $row_id_name = $self->get_id_colname($table);
    my $row_id = $self->{cgi}->param($row_id_name);
    if (!$row_id)
    {
	$self->print_message("Can't update table $table: row-id $row_id_name is NULL");
	return 0;
    }
    my $update_field = $self->{cgi}->param('Update');
    my %update_values = ();
    if ($update_field eq $row_id_name)
    {
	my @columns = $self->get_colnames($table, do_rowid=>0);
	foreach my $col (@columns)
	{
	    if ($col ne $row_id_name)
	    {
		$update_values{$col} = $self->{cgi}->param($col);
		$update_values{$col} =~ s/\r//g;
	    }
	}
    }
    else # update a single value
    {
	$update_values{$update_field} = $self->{cgi}->param($update_field);
	$update_values{$update_field} =~ s/\r//g;
    }
    if ($self->update_one_row(table=>$table,
			      command=>$args{command},
			      row_id=>$row_id,
			      field=>$update_field,
			      update_values=>\%update_values))
    {
	# display the edit fields again
	$self->{cgi}->param(-name=>"Zwhere_$row_id_name", -value=>$row_id);
	$self->do_select($table, 'Edit');
    }

} # do_single_update

=head2 do_add_form

$obj->do_add_form($table);

Set up for adding a row to the database.

=cut
sub do_add_form {
    my $self = shift;
    my $table = shift;
    my $command = 'Add';

    # read the template
    my $template;
    if ($self->{report_template} !~ /\n/
	&& -r $self->{report_template})
    {
	local $/ = undef;
	my $fh;
	open($fh, $self->{report_template})
	    or die "Could not open ", $self->{report_template};
	$template = <$fh>;
	close($fh);
    }
    else
    {
	$template = $self->{report_template};
    }
    # generate the form
    my $form = $self->make_add_form($table);
    my $title = $command . ' ' . $table;

    # Now print the page for the user to see...
    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$form/g;

    print "Content-Type: text/html\n";
    print "\n";
    print $out;

} # do_add_form

=head2 do_add

Add a row to a table.

=cut
sub do_add {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Add',
	@_
    );

    my @columns = $self->get_colnames($table, do_rowid=>0);
    my $row_id_name = $self->get_id_colname($table);

    my %vals = ();
    foreach my $col (@columns)
    {
	$vals{$col} = $self->{cgi}->param($col);
	$vals{$col} =~ s/\r//g;
    }
    if ($self->add_one_row(
	table=>$table,
	add_values=>\%vals))
    {
	# display the edit fields again
	my $row_id = $self->{dbh}->last_insert_id(undef, undef, $table, undef);
	$self->{cgi}->param(-name=>"Zwhere_$row_id_name", -value=>$row_id);
	$self->do_select($table, 'Edit');
    }

} # do_add

=head2 do_single_delete

Delete a single row.

=cut
sub do_single_delete {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Delete',
	@_
    );

    my $row_id_name = $self->get_id_colname($table);
    my $row_id = $self->{cgi}->param($row_id_name);

    # delete the row given in the Delete_Row value
    my $pval = $self->{cgi}->param('Delete_Row');
    if ($pval)
    {
	$pval =~ m#Delete Row ([\d]+)#;
	$row_id = $1;
    }
    if (!$row_id)
    {
	$self->print_message("Can't delete from table $table: row-id $row_id_name is NULL");
	return 0;
    }
    if ($self->delete_one_row(
	table=>$table, row_id=>$row_id))
    {
	# display the edit search
	$self->do_search_form($table, command=>'Edit');
    }
    
} # do_single_delete

=head2 make_search_form

Create the search form for the given table.

my $form = $obj->make_search_form($table, %args);

=cut
sub make_search_form {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Search',
	@_
    );

    my $table2 = $self->{cgi}->param('Table2');

    # read the template
    my $template;
    if ($self->{report_template} !~ /\n/
	&& -r $self->{report_template})
    {
	local $/ = undef;
	my $fh;
	open($fh, $self->{report_template})
	    or die "Could not open ", $self->{report_template};
	$template = <$fh>;
	close($fh);
    }
    else
    {
	$template = $self->{report_template};
    }
    # generate the search form
    my $form = $self->search_form($table,
	command=>$args{command},
	table2=>$table2);
    my $title = $args{command} . ' ' . $table;

    $form = "<p><i>$self->{message}</i></p>\n" . $form if $self->{message};

    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$form/g;
    return $out;

} # make_search_form

=head2 do_search_form

Display the search form for the given table.

=cut
sub do_search_form {
    my $self = shift;
    
    my $out = $self->make_search_form(@_);

    # Now print the page for the user to see...
    print "Content-Type: text/html\n";
    print "\n";
    print $out;

} # do_search_form

=head2 make_table_form

Make the table selection form.

=cut
sub make_table_form {
    my $self = shift;
    my $command = (@_ ? shift : '');

    # read the template
    my $template;
    if ($self->{report_template} !~ /\n/
	&& -r $self->{report_template})
    {
	local $/ = undef;
	my $fh;
	open($fh, $self->{report_template})
	    or die "Could not open ", $self->{report_template};
	$template = <$fh>;
	close($fh);
    }
    else
    {
	$template = $self->{report_template};
    }

    # get the list of tables (and views)
    my @tables = sort $self->get_tables(views=>($command ne 'Editing'));

    # generate the search form
    my $url = $self->{cgi}->url();
    my $form =<<EOT;
<form action="$url">
<p><strong>Table:</strong>
EOT
    foreach my $table (@tables)
    {
	$form .= "<br/><input type='radio' name='Table' value='$table'>$table</input>";
    }
    $form .=<<EOT;
</p>
<input type="submit" value="Submit"/>
<input type="reset" value="Reset"/>
</form>
EOT
    my $title = "Select table";
    $title .= " for $command" if $command;

    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$form/g;

    return $out;

} # make_table_form

=head2 do_table_form

Display the table selection form.

=cut
sub do_table_form {
    my $self = shift;
    
    my $out = $self->make_table_form(@_);

    # Now print the page for the user to see...
    print "Content-Type: text/html\n";
    print "\n";
    print $out;

} # do_table_form

=head1 Helper Methods

Lower-level methods, generally just called from other methods,
but possibly suitable for other things.

=head2 print_message

Print an (error) message to the user.

$self->print_message($message); # error message

$self->print_message($message, 0); # non-error message

=cut
sub print_message {
    my $self = shift;
    my $message = shift;
    my $is_error = (@_ ? shift : 1); # assume error message

    # read the template
    my $template;
    if ($self->{report_template} !~ /\n/
	&& -r $self->{report_template})
    {
	local $/ = undef;
	my $fh;
	open($fh, $self->{report_template})
	    or die "Could not open ", $self->{report_template};
	$template = <$fh>;
	close($fh);
    }
    else
    {
	$template = $self->{report_template};
    }
    my $title = ($is_error 
	? "Error Message"
	: "Message"
    );

    my $contents = ($is_error 
	? "<p style='color: red'>$message</p>\n"
	: "<p>$message</p>\n"
    );

    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$contents/g;
    # Now print the page for the user to see...
    print "Content-Type: text/html\n";
    print "\n";
    print $out;
} # print_message

=head2 search_form

Construct a search-a-table form

=cut
sub search_form {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Search',
	@_
    );

    my @columns = $self->get_colnames($table);
    my $command = $args{command};
    my $where_prefix = $self->{where_prefix};
    my $not_prefix = $self->{not_prefix};
    my $show_label = $self->{show_label};
    my $sort_label = $self->{sort_label};
    my $sort_reversed_prefix = $self->{sort_reversed_prefix};
    my $headers_label = $self->{headers_label};

    my $action = $self->{cgi}->url();
    my $out_str =<<EOT;
<form action="$action" method="get">
<p>
<strong><input type="submit" name="$command" value="$command"/> <input type="reset"/></strong>
EOT
    if ($command eq 'Edit')
    {
	$out_str .=<<EOT;
<input type="submit" name="Add_Row" value="Add Row"/>
EOT
    }
    $out_str .=<<EOT;
<input type="hidden" name="Table" value="$table"/>
</p>
<table border="0">
<tr><td>
<p>Match by column: use <b>*</b> as a wildcard match,
and the <b>?</b> character to match
any <em>single</em> character.
Click on the "NOT" checkbox to negate a match.
</p>
<table border="1" class="plain">
<tr>
<td>Columns</td>
<td>Match</td>
<td>&nbsp;</td>
</tr>
EOT
    for (my $i = 0; $i < @columns; $i++) {
	my $col = $columns[$i];
	my $wcol_label = "${where_prefix}${col}";
	my $ncol_label = "${not_prefix}${col}";

	$out_str .= "<tr><td>";
	$out_str .= "<strong>$col</strong>";
	$out_str .= "</td>\n<td>";
	$out_str .= "<input type='text' name='$wcol_label'/>";
	$out_str .= "</td>\n<td>";
	$out_str .= "<input type='checkbox' name='$ncol_label'>NOT</input>";
	$out_str .= "</td>";
	$out_str .= "</tr>\n";
}
    $out_str .=<<EOT;
</table>
</td><td>
<p>Select the order of columns to display;
and which columns <em>not</em> to display.</p>
<table border="0">
EOT
    for (my $i = 0; $i < @columns; $i++) {
	my $col = $columns[$i];

	$out_str .= "<tr><td>";
	$out_str .= "<select name='${show_label}'>\n";
	$out_str .= "<option value=''>-- not displayed --</option>\n";
	foreach my $fname (@columns)
	{
	    if ($fname eq $col)
	    {
		$out_str .= "<option selected='true' value='${fname}'>${fname}</option>\n";
	    }
	    else
	    {
		$out_str .= "<option value='${fname}'>${fname}</option>\n";
	    }
	}
	$out_str .= "</select>";
	$out_str .= "</td>";
	$out_str .= "</tr>\n";
}
    $out_str .=<<EOT;
</table></td><td>
EOT
    $out_str .=<<EOT;
<p><strong>Num Results:</strong><select name="Limit">
<option value="0">All</option>
<option value="1">1</option>
<option value="10">10</option>
<option value="20">20</option>
<option value="50">50</option>
<option value="100">100</option>
</select>
</p>
<p><strong>Page:</strong>
<input type="text" name="Page" value="1"/>
</p>
EOT
    if ($command eq 'Search')
    {
	$out_str .=<<EOT;
<p><strong>Report Layout:</strong><select name="ReportLayout">
<option value="table">table</option>
<option value="para">paragraph</option>
<option value="list">list</option>
</select>
</p>
EOT
    }

    $out_str .=<<EOT;
<p><strong>Report Style:</strong><select name="ReportStyle">
<option value="full">Full</option>
<option value="medium">Medium</option>
<option value="compact">Compact</option>
<option value="bare">Bare</option>
</select>
</p>
EOT
    my @tables = $self->get_tables();
    if (@tables > 1)
    {
	$out_str .=<<EOT;
<p><strong>Table #2</strong>
<br/><input type='radio' name='Table2' checked='true' value=''>NONE</input>
EOT
	foreach my $tn (@tables)
	{
	    if ($tn ne $table)
	    {
		$out_str .= "<br/><input type='radio' name='Table2' value='$tn'>$tn</input>\n";
	    }
	}
	$out_str .= "</p>\n";
    }

    $out_str .=<<EOT;
</td></tr></table>
<table border="0">
<tr><td>
<p><strong>Sort by:</strong> To set the sort order, select the column names.
To sort that column in reverse order, click on the <strong>Reverse</strong>
checkbox.
</p>
<table border="0">
EOT

    my $num_sort_fields = ($self->{max_sort_fields} < @columns
	? $self->{max_sort_fields} : @columns);
    for (my $i=0; $i < $num_sort_fields; $i++)
    {
	my $col = $columns[$i];
	$out_str .= "<tr><td>";
	$out_str .= "<select name='${sort_label}'>\n";
	$out_str .= "<option value=''>--choose a sort column--</option>\n";
	foreach my $fname (@columns)
	{
	    $out_str .= "<option value='${fname}'>${fname}</option>\n";
	}
	$out_str .= "</select>";
	$out_str .= "</td>";
	$out_str .= "<td>Reverse <input type='checkbox' name='${sort_reversed_prefix}${i}' value='1'/>";
	$out_str .= "</td>\n";
	$out_str .= "</tr>";
    }
    $out_str .=<<EOT;
</table>
</td><td>
EOT
    if ($command eq 'Search')
    {
	$out_str .=<<EOT;
<p><strong>Headers:</strong>
Indicate which columns you wish to be in headers by giving
the columns in template form; for example:<br/>
{\$Col1} {\$Col2}<br/>
means that the header contains columns <em>Col1</em> and <em>Col2</em>.
<br/>
EOT
	for (my $i=1; $i <= $self->{max_headers}; $i++)
	{
	    $out_str .=<<EOT
<strong>Header $i</strong>
<input type="text" name="$headers_label" size="60"/><br/>
EOT
	}
	$out_str .= "</p>\n";
    }

    $out_str .=<<EOT;
</td></tr>
</table>
<p><strong><input type="submit" name="$command" value="$command"/> <input type="reset"/></strong>
EOT
    if ($command eq 'Edit')
    {
	$out_str .=<<EOT;
<input type="submit" name="Add_Row" value="Add Row"/>
EOT
    }
    $out_str .=<<EOT;
</p>
</form>
EOT
    return $out_str;
} # search_form

=head2 make_add_form

Construct an add-a-row form.

=cut
sub make_add_form {
    my $self = shift;
    my $table = shift;
    my %args = (
	command=>'Add',
	@_
    );

    my $row_id_name = $self->get_id_colname($table);
    my @columns = $self->get_colnames($table, do_rowid=>0);
    my $command = $args{command};
    my $table2_str = ($args{table2}
	?  "<input type='hidden' name='Table2' value='$args{table2}'/>"
	: ''
    );

    my $action = $self->{cgi}->url();
    my $out_str =<<EOT;
<form action="$action" method="get">
<p>
<strong><input type="submit" name="$command" value="$command"/> <input type="reset"/></strong>
<input type="hidden" name="Table" value="$table"/>
$table2_str
</p>
<table border="1" class="plain">
<tr>
<td>Columns</td>
<td>Value</td>
</tr>
EOT
    for (my $i = 0; $i < @columns; $i++) {
	my $col = $columns[$i];

	$out_str .= "<tr><td>";
	$out_str .= "<strong>$col</strong>";
	$out_str .= "</td>\n<td>";
	if ($col eq $row_id_name)
	{
	    $out_str .= "<input type='hidden' name='$col' value='NULL'/>";
	}
	else
	{
	    $out_str .= $self->get_input_field(table=>$table,
		colname=>$col, value=>'');
	}
	$out_str .= "</td>";
	$out_str .= "</tr>\n";
}
    $out_str .=<<EOT;
</table>
</form>
EOT
    return $out_str;
} # make_add_form

=head2 make_buttons

Make the buttons for the forms.

=cut
sub make_buttons {
    my $self = shift;
    my %args = (
	table=>'',
	command=>'Search',
	@_
    );
    my $table = $args{table};
    my $table2 = $args{table2};
    my $page = $args{page};
    my $limit = $args{limit};
    my $total = $args{total};
    my $command = $args{command};

    my $num_pages = ($limit ? ceil($total / $limit) : 0);

    my $url = $self->{cgi}->url();
    my @out = ();
    push @out,<<EOT;
<table>
<tr><td>
<form action="$url" method="get">
<input type="hidden" name="Table" value="$table"/>
<input type="hidden" name="Table2" value="$table2"/>
<input type="submit" value="$command $table again"/>
EOT
    if ($command eq 'Edit')
    {
	push @out,<<EOT;
<input type="submit" name="Add_Row" value="Add Row"/>
EOT
    }
    push @out,<<EOT;
</form></td>
EOT

    if ($args{limit})
    {
	# reproduce the query ops, with a different page
	# first
	push @out, "<td>";
	push @out, $self->make_page_button(command=>$command,
	    the_page=>1,
	    page_label=>' |&lt; ');
	push @out, "</td>\n";
	# prev
	push @out, "<td>";
	push @out, $self->make_page_button(command=>$command,
	    the_page=>$page - 1,
	    page_label=>' &lt; ');
	push @out, "</td>\n";
	# next
	push @out, "<td>";
	push @out, $self->make_page_button(command=>$command,
	    the_page=>$page + 1,
	    page_label=>' &gt; ');
	push @out, "</td>\n";
	# last
	push @out, "<td>";
	push @out, $self->make_page_button(command=>$command,
	    the_page=>$num_pages,
	    page_label=>' &gt;| ');
	push @out, "</td>\n";
	push @out, "</tr></table>\n";
    }
    else # no pages
    {
	push @out,<<EOT;
</tr></table>
EOT
    }

    return join('', @out);
} # make_buttons

=head2 make_page_button

Make a button for a particular page

=cut

sub make_page_button {
    my $self = shift;
    my %args = (
	command=>'Search',
	the_page=>0,
	page_label=>'Page',
	@_
    );
    my $command = $args{command};
    my $the_page = $args{the_page};
    my $page_label = $args{page_label};

    my $url = $self->{cgi}->url();
    my $result = '';
    $result .=<<EOT;
<form action="$url" method="get">
<input type="hidden" name="Page" value="$the_page"/>
EOT
    foreach my $pfield ($self->{cgi}->param())
    {
	if ($pfield ne 'Page'
	    and $pfield ne $command)
	{
	    my (@vals) = $self->{cgi}->param($pfield);
	    foreach my $val (@vals)
	    {
                $result .=<<EOT;
<input type='hidden' name="$pfield" value="${val}"/>
EOT
	    }
	}
    }
    $result .=<<EOT;
<input type="submit" name="$command" value="$page_label"/>
</form>
EOT
    return $result;
} # make_page_button

=head2 print_select

Print a selection result.
(slightly different for Edits than for Search)

=cut
sub print_select {
    my $self = shift;
    my $sth = shift;
    my $sth2 = shift;
    my %args = (
	table=>'',
	command=>'Search',
	@_
    );
    my @columns = @{$args{columns}};
    my @sort_by = @{$args{sort_by}};
    my $table = $args{table};
    my $page = $args{page};

    # read the template
    my $template;
    if ($self->{report_template} !~ /\n/
	&& -r $self->{report_template})
    {
	local $/ = undef;
	my $fh;
	open($fh, $self->{report_template})
	    or die "Could not open ", $self->{report_template};
	$template = <$fh>;
	close($fh);
    }
    else
    {
	$template = $self->{report_template};
    }
    # generate the HTML table
    my $count = 0;
    my $res_tab = '';
    ($count, $res_tab) = $self->format_report($sth,
					      %args,
					      table=>$table,
					      table2=>$args{table2},
					      columns=>\@columns,
					      sort_by=>\@sort_by,
					     );
    my $buttons = $self->make_buttons(%args);
    my $main_title = ($args{title} ? $args{title}
	: "$table $args{command} result");
    my $title = ($args{limit} ? "$main_title ($page)"
	: $main_title);
    my @result = ();
    push @result, $buttons if ($args{report_style} ne 'bare');
    push @result, $res_tab;
    push @result, "<p>$count rows displayed of $args{total}.</p>\n"
	if ($args{report_style} ne 'bare'
	    and $args{report_style} ne 'compact');
    if ($args{limit} and $args{report_style} eq 'full')
    {
	my $num_pages = ceil($args{total} / $args{limit});
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
						row_template=>'',
					       );
	if ($count2)
	{
	    push @result,<<EOT;
	    <h2>$args{table2}</h2>
		$tab2
		<p>$count2 rows displayed from $args{table2}.</p>
EOT
	}
	elsif ($args{command} eq 'Edit')
	{
	    push @result,<<EOT;
	    <h2>Edit $args{table2}</h2>
EOT
	    # no rows, but editing
	    push @result, $self->make_add_form($args{table2});
	}
    }
    push @result, $buttons if ($args{report_style} ne 'bare');

    # prepend the query and message
    unshift @result, "<p>$args{query}</p>\n" if ($args{debug});
    unshift @result, "<p><i>$self->{message}</i></p>\n", if $self->{message};

    my $contents = join('', @result);
    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$contents/g;
    # if we're given an outfile, print to that
    if ($args{outfile})
    {
	my $fh;
	open($fh, ">", $args{outfile})
	    or die "Could not open $args{outfile} for writing";
	print $fh $out;
	close($fh);
    }
    else
    {
	# Now print the page for the user to see...
	print "Content-Type: text/html\n";
	print "\n";
	print $out;
    }
} # print_select

=head2 format_report

Format the report results
If 'command' is 'Search' then use the parent format_report;
otherwise make an edit-table.

=cut
sub format_report {
    my $self = shift;
    my $sth = shift;
    my %args = (
	table=>'',
	command=>'Edit',
	@_
    );

    if ($args{command} eq 'Search')
    {
	return $self->SUPER::format_report($sth, %args);
    }
    elsif ($args{command} eq 'Edit')
    {
	return $self->make_edit_table($sth, %args);
    }
    elsif ($args{command} eq 'EditText')
    {
	return $self->make_edittext($sth, %args);
    }

} # format_report

=head2 make_edit_table

Make a table for editing a search result.

=cut
sub make_edit_table {
    my $self = shift;
    my $sth = shift;
    my %args = (
	table=>'',
	command=>'Edit',
	report_style=>'full',
	@_
    );
    my @columns = @{$args{columns}};
    my @sort_by = @{$args{sort_by}};
    my $command = $args{command};
    my $table = $args{table};
    my $table2 = $args{table2};
    my $report_style = $args{report_style};
    my $table_border = $args{table_border};
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
    my $row_id_ind = -1;
    my $url = $self->{cgi}->url();
    # by default, show all columns
    my @show_cols = ();
    for (my $i = 0; $i < @columns; $i++)
    {
	$show_cols[$i] = 1;
	if ($columns[$i] eq $row_id_name)
	{
	    $row_id_ind = $i;
	}
    }

    my @nice_cols = ();
    for (my $ci = 0; $ci < @columns; $ci++)
    {
	my $nicecol = $columns[$ci];
	if ($truncate_colnames)
	{
	    my @colwords = split('_', $nicecol);
	    foreach my $cw (@colwords)
	    {
		$cw = $self->{_tobj}->convert_value(value=>$cw,
		    format=>"trunc${truncate_colnames}",
		    name=>$columns[$ci]);
		$cw = $self->{_tobj}->convert_value(value=>$cw,
		    format=>'proper',
		    name=>$columns[$ci]);
	    }
	    $nicecol = join(' ', @colwords);
	}
	else
	{
	    $nicecol =~ s/_/ /g;
	    $nicecol = $self->{_tobj}->convert_value(value=>$nicecol,
		format=>'proper',
		name=>$columns[$ci]);
	}
	$nice_cols[$ci] = $nicecol;
    }

    # get the rows
    my $tbl_ary_ref = $sth->fetchall_arrayref;
    my $single_row = (@{$tbl_ary_ref} == 1);
    my $new_table = 1;
    for (my $ri = 0; $ri < @{$tbl_ary_ref}; $ri++)
    {
	my @row = @{$tbl_ary_ref->[$ri]};
	$count++;
	# new table
	push @out,<<EOT;
<form action="$url">
<input type="hidden" name="Table" value="$table"/>
EOT
	if ($table2)
	{
	    push @out,<<EOT;
<input type="hidden" name="Table2" value="$table2"/>
EOT
	}
	push @out, "<table border='$table_border' class='plain'>";
	if ($report_style ne 'bare')
	{
	    push @out, '<thead><tr>';
	    # a single-row table has its columns on the side
	    push @out, "<th>Column</th><th>Value</th>\n";
	    push @out, "</tr></thead>\n";
	}

	# a row for each column-value
	for (my $ci = 0; $ci < @columns; $ci++)
	{
	    if ($show_cols[$ci])
	    {
		my $col = $columns[$ci];
		my $val = $row[$ci];
		$val = 'NULL' if !defined $val;
		push @out, '<tr>';
		push @out, '<td><strong>';
		push @out, "<input type='submit' name='Update' value='$col'/>";
		push @out, "</strong></td>\n";
		push @out, '<td>';
		if ($col ne $row_id_name)
		{
		    push @out,$self->get_input_field(table=>$table,
			colname=>$col,
			value=>$val);
		}
		else
		{
		    push @out,<<EOT;
<input type="hidden" size="50" name="$col" value="$val"/>
$val
<input type="submit" name="Delete" value="Delete"/>
<input type="submit" name="Add" value="Add"/>
EOT
		}
		push @out, '</td>';
		push @out, "</tr>\n";
	    }
	}
	push @out, "</table>\n";
	push @out, "</form>\n";
    }
    if (0)
    {
	for (my $ri = 0; $ri < @{$tbl_ary_ref}; $ri++)
	{
	    my @row = @{$tbl_ary_ref->[$ri]};
	    if ($new_table)
	    {
		push @out,<<EOT;
<form action="$url">
<input type="hidden" name="Table" value="$table"/>
EOT
		if ($table2)
		{
		    push @out,<<EOT;
<input type="hidden" name="Table2" value="$table2"/>
EOT
		}
		push @out, "<table border=\"$table_border\" class=\"plain\">";
		if ($report_style ne 'bare')
		{
		    push @out, '<thead><tr>';
		    push @out, "<th>&nbsp;</th>";
		    for (my $ci = 0; $ci < @columns; $ci++)
		    {
			if ($show_cols[$ci])
			{
			    my $nicecol = $nice_cols[$ci];
			    push @out, "<th>$nicecol</th>";
			}
		    }
		    push @out, "</tr></thead>\n";
		}
		$new_table = 0;
	    }
	    push @out, "<tr>";
	    my $row_id_val = 'UNKNOWN';
	    $row_id_val = $row[$row_id_ind] if ($row_id_ind >= 0);
	    push @out,<<EOT;
<td><input type="submit" name="Edit_Row" value="Edit Row $row_id_val"/>
<!-- row_id_ind=$row_id_ind -->
<input type="submit" name="Add_Row" value="Add Row"/>
<input type="submit" name="Delete_Row" value="Delete Row $row_id_val"/>
</td>
EOT
	    for (my $ci = 0; $ci < @columns; $ci++)
	    {
		if ($show_cols[$ci])
		{
		    my $col = $columns[$ci];
		    my $val = $row[$ci];
		    $val = 'NULL' if !defined $val;
		    push @out, '<td>';
		    push @out, ($val ? $val : '&nbsp');
		    push @out, "</td>\n";
		}
	    }
	    push @out, "</tr>\n";
	    $count++;
	} # for each row
    }

    my $out_str = join('', @out);
    return ($count, $out_str);
} # make_edit_table

=head2 make_edittext

Make a textarea for editing a search result.

=cut
sub make_edittext {
    my $self = shift;
    my $sth = shift;
    my %args = (
	table=>'',
	command=>'EditText',
	report_style=>'full',
	@_
    );
    my @columns = @{$args{columns}};
    my @sort_by = @{$args{sort_by}};
    my $command = $args{command};
    my $table = $args{table};
    my $table2 = $args{table2};
    my $report_style = $args{report_style};
    my $table_border = $args{table_border};

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
    my @out = ();
    my $count = 0;
    my $row_id_name = $self->get_id_colname($table);
    my $row_id_ind = -1;
    my $url = $self->{cgi}->url();
    # by default, show all columns
    my @show_cols = ();
    for (my $i = 0; $i < @columns; $i++)
    {
	$show_cols[$i] = 1;
	if ($columns[$i] eq $row_id_name)
	{
	    $row_id_ind = $i;
	}
    }

    # no change or truncation of colnames
    my @nice_cols = ();
    for (my $ci = 0; $ci < @columns; $ci++)
    {
	my $nicecol = $columns[$ci];
	$nice_cols[$ci] = $nicecol;
    }

    # get the rows
    my $tbl_ary_ref = $sth->fetchall_arrayref;
    my $single_row = (@{$tbl_ary_ref} == 1);
    my $new_table = 1;
    for (my $ri = 0; $ri < @{$tbl_ary_ref}; $ri++)
    {
	my @row = @{$tbl_ary_ref->[$ri]};
	$count++;
	# new table
	push @out,<<EOT;
<form action="$url">
<input type="hidden" name="Table" value="$table"/>
EOT
	if ($table2)
	{
	    push @out,<<EOT;
<input type="hidden" name="Table2" value="$table2"/>
EOT
	}
	push @out, "<table border='$table_border' class='plain'>";
	if ($report_style ne 'bare')
	{
	    push @out, '<thead><tr>';
	    # a single-row table has its columns on the side
	    push @out, "<th>Column</th><th>Value</th>\n";
	    push @out, "</tr></thead>\n";
	}

	# a row for each column-value
	for (my $ci = 0; $ci < @columns; $ci++)
	{
	    if ($show_cols[$ci])
	    {
		my $col = $columns[$ci];
		my $val = $row[$ci];
		$val = 'NULL' if !defined $val;
		push @out, '<tr>';
		push @out, '<td><strong>';
		push @out, "<input type='submit' name='Update' value='$col'/>";
		push @out, "</strong></td>\n";
		push @out, '<td>';
		if ($col ne $row_id_name)
		{
		    push @out,$self->get_input_field(table=>$table,
			colname=>$col,
			value=>$val);
		}
		else
		{
		    push @out,<<EOT;
<input type="hidden" size="50" name="$col" value="$val"/>
$val
<input type="submit" name="Delete" value="Delete"/>
<input type="submit" name="Add" value="Add"/>
EOT
		}
		push @out, '</td>';
		push @out, "</tr>\n";
	    }
	}
	push @out, "</table>\n";
	push @out, "</form>\n";
    }
    if (0)
    {
	for (my $ri = 0; $ri < @{$tbl_ary_ref}; $ri++)
	{
	    my @row = @{$tbl_ary_ref->[$ri]};
	    if ($new_table)
	    {
		push @out,<<EOT;
<form action="$url">
<input type="hidden" name="Table" value="$table"/>
EOT
		if ($table2)
		{
		    push @out,<<EOT;
<input type="hidden" name="Table2" value="$table2"/>
EOT
		}
		push @out, "<table border=\"$table_border\" class=\"plain\">";
		if ($report_style ne 'bare')
		{
		    push @out, '<thead><tr>';
		    push @out, "<th>&nbsp;</th>";
		    for (my $ci = 0; $ci < @columns; $ci++)
		    {
			if ($show_cols[$ci])
			{
			    my $nicecol = $nice_cols[$ci];
			    push @out, "<th>$nicecol</th>";
			}
		    }
		    push @out, "</tr></thead>\n";
		}
		$new_table = 0;
	    }
	    push @out, "<tr>";
	    my $row_id_val = 'UNKNOWN';
	    $row_id_val = $row[$row_id_ind] if ($row_id_ind >= 0);
	    push @out,<<EOT;
<td><input type="submit" name="Edit_Row" value="Edit Row $row_id_val"/>
<!-- row_id_ind=$row_id_ind -->
<input type="submit" name="Add_Row" value="Add Row"/>
<input type="submit" name="Delete_Row" value="Delete Row $row_id_val"/>
</td>
EOT
	    for (my $ci = 0; $ci < @columns; $ci++)
	    {
		if ($show_cols[$ci])
		{
		    my $col = $columns[$ci];
		    my $val = $row[$ci];
		    $val = 'NULL' if !defined $val;
		    push @out, '<td>';
		    push @out, ($val ? $val : '&nbsp');
		    push @out, "</td>\n";
		}
	    }
	    push @out, "</tr>\n";
	    $count++;
	} # for each row
    }

    my $out_str = join('', @out);
    return ($count, $out_str);
} # make_edittext

=head2 get_input_field

Get the required input field for the table+column

=cut
sub get_input_field {
    my $self = shift;
    my %args = (
	table=>'',
	colname=>'',
	@_
    );
    my $col = $args{colname};
    my $val = $args{value};
    my $qval = $val;
    $qval =~ s/</&lt;/g;
    $qval =~ s/>/&gt;/g;
    $qval =~ s/"/&quot;/g;

    my $type = $self->{input_format}->{$args{table}}->{$col}->{type};
    if ($type eq 'textarea')
    {
	my $cols = $self->{input_format}->{$args{table}}->{$col}->{cols};
	my $rows = $self->{input_format}->{$args{table}}->{$col}->{rows};
	return <<EOT;
<textarea name="$col" cols="$cols" rows="$rows"/>
$qval
</textarea>
EOT
    }
    elsif ($type eq 'text')
    {
	my $size = $self->{input_format}->{$args{table}}->{$col}->{size};
	return <<EOT;
<input type="text" size="$size" name="$col" value="$qval"/>
EOT
    }
    return <<EOT;
<input type="text" size="50" name="$col" value="$qval"/>
EOT
} # get_input_field

=head1 REQUIRES

    SQLite::Work
    CGI

    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}


=head1 SEE ALSO

perl(1).

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

1; # End of SQLite::Work::CGI
__END__
