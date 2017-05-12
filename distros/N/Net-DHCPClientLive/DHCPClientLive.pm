package Net::DHCPClientLive;

use 5.008;
use warnings;
use Carp;
our @ISA = qw();
our $VERSION = '0.02';

use Net::RawIP;
use Net::ARP;
use Net::PcapUtils;
use NetPacket::ARP;
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::UDP;
my @msgtype = qw(Invalid DISCOVER OFFER REQUEST DECLINE ACK NAK RELEASE);
my %fields = (
              state => 'INIT',     
              interface => undef, 
              cltmac => undef,   
              srvmac => undef,  
              op => 1,         
              htype => 1,     
              hlen => 6,     
              hops => 0,    
              xid => undef,
              secs => 0,  
              flags => 0,
              ciaddr => '0.0.0.0',       
              yiaddr => undef,      
              siaddr => undef,     
              giaddr => undef,    
              sname => 0,        
              bootfile => 0,    
              debug => undef,           
              verb  => undef,           
              options => {},        
              timeout => 10,
              serverid => undef,   
              requestip => undef,
             );
   
sub new {
   my $that = shift;
   my $class = ref( $that ) || $that;
   my $self = { %fields };
   bless $self, $class;
   my ($tobeState);

   if ( @_ ) {
     my %conf = @_;
     if (exists $conf{"state"}) {
        $tobeState = $conf{"state"};
        delete $conf{"state"};
     }
     while ( my ($k, $v) = each %conf ) {
       $self->{"$k"} = $v;
     }
     $self->init();
   }
   $self->{"chaddr"} = $self->{"cltmac"};
   $self->{'verb'} = 1 if ($self->{'debug'});
   return undef unless(ref ($self->pktcaphd()));
   return undef if ($tobeState && ! $self->goState($tobeState));
   return $self;
}

sub init {
   my $self = shift;
   $self->{'cltmac'} = $self->GenMAC() unless(defined $self->{'cltmac'});
   $self->{'serverid'} = '0.0.0.0';
   $self->{'requestip'} = '0.0.0.0';
   $self->{'srvmac'} = 0;
   $self->{'xid'} = sprintf "%0.8d", int( rand 99999999 );
   $self->{'state'} = 'INIT';
}

sub goState {
   my ($self,$tobeState,$pkt) = @_;
   my $currState = $self->{state};
   print "\n\n$self->{cltmac} ($self->{xid}) "."$currState ----> $tobeState\n" if ($self->{'verb'});
   if ($currState eq 'INIT') {
      if ($tobeState eq 'INIT') {
         return 1;
      }else{
         return 0 unless($pkt = $self->discover());
         $self->prtpkt($pkt) if ($self->{'debug'});
         return 0 if ($tobeState ne 'SELECT' && ! $self->goState($tobeState,$pkt));
      }
   }elsif ($currState eq 'SELECT') {
      if ($tobeState eq 'SELECT') {
         $self->{'state'} = 'INIT';
         return 0 unless($self->goState($tobeState));
      }elsif($pkt) {
         $self->{'srvmac'} = $pkt->{'macsrc'};
         $self->{'requestip'} = $pkt->{'yiaddr'};
         $self->{'serverid'} = opt2dot($pkt->{'options'}{'54'});
         return 0 unless($pkt = $self->request());
         $self->prtpkt($pkt) if ($self->{'debug'});
         return 0 if ($tobeState ne 'REQUEST' && ! $self->goState($tobeState,$pkt));
      }else{
         $self->{'state'} = 'INIT';
      }
   }elsif ($currState eq 'REQUEST') {
      if ($tobeState eq 'REQUEST') {
         $self->{'state'} = 'SELECT';
         return 0 unless($self->goState($tobeState));
      }elsif ($tobeState eq 'INIT') {
         $self->decline();
         $self->init();
      }elsif($pkt) {  
         if ($pkt->{'options'}{'53'} == 6) {
            $self->init();
         }else{
            $self->{'state'} = 'BOUND';
            $self->{'ciaddr'} = $pkt->{'yiaddr'};
            $self->{'siaddr'} = $pkt->{'siaddr'};
            $self->{'giaddr'} = $pkt->{'giaddr'};
            $self->{'lease'} = $pkt->{'options'}{'51'};
            $self->{'t1'} = $pkt->{'options'}{'58'};
            $self->{'t2'} = $pkt->{'options'}{'59'};
            return 0 if ($tobeState ne 'BOUND' && ! $self->goState($tobeState));
         }
      }else{
         return 0 unless($pkt = $self->request());
         $self->prtpkt($pkt) if ($self->{'debug'});
         return 0 unless($self->goState($tobeState,$pkt));
      }
  }elsif ($currState eq 'BOUND') {
      if ($tobeState eq 'RENEW' || $tobeState eq 'BOUND') {
         return 0 unless($pkt = $self->renew());
         $self->prtpkt($pkt) if ($self->{'debug'});
         return 0 if ($tobeState ne 'RENEW' && ! $self->goState($tobeState,$pkt));
      }elsif($tobeState eq 'REBIND') {
         $pkt = $self->renew(); 
         $self->prtpkt($pkt) if ($self->{'debug'} && $pkt);
         return 0 if (! $self->goState($tobeState));
      }else{
         $self->release();
         $self->init();
         return 0 unless($self->goState($tobeState));
      } 
   }elsif ($currState eq 'RENEW') {
      if ($tobeState eq 'RENEW') {
         $self->{'state'} = 'BOUND';
         return 0 unless($self->goState($tobeState));
      }elsif($tobeState eq 'BOUND' && $pkt) {
         $self->{'state'} = 'BOUND';
         $self->{'lease'} = $pkt->{'options'}{'51'};
         $self->{'t1'} = $pkt->{'options'}{'58'};
         $self->{'t2'} = $pkt->{'options'}{'59'};
      }elsif($tobeState eq 'BOUND') {
         return 0 unless($pkt = $self->rebind());
         $self->prtpkt($pkt) if ($self->{'debug'});
         return 0 unless($self->goState($tobeState,$pkt));
      }elsif($tobeState eq 'REBIND') {
         return 0 unless($pkt = $self->rebind());
         $self->prtpkt($pkt) if ($self->{'debug'});
      }else{
         $self->release();
         $self->init();
         return 0 unless($self->goState($tobeState));
      }
   }elsif ($currState eq 'REBIND') {
      if ($tobeState eq 'REBIND') {
         $self->{'state'} = 'RENEW';
         return 0 unless($self->goState($tobeState));
      }elsif($tobeState eq 'BOUND' && $pkt) {
         $self->{'state'} = 'BOUND';
      }elsif($tobeState eq 'BOUND') {
         $self->{'state'} = 'RENEW';
         return 0 unless($self->goState($tobeState));
      }else{
         $self->release();
         $self->init();
         return 0 unless($self->goState($tobeState));
      }
   }else{
   }
   1;
}

sub discover {
   my $self = shift;
   my %options = %{$self->{options}};

   $self->{'ciaddr'} = '0.0.0.0';
   $self->{'yiaddr'} = '0.0.0.0';
   $self->{'siaddr'} = '0.0.0.0';
   $self->{'giaddr'} = '0.0.0.0';

   $options{53} = '1';
   $options{61} = mac2opt($self->{"cltmac"});
   $self->{"options"} = \%options;

   $self->pktsend();
   $self->{'state'} = 'SELECT';
   return $self->pktrcv();
}

sub request { 
   my $self = shift;
   my %options = %{$self->{options}};
   my $pkt;
   $options{53} = '3';
   $options{61} = mac2opt($self->{"cltmac"});
   $options{54} = dot2opt($self->{'serverid'});
   $options{50} = dot2opt($self->{'requestip'});
   $self->{"options"} = \%options;
   $self->pktsend();
   $self->{'state'} = 'REQUEST';
   return $self->pktrcv();
}
sub renew {
   my $self = shift;
   my %options = %{$self->{options}};
   my $pkt;
   $self->{'siaddr'} = '0.0.0.0';
   $options{53} = '3'; 
   $options{61} = mac2opt($self->{"cltmac"});
   $self->{"options"} = \%options;
   $self->pktsend();
   $self->{'state'} = 'RENEW';
   while ($pkt = $self->pktrcv()) {
      if ($pkt->{ethertype} eq '0806') {
         $self->arpreply();
      }else{
         return $pkt;
      }
   }
   return 0;
}

sub rebind {
   my $self = shift;
   my %options = %{$self->{options}};
   my $pkt;
   $self->{'siaddr'} = '0.0.0.0';
   $options{53} = '3';
   $options{61} = mac2opt($self->{"cltmac"});
   $self->{"options"} = \%options;
   $self->pktsend();
   $self->{'state'} = 'REBIND';
   while ($pkt = $self->pktrcv()) {
      if ($pkt->{ethertype} eq '0806') {
         $self->arpreply();
      }else{
         return $pkt;
      }
   }
}

sub decline {
   my $self = shift;
   my %options = %{$self->{options}};

   $options{53} = '4';
   $options{50} = dot2opt($self->{'requestip'});
   $options{54} = dot2opt($self->{'serverid'});
   $options{61} = mac2opt($self->{"cltmac"});
   $self->{"options"} = \%options;
   $self->pktsend();
}
 
sub release { 
   my $self = shift;
   my %options = %{$self->{options}};

   $options{53} = '7';  
   $options{54} = dot2opt($self->{'serverid'});
   $options{61} = mac2opt($self->{"cltmac"});
   $self->{"options"} = \%options; 
   $self->{'yiaddr'} = '0.0.0.0'; 
   $self->{'siaddr'} = '0.0.0.0';
   $self->{'giaddr'} = '0.0.0.0';
   $self->pktsend();
}
  
sub pktsend {
   my $self = shift;
   my $macaddr = $self->{'cltmac'};
   my $interface = $self->{'interface'};
   my $data = $self->encode();
   my $p;
   if (exists $self->{rawip}) {
      $p = $self->{rawip};
   }else{
      $p = new Net::RawIP( {udp => {}} );
      $p->ethnew( $interface );
   }
   if ($self->{"state"} =~ /INIT|SELECT|REQUEST|REBIND|RENEW/) {
      $p->ethset( source => $macaddr, dest => 'ff:ff:ff:ff:ff:ff');
      $p->set( {ip => {saddr => '0.0.0.0', daddr => '255.255.255.255'},
                udp => {source => 68, dest => 67, data => $data}} );
   }else{
      $p->ethset( source => $macaddr, dest => $self->{"srvmac"});
      $p->set( {ip => {saddr => $self->{"requestip"}, daddr => $self->{"serverid"} },
                udp => {source => 68, dest => 67, data => $data}} );
   }
   $p->ethsend;

   if ($self->{'verb'}) {
      my ($dstmac, $srcmac, $srcip, $dstip, $srcport, $dstport) = $p->get( {eth => [qw(dest source )], ip => [qw(saddr daddr)], udp => [qw(source dest)]} );
      print "\nXMIT: ", $self->{'xid'},"\n";
      printf "\t%s (%s) :%d ===> %s (%s) :%d\n", ip2dot($srcip), net2mac($srcmac), $srcport, ip2dot($dstip), net2mac($dstmac), $dstport;
      print "\tDHCP ", $msgtype[$self->{'options'}{53}], "\n";
   }
   $self->{rawip} = $p unless(exists $self->{rawip});
   return 1;
}

sub arpreply {
   my $self = shift;
   Net::ARP::send_packet("$self->{interface}","$self->{requestip}","$self->{serverid}","$self->{cltmac}","$self->{srvmac}",'2');
   if ($self->{verb}) {
      print "\nXMIT ARP on $self->{requestip}:\n";
      print "\t$self->{cltmac} $self->{requestip} => $self->{serverid}$self->{srvmac}\n";
   }
}

sub pktcaphd {
   my $self = shift;
   my $filter;
   $filter = "udp dst port 68 or arp host $self->{'ciaddr'}";
   my $pkt_descriptor = Net::PcapUtils::open( FILTER  => "$filter",
                                              DEV     => $self->{'interface'},
                                              SNAPLEN => 400,
                                              PROMISC => 1,
                                         ) or die "@_\n";
  if ( ! ref($pkt_descriptor) ) {
     die "Net::PcapUtils::open returned: $pkt_descriptor\n";
  }
  $self->{pcaphd} = $pkt_descriptor;
  return $pkt_descriptor;
}


sub pktrcv {
   my $self = shift;
   my $pkt_descriptor = $self->{pcaphd};
   my $pkt;

   $SIG{ALRM} = sub { die "timeout"; };
   alarm($self->{timeout});

   eval {
      my ($ttl,$macdst,$macsrc,$ethertype);
      while(1) {
         my ($packet,%hdr) = Net::PcapUtils::next($pkt_descriptor);
         my $eth_frame = NetPacket::Ethernet->decode($packet);
         $macdst = str2mac($eth_frame->{dest_mac});
         $macsrc = str2mac($eth_frame->{src_mac});
         $ethertype = sprintf("%0.4x",$eth_frame->{type});
         if ($self->{'debug'}) {
            print "\nGot a pkt \n\t";
            print "$macsrc  ==> $macdst";
            printf " (EtherType = %04x)\n\n", $eth_frame->{type};
         }
         if ( $ethertype eq '0806') {
            my $arp_obj = NetPacket::ARP->decode( $eth_frame->{data},$eth_frame );
            if ($self->{'debug'}) {
               print "\tARP header:\n";
               printf "\tprotocol ==> %0.4x",$arp_obj->{proto};
               print " harware type ==> $arp_obj->{htype}, ";
               print "harware length ==> $arp_obj->{hlen}, ";
               print "proto length ==> $arp_obj->{plen}\n";
               print "\topcode ==> $arp_obj->{opcode}\n";
               print "\tsrc mac ==> ", str2mac($arp_obj->{sha});
               print ", src ip ==> $arp_obj->{spa} => ", hex2dot($arp_obj->{spa}),"\n";
               print "\tdst mac ==> ", str2mac($arp_obj->{tha});
               print ", dst ip ==> $arp_obj->{tpa} => ", hex2dot($arp_obj->{tpa}),"\n\n";
            }
            if ($arp_obj->{opcode} == 1 && hex2dot($arp_obj->{tpa}) eq $self->{requestip}) {
               $pkt->{'macdst'} = $macdst;
               $pkt->{"macsrc"} = $macsrc;
               $pkt->{'ethertype'} = $ethertype;
               if ($self->{'verb'}) {
                  print "\nRCVD:   ARP Request\n";
                  print "\t$pkt->{macsrc} ===> $pkt->{'macdst'} asking for ",hex2dot($arp_obj->{tpa}),"\n";
               }
               last;
            }
         }else{
            my $ip_datagram = NetPacket::IP->decode( $eth_frame->{data} );
            my $udp_datagram = NetPacket::UDP->decode( $ip_datagram->{data} );
            my $bootp_datagram = $self->bootpdecode( $udp_datagram->{data} );
            if ($self->{'verb'}) {
               print "\nRCVD: DHCP $msgtype[$bootp_datagram->{'options'}{53}]\n";
               print  "\t$ip_datagram->{src_ip} -> $ip_datagram->{dest_ip}";
               print  "\t( id: $ip_datagram->{id}, ttl: $ip_datagram->{ttl} )\n";
               print  "\tUDP Source: $udp_datagram->{src_port} -> ";
               print  "UDP Destination: $udp_datagram->{dest_port}\n";
               print  "\tUDP Length: $udp_datagram->{len}, ";
               print  "UDP Checksum: $udp_datagram->{cksum}, ";
               print  "UDP Data length:", length($udp_datagram->{data}),"\n";
               print  "\txid: $bootp_datagram->{xid}\n";
            }
            next unless($self->{"xid"} == $bootp_datagram->{"xid"});
            print "\t=====> $self->{xid} matched\n" if ($self->{'verb'});
            $pkt = $bootp_datagram;
            $pkt->{'ttl'} = $ip_datagram->{ttl};
            $pkt->{'saddr'} = $ip_datagram->{src_ip};
            $pkt->{'daddr'} = $ip_datagram->{dest_ip};
            $pkt->{'macdst'} = $macdst;
            $pkt->{"macsrc"} = $macsrc;
            $pkt->{'ethertype'} = $ethertype;
            last;
         }
      }
   };

   alarm( 0 );

   if ( $@ ) {
      if ( $@ =~ /timeout/ ) {
         print "TIMEOUT\n";
         return 0;
      } else { 
         print "\n\n<$@>\n\n";
      }
   }
   print "return from pkt capture, looks good\n\n" if ($self->{'debug'});
   return $pkt;
}

sub bootpdecode {
   my $self = shift;
   my $data = shift;
   my $pkt = {};

   my $bootpkeys = [qw(op htype hlen hops xid secs flags ciaddr yiaddr siaddr giaddr chaddr )];
   my $bootpvals = [map { hex($_) } unpack "H2 H2 H2 H2 H8 H4 H4 H8 H8 H8 H8 H12", substr($data, 0, 33)];
   for ( my $i = 0; $i < scalar @$bootpkeys; $i++ ) {
      print "\t$bootpkeys->[$i] => $bootpvals->[$i]\n" if ($self->{'debug'});
      $pkt->{$bootpkeys->[$i]} = $bootpvals->[$i];
   }
   for (@$bootpkeys) {
      if ( /^xid$/) { 
         $pkt->{$_} = sprintf "%x", $pkt->{$_};
      }elsif( /iaddr/) {
         $pkt->{$_} = ip2dot($pkt->{$_});
      }
   }
   my %options; 
   my @opts = unpack "C" x ( length( $data ) - 240 ), substr $data, 240;
   for ( my $i = 0; $i <= $#opts; $i++ ) {
     my $opt = $opts[$i++];
     my $len = $opts[$i++]; 
     my $offset = $len + $i - 1;
     my $string = "";
     for ( my $q = $i; $q <= $offset; $q++ ) {
       if ( $string ) {
        $string = sprintf "%s %d", $string, $opts[$q];
       } else { 
        $string = sprintf "%d", $opts[$q];
       }
     }
     last if ($opt eq '255');
     $options{$opt} = $string;
     $i = $i + $len - 1;
   }
   $pkt->{'options'} = \%options;
   return $pkt;
}

sub prtpkt {
   my ($self,$pkt) = @_;
   print "\nRCVD: $pkt->{'xid'}\n";
   printf 
   "\t%s (%s) ===> %s (%s)\n\tDHCP%s packet:\n",
      $pkt->{'saddr'}, $pkt->{'macsrc'},$pkt->{'daddr'}, $pkt->{'macdst'}, $msgtype[$pkt->{"options"}{'53'}];
      printf "\tClient IP: %s\n\tYour IP: %s\n\tNext server IP: %s\n\tRelay agent IP: %s\n", $pkt->{'ciaddr'}, $pkt->{'yiaddr'}, $pkt->{'siaddr'},$pkt->{'giaddr'};
      $self->prtoptions($pkt);
}


# print the DHCP options
# refer to rfc1533 for these options
sub prtoptions {
   my ($self,$pkt) = @_;
   print "\tOptions:\n";
   for my $option (keys %{$pkt->{'options'}}) {
      if ($option eq '53') {
         my $msgtype = $msgtype[$pkt->{'options'}{$option}];
         print "\t53: <DHCP$msgtype>\n";
      }elsif ($option eq '1') {
         my $mask = opt2dot($pkt->{"options"}{$option});
         print "\t1: Client IP Mask => <$mask>\n";
      }elsif ($option eq '3') {
         my $routers;
         my @r = split /\s/, $pkt->{"options"}{$option};
         for (my $i = 0; $i <= @r/4; $i += 4) { 
            my $router = join '.', $r[$i],$r[$i + 1],$r[$i + 2],$r[$i + 3];
            ($i == 0) ? $routers = $router : $routers .= ','."$router";
         }
         print "\t3: Router(s) on Client subnet => <$routers>\n";
      }elsif ($option eq '4') {
         # the same format at '3', will expand it later
         print "\t4: Time server(s)=> <", $pkt->{'options'}{$option}, ">\n";
      }elsif ($option eq '6') {
         # the same format at '3', will expand it later
         print "\t6: DNS server(s)=> <", $pkt->{'options'}{$option}, ">\n";
      }elsif ($option eq '15') {
         my $domain = join '', map { chr ($_) } split /\s/, $pkt->{"options"}{$option};
         print "\t15: Domain Name => <$domain>\n";
      }elsif ($option eq '50') {
         my $ciaddr = opt2dot($pkt->{"options"}{$option});
         print "\t50: Requested IP address => <$ciaddr>\n";
      }elsif ($option eq '51') {
         my $lease = $pkt->{"options"}{$option};
         print "\t51: Lease time => <$lease>\n";
      }elsif ($option eq '54') {
         my $srvid = opt2dot($pkt->{"options"}{$option});
         print "\t54: Server Identifier => <$srvid>\n";
      }elsif ($option eq '58') {
         my $t1 = $pkt->{"options"}{$option};
         print "\t58: T1 => <$t1>\n";
      }elsif ($option eq '59') {
         my $t2 = $pkt->{"options"}{$option};
         print "\t59: T2 => <$t2>\n";
      }else{
         print "\tUnknow option <", $pkt->{"options"}{$option}, ">\n";
      }
   }
}

sub GenMAC { 
  my $self = shift;
  my $tmp_mac="00:4d:5a";
  my $i=0;
  while($i++ < 3) { 
    $tmp_mac.=":" . sprintf("%x",int rand 16);
    $tmp_mac.=sprintf("%x",int rand 16);
  }
  return($tmp_mac);
}

sub dot2opt { 
  my $dotip = shift;
  return join ' ', map {sprintf("%x",$_)} split /\./, $dotip;
}


sub opt2dot {
  my $opt = shift; 
  return join '.', split /\s/, $opt;
}

sub hex2dot { 
  my @hexip = split //, shift;
  my @h;
  for (my $i = 0; $i < 8; $i += 2) {
     push @h, join '', $hexip[$i],$hexip[$i + 1];
  }
  return join '.', map { hex($_) } @h;
}

sub mac2opt {
  my $mac = shift;
  return join ' ', split /:/, $mac;
}

sub prtStatus {
   my $self = shift;
   for my $fd (keys %$self) {
      if ( $fd eq 'options' ) {
         for (keys %{$self->{$fd}}) { print "\t\t$_ ==> ", $self->{$fd}{$_}, "\n" }
      }else{
         print "\t$fd => ", $self->{$fd}, "\n";
      }
   }
}


sub encode {
  my $self = shift;
  my $magic = pack "C4", 99, 130, 83, 99;
  my @ciaddr = split /\./, $self->{'ciaddr'};
  my @yiaddr = split /\./, $self->{'yiaddr'};
  my @siaddr = split /\./, $self->{'siaddr'};
  my @giaddr = split /\./, $self->{'giaddr'};

  my @chaddr = mac2net( $self->{'chaddr'} );

  my $data = pack "C4 H8 H4 H4 C4 C4 C4 C4 C16 H128 H256",
     $self->{'op'}, $self->{'htype'}, $self->{'hlen'}, $self->{'hops'}, $self->{'xid'}, $self->{'secs'},
     $self->{'flags'}, @ciaddr, @yiaddr, @siaddr, @giaddr, @chaddr, $self->{'sname'}, $self->{'bootfile'};

  $data = join '', $data, $magic;

  my $o = $self->{'options'};
  my %options = %$o;

  foreach my $key ( keys %options ) {
    my @p = split / /, $options{$key};
    map { $_ = hex( $_ ); } @p;

    my $format = sprintf "C%d", $#p+3;

    my $options = pack $format, $key, $#p+1, @p;

    $data = join '', $data, $options;
  }

  my $end = pack "C2", 255, 0;

  $data = join '', $data, $end;

  return $data;
}

sub str2mac {
  return sprintf( "%s%s:%s%s:%s%s:%s%s:%s%s:%s%s", split //, shift);
}

sub net2mac {
  return sprintf( "%.2x:%.2x:%.2x:%.2x:%.2x:%.2x", unpack( "C6", shift ) );
}

sub mac2net {
  my @a = split /:/, shift;
  
  for ( 1..10 ) {
    push @a, '0';
  }
  
  map { $_ = hex($_); } @a;
    
  return @a;
}

sub ip2dot {
  return sprintf( "%u.%u.%u.%u", unpack( "C4", pack( "N", shift ) ) );
}


1;
__END__;


######################## User Documentation ##########################
=head1 NAME

	Net::DHCPClientLive - stateful DHCP client object

=cut

=head1 SYNOPSIS

   use Net::DHCPClientLive;
   my $client = new Net::DHCPClientLive( interface => "eth0", state => 'BOUND')
                      or die "failed to move to BOUND state\n";
   print "DHCP client $client->{cltmac} is created and assigned $client->{requestip} from server\n";
 
=cut

=head1 DESCRIPTION

Net::DHCPClientLive allows you to create and manipulate DHCP client(s) so that you
can test the behavior of your DHCP server upon client state transition.

DHCP client is a stateful host. It reaches "BOUND" state after the successful discover
process, and will renew and/or rebind when T1/T2 timer expire. The state will be changed
accordingly depending on the behavior of the server.

With this module you can move client's state, make transition, and even let it go freely.
At each attempt of operation, it can tell whether it success or fail, so that you know
if your server works as expected.

You can create many DHCP clients at the same time. In this way you can easily execute
scalability test. Image you create 100 live DHCP clients, they are alive as though there
were 100 hosts there, doing renew, rebind, or release interacting with your DHCP server
for a few days, just like they do in real scenario.

I also provide some code showing how to do this in EXAMPLES section.

Client identifier
   - mac address is the identifier of a client, it's assigned when created and kept in the whole life cycle
   - xid is kept in the client life cycle until back to INIT, when xid is initialized

The following is the detail description of state transition.
   INIT->SELECT  
      send DISCOVER, receive OFFER, check and report, 
      return true if receiving DHCP OFFER from server, or false if no OFFER received.
      The state of client moves to SELECT anyway.


   INIT->REQUEST 
   SELECT->REQUEST 
      send DISCOVER, receive OFFER, and send REQUEST, check ACK and report,
      return true if receiving both DHCP OFFER and ACK from server, or false otherwise
      The state of client moves to SELECT if no OFFER received or REQUEST if OFFER received.

   SELECT->SELECT
      same as INIT->SELECT, 
      this allows you to test intensively the server response to DISCOVER

   REQUEST->REQUEST
      same as SELECT->REQUEST, 
      this allows you to test intensively the server response to DISCOVER/REQUEST


   INIT->BOUND 
      send DISCOVER, receive OFFER, and send REQUEST, receive ACK and update.
      return true only if the whole process correct.
      The state of client moves accordingly to SELECT, REQUEST, or BOUND
      SELECT if client sends DISCOVER
      REQUEST if client receives OFFER, then sends REQUEST
      BOUND if client receives ACK after sending REQUEST

   SELECT->BOUND
      back to INIT, then same to above

   REQUEST->BOUND
      send REQUEST, receive ACK and update (because client already has server offer info in obj)
      return true only if the client receives ACK.
      The state of client moves to BOUND if receives ACK, or stay at REQUEST if no ACK

   BOUND->BOUND 
      Simulates T1 expire. Sends unicast REQUEST to server, and move to RENEW
      move to BOUND and refresh lease after receiving ACK from server
      return true if receives ACK
      Note: Linux server sends ARP request to client ip, client has to replay this ARP
         before Linux server sends ACK

   RENEW->BOUND
   REBIND->BOUND
      Simulates T2 expire. sends broadcase REQUEST, move to BOUND and refresh lease if receives ACK
      return true if receives ACK


   BOUND->RENEW
      Simulates T1 expire. Sends unicast REQUEST to server, and move to RENEW
      return true if receives ACK 
      Note: Linux server sends ARP request to client ip, client also replay this ARP
         before Linux server sends ACK

   BOUND->REBIND
      Does BOUND->RENEW first
      Then ignore ACK and does RENEW->REBIND

   RENEW->REBIND
      Simulates T2 expire. sends broadcase REQUEST
      return true if receives ACK to this broadcase REQUEST


   REBIND->INIT
   RENEW->INIT
      Sends RELEASE and move to INIT

 
   RENEW->SELECT  
   RENEW->REQUEST
   REBIND->SELECT
   REBIND->REQUEST

      1. ->INIT
      2. INIT->REQUEST


   undef->INIT
      do nothing

   SELECT->INIT
      clear XID

   REQUEST->INIT 
      send DECLINE, clear XID


=cut

=head1 METHODS

new - create a new Net::DHCPClientLive object

   $clt = new Net::DHCPClientLive(interface => eth0,  # interface name of your host
                                  state => 'BOUND',   # state to be moved for this client, one of
                                                      # INIT, SELECT,REQUEST,BOUND,RENEW,REBIND
                                  mac => '00:01:02:03:04:05', # default is auto-created randomly
                                  options => {key => value, ...}, # refer to rfc2131 for options
                                  verb => $verb);     # print more pkt exchange info

   You don't need to specify options unless you have special interest, in which case, the dhcp packet
   exchangewill contain those options. If there is no "mac", the client is assgined one automatically,
   and it becomes the identifier of the client.


goState($state)

  $clt->goState('RENEW');

  The only argument to goState method is the state name you are driving the client to move to. 
  It returns true if the client successfully move the state, otherwise returns false.
  Refer to "DESCRIPTION" section for detail of state transition
  Legal state name includes "INIT","SELECT","REQUEST","BOUND","RENEW", and "REBIND".


Other methods
 
 These methods are called by goState. You probably don't need them. Just in case, you can use them to send some kind of DHCP packets.

 $clt->discover()
 $clt->request()
 $clt->renew()
 $clt->rebind()
 $clt->decline()
 $clt->release()


=cut

=head1 EXAMPLES

Here is a subroutine used to do state transition. It creates a client and try to move its state to $middleState, then it moves to $finalState if it is provided, 
It returns the client object on success, or false on failure.


   sub stateTransition {
      my ($middleState,$finalState) = @_;
      my $clt;
      unless ($clt = new Net::DHCPClientLive( interface => "eth1", state => $middleState )) {
         print "server response abnormal to $clt->{cltmac}\n";
         return 0;
      }else{
         print "$clt->{cltmac} moved to $clt->{'state'}\n";
      }
      return $clt unless($finalState);
      unless ($clt->goState($finalState)) {
         print "server response abnormal to $clt->{cltmac}\n";
         return 0;
      }else{
         print "$clt->{cltmac} moved to $clt->{'state'}\n";
      }
      return $clt;
   }


Here is another example to simulate multiple live clients. Please note that each client exists as individual process in your host.

   $SIG{CHLD} = sub {while( waitpid(-1, WNOHANG) > 0 ) {} };
   $SIG{INT} = sub { kill 'KILL', 0 };
   $SIG{QUIT} = sub { kill 'KILL', 0 };
   my $clt;
   my @liveClt = ();
   
   # create $numClient clients 
   for (my $k = 1; $k <= $numClient; $k++) {
      if ($clt = new Net::DHCPClientLive( interface => "$hostint", state => 'BOUND', verb => $verb)) {
         print "created live a client No.$k: $clt->{cltmac}\n";
         my $W = gensym();
         my $R = gensym();
         my $pid;
         if (pipe($R,$W) && defined($pid = fork())) {
            if ($pid) {
               # keep the client
               close $W;
               $clt->{sock} = $R;
               push @liveClt, $clt;
            }else{
               # a client is created
               close $R;
               open(STDOUT, ">&$W");
               select $W; $| = 1;
               while (1) {
                  my $now = time;
                  while (time < $now + $clt->{t1}) {};
                  print "T1 expired, renewing ... ";
                  unless ($clt->goState('BOUND')) {
                     print "failed\n";
                     my $now = time;
                     while (time < $now + $clt->{t2} - $clt->{t1}) {};
                     print "T2 expired, rebinding ...";
                     unless ($clt->goState('BOUND')) {
                        print "rebinding failed, relasing the client\n";
                        $clt->goState('INIT');
                        exit 0;
                     }else{
                        print "done\n";
                     }
                  }else{
                     print "done\n";
                  }
               }
            }
         }else{
            print("max clients has been created\n");
            last;
         }
      }else{
         print "No.$k client failed to go to BOUND\n";
      }
   }
   
   # main process shows information printed by clients
   if (@liveClt) {
      print "Totally created ", scalar @liveClt, " client(s)\n";
      my $liveCltSock = new IO::Select();
      for (@liveClt) {
         $liveCltSock->add($_->{sock});
      }
      while ( my @cltCanSay = $liveCltSock->can_read() ) {
         for my $cltSock (@cltCanSay) {
            my ($client) = grep {$_->{sock} eq $cltSock} @liveClt;
            my $msg = <$cltSock>;
            next if ($msg =~ /^\s*$/);
            print "$client->{cltmac}: $msg";
         }
      }
   }

=head1 REQUIRES

This module need to use the following modules
   Net::RawIP;
   Net::ARP;
   Net::PcapUtils;
   NetPacket::ARP;
   NetPacket::Ethernet;
   NetPacket::IP;
   NetPacket::UDP;


=head1 AUTHOR

Ming Zhang, E<lt>ming2004@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Ming Zhang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
