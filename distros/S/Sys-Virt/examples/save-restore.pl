#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;

my $xml = <<EOF;
<domain type='kvm'>
  <name>perl-demo</name>
  <memory>219200</memory>
  <currentMemory>219136</currentMemory>
  <vcpu>1</vcpu>
  <os>
    <type arch='i686'>hvm</type>
    <boot dev='network'/>
  </os>
  <features>
    <acpi/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <serial type='pty'>
      <target port='0'/>
    </serial>
  </devices>
</domain>
EOF


my $conn = Sys::Virt->new(uri => "qemu:///session");

print "Starting a transient guest\n";
my $dom = $conn->create_domain($xml);

print "Saving the guest\n";

my $curxml = $dom->get_xml_description();

$dom->save("perl-demo.img", $curxml, Sys::Virt::Domain::SAVE_BYPASS_CACHE);

my $newxml = $conn->get_save_image_xml_description("perl-demo.img");

print $newxml;

print "Restoring the guest\n";
$conn->restore_domain("perl-demo.img", $newxml, Sys::Virt::Domain::SAVE_BYPASS_CACHE);

print "Destroying the guest\n";
$dom = $conn->get_domain_by_name("perl-demo");
$dom->destroy;

unlink "perl-demo.img";
