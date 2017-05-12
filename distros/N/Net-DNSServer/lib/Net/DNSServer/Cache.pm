package Net::DNSServer::Cache;

use strict;
use Exporter;
use vars qw(@ISA $expiration_check);
use Net::DNSServer::Base;
use Net::DNS;
use Net::DNS::RR;
use Net::DNS::Packet;
use Carp qw(croak);

@ISA = qw(Net::DNSServer::Base);
$expiration_check = undef;

# Created and passed to Net::DNSServer->run()
sub new {
  my $class = shift || __PACKAGE__;
  my $self  = shift || {};
  $self -> {dns_cache} ||= {};
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
  my $cache_structure = $self -> {dns_cache} -> {"$key;structure"} || undef;
  unless ($cache_structure &&
          (ref $cache_structure) eq "ARRAY" &&
          (scalar @$cache_structure) == 3) {
    print STDERR "DEBUG: Structure Cache miss on [$key]\n";
    return undef;
  }
  print STDERR "DEBUG: Structure Cache hit on [$key]\n";
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
    my $lookup = validate_ttl($self -> {dns_cache} -> {"$rr_string;lookup"});
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
  $self->flush_expired_ttls;
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
    my $expiration = $ttl + time;
    $answer_hash->{$key} ||= [];
    push @{$answer_hash->{$key}},
    [$expiration, $rdatastr];
    if (!$expiration_check ||
        $expiration < $expiration_check) {
      # Keep track of when the earliest entry will expire.
      $expiration_check = $expiration;
    }
  }
  foreach my $key (keys %{$answer_hash}) {
    print STDERR "DEBUG: Storing lookup cache for [$key;lookup] (".(scalar @{$answer_hash->{$key}})." elements)\n";
    # Save the rdatastr values into the lookup cache
    $self->{dns_cache}->{"$key;lookup"} = $answer_hash->{$key};
  }
  return [keys %{$answer_hash}];
}

sub flush_expired_ttls {
  my $self = shift;
  my $now = time;
  return unless $now > $expiration_check;
  my ($next_expiration_check, $lookup, $cache);
  $next_expiration_check = undef;
  while (($lookup,$cache) = each %{ $self -> {dns_cache} }) {
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

Net::DNSServer::Cache
- A Net::DNSServer::Base which implements
a DNS Cache in memory to increase
resolution speed and to follow rfcs.

=head1 SYNOPSIS

  #!/usr/bin/perl -w -T
  use strict;
  use Net::DNSServer;
  use Net::DNSServer::Cache;

  my $resolver1 = new Net::DNSServer::Cache;
  my $resolver2 = ... another resolver object ...;
  run Net::DNSServer {
    priority => [$resolver1,$resolver2],
  };

=head1 DESCRIPTION

This resolver will cache responses that
another module resolves complying with the
corresponding TTL of the response.
It cannot provide resolution for a request
unless it already exists within its cache.
Note: This resolver may not work properly
with a forking server.

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

L<Net::DNSServer::Base>

=head1 COPYRIGHT

Copyright (c) 2001, Rob Brown.  All rights reserved.
Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: Cache.pm,v 1.8 2002/04/29 09:29:49 rob Exp $

=cut
