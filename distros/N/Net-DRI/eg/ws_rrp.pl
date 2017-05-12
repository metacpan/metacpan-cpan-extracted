#!/usr/bin/perl -w

use strict;

use Net::DRI;
use Net::DRI::Data::Hosts;

use DateTime::Duration;

my $dri=Net::DRI->new(10);

eval {
############################################################################################################
$dri->add_registry('WS',{tz=>'America/Los_Angeles'});

## This connects to .WS OT&E server
my $rc=$dri->target('WS')->add_current_profile('profile1','rrp',{defer=>0,socktype=>'ssl',remote_host=>'www.worldsite.ws',remote_port=>648,ssl_key_file=>'./privkey.pem',ssl_cert_file=>'./cacert.pem',ssl_ca_file=>'./cacert.pem',ssl_cipher_list=>'TLSv1',protocol_connection=>'Net::DRI::Protocol::RRP::Connection',protocol_version=>1,client_login=>'MyLOGIN',client_password=>'MyPASSWORD'});

my $dom='toto-'.time().'.ws';
$rc=$dri->domain_check($dom);
print "$dom does not exist\n" unless $dri->get_info('exist');
$rc=$dri->domain_create($dom,{pure_create=>1,duration=>DateTime::Duration->new(years =>5)});
print "$dom created\n" if $rc->is_success();
$rc=$dri->domain_check($dom);
print "$dom does exist now\n" if $dri->get_info('exist');
$rc=$dri->domain_info($dom);
print "domain_info OK\n" if $rc->is_success();

my $ns='ns.titi-'.time().'.fr';
my $nso=Net::DRI::Data::Hosts->new($ns);
print "NS=$ns\n";
my $e=$dri->host_exist($ns);
print "Host exist\n" if ($e==1);
if ($e==0)
{
 print "Creating $ns\n";
 $rc=$dri->host_create($nso);
 print "Host created OK\n";
}

$rc=$dri->domain_update_ns_add($dom,$nso);
print "ns_add OK\n" if $rc->is_success();
$rc=$dri->domain_info($dom);
$rc=$dri->domain_update_ns_del($dom,$nso);
print "ns_del OK\n" if $rc->is_success();
$rc=$dri->domain_info($dom);


$rc=$dri->host_delete($nso);
print "host_delete OK\n";

my $s=$dri->create_status()->no('update');
$rc=$dri->domain_update_status_add($dom,$s);
print "status_add OK\n" if $rc->is_success();
$rc=$dri->domain_info($dom);
$rc=$dri->domain_update_status_del($dom,$s);
print "status_del OK\n" if $rc->is_success();
$rc=$dri->domain_info($dom);


$rc=$dri->domain_delete($dom,{pure_delete => 1});
print "domain_delete OK\n" if $rc->is_success();
};

if ($@)
{ 
 print "\n\nAN ERROR happened !!!\n";
 if (ref($@))
 {
  $@->print();
 } else
 {
  print($@);
 }
} else
{
 print "\n\nNo error";
}

print "\n";

exit 0;
