#! -*- perl -*-

my $script = <<'EOF';
<ep-package name="SNMP::Monitor::EP" require=1>
<ep-snmpmon-auth configuration="~etc_dir~/configuration" user="">
<ep-snmpmon-graph>
<HTML><HEAD>

<STYLE TYPE="text/css">
td {font-size: 11px; font-family: Verdana;}
th {font-size: 11px; font-family: Verdana;}
H1 {font-size: 20px; font-family: Verdana;}
H2 {font-size: 14px; font-family: Verdana;}
H3 {font-size: 14px; font-family: Verdana;}
A:LINK { font-family: Verdana;  color: #0097BF; }
</STYLE>

<TITLE>SNMP-Monitor - Interface utilization</TITLE></HEAD>
<BODY bgcolor="#FFFFFF">
<H1><STRONG>SNMP-Monitor - Interface utilization</STRONG></H1>
<H3>Select interfaces being displayed:</H3>
<CENTER>
<FORM ACTION=graph.ep METHOD=GET>
  <TABLE WIDTH=500>
    <TR BGCOLOR="#CCCCCC"><TH>Interface</TH><TH>Yes/No</TH></TR>
   <ep-list items="snmpmon_interfaces" item="if">
    <TR><TD>$if->interface->short_message$</TD>
        <TD ALIGN=CENTER>
          <INPUT TYPE=checkbox NAME="if_$i$" $if->selected$
           VALUE="$if->host->name$:$if->interface->num$"></TD>
    </TR>
   </ep-list>
  </TABLE>
  <TABLE>
    <TR><TH>Show the last</TH>
        <TD><ep-select range="1..5" item=d name=days
             selected="$cgi->days$"
            ><OPTION $selected$>$d$</ep-select></TD>
        <TH>days until</TH>
        <TD COLSPAN=3><ep-select range="1..31" item=d name=to_d
             selected="$cgi->to_d$"
            ><OPTION $selected$>$d$</ep-select
            >.<ep-select range="1..12" item=m name=to_m
               selected="$cgi->to_m$"
            ><OPTION $selected$>$m$</ep-select
            >.<ep-select range="($_->{date_y}-4).'..'.$_->{date_y}"
               item=y name=to_y selected="$cgi->to_y$"
            ><OPTION $selected$>$y$</ep-select></TD>
    </TR>
    <TR><TH>Scale:</TH>
        <TD><select name="scale">
              <ep-list range="100,75,50,25,10,5,2,1,0.5" item=s
                selected="$cgi->scale$">
	        <OPTION VALUE="$s$" $selected$>$s$ %
              </ep-list>
              <ep-if cnd="$cgi->scale$<0">
	        <OPTION VALUE="-1" selected>Optimal
              <ep-else>
	        <OPTION VALUE="-1">Optimal
              </ep-if>
            </select></TD>
        <TH>Critical Line:</TH>
	<TD><SELECT NAME=critical>
	      <ep-list items=crit item=c>
		<OPTION VALUE="$c->value$" $c->selected$>$c->text$</ep-list>
            </SELECT></TD>
        <TH>Show Average:</TH>
        <TD><INPUT TYPE=checkbox NAME=average $avg_checked$></TD>
    </TR>
  </TABLE>
  <INPUT TYPE=SUBMIT VALUE="Show Me">
</FORM>
</CENTER>
<ep-if eval="$snmpmon_display$">
<H2>Display</H2>
<ep-list items="snmpmon_if_displayed" item="if">
<H3>$if->interface->short_message$</H3>
<CENTER><IMG SRC="ifgif.ep?if=$if->host->name$:$if->interface->num$&scale=$cgi->scale$&to_y=$cgi->to_y$&to_m=$cgi->to_m$&to_d=$cgi->to_d$&days=$cgi->days$&critical=$cgi->critical$&average=$cgi->average$">
</CENTER>
</ep-list>
</ep-if>
</BODY>
</HTML>
EOF

require SNMP::Monitor;
my $config = SNMP::Monitor->Configuration('configuration');

require Config;
$config->{'startperl'} = $Config::Config{'startperl'};
$config->{'startperl'} = $Config::Config{'startperl'}; # Make -w happy ...


$script =~ s/\~(\w+)\~/$config->{$1}/eg;

if (!(-d "html")  &&  !(mkdir "html", 0755)) {
    die "Cannot create directory 'html': $!";
}
if (!open(FILE, ">html/graph.ep")  ||
    !(print FILE ($script))  ||  !close(FILE)) {
    die "Error while writing html/index.ep file: $!";
}
