package Net::GrpNetworks;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.08';

# Preloaded methods go here.

sub new
   {
   my $class = shift;
   my $GrpNet = {};

   bless $GrpNet, $class;
   return $GrpNet; 
   }

sub find
   {
   my ($obj, $ip) = @_;

   my($ret, $first, $middle, $last, $int_ip);

   $first = 0;
   $last = $#{$obj->{'Net'}};
   $int_ip = ip2int($ip);
   while ( $last >= $first and $ret eq '' )
      {
      $middle = int(($last + $first)/2);
      if ( $obj->{'Net'}[$middle]{'Network'} <= $int_ip ) # May be the correct network
         {
         if ( ($int_ip & $obj->{'Net'}[$middle]{'Mask'}) == $obj->{'Net'}[$middle]{'Network'} )
            {
            $ret = $obj->{'Net'}[$middle]{'Name'};
            }
         $first = $middle + 1;
         }
       else
         {
         $last = $middle - 1;
         }
      }
   return($ret);
   }



sub print
   {
   my ($obj) = @_;

   my $status = 0; # FALSE
   my ($ref, $name, $network, $mask);

   foreach $ref ( @{$obj->{'Net'}} )
      {
      $name = $ref->{'Name'};
      $network = int2ip($ref->{'Network'});
      $mask = int2ip($ref->{'Mask'});
      print "Name: $name - Net: $network - Mask: $mask\n";
      $status = 1; # TRUE
      }
   return($status);
   }
   

sub add
   {
   my ($obj, $grp_name, $net, $mask) = @_;

   my($status, @table);

   $status = 0; # FALSE

   if ( verif_ip_is_ok($net) and verif_ip_is_ok($mask) )
      {

      #
      # INCLUDE A NEW ITEN
      #
      push @{$obj->{'Net'}}, {'Name'	=> "$grp_name",
                              'Network'	=> ip2int($net),
                              'Mask'	=> ip2int($mask)};

      #
      # SORT THE TABLE OF NETWORK 
      #
      @table = sort { $a->{'Network'} <=> $b->{'Network'} } @{$obj->{'Net'}};
      $obj->{'Net'} = \@table;


      $status = 1; # TRUE
      }
   return($status);
   }


sub verif_ip_is_ok
   {
   my($ip) = @_;

   my $status = 0; # FALSE

   if ( $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ )
      {
      if ( $1 >= 0 and $1 <= 255 and
           $2 >= 0 and $2 <= 255 and
           $3 >= 0 and $3 <= 255 and
           $4 >= 0 and $4 <= 255 ) # IP is OK
         {
         $status = 1; # TRUE
         }
      }
   return($status);
   }

sub ip2int
   {
   my($ip) = @_;
   my $int=0;
   my($ip1,$ip2,$ip3,$ip4);

   if ( $ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ )
      {
      $int = ($1 * 16777216) + ($2 * 65536) + ($3 * 256) + $4;
      }
   return($int);
   }

sub int2ip
   {
   my($int) = @_;

   my($ip1, $ip2, $ip3, $ip4);
   my $ip = '';

   $ip1 = int($int/16777216);
   $ip2 = int(($int & 16711680)/65536);
   $ip3 = int(($int & 65280)/256);
   $ip4 = $int & 255;
   $ip = "$ip1.$ip2.$ip3.$ip4";
   return($ip);
   }


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::GrpNetworks - Perl extension to determine in which network group a IP belongs to. 

=head1 SYNOPSIS

  use Net::GrpNetworks;

  $grpnet = new Net::GrpNetworks();

  $grpnet->add(group name, network block, netmask);
  $GroupName = $grpnet->find(IP); 


=head1 DESCRIPTION

Net::GrpNetworks creates network groups and allows researching 
for specific IPs discovering in which network group each IP belongs to.

For example:

  use Net::GrpNetworks;

  $grpnet = new Net::GrpNetworks();

  $grpnet->add("New York", "210.210.10.0", "255.255.255.0");
  $grpnet->add("New York", "210.210.11.0", "255.255.255.0");
  $grpnet->add("New York", "210.210.12.0", "255.255.254.0");
  $grpnet->add("Rio de Janeiro", "200.255.49.128", "255.255.255.128");
  $grpnet->add("Rio de Janeiro", "200.255.50.0", "255.255.252.0");
  $grpnet->add("Rio de Janeiro", "200.255.60.0", "255.255.255.0");

  $City = $grpnet->find("200.255.60.10");  # $City will be set to "Rio de Janeiro"
  if ( $City = $grpnet->find("210.210.9.5") ) # Will be false

=head1 COPYRIGHT

    Copyright (c) 1997 Andre Rodrigues Viegas. All rights reserved. This
    program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself. 

=head1 AUTHOR

Andre R. Viegas, andre.viegas@writeme.com.br

