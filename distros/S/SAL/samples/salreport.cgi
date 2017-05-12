#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use SAL::DBI;
use SAL::WebDDR;

print "Content-type: text/html\n\n";

my $report_title = 'Report Test Page';

my $q = new CGI;
my $self_url = $q->script_name();

my $dbo_factory = new SAL::DBI;
my $dbo_data = $dbo_factory->spawn_sqlite(':memory:');
my $gui = new SAL::WebDDR;

#######################################################################################################################
# Build a sample report...
my $report_query = qq[create table ReportData (dfm varchar(255), name varchar(255), purchases int(11), sort int(11))];
$dbo_data->do($report_query);

my $header_dfm = qq|[strong bg=#dddddd solid_over solid_under]|;
my $totals_dfm = qq|[strong dashed_over solid_under]|;

$report_query = qq[insert into ReportData values('$header_dfm Data Formatting Tags','Customer','Purchases','0')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Morris','30','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Albert','22','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Tina','14','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','John','2','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values(' ','Jane','19','1')];
$dbo_data->do($report_query);
$report_query = qq[insert into ReportData values('$totals_dfm','Totals','0','999')];  # we'll replace this 0 later...
$dbo_data->do($report_query);

#######################################################################################################################
# Query Section

$report_query = 'SELECT * FROM ReportData ORDER BY sort, name';
my ($w, $h) = $dbo_data->execute($report_query);


#######################################################################################################################
# Preprocessing Section

# Setup some constants for ease of reading
my $DFMCol = 0;
my $NameCol = 1;
my $PurchasesCol = 2;
my $SortCol = 3;

my $total_purchases = 0;

for (my $y=0; $y <= $h; $y++) {
	my $dtmp = $dbo_data->{data}->[$y][$PurchasesCol];
	if ($dtmp > 0) {
		$total_purchases += $dtmp;
	} elsif ( $dbo_data->{data}->[$y][$SortCol] == '999' ) {
		$dbo_data->{data}->[$y][$PurchasesCol] = $total_purchases;
	}
}


#######################################################################################################################
# Display Section

$gui->{datasource} = $dbo_data;
$gui->{dfm_column} = '0';
$gui->{skip_fields} = 's 0 3 s';
$gui->{default_font_style} = 'font-size: 12px;';

my $report = $gui->build_report();
my $interface = build_interface();
my $toolbar = build_toolbar();

print qq[
<html>
<head>
<title>$report_title</title>
<link rel="stylesheet" type="text/css" href="/css/report.css"/>
</head>
<body>
<a name="top"></a>
$toolbar
$report
$interface
</body>
</html>
];

sub build_interface {
	my $content;

	$content .= qq[
<a name="interface"></a><strong>Report Options</strong><br/>
<a href="#top" style="text-decoration: underline">Back to top</a>  
<a href="more.cgi" style="text-decoration: underline">Change report type</a>  
<a href="javascript:window.print();" style="text-decoration: underline">Print report</a><br/>
<form action="$self_url" method="POST">
<table border=0 cellspacing=0 cellpadding=2>
<tr>
<td style="color: #aaa;">Add interface form for adding report criteria here.</td>
</tr>
<tr>
<td align=left><input type="submit" value="View"></td>
</tr>
</table>
</form>
];

	return $content;
}

sub build_toolbar {
	my $interface_icon = "<a href=\"#interface\"><img src=\"/icons/comp.gray.gif\" alt=\"Report Options\" border=0></a>  ";
	my $help_icon = qq[<a href="" target="_blank"><img src="/icons/unknown.gif" alt="Help" border=0></a>  ];

	return qq[
<table border=0 width=100% cellspacing=0 cellpadding=2>
<tr>
<td align=left valign=top style="border-bottom: 3px double #000;">$report_title</td>
<td align=right valign=top style="border-bottom: 3px double #000;">$interface_icon $help_icon</td>
</tr>
</table><br/>
];
}
