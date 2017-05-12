#! -*- perl -*-

my $script = <<'EOF';
<ep-package name="SNMP::Monitor::EP" require=1>
<ep-snmpmon-auth configuration="~etc_dir~/configuration" user="">
<ep-snmpmon-index>
<HTML><HEAD>
<STYLE TYPE="text/css">
td {font-size: 11px; font-family: Verdana;} 
th {font-size: 11px; font-family: Verdana;}
H1 {font-size: 20px; font-family: Verdana;}
H3 {font-size: 14px; font-family: Verdana;}
A:LINK { font-family: Verdana;  color: #0097BF; } 
</STYLE>
<TITLE>SNMP-Monitor - Contents</TITLE></HEAD>
<BODY BGCOLOR="#FFFFFF">
<H1><strong>SNMP-Monitor - Contents</strong></H1>
  <P><font face="verdana" size=2>The SNMP monitor offers you the following
  possibilities:</font></P>
  <UL>
    <LI><H3>Show a graphical representation of the interface
	    utilization</H3>
	<FORM ACTION=graph.ep METHOD=GET><CENTER>
	<TABLE WIDTH=500>
	  <TR BGCOLOR="#CCCCCC"><TH>Interface</TH><TH>Yes/No</TH></TR>
	 <ep-list items="snmpmon_interfaces" item="if">
	  <TR><TD>$if->interface->short_message$</TD>
              <TD ALIGN=CENTER>
                <INPUT TYPE=checkbox NAME="if_$i$"
                 VALUE="$if->host->name$:$if->interface->num$"></TD>
          </TR>
         </ep-list>
        </TABLE>
        <TABLE WIDTH=500>
          <TR>
            <TH>Show the last</TD>
            <TD><ep-select name=days range="1..5" item=d
                ><OPTION>$d$</ep-select></TD>
            <TH>days until</TH>
            <TD><ep-select name=to_d range="1..31" item=d
                 selected="$date_d$"
                ><OPTION $selected$>$d$</ep-select
                >.<ep-select name=to_m range="1..12" item=m
                 selected="$date_m$"
                ><OPTION $selected$>$m$</ep-select
                >.<ep-select name=to_y item=y
                 range="($_->{'date_y'}-4).'..'.$_->{'date_y'}"
                 selected="$date_y$"
                ><OPTION $selected$>$y$</ep-select></TD>
          <TR>
            <TH>Scale:</TH>
            <TD><select name=scale>
		  <ep-list range="100,75,50,25,10,5,2,1,0.5" item=s>
		    <option value=$s$>$s$ %
		  </ep-list>
		    <option value=-1>Optimal
                </select></TD>
          </TABLE>
          <INPUT TYPE=SUBMIT VALUE="Show Me"></CENTER>
        </FORM>
    <LI><H3>Show interface statistics</H3>
	<FORM ACTION=stats.ep METHOD=GET><CENTER>
        <TABLE WIDTH=500>
	  <TR BGCOLOR="#CCCCCC"><TH>Interface</TH><TH>Yes/No</TH></TR>
	 <ep-list items="snmpmon_interfaces" item="if">
	  <TR><TD>$if->interface->short_message$</TD>
              <TD ALIGN=CENTER>
                <INPUT TYPE=checkbox NAME="if_$i$"
                 VALUE="$if->host->name$:$if->interface->num$"></TD>
          </TR>
         </ep-list>
        </TABLE>
        <TABLE>
          <TR><TH>From:</TD>
              <TD><ep-select name=from_d range="1..31" item=d
                   selected="$from_d$"
                  ><OPTION $selected$>$d$</ep-select></TD>
              <TD>.</TD>
              <TD><ep-select name=from_m range="1..12" item=m
                   selected="$from_m$"
                  ><OPTION $selected$>$m$</ep-select></TD>
              <TD>.</TD>
              <TD><ep-select name=from_y item=y
                   range="($_->{'date_y'}-4).'..'.$_->{'date_y'}"
                   selected="$from_y$"
                  ><OPTION $selected$>$y$</ep-select></TD>
          <TR><TH>To:</TD>
              <TD><ep-select name=to_d range="1..31" item=d
                   selected="$to_d$"
                  ><OPTION $selected$>$d$</ep-select></TD>
              <TD>.</TD>
              <TD><ep-select name=to_m range="1..12" item=m
                   selected="$to_m$"
                  ><OPTION $selected$>$m$</ep-select></TD>
              <TD>.</TD>
              <TD><ep-select name=to_y item=y
                   range="($_->{'date_y'}-4).'..'.$_->{'date_y'}"
                   selected="$to_y$"
                  ><OPTION $selected$>$y$</ep-select></TD>
            </TABLE>
          <INPUT TYPE=SUBMIT VALUE="Show Me"></CENTER>
        </FORM>
  </UL>
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
if (!open(FILE, ">html/index.ep")  ||
    !(print FILE ($script))  ||  !close(FILE)) {
    die "Error while writing html/index.ep file: $!";
}
