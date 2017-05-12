#!/sw/bin/perl -w

use warnings;
use strict;
use Test::More qw(no_plan);

BEGIN {
	use Data::Dumper;
	use Carp;
	use_ok("NetSNMP::OID");
	use_ok("SNMP::Class");
}

my $s = SNMP::Class->new({ DestHost => 'localhost' });
$s->deactivate_bulkwalks;


###my $ifTable = $s->walk("ifTable");

#$ifTable->label("ifDescr","ifSpeed");
#print $ifTable->value("en0")->dump;
#print $ifTable->find("ifDescr"=>"en0")->ifSpeed;

my $ipf = $s->walk("ipForwarding")->value;

unless ($ipf->is_forwarding) {
	print STDERR "NOT forwarding\n\n";
}




exit;


my $oid = NetSNMP::OID->new(".1.2.3.4.5");

my $oid10 = SNMP::Class::OID->new($oid);

my $oid2 = SNMP::Class::OID->new(".1.2.3.4.5");

my $oid4 = SNMP::Class::OID->new(".1.2.3.4.5.6");


my $oid_z = SNMP::Class::OID->new("0");
my $oid_dotz = SNMP::Class::OID->new(".0");

my $oid3 = SNMP::Class::OID->new_from_string("foo");

my $oid9 = $oid2 . ".1.2.3";
my $oid99 = ".1.2.3" . $oid2;

my $zDz = SNMP::Class::OID->new("0.0");


ok($oid9->numeric eq '.1.2.3.4.5.1.2.3',"Concatenation of object and string");
ok($oid99->numeric eq '.1.2.3.1.2.3.4.5',"Reverse concatenation");
ok(($oid2.$oid2)->numeric eq '.1.2.3.4.5.1.2.3.4.5',"Concatenation of objects");
ok(($oid2.$zDz)->numeric eq '.1.2.3.4.5',"Concatenation of object to zeroDotZero");
ok(($zDz.$oid2)->numeric eq '.1.2.3.4.5',"Concatenation of zeroDotZero to object");
ok($oid2 == SNMP::Class::OID->new($oid),"basic OID comparison and construction from NetSNMP::OID");
ok($oid2 == ".1.2.3.4.5","Comparison to string");
ok($oid2 > ".1.2.3","Comparison to smaller oid");
ok($oid2 < ".1.2.3.4.5.6","Comparison to bigger oid");
ok($oid2 < ".1.2.3.4.6","Comparison to bigger oid (2)");
ok($oid2 < ".2.2.3.4.5","Comparison to bigger oid (3)");
ok($oid2 > ".1.1.3.4.5","Comparison to smaller oid (2)");
ok($oid2 == $oid2,"Comparison");
ok('1.2.3.4.5' == $oid2,"reverse comparison");
ok($oid2->oid_is_equal($oid2),"Comparison using oid_is_equal");
ok($oid2->oid_is_equal('.1.2.3.4.5'),"Comparison using oid_is_equal");
ok($oid2 eq $oid2,"Comparison using cmp");
ok($oid2->contains($oid4),"Hierarchy checking");
ok($oid2->contains(".1.2.3.4.5.6"),"Hierarchy checking with string argument");
ok($oid3 == SNMP::Class::OID->new(".3.102.111.111"),"String conversion test");
ok($oid2->[0] eq 1,"array reference overloading subscript");
ok($oid_z->to_array eq 0,"zero oid numeric representation"); 
ok($oid_z->numeric eq '.0',"zero oid string representation"); 
ok($oid_dotz->to_array eq (0),"zero oid numeric representation"); 
ok($oid_dotz->numeric eq '.0',"zero oid string representation"); 
ok($oid2->numeric eq ".1.2.3.4.5" ,"oid numeric method");
ok($oid2->slice(1,2,3,4) == SNMP::Class::OID->new(".1.2.3.4"),"oid slicing explicit");
ok($oid2->slice(1,4) == SNMP::Class::OID->new(".1.2.3.4"),"oid slicing implicit");
ok($oid2->slice(1..4) == SNMP::Class::OID->new(".1.2.3.4"),"oid slicing with range");
ok($oid2->slice(1..1) == SNMP::Class::OID->new(".1"),"oid slicing with 1 member");
ok($oid2->slice(1) == SNMP::Class::OID->new(".1"),"oid slicing with 1 argument");
eval { $oid2->slice(2,1) }; ok($@,"reverse slice failure");
#####
my $oid15 = SNMP::Class::OID->new("ifDescr.14");
ok($oid15->get_label_oid == "ifDescr","get_label_oid on ifDescr.14");
ok($oid15->get_instance_oid == ".14","get_instance_oid on ifDescr.14");
my $oid16 = SNMP::Class::OID->new("ifTable");
ok($oid16->get_label_oid == "ifTable","get_label_oid on ifTable");
ok(!defined($oid16->get_instance_oid),"get_instance_oid on ifTable");
my $oid17 = SNMP::Class::OID->new(".10.11.12");
ok(!defined($oid17->get_label_oid),"get_label_oid on something that does not exist");
ok(!defined($oid17->get_instance_oid),"get_instance_oid on something that does not exist");
my $oid18 = SNMP::Class::OID->new("sysUpTime.0");
ok($oid18->get_label_oid == "sysUpTimeInstance","get_label_oid on sysUpTime");
ok(!defined($oid18->get_instance_oid),"get_instance_oid on something that does not exist");
my $oid19 = SNMP::Class::OID->new("sysName.0");
ok($oid19->get_label_oid == "sysName","get_label_oid on ifDescr.14");
ok($oid19->get_instance_oid == ".0","get_instance_oid on ifDescr.14");


#.3.102.111.111
#

my $v1 = SNMP::Class::Varbind->new(oid=>$oid9);
my $v2 = SNMP::Class::Varbind->new(oid=>".1.2.3.4.5.1.2.3");
my $v3 = SNMP::Class::Varbind->new(oid=>$oid15,raw_value=>"ethernet0",type=>"OCTET_STRING");
my $v5 = SNMP::Class::Varbind->new(oid=>"ipAdEntAddr.1.2.3.4",value=>"192.168.1.1");
my $v6 = SNMP::Class::Varbind->new(oid=>"sysUpTime.0", raw_value=>"1111");
isa_ok($v1,"SNMP::Class::Varbind");
isa_ok($v2,"SNMP::Class::Varbind");
isa_ok($v3,"SNMP::Class::Varbind");
isa_ok($v5,"SNMP::Class::Varbind");
isa_ok($v5,"SNMP::Class::Varbind::IpAddress");
isa_ok($v6,"SNMP::Class::Varbind::SysUpTime");
print $v6->get_absolute,"\n";
ok($v3->generate_varbind->isa("SNMP::Varbind"),"generate_varbind check");
ok($v3->dump eq "ifDescr.14 ethernet0 OCTET_STRING","dump method");
my $vb1 = SNMP::Varbind->new(["ifDescr.33"]);
isa_ok($vb1,"SNMP::Varbind");
my $v4 = SNMP::Class::Varbind->new(varbind=>$vb1);
isa_ok($v4,"SNMP::Class::Varbind");






#print $ifTable->get_value;

#my $ifDescr = $ifTable->object("ifDescr");

#print $ifDescr.1,"\n";


#####print $ifTable->object("ifDescr").3,"\n";


####print $ifTable->find("ifDescr","en0")->object("ifSpeed")->value,"\n";
