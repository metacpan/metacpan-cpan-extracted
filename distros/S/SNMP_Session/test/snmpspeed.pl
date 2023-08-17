#!/usr/local/bin/perl
# -*- mode: Perl -*-
##################################################################
# Config file creator
##################################################################
# Created by Tobias Oetiker <oetiker@ee.ethz.ch>
# this produces a config file for one router, by bulling info
# off the router via snmp
#################################################################
#
# Distributed under the GNU copyleft
#
# $Id: snmpspeed.pl,v 1.3 2001-11-14 13:24:32 leinen Exp $
#
use SNMP_Session "0.54";
$SNMP_Session::default_timeout = 0.2;
$SNMP_Session::default_backoff = 1.5;
  
use BER "0.51";

%snmpget::OIDS = (  'sysDescr' => '1.3.6.1.2.1.1.1.0',
		    'sysContact' => '1.3.6.1.2.1.1.4.0',
		    'sysName' => '1.3.6.1.2.1.1.5.0',
		    'sysLocation' => '1.3.6.1.2.1.1.6.0',
		    'sysUptime' => '1.3.6.1.2.1.1.3.0',
		    'ifNumber' =>  '1.3.6.1.2.1.2.1.0',
		    ###################################
		    # add the ifNumber ....
   # add the ifNumber ....
   'ifDescr' => '1.3.6.1.2.1.2.2.1.2',
   'ifType' => '1.3.6.1.2.1.2.2.1.3',
   'ifIndex' => '1.3.6.1.2.1.2.2.1.1',
   'ifInErrors' => '1.3.6.1.2.1.2.2.1.14',
   'ifOutErrors' => '1.3.6.1.2.1.2.2.1.20',
   'ifInOctets' => '1.3.6.1.2.1.2.2.1.10',
   'ifOutOctets' => '1.3.6.1.2.1.2.2.1.16',
   'ifInDiscards' => '1.3.6.1.2.1.2.2.1.13',
   'ifOutDiscards' => '1.3.6.1.2.1.2.2.1.19',
   'ifInUcastPkts' => '1.3.6.1.2.1.2.2.1.11',
   'ifOutUcastPkts' => '1.3.6.1.2.1.2.2.1.17',
   'ifInNUcastPkts' => '1.3.6.1.2.1.2.2.1.12',
   'ifOutNUcastPkts' => '1.3.6.1.2.1.2.2.1.18',
   'ifInUnknownProtos' => '1.3.6.1.2.1.2.2.1.15',
   'ifOutQLen' => '1.3.6.1.2.1.2.2.1.21',
   'ifSpeed' => '1.3.6.1.2.1.2.2.1.5',
 		    'ifDescr' => '1.3.6.1.2.1.2.2.1.2',
		    'ifType' => '1.3.6.1.2.1.2.2.1.3',
		    'ifIndex' => '1.3.6.1.2.1.2.2.1.1',
		    'ifSpeed' => '1.3.6.1.2.1.2.2.1.5', 
		    'ifOperStatus' => '1.3.6.1.2.1.2.2.1.8',		 
		    'ifAdminStatus' => '1.3.6.1.2.1.2.2.1.7',		 
		    # up 1, down 2, testing 3
		    'ipAdEntAddr' => '1.3.6.1.2.1.4.20.1.1',
		    'ipAdEntIfIndex' => '1.3.6.1.2.1.4.20.1.2',
		    'sysObjectID' => '1.3.6.1.2.1.1.2.0',
		    'CiscolocIfDescr' => '1.3.6.1.4.1.9.2.2.1.1.28',
		    'CiscoportIndex' => '1.3.6.1.4.1.9.5.1.4.1.1.2',
		    'CiscoportName' => '1.3.6.1.4.1.9.5.1.4.1.1.4',
		    'CiscoportIfIndex' => '1.3.6.1.4.1.9.5.1.4.1.1.11',
		    'CiscoswPortName' => '1.3.6.1.4.1.437.1.1.3.3.1.1.3',

		 );




sub main {

    my $session = SNMP_Session->open ('ezci1.ethz.ch', 'public', 161)
	|| die "open SNMP session: $SNMP_Session::errmsg";
    $|=1;
for (my $i=0;$ i < 100; $i++){
    print "$i, ";# if $i % 10 ==0; 
    my($ifinoct) = snmpget($session,'ifInOctets.1');
    $ifinoct = snmpget($session,'ifInOctets.2');
}
    $session->close ()
	|| die "close SNMP session: $SNMP_Session::errmsg";
}  
main;
exit(0);

sub snmpget {
  my($session,@vars) = @_;
  my(@enoid, $var,$response, $bindings, $binding, $value, $inoid,$outoid,
     $upoid,$oid,@retvals);
  foreach $var (@vars) {
    if ($var =~ /^([a-z]+)/i) {
      my $oid = $snmpget::OIDS{$1};
      if ($oid) {
        $var =~ s/$1/$oid/;
      } else {
        die "Unknown SNMP var $var\n"
      }
    }
    print "SNMPGET OID: $var\n" if $main::DEBUG >5;
    push @enoid,  encode_oid((split /\./, $var));
  }
  srand();
  if ($session->get_request_response(@enoid)) {
    $response = $session->pdu_buffer;
    ($bindings) = $session->decode_get_response ($response);
    while ($bindings) {
      ($binding,$bindings) = decode_sequence ($bindings);
      ($oid,$value) = decode_by_template ($binding, "%O%@");
      my $tempo = pretty_print($value);
      $tempo=~s/\t/ /g;
      $tempo=~s/\n/ /g;
      $tempo=~s/^\s+//;
      $tempo=~s/\s+$//;
      push @retvals,  $tempo;
    }
    return (@retvals);
  } else {
    return (-1,-1);
  }
}                    


sub snmpgettable{
  my($host,$community,$var) = @_;
  my($next_oid,$enoid,$orig_oid, 
     $response, $bindings, $binding, $value, $inoid,$outoid,
     $upoid,$oid,@table,$tempo,$tempoO);
  die "Unknown SNMP var $var\n" 
    unless $snmpget::OIDS{$var};
  
  $orig_oid = encode_oid(split /\./, $snmpget::OIDS{$var});
  $enoid=$orig_oid;
  srand();
  my $session = SNMP_Session->open ($host ,
                                 $community, 
                                 161);
  for(;;)  {
    if ($session->getnext_request_response(($enoid))) {
      $response = $session->pdu_buffer;
      ($bindings) = $session->decode_get_response ($response);
      ($binding,$bindings) = decode_sequence ($bindings);
      ($next_oid,$value) = decode_by_template ($binding, "%O%@");
      # quit once we are outside the table
      last unless BER::encoded_oid_prefix_p($orig_oid,$next_oid);
      $tempo = pretty_print($value);
      #print "$var: '$tempo'\n";
      $tempo=~s/\t/ /g;
      $tempo=~s/\n/ /g;
      $tempo=~s/^\s+//;
      $tempo=~s/\s+$//;
      push @table, $tempo;
     
    } else {
      die "No answer from $ARGV[0]\n";
    }
    $enoid=$next_oid;
  }
  $session->close ();    
  return (@table);
}

sub snmpgettable2{
  my($host,$community,$var) = @_;
  my($next_oid,$enoid,$orig_oid, 
     $response, $bindings, $binding, $value, $inoid,$outoid,
     $upoid,$oid,@table,$tempo,$tempoO);
  die "Unknown SNMP var $var\n" 
    unless $snmpget::OIDS{$var};
  
  $orig_oid = encode_oid(split /\./, $snmpget::OIDS{$var});
  $enoid=$orig_oid;
  $tempoO = pretty_print($orig_oid);
  $tempoO=~s/\t/ /g;
  $tempoO=~s/\n/ /g;
  $tempoO=~s/^\s+//;
  $tempoO=~s/\s+$//;
  srand();
  my $session = SNMP_Session->open ($host ,
                                 $community, 
                                 161);
  for(;;)  {
    if ($session->getnext_request_response(($enoid))) {
      $response = $session->pdu_buffer;
      ($bindings) = $session->decode_get_response ($response);
      ($binding,$bindings) = decode_sequence ($bindings);
      ($next_oid,$value) = decode_by_template ($binding, "%O%@");
      # quit once we are outside the table
      last unless BER::encoded_oid_prefix_p($orig_oid,$next_oid);
      $tempo = pretty_print($next_oid);
      $tempo=~s/\t/ /g;
      $tempo=~s/\n/ /g;
      $tempo=~s/^\s+//;
      $tempo=~s/\s+$//;
      $tempo=substr($tempo,length($tempoO)+1);
      #print "$var: '$tempo'\n";
      push @table, $tempo;
     
    } else {
      die "No answer from $ARGV[0]\n";
    }
    $enoid=$next_oid;
  }
  $session->close ();    
  return (@table);
}

sub fmi {
  my($number) = $_[0];
  my(@short);
  @short = ("Bytes/s","kBytes/s","MBytes/s","GBytes/s");
  my $digits=length("".$number);
  my $divm=0;
  while ($digits-$divm*3 > 4) { $divm++; }
  my $divnum = $number/10**($divm*3);
  return sprintf("%1.1f %s",$divnum,$short[$divm]);
}
