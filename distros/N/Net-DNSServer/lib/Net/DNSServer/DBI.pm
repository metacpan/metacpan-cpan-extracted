package Net::DNSServer::DBI;

# $Id: DBI.pm,v 1.3 2002/04/29 10:50:31 rob Exp $
# This module simply forwards a request to another name server to do the work.

use strict;
use Exporter;
use vars qw(@ISA $default_ttl);
use Net::DNSServer::Base;
use Net::DNS;
use Net::DNS::Packet;
use DBI;
use Carp qw(croak);

@ISA = qw(Net::DNSServer::Base);

# Default TTL if none specified in the database.
$default_ttl = 86400;

# Created before calling Net::DNSServer->run()
sub new {
  my $class = shift || __PACKAGE__;
  my $self = shift || {};
  if (! $self -> {connect} ) {
    croak "Missing required 'connect' DSN array ref settings for DBI";
  }
  if (ref $self -> {connect} ne "ARRAY") {
    croak "must be an array ref to the DBI::connect parameters";
  }
  # Get the persistent connection to the database
  $self -> {dbh} =
    DBI->connect( @{ $self->{connect} } )
      or croak "Could not connect: $DBI::errstr";
  # Prepare the one query that will be done over and over again
  my $query = <<MAGIC;
SELECT address,destination,skeleton,email,serial,refresh,retry,expire,minimum,nslist
FROM zone,soa,template
WHERE domain=? AND authority_id=soa.id AND template_id=template.id
MAGIC
  $self -> {sth} =
    $self -> {dbh} -> prepare($query)
      or croak "Failed to prepare query:\n$query\n  on database handle from connect settings";

  $self -> {default_ttl} ||= $default_ttl;
  $self -> {default_serial} ||= do {
    my $NOW = `date +"%Y%m%d00"`;
    chomp $NOW;
    $NOW;
  };
  $self -> {default_nameservers} ||= do {
    # Determine me and my corresponding name server by default
    local $^W = 0;
    eval {
      require Sys::Hostname;
    } or croak "Sys::Hostname and Socket must be installed if default_nameservers is not passed";
    my ($ns1, $ns2, $myIP);
    $ns1 = Sys::Hostname::hostname()
      or die "Cannot determine hostname";
    # Forward lookup
    $myIP = (gethostbyname($ns1))[4]
      or die "Cannot resolve [$ns1]";
    # Reverse lookup
    $ns1 = gethostbyaddr($myIP,&Socket::AF_INET())
      or die "Cannot determine reverse lookup for [".
        join(".",unpack("C4",$myIP))."]";
    $ns2 = $ns1;
    $ns2 =~ s/^ns(\d*)/"ns".($1+($1%2?1:-1)+!$1)/e;
    $ns1 eq $ns2 ? [ $ns1 ] : [ $ns1, $ns2 ];
  };

  return bless $self, $class;
}

# Called after all pre methods have finished
# Returns a Net::DNS::Packet object as the answer
#   or undef to pass to the next module to resolve
sub resolve {
  my $self = shift;
  my $result = $self -> {question};
  my ($q) = $result->question;
  my $qtype = $q->qtype;
  my $qname = $q->qname;
  my $zone = $qname;
  $qname = "" if $qname eq ".";
  $zone = "." if $zone eq "";

  while ($zone ne "") {
    #print STDERR "DEBUG: Looking for qtype=[$qtype] qname=[$qname] within zone=[$zone]\n";
    $zone=~s/\.$//;
    if (!$self->{sth}->execute($zone)) {
      warn "Crash! Could not execute [$DBI::errstr]\n";
      return undef;
    }
    my ($address,$destination,$skeleton,$email,$serial,$refresh,$retry,$expire,$minimum);
    local ($_);
    if (($address,$destination,$skeleton,$email,$serial,$refresh,$retry,$expire,$minimum,$_)
        =$self->{sth}->fetchrow_array) {
      my @nslist=split;                       # Get the name server list
      # NULL means use generated serial
      $serial = $self->{default_serial} unless defined $serial && length $serial;

      $email =~ s/%NS%/$self->{default_nameservers}->[0]/g;
      $email =~ s/@/./;         # Email address like "<hostmaster@isp.com>"
      $email =~ s/\.*$/./;      # Must be in the format: "hostmaster.isp.com."
      #print STDERR "DEBUG: Address = [$address]\n";
      #print STDERR "DEBUG: Destination = [$destination]\n";
      #print STDERR "DEBUG: TEMPLATE CONTENTS:[$skeleton]\n";
      #print STDERR "DEBUG: Email Contact [$email]\n";
      #print STDERR "DEBUG: SOA BLOCK ([$serial] [$refresh] [$retry] [$expire] [$minimum])\n";
      #print STDERR "DEBUG: Authoritative Name Servers (",join(",",@nslist),")\n";
      my $SOA = "%ZONE%.  IN SOA %NS% $email ($serial $refresh $retry $expire $minimum)\n";
      my $primary = "";
      my $authority = "";
      foreach $authority (@nslist) {
        if (/%NS%/) {
          foreach (@{ $self->{default_nameservers} }) {
            my $a = $authority;
            $a =~ s/%NS%/$_/g;
            $SOA .= "%ZONE%.  IN NS $a\n";
            $primary = $a if $primary eq "";
          }
        } else {
          $SOA .= "%ZONE%.  IN NS $authority\n";
          $primary = $authority if $primary eq "";
        }
      }
      $skeleton=~s/^\n*//;
      $skeleton=$SOA.$skeleton;
      $skeleton=~s/@/%ZONE%./g;
      $skeleton=~s/^(\s+IN)/%ZONE%.$1/gim;
      $skeleton=~s/^([\%\w\-\.]*[\%\w])(\s)/$1.%ZONE%.$2/gim;
      $skeleton=~s/^([\%\w\-\.]+)(\s+IN)/$1\t$self->{default_ttl}$2/gim;
      $skeleton=~s/\n*$/\n/;
      my $ipaddress="";
      if (length $address) {
        $ipaddress=join(".",unpack("C4",pack("N",$address)));
        #print STDERR "DEBUG: Address expanded from [$address] to [$ipaddress]\n";
      }
      my %SWAP=
        ("IPADDRESS"    => $ipaddress,
         "DESTINATION"  => $destination,
         "ZONE"         => $zone,
         "NS"           => $primary,
         );
      $skeleton=~s/%(\w+)%/$SWAP{$1}/g;
      #print STDERR "DEBUG: Munged template:\n$skeleton";

      #print STDERR "DEBUG: Searching for [^$qname.]\n";
      # Try to find an exact match to the query
      while ($skeleton=~/^($qname\.\s+.*\s$qtype\s+.*)/gim) {
        my $dns_entry=$1;
        my $rr=new Net::DNS::RR($dns_entry);
        #print STDERR "DEBUG: - Packet Contents: [",$rr->string,"]\n";
        $result->push("answer",new Net::DNS::RR($dns_entry));
      }
      # If none found and not looking for CNAME, then try CNAME's also
      if (!$result->header->ancount && $qtype ne "CNAME") {
        #print STDERR "DEBUG: No answers found. Searching for a CNAME...\n";
        if ($skeleton=~/^($qname\.\s.*\bCNAME\s+)([\w\-\.]+)/im) {
          my ($dns_entry,$alias)=("$1$2",$2);
          #print STDERR "DEBUG: Found an aliased match! [$dns_entry]\n";
          #print STDERR "DEBUG: Searching for a [$qtype] of a [$alias]\n";
          $result->push("answer",new Net::DNS::RR($dns_entry));
          while ($skeleton=~/^($alias\s.*\s$qtype\s.*)/gim) {
            $dns_entry=$1;
            #print STDERR "DEBUG: Found an alias record! [$dns_entry]\n";
            $result->push("answer",new Net::DNS::RR($dns_entry));
          }
        }
      }
      # If still none found, then look for "*" entry
      if (!$result->header->ancount) {
        #print STDERR "DEBUG: Still no answers found, doing a '*' entry search...\n";
        while ($skeleton=~/^\*.$zone(\.\s.*\b$qtype\b.*)/gim) {
          my $dns_entry="$qname$1";
          #print STDERR "DEBUG: Found a [*.$zone] match! [$dns_entry]\n";
          $result->push("answer",new Net::DNS::RR($dns_entry));
        }
      }
      # If at least one winner was found
      if ($result->header->ancount || $zone eq "") {
        if ($zone eq "") {
          #print STDERR "DEBUG: Searching for NS authorities for (root) zone...\n";
        }
        # Add NS entries if they haven't been added already
        if ($qtype ne "NS" || !$result->header->ancount) {
          while ($skeleton=~/^($zone\.\s.*\bNS\b.*)/gim) {
            my $dns_entry=$1;
            $dns_entry=~s/^(\.\s)/.$1/;
            #print STDERR "DEBUG: Found an authority match! [$dns_entry]\n";
            $result->push("authority",new Net::DNS::RR($dns_entry));
          }
        }
        # This is authoritative if we have any answers
        $result->header->aa(1-!$result->header->ancount);
        # This is a response
        $result->header->qr(1);
        # Recursion not allowed
        $result->header->ra(0);
        # Return the result
        return $result;
      }
    }
  } continue {
    # Reduce one prefix off of $zone
    if ($zone !~ s/^[\w\-]+\.// &&
        $zone !~ s/^[\w\-]+$/./) {
      $zone = "";
    }
  }
  $result->header->rcode('NXDOMAIN');
  #my $snoop=$result->string;
  #$snoop=~s/^/> /gm;
  #print STDERR $snoop;

  return $result;
}

1;
__END__

=head1 NAME

Net::DNSServer::DBI - SQL backend for resolving DNS queries

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use Net::DNSServer;
  use Net::DNSServer::DBI;

  my $dbi_resolver = new Net::DNSServer::DBI {
    connect => [ dbi connect args ... ],
    default_ttl => "3600",
    default_serial => "2002040100",
    default_nameservers => [ qw(ns.isp.com) ],
  };

  run Net::DNSServer {
    priority => [ $dbi_resolver ],
  };

=head1 DESCRIPTION

This resolver translates a DNS query into
an SQL query.  The answer from the SQL
server is translated back into a DNS
response and sent to the DNS client.

This module requires an external database
server to be running and the DBI / DBD::*
API Interface to the SQL database server
to be installed.  The external database
server may run on the same machine as the
name server, (localhost), or it may run on
a separate machine or database cluster
for increased scalability and/or fault
tolerance.

=head2 new

The new() method takes a hash ref of properties.

=head2 connect (required)

This is a hash ref of arguments that will
be passed to DBI->connect() to initiate
the connection to the database which must
yield a valid database handle.

This field is required.

=head2 default_ttl (optional)

This is the $DEFAULT_TTL that will be used in
case a zone template does not contain its own.

If none is supplied, it defaults to 86400.

=head2 default_serial (optional)

This is the serial number to be used for those
in the "soa" table with NULL for serial.

If none is supplied, it defaults to today:

date +"%Y%m%d00"

=head2 default_nameservers (optional)

This is an array ref of name servers to
be used for all entries that have %NS%
in the "soa" table.  The first element
of this array is also considered the
primary SOA server.

If none is supplied, the fully qualified
domain of the hostname is used:

hostname --fqdn

along with its complement name server
computed based on the hostname.
i.e., "ns1.isp.com" will also add
"ns2.isp.com" to this setting.

=head1 EXAMPLE

See demo/mysql/README packaged with this
distribution for a working example using
the MySQL database server as its SQL
backend.

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

L<DBI>,
L<Net::DNSServer>,
L<Net::DNSServer::Base>,

=head1 COPYRIGHT

Copyright (c) 2002, Rob Brown.  All rights reserved.

Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: DBI.pm,v 1.3 2002/04/29 10:50:31 rob Exp $

=cut
