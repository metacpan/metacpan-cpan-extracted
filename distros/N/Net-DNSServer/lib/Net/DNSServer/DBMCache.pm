package Net::DNSServer::DBMCache;

use strict;
use Exporter;
use vars qw(@ISA $expiration_check);
use Net::DNSServer::Base;
use Net::DNS;
use Net::DNS::RR;
use Net::DNS::Packet;
use Carp qw(croak);
use IO::File;
use Fcntl qw(LOCK_SH LOCK_EX LOCK_UN);
use Storable qw(freeze thaw);
use GDBM_File;

@ISA = qw(Net::DNSServer::Base);
$expiration_check = undef;

# Created and passed to Net::DNSServer->run()
sub new {
  my $class = shift || __PACKAGE__;
  my $self  = shift || {};
  if (! $self -> {dbm_file} ) {
    croak 'Usage> new({
    dbm_file    => "/var/named/dns_cache.db",
    fresh       => 0})';
  }
  # Create lock file to serialize DBM accesses and avoid DBM corruption
  my $lock = IO::File->new ("$self->{dbm_file}.LOCK", "w")
    || croak "Could not write to $self->{dbm_file}.LOCK";

  # Test to make sure it can be locked and unlocked successfully
  flock($lock,LOCK_SH) || die "Couldn't get shared lock on $self->{dbm_file}.LOCK";
  flock($lock,LOCK_EX) || die "Couldn't get exclusive lock on $self->{dbm_file}.LOCK";
  flock($lock,LOCK_UN) || die "Couldn't unlock on $self->{dbm_file}.LOCK";
  $lock->close();

  $self -> {dns_cache} = {};
  # Actually connect to dbm file as a test
  tie (%{ $self -> {dns_cache} },
       'GDBM_File',
       $self->{dbm_file},
       &GDBM_WRCREAT,
       0640)
    || croak "Could not connect to $self->{dbm_file}";
  if ($self -> {fresh}) {
    # Wipe any old information if it exists from last time
    %{ $self -> {dns_cache} } = ();
  }
  untie (%{ $self -> {dns_cache} });
  return bless $self, $class;
}

# Check if the TTL is still good
sub validate_ttl {
  my $value = shift or return undef;
  return undef unless (ref $value) eq "ARRAY";
  foreach my $entry (@$value) {
    # If this entry has expired, then throw the whole thing out
    return undef if (ref $entry) ne "ARRAY" || $entry->[0] < time;
  }
  # If nothing has expired, the data is still valid
  return $value;
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

  # Create lock file to serialize DBM accesses and avoid DBM corruption
  my $lock = IO::File->new ("$self->{dbm_file}.LOCK", "w");
  $lock && flock($lock,LOCK_SH);
  tie (%{ $self -> {dns_cache} },
       'GDBM_File',
       $self->{dbm_file},
       &GDBM_WRCREAT,
       0640);
  my $cache_structure = $self -> {dns_cache} -> {"$key;structure"} || undef;
  $cache_structure &&= thaw $cache_structure;
  unless ($cache_structure &&
          (ref $cache_structure) eq "ARRAY" &&
          (scalar @$cache_structure) == 3) {
    print STDERR "DEBUG: Cache miss on [$key;structure]\n";
    untie (%{ $self -> {dns_cache} })
      if tied %{ $self -> {dns_cache} };
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

  my $response = undef;
  # Make sure all sections were loaded successfully from cache.
  if ($answer_ref && $authority_ref && $additional_ref) {
    # Initialize the response packet with a copy of the request
    # packet in order to set the header and question sections
    $response = bless \%{$dns_packet}, "Net::DNS::Packet"
      || die "Could not initialize response packet";

    # Install the RRs into their corresponding sections
    $response->push("answer",      @$answer_ref);
    $response->push("authority",   @$authority_ref);
    $response->push("additional",  @$additional_ref);

    $self -> {net_server} -> {usecache} = 0;
  } else {
    # If not loaded, flush structure key to ensure
    # it will be re-stored in the post() phase.
    delete $self -> {dns_cache} -> {"$key;structure"};
  }
  untie (%{ $self -> {dns_cache} }) if tied %{ $self -> {dns_cache} };
  $lock->close();
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
    my $lookup = validate_ttl(thaw ($self -> {dns_cache} -> {"$rr_string;lookup"})) || undef;
    unless ($lookup && ref $lookup eq "ARRAY") {
      print STDERR "DEBUG: Lookup Cache miss on [$rr_string]\n";
      return undef;
    }
    print STDERR "DEBUG: Lookup Cache hit on [$rr_string]\n";

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
    # Create lock file to serialize DBM accesses and avoid DBM corruption
    my $lock = IO::File->new ("$self->{dbm_file}.LOCK", "w");
    $lock && flock($lock,LOCK_EX);
    tie (%{ $self -> {dns_cache} },
         'GDBM_File',
         $self->{dbm_file},
         &GDBM_WRCREAT,
         0640);
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
    $self -> {dns_cache} -> {"$key;structure"} = freeze \@s;
    $self->flush_expired_ttls;
    untie (%{ $self -> {dns_cache} }) if tied %{ $self -> {dns_cache} };
    $lock->close();
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
    print STDERR "DEBUG: Storing lookup cache for [$key;lookup] (".(scalar @{$answer_hash->{$key}})." elements)\n";
    # Save the rdatastr values into the lookup cache
    $self->{dns_cache}->{"$key;lookup"} = freeze $answer_hash->{$key};
  }
  return [keys %{$answer_hash}];
}

# Called once prior to server shutdown
sub cleanup {
  my $self = shift;
  unlink "$self->{dbm_file}.LOCK";
  if ($self -> {fresh}) {
    # This should handle most kinds of db formats.
    unlink("$self->{dbm_file}",
           "$self->{dbm_file}.db",
           "$self->{dbm_file}.dir",
           "$self->{dbm_file}.pag");
  }
  return 1;
}

sub flush_expired_ttls {
  my $self = shift;
  my $now = time;
  return unless $now > $expiration_check;
  my ($next_expiration_check, $lookup, $cache);
  $next_expiration_check = undef;
  while (($lookup,$cache) = each %{ $self -> {dns_cache} }) {
    $cache = thaw $cache;
    next unless ref $cache eq "ARRAY";
    if ($lookup =~ /^(.+)\;lookup$/) {
      my $rr_string = $1;
      foreach my $entry (@$cache) {
        if (ref $entry eq "ARRAY") {
          my $expires = $entry->[0];
          if ($expires < $now) {
            # Contains a TTL in the past
            # so throw the whole thing out
            delete $self -> {dns_cache} -> {"$rr_string;lookup"};
            last;
          }
          if ($expires > $expiration_check &&
              (!$next_expiration_check ||
               $expires < $next_expiration_check)) {
            $next_expiration_check = $expires;
          }
        }
      }
    }
  }
  $expiration_check = $next_expiration_check || undef;
}

1;
__END__
=head1 NAME

Net::DNSServer::DBMCache - AnyDBM_File DNS Cache resolver

=head1 SYNOPSIS

  #!/usr/bin/perl -w -T
  use strict;
  use Net::DNSServer;
  use Net::DNSServer::DBMCache;

  my $resolver1 = new Net::DNSServer::DBMCache {
    dbm_file    => "/var/named/dns_cache.db",
    dbm_reorder => [qw(DB_File GDBM_File NDBM_File)],
    fresh       => 1,
  };
  my $resolver2 = ... another resolver object ...;
  run Net::DNSServer {
    priority => [$resolver1,$resolver2],
  };

=head1 DESCRIPTION

A Net::DNSServer::Base which uses AnyDBM_File
with locking to implement a DNS Cache on disk to
allow the cache to be shared across processes.
This is useful if the server forks (Net::Server::PreFork)
and to preserve memory by not having to
store large caches in memory.

This resolver will cache responses that
another module resolves complying with the
corresponding TTL of the response.
It cannot provide resolution for a request
unless it already exists within its cache.
This resolver is useful for servers that
may fork, because the cache is stored on
disk instead of in memory.

=head2 new

The new() method takes a hash ref of properties.

=head2 dbm_file (required)

dbm_file is the path to the database file to
use and/or create.
(Passed to the tie call.)

=head2 dbm_reorder (recommended)

This is used to set @AnyDBM_File::ISA before
running import and determines which order to
attempt to format the database with.

=head2 fresh (optional)

Whether or not to use a fresh cache at server startup.
0 means to reuse the dbm_file cache if one exists.
1 means to start fresh and to wipe the database
file at server startup and shutdown and restart.
It defaults to 0 meaning it will try to keep and
reuse the database file it creates.

=head2

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

L<AnyDBM_File>
L<Storable>
L<Net::Server::PreFork>

=head1 COPYRIGHT

Copyright (c) 2001, Rob Brown.  All rights reserved.
Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: DBMCache.pm,v 1.12 2002/06/07 22:55:08 rob Exp $

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
Question;answer
"netscape.com.	IN	A;answer"

Value:
[
 # TTL, VALUE
 [time + 100193, "netscape.com.	IN	A	207.200.89.225"],
 [time + 100193, "netscape.com.	IN	A	207.200.89.193"]
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
