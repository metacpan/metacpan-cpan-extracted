#!/usr/bin/perl
#
# Salesforce.com and SOAP::Lite demonstration code
#

use CGI qw(:standard);
use Salesforce;

my %FIELDS = ( 'lead' => [ qw(Id Salutation FirstName LastName Company Title LeadSource Industry AnnualRevenue Phone MobilePhone Fax Email Website Status Rating Employees EmailOptOut Street City State Zip Country Description) ]
	      );

my $DATATYPE = param('type') || 'lead';
my $LIMIT    = param('per') || 10;
my $ACTION   = param('action') || 'list';
my $SESSION  = cookie('sf_session');

my $service = new Salesforce::SforceService;
my $port = $service->get_port_binding('Soap');

#print header(-type => 'text/html');
#foreach my $key (keys %ENV) {
#    print $key."=".$ENV{$key}."<br />";
#}
#exit;

if (param('submit') eq 'Change Columns') {
    my $cookie = cookie( -NAME => 'sf_columns',
			 -VALUE => join(',',param('col')));
    print header( -COOKIE => $cookie,
		  -LOCATION => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}?action=list");
    exit;
} elsif (param('submit') eq 'Login') {
    my $result = $port->login('username' => param('username'),
			      'password' => param('password'));
    my $cookie = cookie( -NAME => 'sf_session',
			 -VALUE => $port->{'sessionId'});
    print header( -COOKIE => $cookie,
		  -LOCATION => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}?action=list");
    exit;
}
my $COLUMNS  = cookie('sf_columns') || 'Id,FirstName,LastName';

$port->{'sessionId'} = $SESSION;

print header( -TYPE => 'text/html' );
print_header();
if (!$SESSION) {
    login();
} else {
    &$ACTION;
}
print_footer();

sub login {
    print <<END_HTML;
<form method="get" action="$ENV{SCRIPT_NAME}">
  <b>Username:</b><br /><input type="text" name="username" size="30" /><br />
  <b>Password:</b><br /><input type="password" name="password" size="30" /><br />
<br /><input type="submit" name="submit" value="Login" />
</form>
END_HTML
}

sub chcol {
    print <<END_HTML;
<form method="get" action="$ENV{SCRIPT_NAME}">
<input type="hidden" name="type" value="$DATATYPE" />
END_HTML
    foreach my $col (@{$FIELDS{$DATATYPE}}) {
	print "<input type=\"checkbox\" name=\"col\" value=\"$col\"";
	if ($COLUMNS =~ /$col/) {
	    print " checked=\"1\"";
	}
	print " />&nbsp;$col<br />\n";
    }
    print <<END_HTML;
<br /><input type="submit" name="submit" value="Change Columns" />
</form>
END_HTML
}

sub list {
    print <<END_HTML;
<p>
Results per page:
<select name="per">
  <option>10</option>
  <option>20</option>
  <option>30</option>
</select>
</p>
<table width="100%" cellspacing="0" cellpadding="2" border="0">
  <tr bgcolor="#CCCCCC">
    <td></td>
END_HTML
foreach my $col (split(',',$COLUMNS)) {
    print "<td><b>$col</b></td>";
}
print '  </tr>';

my $query_str = "select $COLUMNS from $DATATYPE";
$result = $port->query('query' => $query_str,
		       'limit' => $LIMIT);
if ($result->fault()) {
    print $result->faultstring();
    print "<br /> $query_str <br />"
} else {
    my $i = 0;
    foreach my $elem ($result->valueof('//queryResponse/result/records')) {
	print "<tr".($i % 2 == 0 ? " bgcolor=\"#EEEEEE\"" : "").">";
	printf "<td>%d.</td>",++$i;
	foreach my $col (split(',',$COLUMNS)) {
	    printf "<td>%s</td>",$elem->{$col};
	}
	print "</tr>\n";
    }
}
print '</table>'."\n";

print <<END_HTML;
<br />
<center>
  <a href="$ENV{SCRIPT_NAME}?action=chcol&type=$DATATYPE">Change Columns</a>
</center>
END_HTML
}

sub print_header {
    print <<END_HTML;
<html>
<head><title>sforce SOAP::Lite Demonstration</title>
<meta NAME="Description" CONTENT="sforce">
<meta NAME="Keywords" CONTENT="web services, developers">
<!--<script TYPE="text/javascript" LANGUAGE="JavaScript" SRC="http://www.sforce.com/web-common/js/global_styles.js"></SCRIPT>-->
<script TYPE="text/javascript" LANGUAGE="JavaScript" SRC="http://www.sforce.com/web-common/js/global_functions.js"></SCRIPT>
<script TYPE="text/javascript" LANGUAGE="JavaScript" SRC="http://www.sforce.com/web-common/js/detectFlash.js"></SCRIPT>
</head>

<body BGCOLOR="#EEEEEE" TEXT="#000000" LINK="#003366" VLINK="#666666" ALINK="#003366" MARGINWIDTH="0" MARGINHEIGHT="0" LEFTMARGIN="0" TOPMARGIN="0" >

<center>
<table CELLPADDING="0" CELLSPACING="0" BORDER="0" WIDTH="772" bgcolor="#FFFFFF"> 
<tr>
	<td bgcolor="#cccccc" rowspan="999"><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="1" border="0"></td>
	<td colspan="3"><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="15" border="0"></td>
	<td bgcolor="#cccccc" rowspan="999"><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="1" border="0"></td>
</tr>
<tr>
	<td><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="10" height="1" border="0"></td>
	<td>

		<table CELLPADDING="0" CELLSPACING="0" BORDER="0"> 
			<tr>
				<td>
					<table CELLPADDING="0" CELLSPACING="0" BORDER="0" WIDTH="100%">
						<tr>
							<td width="174"><a href="/us/"><img src="http://www.sforce.com/us/assets/logos/sforce_logo_174x79.gif" alt="" width="174" height="79" border="0"></a></td>
							<td>&#160;&#160;</td>
							<td>
								<table CELLPADDING="0" CELLSPACING="0" BORDER="0" WIDTH="100%">

									<tr><td>&#160;</td></tr>
									<tr>
										<td BGCOLOR="#CC0000" ALIGN="LEFT"  COLSPAN="2"><div style="margin-left: 10px; margin-right: 2px; margin-top: 3px; margin-bottom: 3px;"><img src="http://www.sforce.com/us/assets/sfdc_tagline.gif" alt="" border="0"></div></td>
									</tr>
									<tr>
										<td><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="1" border="0"></td>
									</tr>
									<tr>
										<td BGCOLOR="#000000"  COLSPAN="2"><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="1" border="0"></td>

									</tr>
									<tr>
										<td><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="3" border="0"></td>
									</tr>
									<tr>
										
										<td align="CENTER" VALIGN="TOP" nowrap><div style="margin-left: 0px; margin-right: 0px; margin-top: 5px; margin-bottom: 5px; text-decoration: none;"><a href="/us/index.jsp" target="_parent"><img src="http://www.sforce.com/us/assets/home.gif" alt="" width="44" height="13" border="0"></a>&#160;&#160;<a href="/us/solutions/" target="_parent"><img src="http://www.sforce.com/us/assets/solutions.gif" alt="" height="13" border="0"></a>&#160;&#160;<a href="/us/resources/" target="_parent"><img src="http://www.sforce.com/us/assets/resources.gif" alt="" width="67" height="13" border="0"></a>&#160;&#160;<a href="/us/community/index.jsp" target="_parent"><img src="http://www.sforce.com/us/assets/community.gif" alt="" width="74" height="13" border="0"></a>&#160;&#160;<a href="/us/newsevents/" target="_parent"><img src="http://www.sforce.com/us/assets/newsevents.gif" alt="" border="0"></a>&#160;&#160;<a href="/us/showcase/" target="_parent"><img src="http://www.sforce.com/us/assets/showcase.gif" alt="" width="65" height="13" border="0"></a>&#160;&#160;</div></td>
										<td><a href="https://www.sforce.com/us/login.jsp?loc=de" target="_parent"><img src="http://www.sforce.com/us/assets/dev_edition.gif" alt="" width="108" height="18" border="0"></a></td>
									
									</tr>
									<tr>
										<td><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="3" border="0"></td>
									</tr>
									<tr>
										<td BGCOLOR="#000000" COLSPAN="2"><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="1" border="0"></td>
									</tr>
									<tr>
										<td BACKGROUND="http://www.sforce.com/us/assets/red_dot.gif" COLSPAN="2"><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="3" border="0"></td>
									</tr>
									
								</table>

							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr><td><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="1" height="15" border="0"></td></tr>
			<tr>
				<td COLSPAN="3">
					<table WIDTH="750" CELLPADDING="0" CELLSPACING="0" BORDER="0">
<tr>
	<td height="40" valign="middle" style="border-bottom: 2px solid #CC0000; border-top: 1px solid #CCCCCC; border-left: 1px solid #CCCCCC;"><img src="http://www.sforce.com/us/assets/mast-head.gif" border="0"></td>
	<td height="40" valign="middle" style="border-bottom: 2px solid #CC0000; border-top: 1px solid #CCCCCC; border-right: 1px solid #CCCCCC;" align=right><img src="http://www.sforce.com/us/assets/mast_nosobug.gif" border="0"></td>	
</tr>
<tr>
	<!-- ***** begin main cell ***** -->
	<td valign="top" width="100%" align="left">
		<table bgColor=#ffffff cellSpacing=0 cellPadding=0 border="0" width="550">
			<tr><td><br><br></td></tr>
			<tr valign="top">

				<td>
<!-- BEGIN CONTENT -->
END_HTML
}

sub print_footer {
    print <<END_HTML;
<!-- END CONTENT -->

				</td>
			</tr>
			<tr><td><br><br></td></tr>			
			
		</table>
	</td>
	<!-- ***** end main cell ***** -->

	<td><img src="http://www.sforce.com/us/assets/1x1_spacer.gif" alt="" width="5" height="1" border="0"></td>

</tr>
</table>
</center>
</body>
</html>

END_HTML
}
