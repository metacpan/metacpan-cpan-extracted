#!/usr/bin/perl

# Test the parsing of the bundled dictionary files...

# $Id: bundled.t 98 2009-10-14 15:26:33Z lem $

use Test::Warn;
use Test::More;
use Net::Radius::Dictionary;

my %dict = 
    (
     'dicts/dictionary.base' 
     => { attr => 39, vendor => undef, vsa => 0 },
     'dicts/dictionary.3com-o' 
     => { attr => 3, vendor => 'USR', vsa => 259 },
     'dicts/dictionary' 	
     => { attr => 78, vendor => undef, vsa => 0 },
     'dicts/dictionary.3com' 	
     => { attr => 0, vendor => '3com', vsa => 1 },
     'dicts/dictionary.3gpp2' 	
     => { attr => 0, vendor => '3GPP2', vsa => 74 },
     'dicts/dictionary.3gpp' 	
     => { attr => 0, vendor => '3GPP', vsa => 17 },
     'dicts/dictionary.acc' 	
     => { attr => 0, vendor => 'Acc', vsa => 47 },
     'dicts/dictionary.alcatel' 
     => { attr => 0, vendor => 'Alcatel', vsa => 21 },
     'dicts/dictionary.alteon'  
     => { attr => 0, vendor => 'Alteon', vsa => 1 },
     'dicts/dictionary.altiga'  
     => { attr => 0, vendor => 'Altiga', vsa => 29},
     'dicts/dictionary.aptis'	
     => { attr => 0, vendor => 'Aptis', vsa => 36 },
     'dicts/dictionary.ascend' 
     => { attr => 137, vendor => 'Ascend',vsa => 249 },
     'dicts/dictionary.bay'	
     => { attr=>0,vendor=>'Bay-Networks',vsa => 65 },
     'dicts/dictionary.bintec'	
     => { attr => 0, vendor => 'BinTec', vsa => 17 },
     'dicts/dictionary.bristol'	
     => { attr => 0, vendor => 'Bristol', vsa => 5 },
     'dicts/dictionary.broadsoft' 
     => { attr => 0, vendor => 'BroadSoft', vsa => 132 },
     'dicts/dictionary.cablelabs' 
     => { attr => 0, vendor => 'CableLabs', vsa => 62 },
     'dicts/dictionary.cabletron' 
     => { attr => 0, vendor => 'Cabletron', vsa => 2 },
     'dicts/dictionary.cisco'	
     => { attr => 0, vendor => 'Cisco', vsa => 83 },
     'dicts/dictionary.cisco.bbsm' 
     => { attr => 0, vendor => 'Cisco-BBSM', vsa => 1 },
     'dicts/dictionary.cisco.vpn3000' 
     => { attr => 0, vendor => 'Cisco-VPN3000', vsa => 74 },
     'dicts/dictionary.cisco.vpn5000' 
     => { attr => 0, vendor => 'Cisco-VPN5000', vsa => 7 },
     'dicts/dictionary.colubris' 
     => { attr => 0, vendor => 'Colubris', vsa => 1 },
     'dicts/dictionary.columbia_university' 
     => { attr => 0, vendor => 'Columbia-University', vsa => 4 },
     'dicts/dictionary.compat' 
     => { attr => 21, vendor => undef, vsa => 0 },
     'dicts/dictionary.cosine' 
     => { attr => 0, vendor => 'Cosine', vsa => 8 },
     'dicts/dictionary.erx' 
     => { attr => 0, vendor => 'ERX', vsa => 51 },
     'dicts/dictionary.extreme' 
     => { attr => 0, vendor => 'Extreme', vsa => 4 },
     'dicts/dictionary.foundry' 
     => { attr => 0, vendor => 'Foundry', vsa => 4 },
     'dicts/dictionary.freeradius' 
     => { attr => 0, vendor => 'FreeRADIUS', vsa => 1 },
     'dicts/dictionary.gandalf' 
     => { attr => 0, vendor => 'Gandalf', vsa => 33 },
     'dicts/dictionary.garderos' 
     => { attr => 0, vendor => 'Garderos', vsa => 2 },
     'dicts/dictionary.gemtek' 
     => { attr => 0, vendor => 'Gemtek', vsa => 6 },
     'dicts/dictionary.huawei' 
     => { attr => 0, vendor => 'Huawei', vsa => 52 },
     'dicts/dictionary.itk' 
     => { attr => 0, vendor => 'ITK', vsa => 32 },
     'dicts/dictionary.juniper' 
     => { attr => 0, vendor => 'Juniper', vsa => 5 },
     'dicts/dictionary.karlnet' 
     => { attr => 0, vendor => 'KarlNet', vsa => 4 },
     'dicts/dictionary.livingston' 
     => { attr => 0, vendor => 'Livingston', vsa => 21 },
     'dicts/dictionary.localweb' 
     => { attr => 0, vendor => 'Local-Web', vsa => 15 },
     'dicts/dictionary.merit' 
     => { attr => 0, vendor => 'Merit', vsa => 3 },
     'dicts/dictionary.microsoft' 
     => { attr => 0, vendor => 'Microsoft', vsa => 33 },
     'dicts/dictionary.mikrotik' 
     => { attr => 0, vendor => 'Mikrotik', vsa => 3 },
     'dicts/dictionary.navini' 
     => { attr => 0, vendor => 'Navini', vsa => 1 },
     'dicts/dictionary.netscreen' 
     => { attr => 0, vendor => 'Netscreen', vsa => 7 },
     'dicts/dictionary.nokia' 
     => { attr => 5, vendor => undef, vsa => 0 },
     'dicts/dictionary.nomadix' 
     => { attr => 0, vendor => 'Nomadix', vsa => 13 },
     'dicts/dictionary.propel' 
     => { attr => 0, vendor => 'Propel', vsa => 5 },
     'dicts/dictionary.quintum' 
     => { attr => 0, vendor => 'Quintum', vsa => 23 },
     'dicts/dictionary.redback' 
     => { attr => 0, vendor => 'Redback', vsa => 170 },
     'dicts/dictionary.redcreek' 
     => { attr => 0, vendor => 'RedCreek', vsa => 9 },
     'dicts/dictionary.shasta' 
     => { attr => 0, vendor => 'Shasta', vsa => 3 },
     'dicts/dictionary.shiva'
     => { attr => 0, vendor => 'Shiva', vsa => 16 },
     'dicts/dictionary.sonicwall' 
     => { attr => 0, vendor => 'SonicWall', vsa => 4 },
     'dicts/dictionary.springtide' 
     => { attr => 0, vendor => 'SpringTide', vsa => 8 },
     'dicts/dictionary.t_systems_nova' 
     => { attr => 0, vendor => 'T-Systems-Nova', vsa => 15 },
     'dicts/dictionary.telebit' 
     => { attr => 0, vendor => 'Telebit', vsa => 4 },
     'dicts/dictionary.trapeze' 
     => { attr => 0, vendor => 'Trapeze', vsa => 8 },
     'dicts/dictionary.tunnel' 
     => { attr => 12, vendor => undef, vsa => 0 },
     'dicts/dictionary.unisphere' 
     => { attr => 0, vendor => 'Unisphere', vsa => 49 },
     'dicts/dictionary.unix' 
     => { attr => 0, vendor => 'Unix', vsa => 6 },
     'dicts/dictionary.usr' 
     => { attr => 2, vendor => 'USR', vsa => 259 },
     'dicts/dictionary.valemount' 
     => { attr => 0, vendor => 'ValemountNetworks', vsa => 5 },
     'dicts/dictionary.versanet' 
     => { attr => 0, vendor => 'Versanet', vsa => 1 },
     'dicts/dictionary.wispr' 
     => { attr => 0, vendor => 'WISPr', vsa => 11 },
     'dicts/dictionary.xedia' 
     => { attr => 0, vendor => 'Xedia', vsa => 6 },
    );

plan tests => 6 * keys %dict;

# Determine which dicts are not readable and produce the appropiate skip
for my $d (keys %dict)
{
    unless (-f $d)
    {
	delete $dict{$d};
	fail "Access $d: $!";
      SKIP: { skip "(Consequence of previous failure)", 5 };
	next;
    }

    $dict{$d}->{dict} = new Net::Radius::Dictionary;
    isa_ok($dict{$d}->{dict}, 'Net::Radius::Dictionary');
}

# Verify what happens upon reading the dictionary - Check for warnings
# if the proper module is available
while (my ($dict, $h) = each %dict)
{
    warning_is { $h->{dict}->readfile($dict) } undef, 
    "No warning to readfile('$dict')";
}

# Now check the dictionary contents...

# XXX - These tests peek inside the object. Probably their methods should
# be encapsulated through adequate accessors. However, these functions
# are never required for real use

while (my ($d, $h) = each %dict)
{
    my $dict = $h->{dict};
    my $attr = $dict->{attr};
    is(keys %{$attr}, $dict{$d}->{attr}, "Correct number of attributes in $d");
    my $num = undef;
  SKIP: {
      skip "No vendors defined in $d", 3
	  if not defined $dict{$d}->{vendor};
      warning_is {$num = $dict->vendor_num($dict{$d}->{vendor})} undef, 
      "No warn fetching vendor " . $dict{$d}->{vendor} . " in $d" ;
      ok(defined $num, "Vendor " . $dict{$d}->{vendor} . " in $d");
      is(scalar(keys %{$dict->{vsattr}->{$num}}), 
	 $dict{$d}->{vsa},
	 "Correct number of VSAs for " . $dict{$d}->{vendor} . " in $d");
      # print "$_\n" for keys %{$dict->{vsattr}->{$num}};
  };
}
