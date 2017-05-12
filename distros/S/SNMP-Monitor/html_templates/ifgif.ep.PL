#! -*- perl -*-

my $script = <<'EOF';
<ep-package name="SNMP::Monitor::EP" require=1>
<ep-snmpmon-auth configuration="~etc_dir~/configuration" user=""
	interface="$cgi->if$">
<ep-database dsn="$snmpmon_config->dbi_dsn$"
             user="$snmpmon_config->dbi_user$"
             password="$snmpmon_config->dbi_pass$">
<ep-snmpmon-ifgif>
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
if (!open(FILE, ">html/ifgif.ep")  ||
    !(print FILE ($script))  ||  !close(FILE)) {
    die "Error while writing html/index.ep file: $!";
}
