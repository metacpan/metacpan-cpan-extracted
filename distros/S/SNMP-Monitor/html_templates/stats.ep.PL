#! -*- perl -*-

my $script = <<'EOF';
<ep-package name="SNMP::Monitor::EP" require=1>
<ep-snmpmon-auth configuration="~etc_dir~/configuration" user="">
<ep-snmpmon-stats>
<HTML><HEAD>

<STYLE TYPE="text/css">
td {font-size: 11px; font-family: Verdana;}
th {font-size: 11px; font-family: Verdana;}
H1 {font-size: 20px; font-family: Verdana;}
H2 {font-size: 14px; font-family: Verdana;}
H3 {font-size: 14px; font-family: Verdana;}
A:LINK { font-family: Verdana;  color: #0097BF; }
</STYLE>

<TITLE>SNMP-Monitor - Interface statistics</TITLE></HEAD>
<BODY BGCOLOR="#FFFFFF">
<H1><STRONG>SNMP-Monitor - Interface statistics</STRONG></H1>
<CENTER>
<FORM ACTION=stats.ep METHOD=GET>
<TABLE WIDTH=600>
  <TR BGCOLOR="#CCCCCC"><TH>Interface</TH><TH>Yes/No</TH></TR>
 <ep-list items="snmpmon_interfaces" item="if">
  <TR><TD>$if->interface->short_message$</TD>
      <TD VALIGN=CENTER>
        <INPUT TYPE=checkbox NAME="if_$i$" $if->selected$
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
<INPUT TYPE=SUBMIT VALUE="Show Me">
</FORM>
</CENTER>
<ep-if eval=$snmpmon_display$>
<ep-database dsn="$snmpmon_config->dbi_dsn$"
             user="$snmpmon_config->dbi_user$"
             password="$snmpmon_config->dbi_pass$">
<ep-snmpmon-stats2>
<H3>Interface stats</H3>
<CENTER>
<P>
<TABLE WIDTH=300>
  <TR BGCOLOR="#CCCCCC">
    <TH>From:</TH>
    <TH>To:</TH>
    <TH>Secs:</TH>
  </TR>
  <TR>
    <TD>$from_d$-$from_m$-$from_y$</TD>
    <TD>$to_d$-$to_m$-$to_y$</TD>
    <TD ALIGN=RIGHT>$secs$</TD>
  </TR>
</TABLE>
</P>
<TABLE WIDTH=600>
  <TR BGCOLOR="#CCCCCC">
    <TH>Interface</TH><TH>Incoming Octets</TH><TH>Outgoing Octets</TH>
    <TH>Sum</TH><TH>Average (Bit/sec)</TH><TH>Uptime (Percent)</TH></TR>
 <ep-list items="snmpmon_if_displayed" item="if">
  <TR><TD>$if->interface->short_message$</TD>
      <TD ALIGN=RIGHT>$if->in_octets$</TD>
      <TD ALIGN=RIGHT>$if->out_octets$</TD>
      <TD ALIGN=RIGHT>$if->sum_octets$</TD>
      <TD ALIGN=RIGHT>$if->avg_octets$</TD>
      <TD ALIGN=RIGHT>$if->up_percent$</TD></TR>
 </ep-list>
</TABLE>
</CENTER>
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
if (!open(FILE, ">html/stats.ep")  ||
    !(print FILE ($script))  ||  !close(FILE)) {
    die "Error while writing html/stats.ep file: $!";
}
