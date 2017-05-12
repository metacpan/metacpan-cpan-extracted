#!./perl

use lib ".";
use SNMP::Util;
use FileHandle qw(autoflush);
$ENV{'MAX_LOG_LEVEL'} = 'none';

## Local variables.
my(
   $community,
   $errno,
   $host1,
   $instance1,
   $oid,
   $oid1,
   $oid2,
   $oid_num,
   $snmp1,
   $type,
   $value,
   $vars,
   @vals,
   );

$SNMP_FILE = new FileHandle;

($IP,$community) = &get_snmp_data;



$snmp = new SNMP::Util(-device => $IP,
                  -community => $community,
                  -timeout => 5,
                  -retry => 2,
                  -poll => 'on',
                  -poll_timeout => .1,
	          -verbose => 'off',
		  -delimiter => ' ',  # Optional for octets default is space
                 )
    or die "Can't create snmp object for $IP\n";

$test_num = 8;  # Numter of tests to run

print "1..$test_num\n";

$test_num = 1;
#print STDERR "\nTest $test_num - get uptime "; 
@uptime = $snmp->get('nve','sysUpTime.0');

if (!$snmp->error && $uptime[0] =~ /sysUpTime/ && $uptime[1] =~ /^\d+/ && $uptime[2] =~ /day/){
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1;
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok $test_num\n";
}

$test_num++;
#print STDERR "Test $test_num - get sysDescr ";
$sysdescr = $snmp->get('v','sysDescr.0');

if (!$snmp->error && $sysdescr =~ /^[a-zA-Z]+/){
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1;
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok $test_num\n";
    $test_results[$test_num] = 0;
}

@interfaces = $snmp->walk('i','ifAdminStatus');
$interface = $interfaces[$#interfaces-1];


$test_num++;
@oids = ($interface,ifAdminStatus);
#print STDERR "Test $test_num - snmp format Test ";
@result = $snmp->get('oOnNtvei',@oids);
if (!$snmp->error && 
    $result[0] =~ /^1.3.6.1/ && $result[1] =~ /^1.3.6.1/ &&
    $result[2] =~ /^ifAdminStatus\.\d+$/ && $result[3] =~ /^ifAdminStatus$/ &&
    $result[4] =~ /integer/i && $result[5] =~ /^\d+/ &&
    ($result[6] eq 'up' || $result[6] eq 'down') &&
    $result[7] =~ /^\d+/){
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1;
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok $test_num\n";
    $test_results[$test_num] = 0;
}

$test_num++;
@oids = ($interface,ifIndex,ifAdminStatus,ifOperStatus,ifSpeed);
#print STDERR "Test $test_num - snmpget multivarbind ";
@result = $snmp->get('ne',@oids);
if (!$snmp->error && 
    $result[0] =~ /^ifIndex/ && $result[1] =~ /^\d+/ &&
    $result[2] =~ /^ifAdminStatus/ && ($result[3] eq 'up' || $result[3] eq 'down') &&
    $result[4] =~ /^ifOperStatus/ && ($result[5] eq 'up' || $result[5] eq 'down') &&
    $result[6] =~ /^ifSpeed/ && $result[7] =~ /\d+/){
    print "ok $test_num\n";
    #print STDERR "ok \n";
    $test_results[$test_num] = 1; 
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok \n";
    $test_results[$test_num] = 0;
}

$test_num++;
#print STDERR "Test $test_num - snmpset sysContact.0 and restore ";
$sys_contact =  $snmp->get('v',"sysContact.0");
$snmp->set("sysContact.0" => 'test-string');
$result = $snmp->get('v',"sysContact.0");
$snmp->set("sysContact.0" => $sys_contact);
$restore_result = $snmp->get('v',"sysContact.0");

if (!$snmp->error && $result eq 'test-string' && $restore_result eq $sys_contact ){ 
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1;
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok $test_num\n";
    $test_results[$test_num] = 0;
}

$test_num++;
#print STDERR "Test $test_num - snmpnext test ";
@result = $snmp->next('ne',"ifAdminStatus.$interface");

if (!$snmp->error && $result[0] =~ /ifAdminStatus/ && ($result[1] eq 'up' || $result[1] eq 'down')){
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1;
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok $test_num\n";
    $test_results[$test_num] = 0;
}

$test_num++;
@oids = qw(ifAdminStatus ifOperStatus ifSpeed);
#print STDERR "Test $test_num - snmpwalk test ";
@result = $snmp->walk('onte',@oids);

$number_results = @result;
$number_interfaces = @interfaces;
if (!$snmp->error && $number_results == ($number_interfaces * 3 * 4)){ 
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1;
}
else{
    print "not ok $test_num\n";
    #print STDERR "not ok $test_num\n";
    $test_results[$test_num] = 0;
}

@oids = qw(ifAdminStatus ifOperStatus ifSpeed);
$test_num++;
#print STDERR "Test $test_num - snmpwalk_hash test ";
$hash = $snmp->walk_hash('e',@oids);
@indexes = sort by_index (keys %{$hash->{$oids[0]}});
if (!$snmp->error && @indexes == @interfaces){ 
    print "ok $test_num\n";
    #print STDERR "ok $test_num\n";
    $test_results[$test_num] = 1; 
}
else{
    #print STDERR "not ok $test_num\n";
    $test_results[$test_num] = 0;
    
}



sub by_index {
    local($i, @a, @b);

    @a = split (/\./, $a);
    @b = split (/\./, $b);

    if (@a > @b) {
        $#b = $#a;
    }
    elsif (@b > @a) {
        $#a = $#b;
    }

    for ($i = 0; $i <= $#a; $i++) {
        return ($a[$i] <=> $b[$i]) unless ($a[$i] == $b[$i]);
    }

    0;
}

sub usage{
   print "Usage: \n";
   print "       snmptest <IP> <community string> \n";
   print "\n";
   print "       IP = IP address or Switch name\n";
   print "       comm = defaults to hostname\n";
   exit;
}

sub get_snmp_data{

   my(
     $community,
     $IP,
     @Fld,
     @snmp_data,
     );

   if (-e "./snmp.data"){
      open ($SNMP_FILE,"./snmp.data") || die "Can't open file ./snmp.data\n";
   }
   else{
      open ($SNMP_FILE,"t/snmp.data") || die "Can't open file t/snmp.data\n";
   }

   while (<$SNMP_FILE>){
      @Fld = split(' ',$_);
      if ($Fld[0] =~ /ip/i){
         $IP = $Fld[2];
      }
      elsif ($Fld[0] =~ /community/i){
         $community = $Fld[2];
      }
   }
   push @snmp_data,$IP,$community;
   @snmp_data;
}

