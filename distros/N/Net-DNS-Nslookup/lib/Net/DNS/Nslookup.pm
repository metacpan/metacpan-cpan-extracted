package Net::DNS::Nslookup;

# Copyright (c) 2011 Paul Greenberg. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION);
$VERSION = 0.03;

$|=1;

my $so = $^O;
my $cmd = "nslookup";
my $cmdargs = "";
my $debug;
my $flags;

if ($^O =~ /win/i) {
 $flags = 'w';
 $cmdargs = "2>&1";
} else {
 $flags = 'u';
}

sub get_ips {
 my $response = "";
 my $dnsquery = $_[1];
 my $wait = "y";
 my $ct = 0;

 if($flags eq "u") { 
  printf("found %s\n", $flags) if $debug;
 }

 open (DNSQUERY, "$cmd $dnsquery $cmdargs |");
 while (<DNSQUERY>){
  my $ln = $_;
  chomp($ln);
  if( $ln =~ /Non-authoritative answer:/) { $wait = "n" }
  next if ($wait eq "y");
  $ct++;
  printf("%s\n", $ln) if $debug;
  if($flags eq "u") {
   # For *nix
   if($ln =~ /^Address:\s*(.*)$/) {
    printf("%s\n", $1) if $debug;
    $response = $response . $dnsquery.",".$1."\n"; 
   }
  } else {
   # For win
   next if ($ct < 4);
   if($ln =~ m/^Address:\s+(.*)$/) {
    $response = $response . $dnsquery.",".$1."\n";
   }
   if($ln =~ m/^Addresses:\s+(.*)$/) {
    my $t = $1;
    $t =~ s/ //g;
    my @t = split(/,/, $t);
    foreach (@t) {
     $response = $response . $dnsquery.",".$_."\n";
    }
   }  
  }
 }
 close DNSQUERY;
 chomp $response;
 return $response;
}

1;
__END__

=head1 NAME

  Net::DNS::Nslookup - Perl module to resolve DNS name to IP address(es)
  using nslookup.

=head1 DESCRIPTION

  Nslookup module provides simple way to resolve DNS name to 
  IP address(es) on a local system (Linux, Win*, Mac OS X 10.3.9, Solaris).

=head1 SYNOPSIS

  use strict;
  use Net::DNS::Nslookup;
  
  printf("%s\n", "# Resolving multiple domains");
  my @sites = ("www.google.com","www.cnn.com","www.jobs.com");
  foreach my $dnsname (@sites) {
   my $dns_resp = Net::DNS::Nslookup->get_ips($dnsname);
   printf("%s\n", $dns_resp);
  }
	
  printf("%s\n", "# Resolving single domain www.msn.com");
  my $nslookup = Net::DNS::Nslookup->get_ips("www.msn.com");
  printf("%s\n", $nslookup);
	
  Output:
  # Resolving multiple domains
  www.google.com,74.125.226.176
  www.google.com,74.125.226.177
  www.google.com,74.125.226.178
  www.google.com,74.125.226.179
  www.google.com,74.125.226.180
  www.cnn.com,157.166.226.25
  www.cnn.com,157.166.226.26
  www.cnn.com,157.166.255.18
  www.cnn.com,157.166.255.19
  www.cnn.com,157.166.224.25
  www.cnn.com,157.166.224.26
  www.jobs.com,208.71.192.206
  # Resolving single domain www.msn.com
  www.msn.com,65.55.17.25

=head1 METHODS

=head2 get_ips()

  $dns_resp = Net::DNS::Nslookup->get_ips("www.google.com");

  Resolve name such as www.google.com to IP address(es). 

=head1 SYSTEM REQUIREMENTS

  This module requires "nslookup" binary.  

=head1 SEE ALSO

  man nslookup

=head1 AUTHOR

  Paul Greenberg
  http://www.isrcomputing.com
    
=head1 COPYRIGHT

  Copyright (c) 2011 Paul Greenberg. All rights reserved.
  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=cut
