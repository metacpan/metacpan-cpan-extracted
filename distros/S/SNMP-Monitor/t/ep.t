# -*- perl -*-

use strict;
$| = 1; $^W = 1;
use Cwd;

# Try to locate ep.cgi
my $haveFileSpec = eval { require File::Spec };
my @path = $haveFileSpec ? File::Spec->path() : split(/:/, $ENV{'PATH'});
my $ep_cgi_path;
foreach my $dir (@path) {
    my $file = $haveFileSpec ?
	File::Spec->catfile($dir, "ep.cgi") : "$dir/ep.cgi";
    if (-x $file) {
	$ep_cgi_path = $file;
	last;
    }
}
if (!$ep_cgi_path) {
    print "1..0\n";
    exit 0;
}

print "1..3\n";
{
    my $numTests = 0;
    sub Test {
	my $result = shift; my $msg = shift;
	if (defined($msg)) { $msg = " $msg" } else { $msg = '' }
	++$numTests;
	print "not " unless $result;
	print "ok $numTests$msg\n";
	$result;
    }
}


$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = '';
$ENV{'PATH_TRANSLATED'} = $haveFileSpec ?
    File::Spec->catdir(Cwd::cwd(), "html", "index.ep") :
    "./html/index.ep";

Test(open(PIPE, sprintf("$^X %s -MSNMP::Monitor::EP %s |",
			join(" ", map { "-I$_" } @INC), $ep_cgi_path)));
my $output;
{
    local $/ = undef;
    Test(defined($output = <PIPE>));
}
my $result;
$result = 1 if $output =~ /SNMP-Monitor - Contents/; # Worked all ok
$result = 1 if $output =~ /Cannot read configuration file/;
	# Could not read /etc/snmpmon/configuration, due to permissions
	# or missing installation - ok.
Test($result);
print $output;
