package Net::DNSServer::SharedCache;

use strict;
use Exporter;
use vars qw(@ISA);
use Net::DNSServer::Base;
use Net::DNS;
use Net::DNS::RR;
use Net::DNS::Packet;
use Carp qw(croak);
use IPC::SharedCache;

@ISA = qw(Net::DNSServer::Base);

# Created and passed to Net::DNSServer->run()
sub new {
  my $class = shift || __PACKAGE__;
  my $self  = shift || {};
  if (! $self -> {ipc_key} || ! exists $self -> {max_size}) {
    croak 'Usage> new({ipc_key => "fred" [ , max_size => 50_000_000 ] [, fresh => 0 ] })';
  }
  if ($self -> {fresh}) {
    &IPC::SharedCache::remove( $self -> {ipc_key} );
  }
  my %dns_cache=();
  tie (%dns_cache, 'IPC::SharedCache',
       ipc_key             => $self->{ipc_key},
       load_callback       => \&load_answer,
       validate_callback   => \&validate_ttl,
       max_size            => $self->{max_size},
       ) || die "IPC::SharedCache failed for ipc_key [$self->{ipc_key}]";
  if ($self -> {fresh}) {
    %dns_cache = ();
  }
  $self -> {dns_cache} = \%dns_cache;
  return bless $self, $class;
}

# If the TTL expires, there is nothing to use anymore.
sub load_answer {
  my $key = shift;
  print STDERR "DEBUG: load_answer called for [$key]\n";
  return \undef;
}

# Check if the TTL is still good
sub validate_ttl {
  my ($key, $value) = @_;
  print STDERR "DEBUG: validate_ttl called for [$key]\n";
  # There is no TTL stored in the DNS structure result
  return 1 if $key =~ /\;(structure)$/;
  return 1 unless $key =~ /\;(lookup)$/;
  return 0 unless (ref $value) eq "ARRAY";
  foreach my $entry (@$value) {
    # If this entry has expired, then throw the whole thing out
    return 0 if (ref $entry) ne "ARRAY" || $entry->[0] < time;
  }
  # If nothing has expired, the data is still valid
  return 1;
}

# Called immediately after incoming request
# Takes the Net::DNS::Packet question as an argument
sub pre {
  my $self = shift;
  my $net_dns_packet = shift || croak 'Usage> $obj->resolve($Net_DNS_obj)';
  $self -> {question} = $net_dns_packet;
  $self -> {net_server} -> {usecache} = 1;
  return 1;
}

# Called after all pre methods have finished
# Returns a Net::DNS::Packet object as the answer
#   or undef to pass to the next module to resolve
sub resolve {
  my $self = shift;
  my $dns_packet = $self -> {question};
  my ($question) = $dns_packet -> question();
  my $key = $question->string();
  my $cache_structure = $self -> {dns_cache} -> {"$key;structure"} || undef;
  unless ($cache_structure &&
          (ref $cache_structure) eq "ARRAY" &&
          (scalar @$cache_structure) == 3) {
    print STDERR "DEBUG: Cache miss on [$key;structure]\n";
    return undef;
  }
  print STDERR "DEBUG: Cache hit on [$key;structure]\n";
  # Structure key found in cache, so lookup actual values

  # ANSWER Section
  my $answer_ref      = $self->fetch_rrs($cache_structure->[0]);

  # AUTHORITY Section
  my $authority_ref   = $self->fetch_rrs($cache_structure->[1]);

  # ADDITIONAL Section
  my $additional_ref  = $self->fetch_rrs($cache_structure->[2]);

  # Make sure all sections were loaded successfully from cache.
  unless ($answer_ref && $authority_ref && $additional_ref) {
    # If not, flush structure key to ensure
    # it will be re-stored in the post() phase.
    delete $self -> {dns_cache} -> {"$key;structure"};
    return undef;
  }

  # Initialize the response packet with a copy of the request
  # packet in order to set the header and question sections
  my $response = bless \%{$dns_packet}, "Net::DNS::Packet"
    || die "Could not initialize response packet";

  # Install the RRs into their corresponding sections
  $response->push("answer",      @$answer_ref);
  $response->push("authority",   @$authority_ref);
  $response->push("additional",  @$additional_ref);

  $self -> {net_server} -> {usecache} = 0;
  return $response;
}

sub fetch_rrs {
  my $self = shift;
  my $array_ref = shift;
  my @rrs = ();
  if (ref $array_ref ne "ARRAY") {
    return undef;
  }
  foreach my $rr_string (@$array_ref) {
    my $lookup = $self -> {dns_cache} -> {"$rr_string;lookup"} || undef;
    unless ($lookup && ref $lookup eq "ARRAY") {
      return undef;
    }
    foreach my $entry (@$lookup) {
      return undef unless ref $entry eq "ARRAY";
      my ($expire,$rdatastr) = @$entry;
      my $rr = Net::DNS::RR->new ("$rr_string\t$rdatastr");
      $rr->ttl($expire - time);
      push @rrs, $rr;
    }
  }
  return \@rrs;
}

# Called after response is sent to client
sub post {
  my $self = shift;
  if ($self -> {net_server} -> {usecache}) {
    # Grab the answer packet
    my $dns_packet = shift;
    # Store the answer into the cache
    my ($question) = $dns_packet -> question();
    my $key = $question->string();
    my @s = ();
    push @s, $self->store_rrs($dns_packet->answer);
    push @s, $self->store_rrs($dns_packet->authority);
    push @s, $self->store_rrs($dns_packet->additional);
    print STDERR "DEBUG: Storing cache for [$key;structure]\n";
    $self -> {dns_cache} -> {"$key;structure"} = \@s;
  }
  return 1;
}

# Subroutine: store_rrs
# PreConds:   Takes a list of RR objects
# PostConds:  Stores rdatastr components into cache
#             and returns a list of uniques
sub store_rrs {
  my $self = shift;
  my $answer_hash = {};
  my $dns_cache = $self -> {dns_cache};
  foreach my $rr (@_) {
    my $key = join("\t",$rr->name.".",$rr->class,$rr->type);
    my $rdatastr = $rr->rdatastr();
    my $ttl = $rr->ttl();
    if (!exists $answer_hash->{$key}) {
      $answer_hash->{$key} = [];
    }
    push @{$answer_hash->{$key}},
    [$ttl + time, $rdatastr];
  }
  foreach my $key (keys %{$answer_hash}) {
    # Save the rdatastr values into the lookup cache
    $dns_cache->{"$key;lookup"} = $answer_hash->{$key};
  }
  return [keys %{$answer_hash}];
}

# Called once prior to server shutdown
sub cleanup {
  my $self = shift;
  if ($self -> {fresh}) {
    %{$self -> {dns_cache}} = ();
  }
  untie %{$self -> {dns_cache}};
  if ($self -> {fresh}) {
    &IPC::SharedCache::remove( $self -> {ipc_key} );
  }
  return 1;
}

1;
__END__

=head1 NAME

Net::DNSServer::SharedCache - IPC::SharedCache DNS Cache resolver

=head1 SYNOPSIS

  #!/usr/bin/perl -w -T
  use strict;
  use Net::DNSServer;
  use Net::DNSServer::SharedCache;

  my $resolver1 = new Net::DNSServer::SharedCache {
    ipc_key  => "DNSk",
    max_size => 0,
    fresh    => 1,
  };
  my $resolver2 = ... another resolver object ...;
  run Net::DNSServer {
    priority => [$resolver1,$resolver2],
  };

=head1 DESCRIPTION

A Net::DNSServer::Base which uses IPC::SharedCache
to implement a DNS Cache in shared memory to allow
the cache to be shared across processes.
This is useful if the server forks (Net::Server::PreFork).

This resolver will cache responses that
another module resolves complying with the
corresponding TTL of the response.
It cannot provide resolution for a request
unless it already exists within its cache.
This resolver is useful for servers that
may fork, because all processes will be
able to access the same cache in shared
memory.

=head2 new

The new() method takes a hash ref of properties.

=head2 ipc_key (required)

ipc_key is required by IPC::SharedCache
to tie a portion of shared memory.
It can be specified as either a four-character
string or an integer value.
(Passed to the tie call.)

=head2 max_size (optional)

This value is specified in bytes.
It defaults to 0, which specifies no limit on the size of the cache.
Turning this feature on costs a fair ammount of performance.
(Passed to the tie call.)

=head2 fresh (optional)

Whether or not to use a fresh cache
at server startup.
0 means to reuse the cache under the
ipc_key specified if one exists.
1 means to start fresh and to release
the shared memory at server startup
and shutdown and restart.
It defaults to 0 meaning it will not cleanup
the shared memory segments it creates.

Use ipcs and ipcrm to manually manage the
shared memory segments if necessary.

=head2

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

See
L<IPC::SharedCache>
for more details on ipc_key and max_size.

L<Net::Server::PreFork>

ipcs(8), ipcrm(8)

=head1 COPYRIGHT

Copyright (c) 2001, Rob Brown.  All rights reserved.
Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: SharedCache.pm,v 1.4 2002/04/08 07:01:17 rob Exp $

=cut

DBM key/value storage format

Key:
Question;struct

"netscape.com.	IN	ANY;structure"

Note that [TAB] delimites the three parts of the question.


Value:
[
 # ANSWERS
 ["netscape.com.	IN	NS",
  "netscape.com.	IN	A",
  "netscape.com.	IN	SOA"],
 # AUTHORITIES
 ["netscape.com.	IN	NS"],
 # ADDITIONALS
 ["ns.netscape.com.	IN	A",
  "ns2.netscape.com.	IN	A"]
]


-OR-


Key:
Question;lookup
"netscape.com.	IN	A;lookup"

Value:
[
 # TTL, VALUE (rdatastr)
 [time + 100193, "207.200.89.225"],
 [time + 100193, "207.200.89.193"]
]


;; ANSWER SECTION (5 records)
netscape.com.	100193	IN	NS	NS.netscape.com.
netscape.com.	100193	IN	NS	NS2.netscape.com.
netscape.com.	1190	IN	A	207.200.89.225
netscape.com.	1190	IN	A	207.200.89.193
netscape.com.	100	IN	SOA	NS.netscape.com. dnsmaster.netscape.com. (
					2001051400	; Serial
					3600	; Refresh
					900	; Retry
					604800	; Expire
					600 )	; Minimum TTL

;; AUTHORITY SECTION (2 records)
netscape.com.	100193	IN	NS	NS.netscape.com.
netscape.com.	100193	IN	NS	NS2.netscape.com.

;; ADDITIONAL SECTION (2 records)
NS.netscape.com.	138633	IN	A	198.95.251.10
NS2.netscape.com.	115940	IN	A	207.200.73.80
