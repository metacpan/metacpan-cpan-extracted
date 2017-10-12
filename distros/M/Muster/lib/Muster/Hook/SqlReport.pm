package Muster::Hook::SqlReport;
$Muster::Hook::SqlReport::VERSION = '0.62';
=head1 NAME

Muster::Hook::SqlReport - Muster SQL-report directive

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::SqlReport> processes the SQL-report directive.
Excpects SQLite databases in the config.

=cut

use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;

use Carp 'croak';
use DBI;
use POSIX;
use YAML;
use Text::NeatTemplate;
use SQLite::Work;

=head1 METHODS

L<Muster::Hook::SqlReport> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Initialize and register.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $config = shift;

    $self->{databases} = {};
    while (my ($alias, $file) = each %{$config->{hook_conf}->{'Muster::Hook::SqlReport'}})
    {
        if (!-r $file)
        {
            warn __PACKAGE__, " cannot read database '$file'";
        }
        else
        {
	    my $rep = SQLite::Work::Muster->new(database=>$file);
	    if (!$rep or !$rep->do_connect())
	    {
		warn __PACKAGE__, "Can't connect to $file: $DBI::errstr";
	    }
            else
            {
                $rep->{dbh}->{sqlite_unicode} = 1;
                $self->{databases}->{$alias} = $rep;
            }
        }
    }

    $hookmaster->add_hook('sqlreport' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>1,
                directive=>'sqlreport',
                call=>sub {
                    my %args2 = @_;

                    return $self->process(%args2);
                },
                %args,
            );
        },
    );
    return $self;
} # register

sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my @p = @{$args{params}};
    my %params = @p;

    my $page = $leaf->pagename;
    foreach my $p (qw(database table where))
    {
	if (!exists $params{$p})
	{
	    croak ("sqlreport: missing $p parameter");
	}
    }
    if (!exists $self->{databases}->{$params{database}})
    {
	croak (sprintf('sqlreport: database %s does not exist',
		$params{database}));
    }

    # If there is more than one report on a page,
    # the report will need an ID for pagination and/or query
    # If there is only one report on the page, then it doesn't.
 
    # Check for pagination and query
    my $c = $args{controller}; # build-phase has a controller
    my $n = 1;
    my $limit = (exists $params{limit} ? $params{limit} : 0);
    my $n_id = (exists $params{report_id}
        ? "n_".$params{report_id} : "n");

    # pagination happens when the limit is not zero
    if ($limit)
    {
        $n = $c->param($n_id) || 1;
    }

    # Check the q parameter and AND it with the "where"
    my $q_id = (exists $params{report_id}
        ? "q_".$params{report_id} : "q");
    my $q = $c->param($q_id);
    my $w = $params{where};
    if ($q)
    {
        $params{where} = "($w) AND ($q)";
    }

    # if there is query_form enabled:
    # - print a query form
    my $form = '';
    if (exists $params{query_form} and $params{query_form})
    {
        my $this_url = $c->req->url->to_string;
        $form =<<EOT;
<div>
<form action="$this_url">
<strong>WHERE:</strong> $w
<strong>AND</strong><br/>
<textarea name="$q_id" rows="4" cols="60">$q</textarea>
<input type="submit" value="Search">
</form>
</div>
EOT
    }

    my $result = $self->{databases}->{$params{database}}->do_report(%params,page=>$n,limit=>$limit,q=>$q);

    if ($params{ltemplate}
        and $result)
    {
        my $out2 = $params{ltemplate};
        $out2 =~ s/CONTENTS/$result/g;
        $result = $out2;
    }
    return $form . $result;
} # preprocess

sub DESTROY {
    my $self = shift;

    if (exists $self->{databases}
            and defined $self->{databases}
            and ref $self->{databases} eq 'HASH')
    {
        foreach my $db (keys %{$self->{databases}})
        {
            if (defined $self->{databases}->{$db}
                    and defined $self->{databases}->{$db}->{dbh})
            {
                $self->{databases}->{$db}->do_disconnect();
            }
        }
    }
} # DESTROY

1;
# =================================================================
package SQLite::Work::Muster;
$SQLite::Work::Muster::VERSION = '0.62';
use SQLite::Work;
use Text::NeatTemplate;
use POSIX;
our @ISA = qw(SQLite::Work);

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = SQLite::Work->new(%parameters);

    $self->{report_template} = '<!--sqlr_contents-->'
	if !defined $parameters{report_template};
    bless ($self, ref ($class) || $class);
} # new

=head2 print_select

RETURN a selection result.

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
    my @sort_by = @{$args{sort_by}};
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
	sort_by=>\@sort_by,
	num_pages=>$num_pages,
	);
    my $buttons = $self->make_pagination(%args);
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
    push @result, $buttons if ($args{report_style} ne 'bare');
    if ($args{report_style} ne 'bare'
	    and $args{report_style} ne 'compact'
	    and $args{total} > 1)
    {
        my $summary = '';
	if ($count == $args{total})
	{
	    $summary = "$args{total} rows match.\n";
	}
	else
	{
	    $summary = "$count rows displayed of $args{total}. Page $page of $num_pages.\n";
	}
        push @result, "<p>$summary</p>\n";
    }
    push @result, $res_tab;
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
    push @result, $buttons if ($args{report_style} ne 'bare');

    # prepend the message
    unshift @result, "<p><i>$self->{message}</i></p>\n", if $self->{message};

    my $contents = join('', @result);
    my $out = $template;
    $out =~ s/<!--sqlr_title-->/$title/g;
    $out =~ s/<!--sqlr_contents-->/$contents/g;

    # RETURN the result
    return $out;
} # print_select

=head2 build_where_conditions

If "where" is not a hash. treat it like a query.

Otherwise do the default of the superclass.

=cut
sub build_where_conditions {
    my $self = shift;
    my %args = @_;

    if (ref $args{where} eq 'HASH')
    {
	return $self->SUPER::build_where_conditions(%args);
    }
    my @where = ();
    $args{where} =~ s/;//g; # crude prevention of injection
    $where[0] = $args{where};

    return @where;
} # build_where_conditions

=head2 do_report

Do a report, pre-processing the arguments a bit.

=cut
sub do_report {
    my $self = shift;
    my %args = (
	command=>'Select',
	limit=>0,
	page=>1,
	headers=>'',
	groups=>'',
	sort_by=>'',
	not_where=>{},
	where=>{},
	show=>'',
	layout=>'table',
	row_template=>'',
	outfile=>'',
	report_style=>'full',
	title=>'',
	prev_file=>'',
	next_file=>'',
        report_class=>'report',
        report_div=>'div',
	@_
    );
    my $table = $args{table};
    my $command = $args{command};
    my $report_class = $args{report_class};
    my $report_div = $args{report_div};
    my @headers = (ref $args{headers} ? @{$args{headers}}
	: split(/\|/, $args{headers}));
    my @groups = (ref $args{groups} ? @{$args{groups}}
	: split(/\|/, $args{groups}));
    my @sort_by = (ref $args{sort_by} ? @{$args{sort_by}}
	: split(' ', $args{sort_by}));


    my @columns = (ref $args{show}
	? @{$args{show}}
	: ($args{show}
	    ? split(' ', $args{show})
	    : $self->get_colnames($table)));

    my $total = $self->get_total_matching(%args);
    if ($total == 0)
    {
        return '';
    }

    my ($sth1, $sth2) = $self->make_selections(%args,
	show=>\@columns,
	sort_by=>\@sort_by,
	total=>$total);
    my $out = $self->print_select($sth1,
	$sth2,
	%args,
	show=>\@columns,
	sort_by=>\@sort_by,
	message=>$self->{message},
	command=>$command,
	total=>$total,
	columns=>\@columns,
	headers=>\@headers,
	groups=>\@groups,
	);
    if ($args{debug})
    {
        my $stmt = $sth1->{Statement};
        $out = "<p>$stmt</p>\n$out";
    }
    if ($out and $report_div and $report_class)
    {
        $out =<<EOT;
<$report_div class="$report_class">
$out
</$report_div>
EOT
    }
    elsif ($out and $report_div)
    {
        $out =<<EOT;
<$report_div>
$out
</$report_div>
EOT
    }
    return $out;
} # do_report

=head2 make_pagination

Make the buttons for the pagination.
Pagination happens only when there's a limit not equal to zero.

=cut
sub make_pagination {
    my $self = shift;
    my %args = @_;
    my $page = $args{page};
    my $limit = $args{limit};
    my $total = $args{total};
    my $q = $args{q};

    if (!$limit)
    {
        return "";
    }

    my $num_pages = ceil($total / $limit);
    my $n_id = (exists $args{report_id}
        ? "n_".$args{report_id} : "n");

    # If we leave the "this page" part of the url blank, it defaults to the current page,
    # which is just what we want
    # If we have a large number of pages, we don't want to show links to them all
    my $middle_pages = ceil($num_pages / 2);
    my $leeway = 3;

    my $out=<<EOT;
<div class="pagination">
EOT
    my $printing_buttons = 0;
    for (my $i=1; $i <= $num_pages; $i++)
    {
        my $link = sprintf('<span class="button"><a href="?%s=%d%s"> %d </a></span>',
            $n_id, $i, ($q ? "&q=$q" : ''), $i);
        $link = "<strong style='font-size: 1.5em;'> $i </strong>" if ($i == $page);
        if ($num_pages <= 20
                or ($i <= $leeway + 1)
                or ($i >= ($num_pages - $leeway))
                or ($i >= ($middle_pages - $leeway) and $i <= ($middle_pages + $leeway))
                or ($i >= ($page - $leeway) and $i <= ($page + $leeway))
        )
        {
            $out .= "$link\n";
            $printing_buttons = 1;
        }
        elsif ($num_pages > 20)
        {
            if ($printing_buttons)
            {
                # put a gap in
                $out .= "...\n";
                $printing_buttons = 0;
            }
        }
    }
    $out.=<<EOT;
</div>
EOT

    return $out;
} # make_pagination
1;
