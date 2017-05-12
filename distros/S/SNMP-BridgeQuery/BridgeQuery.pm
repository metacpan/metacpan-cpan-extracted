package SNMP::BridgeQuery;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA 		= qw(Exporter);
@EXPORT 	= qw(queryfdb);
@EXPORT_OK	= qw(querymacs queryports queryat);
$VERSION	= 0.61;

use Net::SNMP;

my ($session);

sub connect {
   my %cla = @_;
   $cla{comm} = "public" unless exists $cla{comm};
   $session = Net::SNMP->session(-hostname  => $cla{host},
                                 -community => $cla{comm},
                                 -translate => [-octetstring => 0x0],
                                 );
}

sub queryat {
   my ($key, $newkey, %final);
   &connect(@_);

   my $ifoid = '1.3.6.1.2.1.3.1.1.1';
   my $ifref = $session->get_table($ifoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   my $physoid = '1.3.6.1.2.1.3.1.1.2';
   my $physref = $session->get_table($physoid);
   
   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   my $addroid = '1.3.6.1.2.1.3.1.1.3';
   my $addrref = $session->get_table($addroid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$physref}) {
      $physref->{$key} = unpack('H12', $physref->{$key});
      next if (length($physref->{$key}) < 12);
      ($newkey = $key) =~ s/$physoid//;
      $final{$physref->{$key}} = 
         $addrref->{$addroid . $newkey} . "|" .
         $ifref->{$ifoid . $newkey};
   }

   return \%final;
}

sub queryfdb {
   my ($key, $newkey, %port, %final);
   &connect(@_);

   my $macoid = '1.3.6.1.2.1.17.4.3.1.1';
   my $macref = $session->get_table($macoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }
   
   my $portoid = '1.3.6.1.2.1.17.4.3.1.2';
   my $portref = $session->get_table($portoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$portref}) {
      ($newkey = $key) =~ s/$portoid\.//;
      $port{$newkey} = $portref->{$key};
   }

   foreach $key (keys %{$macref}) {
      $macref->{$key} = unpack('H12', $macref->{$key});
      next if (length($macref->{$key}) < 12);
      ($newkey = $key) =~ s/$macoid\.//;
      $final{$macref->{$key}} = $port{$newkey}
   }

   return \%final;
}

sub querymacs {
   my ($key, $newkey, %mac);
   &connect(@_);

   my $macoid = '1.3.6.1.2.1.17.4.3.1.1';
   my $macref = $session->get_table($macoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$macref}) {
      ($newkey = $key ) =~ s/$macoid\.//;
      $macref->{$key} = unpack('H12', $macref->{$key});
      $mac{$newkey} = sprintf("%12s", $macref->{$key});
   }

   return \%mac;
}

sub queryports {
   my ($key, $newkey, %port);
   &connect(@_);

   my $portoid = '1.3.6.1.2.1.17.4.3.1.2';
   my $portref = $session->get_table($portoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$portref}) {
      ($newkey = $key ) =~ s/$portoid\.//;
      $port{$newkey} = $portref->{$key};
   }

   return \%port;
}

1;

__END__

=head1 NAME

BridgeQuery - Perl extension for retrieving bridge tables.

=head1 SYNOPSIS

  use SNMP::BridgeQuery;
  use SNMP::BridgeQuery qw(querymacs queryports queryat);

  $fdb = queryfdb(host => $address,
                  comm => $community);
  unless (exists $fdb->{error}) {
     ($fdb->{$mac} = "n/a") unless (exists $fdb->{$mac});
     print "This MAC address was found on port: ".$fdb->{$mac}."\n";
  }

=head1 DESCRIPTION

BridgeQuery polls a device which responds to SNMP Bridge Table
queries and generates a hash reference with each polled MAC
address as the key and the associated port as the value.  The
specific MIBs that are polled are described in RFC1493.

SNMP::BridgeQuery requires Net::SNMP in order to function.
(Checked for during 'perl Makefile.PL')

Devices can be switches, bridges, or most anything that responds
as a OSI Layer 2 component.  Layer 3 devices do not generally
respond and will cause an error.  If an error is generated, it will
return a hash reference with a single element ('error') which
can be tested for.

Two other functions (querymacs & queryports) can be explicitly
exported.  They work the same way as queryfdb, but they return MAC
addresses or ports (respectively) with the SNMP MIB as the hash key.

A newly added function (queryat) can be used on layer 3 switches
to poll the Address Translation Tables.  This is similar to the
data returned by the 'queryfdb' function, but it returns the IP
address of the device and the associated interface (separated by a 
pipe '|') with the MAC address as the key.  On a layer 3 switch,
this interface probably does not correspond to a physical port, 
but more likely refers to a vlan ID.  Using this function on a 
layer 2 device will generate a 'trapped' error.

=head1 ACKNOLEDGEMENTS

David M. Town - Author of Net::SNMP

=head1 AUTHOR

John D. Shearer <bridgequery@netguy.org>

=head1 SEE ALSO

perl(1), perldoc(1) Net::SNMP.

=head1 COPYRIGHT

Copyright (c) 2001-2003 John D. Shearer.  All rights reverved.
This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut


