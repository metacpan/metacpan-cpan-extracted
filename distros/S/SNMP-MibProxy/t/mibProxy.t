#!perl

use strict;
use warnings;
use Test::More tests => 32;
#use Test::More tests => 8;

$ENV{'PATH'} = '/bin:/usr/bin';
#$ENV{'PERL5LIB'} = 'blib/lib';

# Set DEBUG to 1 if you want to see the diag messages
use constant DEBUG => 0;
# Set CLEAN to 0 if you want to maintain the generated config files
use constant CLEAN => 1;
use constant UPDATEINTERVAL => 3;
my $sysDescrString = 'sysDescr.0';
my $sysDescrValue1 = 'test1';
my $sysDescrValue2 = 'test2';
my $ifNumberString = 'ifNumber.0';
my $ifNumberValue1 = 17;
my $ifNumberValue2 = 21;

sub createMibProxyConfigFile($$$$);
sub createPropertiesFile($$$);
sub getOid($$$);
sub getNextOid($$$);

use_ok('SNMP');
use_ok('Config::Properties');
use_ok('File::Temp', qw(tempdir));

ok(! system("blib/script/mibProxy -v"));
ok(! system("blib/script/mibProxy -h"));
ok(system("blib/script/mibProxy -f /dev/null 2>&1"));


# SysDescr is .1.3.6.1.2.1.1.1
my $sysDescrOid = SNMP::translateObj($sysDescrString);
ok($sysDescrOid);
my $ifNumberOid = SNMP::translateObj($ifNumberString);
ok($ifNumberOid);

SKIP: {
    skip "Mibs not loaded, please check the translation of $sysDescrString and $ifNumberString", 28 if (!defined($sysDescrOid) and !defined($ifNumberOid));
my $dir = tempdir('CLEANUP' => CLEAN);
diag("The temp dir is $dir") if DEBUG;
my $configFile = new File::Temp('UNLINK' => CLEAN, 'TEMPLATE' => 'mibProxyXXXXX', 'SUFFIX' => '.conf', 'DIR' => $dir);
my $configFileName=$configFile->filename;
my $propertiesFileName = File::Spec->catfile($dir, 'logparser.properties');
my $logFileName = File::Spec->catfile($dir, 'mibProxy.log');
createMibProxyConfigFile($configFile, $propertiesFileName, $logFileName, UPDATEINTERVAL);
createPropertiesFile($propertiesFileName, $sysDescrValue1, $ifNumberValue1);

#my $pid;
use_ok('IPC::Open2');
my $pid = open2(*Reader, *Writer, "blib/script/mibProxy -f $configFile" );

# PING
print Writer "PING\n";
my $got = <Reader>;
chomp $got;
is($got, 'PONG', 'Test PING PONG protocol');

# get .1.3.6.1.2.1.1.1.0
my ($oid, $type, $value);
($oid, $type, $value) = getOid(\*Writer, \*Reader, $sysDescrOid);
is($oid, $sysDescrOid, "Comparison in get operation with requested oid and target oid for $sysDescrString = $sysDescrOid");
is($type, 'string', "Check of type string for oid $sysDescrString = $sysDescrOid");
is($value, $sysDescrValue1, "Check of value for oid $sysDescrString = $sysDescrValue1");

($oid, $type, $value) = getOid(\*Writer, \*Reader, $ifNumberOid);
is($oid, $ifNumberOid, "Comparison in get operation with requested oid and target oid for $ifNumberString = $ifNumberOid");
is($type, 'INTEGER32', "Check of type INTEGER32 for oid $ifNumberString = $ifNumberOid");
is($value, $ifNumberValue1, "Check of value for oid $ifNumberString = $ifNumberValue1");

createPropertiesFile($propertiesFileName, $sysDescrValue2, $ifNumberValue2);

# There shouldn't have passed more than 3 seconds, so the values should be the old ones
($oid, $type, $value) = getOid(\*Writer, \*Reader, $sysDescrOid);
is($oid, $sysDescrOid, "Comparison in get operation with requested oid and target oid for $sysDescrString = $sysDescrOid");
is($type, 'string', "Check of type string for oid $sysDescrString = $sysDescrOid");
is($value, $sysDescrValue1, "Check of value for oid $sysDescrString = $sysDescrValue1");

($oid, $type, $value) = getOid(\*Writer, \*Reader, $ifNumberOid);
is($oid, $ifNumberOid, "Comparison in get operation with requested oid and target oid for $ifNumberString = $ifNumberOid");
is($type, 'INTEGER32', "Check of type INTEGER32 for oid $ifNumberString = $ifNumberOid");
is($value, $ifNumberValue1, "Check of value for oid $ifNumberString = $ifNumberValue1");

# Wait for UPDATEINTERVAL
sleep UPDATEINTERVAL + 1;
($oid, $type, $value) = getOid(\*Writer, \*Reader, $sysDescrOid);
is($oid, $sysDescrOid, "Comparison in get operation with requested oid and target oid for $sysDescrString = $sysDescrOid");
is($type, 'string', "Check of type string for oid $sysDescrString = $sysDescrOid");
is($value, $sysDescrValue2, "Check of value for oid $sysDescrString = $sysDescrValue1");

($oid, $type, $value) = getOid(\*Writer, \*Reader, $ifNumberOid);
is($oid, $ifNumberOid, "Comparison in get operation with requested oid and target oid for $ifNumberString = $ifNumberOid");
is($type, 'INTEGER32', "Check of type INTEGER32 for oid $ifNumberString = $ifNumberOid");
is($value, $ifNumberValue2, "Check of value for oid $ifNumberString = $ifNumberValue1");

# GetNext
($oid, $type, $value) = getNextOid(\*Writer, \*Reader, $sysDescrOid);
is($oid, $ifNumberOid, "Comparison in getnext operation with requested oid and target oid for $sysDescrString = $sysDescrOid -> $ifNumberString = $ifNumberOid");
is($type, 'INTEGER32', "Check of type INTEGER32 for getnext oid $sysDescrString = $sysDescrOid -> $ifNumberString = $ifNumberOid");
is($value, $ifNumberValue2, "Check of value for getnext oid $sysDescrString = $sysDescrOid -> $ifNumberString = $ifNumberOid");

# End of MIB should return undef
($oid, $type, $value) = getNextOid(\*Writer, \*Reader, $ifNumberOid);
is($oid, undef, "Comparison in getnext operation with requested oid and target oid for $ifNumberString = $ifNumberOid");


# Close the mibProxy process
close(*Writer);

}

exit 0;

sub createMibProxyConfigFile($$$$) {
    my ($configFile, $propertiesFileName, $logFileName, $updateInterval) = @_;
    my $date = localtime();

    print $configFile <<EOF;
# Automatically generated for $0 at $date
log4perl.logger.mibProxy.Default= DEBUG, A1
log4perl.appender.A1=Log::Dispatch::FileRotate
log4perl.appender.A1.filename=$logFileName
log4perl.appender.A1.DatePattern=yyyy-MM-dd-HH
log4perl.appender.A1.mode=append
log4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.A1.layout.ConversionPattern=%d [%c] %m %n
#
propertiesFile=$propertiesFileName
updateInterval=$updateInterval
EOF
}

sub createPropertiesFile($$$) {
    my ($propertiesFileName, $string, $int) = @_;

    my $properties = new Config::Properties;
    $properties->setProperty($sysDescrString, $string);
    $properties->setProperty($ifNumberString, $int);
    open PROPS, "> $propertiesFileName"
	or die "Cannot write to the $propertiesFileName: $!";
    $properties->store(*PROPS);
    close PROPS;
}

sub getOid($$$) {
    my ($writer, $reader, $requestOid) = @_;
    print $writer "get\n";
    print $writer "$requestOid\n";
    my $oid = <$reader>;
    chomp $oid;
    my $type = <$reader>;
    chomp $type;
    my $value = <$reader>;
    chomp $value;
    diag("$oid $type $value") if (DEBUG);

    return ($oid, $type, $value);
}
sub getNextOid($$$) {
    my ($writer, $reader, $requestOid) = @_;
    print $writer "getnext\n";
    print $writer "$requestOid\n";
    my $oid = <$reader>;
    chomp $oid;
    if ($oid eq 'NONE') {
	return (undef, undef, undef);
    }
    my $type = <$reader>;
    chomp $type;
    my $value = <$reader>;
    chomp $value;
    diag("$oid $type $value") if (DEBUG);

    return ($oid, $type, $value);
}
