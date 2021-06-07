package Net::SIGTRAN::M3UA;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

use 5.008008;
use Net::SIGTRAN::SCTP;
use strict;
use Data::Dumper;
use warnings;
our @ISA = qw(Net::SIGTRAN::SCTP);

our $VERSION = '0.1.1';

use constant MessageClass_Value => {
   0 => 'MGMT',
   1 => 'Transfer',
   2 => 'SSNM',
   3 => 'ASPSM',
   4 => 'ASPTM',
   9 => 'RKM'
};

use constant MessageType_Value => {
  0 => {
     0 => 'ERR',
     1 => 'NTFY'
  },
  1 => {
     1 => 'DATA'
  },
  2 => {
     1 => 'DUNA',
     2 => 'DAVA',
     3 => 'DAUD',
     4 => 'SCON',
     5 => 'DUPU',
     6 => 'DRST'
  },
  3 => {
     1 => 'ASPUP',
     2 => 'ASPDN',
     3 => 'BEAT',
     4 => 'ASPUP_ACK',
     5 => 'ASPDN_ACK',
     6 => 'BEAT_ACK'
  },
  4 => {
     1 => 'ASPAC',
     2 => 'ASPIA',
     3 => 'ASPAC_ACK',
     4 => 'ASPIA_ACK'
  },
  9 => {
     1 => 'REG_REQ',
     2 => 'REG_RSP',
     3 => 'DEREG_REQ',
     4 => 'DEREG_RSP',
  }
};

use constant Parameter_Value => {
   0x0004 => 'InfoString',
   0x0006 => 'RoutingContext',
   0x0007 => 'DiagnosticInformation',
   0x0009 => 'HeartbeatData',
   0x000b => 'TrafficModeType',
   0x000c => 'ErrorCode',
   0x000d => 'Status',
   0x0011 => 'ASPIdentifier',
   0x0012 => 'AffectedPointCode',
   0x0013 => 'CorrelationId',
   0x0200 => 'NetworkAppearance',
   0x0204 => 'UserCause',
   0x0205 => 'CongestionIndications',
   0x0206 => 'ConcernedDestination',
   0x0207 => 'RoutingKey',
   0x0208 => 'RegistrationResult',
   0x0209 => 'DeregistrationResult',
   0x020a => 'LocalRoutingKeyIdentifier',
   0x020b => 'DestinationPointCode',
   0x020c => 'ServiceIndicators',
   0x020f => 'OriginatingPointCodeList',
   0x0210 => 'ProtocolData',
   0x0212 => 'RegistrationStatus',
   0x0213 => 'DeregistrationStatus'
};

use constant Parameter_Order => {
  'MGMT' => {
     'ERR' => ['ErrorCode','RoutingContext','NetworkAppearance','AffectedPointCode','DiagnosticInformation'],
     'NTFY' => ['Status','ASPIdentifier','RoutingContext','InfoString']
  },
  'Transfer' => {
     'DATA' => ['NetworkAppearance','RoutingContext','ProtocolData','CorrelationId']
  },
  'SSNM' => {
     'DUNA' => ['NetworkAppearance','RoutingContext','AffectedPointCode','InfoString'],
     'DAVA' => ['NetworkAppearance','RoutingContext','AffectedPointCode','InfoString'],
     'DAUD' => ['NetworkAppearance','RoutingContext','AffectedPointCode','InfoString'],
     'SCON' => ['NetworkAppearance','RoutingContext','AffectedPointCode','ConcernedDestination','CongestionIndications','InfoString'],
     'DUPU' => ['NetworkAppearance','RoutingContext','AffectedPointCode','UserCause','InfoString'],
     'DRST' => ['NetworkAppearance','RoutingContext','AffectedPointCode','InfoString']
  },
  'ASPSM' => {
     'ASPUP' => ['ASPIdentifier','InfoString'],
     'ASPDN' => ['InfoString'],
     'BEAT' => ['HeartbeatData'],
     'ASPUP_ACK' => ['ASPIdentifier','InfoString'],
     'ASPDN_ACK' => ['InfoString'],
     'BEAT_ACK' => ['HeartbeatData']
  },
  'ASPTM' => {
     'ASPAC' => ['TrafficModeType','RoutingContext','InfoString'],
     'ASPIA' => ['RoutingContext','InfoString'],
     'ASPAC_ACK' => ['TrafficModeType','RoutingContext','InfoString'],
     'ASPIA_ACK' => ['TrafficModeType','RoutingContext','InfoString']
  },
  'RKM' => {
     'REG_REQ' => ['RoutingKey'],
     'REG_RSP' => ['RegistrationResult'],
     'DEREG_REQ' => ['RoutingContext'],
     'DEREG_RSP' => ['DeregistrationResult']
  }
};

sub hashing {
   my $hash1=shift;
   my %hash2=reverse(%$hash1);
   return \%hash2;
}

sub hashhashing {
   my $hash1=shift;
   my $hash2=shift;
   my $hash3=();
   foreach my $k1 (keys(%$hash2)) {
      my %tmphash=reverse(%{$hash1->{$k1}});
      $hash3->{$hash2->{$k1}}=\%tmphash;
   }
   #print STDERR "MessageType: ".Dumper($hash3)."\n";
   return $hash3;
}

use constant MessageClass_Name => &hashing(MessageClass_Value);
use constant MessageType_Name => &hashhashing(MessageType_Value,MessageClass_Value);
use constant Parameter_Name => &hashing(Parameter_Value);

#  SPA (ASP)                               SPB (GCS)
#   |---------------- ASP UP --------------->|
#   |<--------------- ASP UP ack ------------|
#   |---------------- ASP Active ----------->|
#   |<--------------- ASP Active ack --------|
#   |<--------------- Notify ----------------|
#   |                                        |
#   |---------------- DAUD ----------------->|
#   |<--------------- DAVA ------------------|

sub new {
   my $class=shift;
   my $self=$class->SUPER::new(@_);
   $self->{'MaxPacketSize'}=1500;
   $self->{'PPID'}=0x03000000;
   $self->{'Version'}=1;
   $self->{'MaxStreamId'}=16 unless ($self->{'MaxStreamId'});
   bless $self,$class;
   return $self;
}

# Management (MGMT) Messages
#0 Error (ERR)
#1 Notify (NTFY)

sub NTFY {
   my $class=shift;
   my $sock=shift;
   my $statustype=shift||0;
   my $statusinfo=shift||0;
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'MGMT NTFY',
      'MessageClass' => 'MGMT',
      'MessageType' => 'NTFY',
      'Status' => $statustype*0x10000+$statusinfo
   };
   $class->writepdu($sock,0,$pdu);
}

# Transfer Messages
#0 Reserved
#1 Payload Data (DATA)

sub encodeProtocolData {
   my $class=shift;
   my $opc=shift||0;
   my $dpc=shift||0;
   my $si=shift||0;
   my $ni=shift||0;
   my $mp=shift||0;
   my $sls=shift||0;
   my $userdata=shift;
   return sprintf("%08x%08x%02x%02x%02x%02x",$opc,$dpc,$si,$ni,$mp,$sls).$userdata;
}

sub DATA {
   my $class=shift;
   my $sock=shift;
   my $networkappearance=shift;
   my $routingcontext=shift;
   my $protocoldata=shift;
   my $correlationid=shift;
   my $pdu={
      'Version' => $class->{'Version'},
      'M3UA' => 'Transfer DATA',
      'MessageClass' => 'Transfer',
      'MessageType' => 'DATA',
      'ProtocolData'=> $protocoldata
   };
   $pdu->{'NetworkAppearance'}=$networkappearance if (defined($networkappearance));
   $pdu->{'RoutingContext'}=$routingcontext if (defined($routingcontext));
   $pdu->{'CorrelationId'}=$correlationid if (defined($correlationid));

   #$class->writepdu($sock,int(rand($class->{'MaxStreamId'}))+1,$pdu);
   $class->writepdu($sock,0,$pdu);
}

# SS7 Signalling Network Management (SSNM) Messages
#0 Reserved
#1 Destination Unavailable (DUNA)
#2 Destination Available (DAVA)
#3 Destination State Audit (DAUD)
#4 Signalling Congetion (SCON)
#5 Destination User Part Unavailable (DUPU)
#6 Destination Restricted (DRST)

sub DUNA {
   my $class=shift;
   my $sock=shift;
   my $networkappearance=shift||0;
   my $routingcontext=shift||0;
   my $affectedpointcode=shift||0;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'SSNM DUNA',
      'MessageClass' => 'SSNM',
      'MessageType' => 'DUNA',
      'NetworkAppearance' => $networkappearance,
     'RoutingContext' => $routingcontext,
     'AffectedPointCode' => $affectedpointcode
   };
   $class->writepdu($sock,0,$pdu);
}

sub DAVA {
   my $class=shift;
   my $sock=shift;
   my $networkappearance=shift||0;
   my $routingcontext=shift||0;
   my $affectedpointcode=shift||0;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'SSNM DAVA',
      'MessageClass' => 'SSNM',
      'MessageType' => 'DAVA',
      'NetworkAppearance' => $networkappearance,
     'RoutingContext' => $routingcontext,
     'AffectedPointCode' => $affectedpointcode
   };
   $class->writepdu($sock,0,$pdu);
}

sub DAUD {
   my $class=shift;
   my $sock=shift;
   my $networkappearance=shift||0;
   my $routingcontext=shift||0;
   my $affectedpointcode=shift||0;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'SSNM DAUD',
      'MessageClass' => 'SSNM',
      'MessageType' => 'DAUD',
      'NetworkAppearance' => $networkappearance,
     'RoutingContext' => $routingcontext,
     'AffectedPointCode' => $affectedpointcode
   };
   $class->writepdu($sock,0,$pdu);
}

# ASP State Maintenance (ASPSM) Messages
#0 Reserved
#1 ASP Up (ASPUP)
#2 ASP Down (ASPDN)
#3 Heartbeat (BEAT)
#4 ASP Up Acknowledgement (ASPUP ACK)
#5 ASP Down Acknowledgement (ASPDN ACK)
#6 Heartbeat Acknowledgement (BEAT ACK)

sub ASPUP {
   my $class=shift;
   my $sock=shift;

   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'ASPSM ASPUP',
      'MessageClass' => 'ASPSM',
      'MessageType' => 'ASPUP'
   };
   $class->writepdu($sock,0,$pdu);
}

sub ASPUP_ACK {
   my $class=shift;
   my $sock=shift;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'ASPSM ASPUP_ACK',
      'MessageClass' => 'ASPSM',
      'MessageType' => 'ASPUP_ACK'
   };
   $class->writepdu($sock,0,$pdu);
}

sub BEAT {
   my $class=shift;
   my $sock=shift;
   my $heartbeatdata=shift||0;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'ASPSM BEAT',
      'MessageClass' => 'ASPSM',
      'MessageType' => 'BEAT',
     'HeartbeatData' => $heartbeatdata
   };
   $class->writepdu($sock,0,$pdu);
}

sub BEAT_ACK {
   my $class=shift;
   my $sock=shift;
   my $heartbeatdata=shift||0;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'ASPSM BEAT_ACK',
      'MessageClass' => 'ASPSM',
      'MessageType' => 'BEAT_ACK',
     'HeartbeatData' => $heartbeatdata
   };
   $class->writepdu($sock,0,$pdu);
}

# ASP Traffic Maintenance (ASPTM) Messages
#0 Reserved
#1 ASP Active (ASPAC)
#2 ASP Inactive (ASPIA)
#3 ASP Active Acknowledgement (ASPAC ACK)
#4 ASP Inactive Acknowledgement (ASPIA ACK)

sub ASPAC {
   my $class=shift;
   my $sock=shift;
   my $trafficmodetype=shift||0;
   my $routingcontext=shift||0;           
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'ASPTM ASPAC',
      'MessageClass' => 'ASPTM',
      'MessageType' => 'ASPAC',
      'TrafficModeType' => $trafficmodetype,
     'RoutingContext' => $routingcontext
   };
   $class->writepdu($sock,0,$pdu);
}

sub ASPAC_ACK {
   my $class=shift;
   my $sock=shift;
   my $trafficmodetype=shift||0;
   my $routingcontext=shift||0;
   
   my $pdu = {
      'Version' => $class->{'Version'},
     'M3UA' => 'ASPTM ASPAC_ACK',
      'MessageClass' => 'ASPTM',
      'MessageType' => 'ASPAC_ACK',
      'TrafficModeType' => $trafficmodetype,
     'RoutingContext' => $routingcontext
   };
   $class->writepdu($sock,0,$pdu);
}

#Routing Key Management (RKM) Messages (see Section 3.6)
#0 Reserved
#1 Registration Request (REG REQ)
#2 Registration Response (REG RSP)
#3 Deregistration Request (DEREG REQ)
#4 Deregistration Response (DEREG RSP)


sub readpdu {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   return undef if (!defined $sock);
   my ($len,$buffer)=$class->recieve($sock);
   return undef unless ($len>0);
   #return $class->decodepdu($class->bintohex($buffer));
   return $class->decodepdu($buffer);
}

sub recieve {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   my ($readlen,$readpacket)= $class->SUPER::recieve($sock,$class->{'MaxPacketSize'});
   return ($readlen,$readpacket);
}

sub writepdu {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   return undef if (!defined $sock);
   my $streamno=shift;
   return undef if (!defined $streamno);
   my $readpdu=shift|| undef;
   my $out=$class->encodepdu($readpdu);
   #return if (!defined $out);
   #print STDERR 'Encoding Message='. $class->bintohex($out) ."\n";
   return $class->send($sock,$streamno,$out);
}

sub send {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   return undef if (!defined $sock);
   my $streamno=shift;
   return undef if (!defined $streamno);
   my $out=shift;
   #return undef if (!defined $out);
   return $class->SUPER::send($sock,$streamno,length($out),$out);
}

sub encodepdu {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $readpdu=shift|| undef;
   
   #print STDERR "encodepdu=".Dumper($readpdu);
   my @pdukey=keys(%$readpdu);
   #print STDERR Dumper(\@pdukey);
   my $version= $readpdu->{'Version'} ? $readpdu->{'Version'} : 1;
   my $reserved= $readpdu->{'Reserved'} ? $readpdu->{'Reserved'} : 0;
   my $messageclass= $readpdu->{'MessageClass'} && MessageClass_Name->{$readpdu->{'MessageClass'}} ?
      MessageClass_Name->{$readpdu->{'MessageClass'}} : 0;
   my $messagetype= $readpdu->{'MessageClass'} && $readpdu->{'MessageType'} && 
      MessageType_Name->{$readpdu->{'MessageClass'}}->{$readpdu->{'MessageType'}} ? 
      MessageType_Name->{$readpdu->{'MessageClass'}}->{$readpdu->{'MessageType'}} : 0;
   
   #print STDERR "encoding MessageType ".MessageType_Name->{$readpdu->{'MessageClass'}}->{$readpdu->{'MessageType'}} ."\n";
   
   my $message='';
   my $arrangeorder=Parameter_Order->{$readpdu->{'MessageClass'}}->{$readpdu->{'MessageType'}};
   if ($arrangeorder) {
      foreach my $one (@$arrangeorder) {
         next unless defined($readpdu->{$one});
         if ($one=~/^HeartbeatData|ProtocolData$/) {
            #print STDERR "toT16LV ($one) ". Parameter_Name->{$one} ." = $readpdu->{$one} \n";
            if (ref($readpdu->{$one}) eq 'ARRAY') {
               foreach my $eachpara (@{$readpdu->{$one}}) {
                  $message.=$class->toT16LV(pack('n',Parameter_Name->{$one}),$class->hextobin($eachpara));
               }
            } else {
               $message.=$class->toT16LV(pack('n',Parameter_Name->{$one}),$class->hextobin($readpdu->{$one}));
            }
         } else {
            #print STDERR "encode16bitTLV ($one) ". Parameter_Name->{$one} ." = $readpdu->{$one} \n";
            if (ref($readpdu->{$one}) eq 'ARRAY') {
               foreach my $eachpara (@{$readpdu->{$one}}) {
                  $message.=$class->encode16bitTLV(Parameter_Name->{$one},$eachpara);
               }
            } else {
               $message.=$class->encode16bitTLV(Parameter_Name->{$one},$readpdu->{$one});
            }
         } 
      }
   }
   while (length($message) % 4 != 0) {
     $message.=chr(0);
   }
 
   return $class->toT32LV(chr($version).chr($reserved).chr($messageclass).chr($messagetype),$message);
}

sub decodepdu {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $readpacket=shift|| undef;
   my $output=();
   if (length($readpacket)>=8) {
      my $version=ord(substr($readpacket,0,1));
      #Reserved Byte, Ignored.
      my $messageclass=ord(substr($readpacket,2,1));
      my $messagetype=ord(substr($readpacket,3,1));
      my $messagelength=unpack('N',substr($readpacket,4,4));
      my $message=substr($readpacket,8);
      #print STDERR "Read Packet: $messageclass, $messageclass, $readpacket\n";
      #print STDERR MessageClass_Value->{$messageclass} . ' '. MessageType_Value->{$messageclass}->{$messagetype} ."\n";
      #print STDERR "Length ". ($messagelength*2) ." ". (length($readpacket)) ."\n";
      if (defined(MessageClass_Value->{$messageclass}) && defined(MessageType_Value->{$messageclass}->{$messagetype}) &&
         $messagelength==length($readpacket)) {
         $output->{'M3UA'}=MessageClass_Value->{$messageclass} .' '.  
            MessageType_Value->{$messageclass}->{$messagetype};
         $output->{'Version'}=$version;
         $output->{'MessageClass'}=MessageClass_Value->{$messageclass};
         $output->{'MessageType'}=MessageType_Value->{$messageclass}->{$messagetype};
         $output->{'Message'}=$class->bintohex($message);
         while (length($message)>4) {
            #printf">>>>>>>>>>>>>>%d\n",(length($message));
            my $parahead=unpack('n',substr($message,0,2));
            my $paralen=unpack('n',substr($message,2,2));
            my $parabody=$class->bintohex(substr($message,4,$paralen-2));
            $parabody=hex($parabody) unless (Parameter_Value->{$parahead} =~/^HeartbeatData|ProtocolData$/);

            $message=substr($message,$paralen);
            my $temppara=$output->{Parameter_Value->{$parahead}};
            if (defined($temppara)) {         
               if (ref($temppara eq 'ARRAY')) {
                  push @$temppara,$parabody;
                  $output->{Parameter_Value->{$parahead}}=$temppara;
               } else {
                  $output->{Parameter_Value->{$parahead}}=[$temppara,$parabody];
               }
            } else {
               $output->{Parameter_Value->{$parahead}}=$parabody;
            }
         }
      } else {
         $output->{'M3UA'}='Invalid';
      }
   } else {
      $output->{'M3UA'}='Unknown'; 
   } 
   #print STDERR Dumper($output);
   return $output;
}

sub encode16bitTLV {
   my $class=shift;
   my $header=shift;
   my $body=shift;
   #print STDERR "Encoding $header == $body\n";
   return $class->toT16LV(pack('n',$header),pack('N',$body));
}

sub toT16LV {
   my $class=shift;
   my $header=shift;
   my $body=shift;
   return $header. pack('n',2+length($header)+length($body)) .$body;
}

sub toT32LV {
   my $class=shift;
   my $header=shift;
   my $body=shift;
   return $header. pack('N',4+length($header)+length($body)) .$body;
}

sub bintohex {
   my $class=shift;
   my $string=shift;
   my $out='';
   my @strings=split "",$string;
   for (my $i=0;$i<@strings;$i++) {
      $out.= sprintf("%02X",ord($strings[$i]));
   }
   return $out;
   
}

sub hextobin {
   my $class=shift;
   my $string=shift;
   my $out='';
   my @strings=split "",$string;
   for (my $i=0;$i<@strings-1;$i+=2) {
      $out.= pack('C',hex($strings[$i].$strings[$i+1]));
   }
   return $out;
}

1;
__END__

=head1 NAME

Net::SIGTRAN::M3UA - An implementation to create M3UA protol stack to provide SIGTRAN stack implementation in perl.

=head1 SYNOPSIS

=head2 Server Example

use Net::SIGTRAN::SCTP;

use threads;

my $server=new Net::SIGTRAN::M3UA(
   PORT=>12346
);
my $ssock=$server->bind();
if ($ssock) {
   my $csock;
   while($csock = $server->accept($ssock)) {
      print "New Client Connection\n";
      my $thr=threads->create(\&processRequest,$server,$csock);
      $thr->detach();
   }
}

sub processRequest {
   my $server=shift;
   my $ssock=shift;
   my $connSock = $server->accept($ssock);
   cmp_ok($connSock,'>',0,'Unable to accept Client Connection');
   print "Sending to $connSock\n";
   $server->ASPUP($connSock);
   $server->ASPUP_ACK($connSock);
   $server->ASPAC($connSock,2,0);
   $server->ASPAC_ACK($connSock,2,0);
   $server->NTFY($connSock,1,2);
   $server->DAUD($connSock,12,0,1142);
   $server->DAVA($connSock,12,0,1142);
   $server->DUNA($connSock,12,0,1142);
   my $heartbeat='0005000101ffd8398047021227041120';
   $server->BEAT($connSock,$heartbeat);
   $server->BEAT_ACK($connSock,$heartbeat);
   $server->close($connSock);
}


=head2 Client Example

use Net::SIGTRAN::SCTP;

my $client=new Net::SIGTRAN::M3UA(
   HOST=>'127.0.0.1',
   PORT=>12346
);

my $csock=$client->connect();
 #Read ASPUP
 &clientread('ASPUP',$client,$csock);
 #Read ASPUP_ACK
 &clientread('ASPUP_ACK',$client,$csock);
 #Read ASPAC
 &clientread('ASPAC',$client,$csock);
 #Read ASPAC_ACK
 &clientread('ASPAC_ACK', $client,$csock);
 #Read NTFY
 &clientread('NTFY', $client,$csock);
 #Read DAUD
 &clientread('DAUD', $client,$csock);
 #Read DAVA
 &clientread('DAVA', $client,$csock);
 #Read DUNA
 &clientread('DUNA', $client,$csock);
 #Read BEAT
 &clientread('BEAT', $client,$csock);
 #Read BEAT_ACK
 &clientread('BEAT_ACK', $client,$csock);

$client->close($csock);


sub clientread {
   my $title=shift;
   my $client=shift;
   my $csock=shift;
   my ($buffer)=$client->readpdu($csock);
   if ($buffer) {
      if ($buffer->{'M3UA'} =~/Invalid|Unknown/) {
         print("Reading $title test");
      } else {
         print("reading $title test");
         print STDERR Dumper($buffer);
      }
   } else {
      print("Reading $title test, Client Socket does not recieve any packet");
   }
}


=head1 AUTHOR

Christopherus Goo <software@artofmobile.com>

=head1 COPYRIGHT

Copyright (c) 2012 Christopherus Goo.  All rights reserved.
This software may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module
as you wish, but if you redistribute a modified version, please attach a
note listing the modifications you have made.

=cut

