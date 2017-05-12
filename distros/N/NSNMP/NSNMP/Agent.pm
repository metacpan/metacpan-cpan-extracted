use strict;
package NSNMP::Agent;
# Copyright (c) 2003-2004 AirWave Wireless, Inc.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:

#    1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
#    2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#    3. The name of the author may not be used to endorse or
#    promote products derived from this software without specific
#    prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
use NSNMP;
use POSIX;
use NSNMP::Mapper;

# on my 500MHz machine, it handled 2800 requests per second when it
# peremptorily returned an error message

# adding the ability to actually return values slowed the error
# messages to 2300 per second; returning messages with values in them
# was roughly as fast

# adding SNMP SET handling cut it down to 2200 messages per second or
# so.

# Adding community string handling cut it down to 2100 messages per
# second or so.

# Adding error handling and get-next handling cut it down to 2000
# get-requests or 1900 get-next requests per second.  On a very small
# dataset, though; it was down around 1300 for a slightly larger one.

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $self->{typemapper} = NSNMP::Mapper->new(%{$self->{types}});
  $self->{_values} = {
    map { NSNMP->encode_oid($_) => $self->{values}{$_} } keys %{$self->{values}}
  };
  $self->{_oids} = [sort keys %{$self->{_values}}]; # yay BER oids
  $self->{lastoid_idx} = 0;
  $self->{community} ||= 'public';
  return $self;
}

sub _noSuchName {
  my ($dr) = @_;
  return NSNMP->encode(
    request_id => $dr->request_id,
    error_status => NSNMP::noSuchName,
    error_index => 1, # XXX
    type => NSNMP::GET_RESPONSE,
    varbindlist => [$dr->varbindlist], # XXX?
  );
}

sub _badValue {
  my ($dr) = @_;
  return NSNMP->encode(
    request_id => $dr->request_id,
    error_status => NSNMP::badValue,
    error_index => 1, # XXX
    type => NSNMP::GET_RESPONSE,
    varbindlist => [$dr->varbindlist], # XXX??
  );
}

sub next_oid_after {
  my ($self, $oid) = @_;
  my $oids = $self->{_oids};
  my $lastindex = $self->{lastoid_idx};
  my $lastoid = $oids->[$lastindex];
  return $oids->[++$self->{lastoid_idx}] || NSNMP->encode_oid('.1.3')
    if $lastoid and $oid eq $lastoid;
  for my $ii (0..$#$oids) {
    if ($oids->[$ii] gt $oid) {
      $self->{lastoid_idx} = $ii;
      return $oids->[$ii];
    }
  }
  return NSNMP->encode_oid('.1.3');  # hope nobody tries to attach a value here
}

sub handle_get_request {
  my ($self, $dr, $reqtype) = @_;
  my @rvbl;
  for my $varbind ($dr->varbindlist) {
    my ($oid, $type, $value) = @{$varbind};
    $oid = $self->next_oid_after($oid) if $reqtype eq NSNMP::GET_NEXT_REQUEST;
    # XXX damn, I thought I could avoid decoding this OID:
    my ($otype, $instance) = $self->{typemapper}->map(NSNMP->decode_oid($oid));
    my $ovalue = $self->{_values}{$oid};
    return _noSuchName($dr) if not defined $otype or not defined $ovalue;
    push @rvbl, [$oid, $otype, $ovalue];
  }
  return NSNMP->encode(
    request_id => $dr->request_id,
    type => NSNMP::GET_RESPONSE,
    varbindlist => \@rvbl,
  );
}

sub handle_set_request {
  my ($self, $dr) = @_;
  for my $varbind ($dr->varbindlist) {
    my ($oid, $type, $value) = @{$varbind};
    my ($otype, $instance) = $self->{typemapper}->map(NSNMP->decode_oid($oid));
    my $ovalue = $self->{_values}{$oid};
    return _noSuchName($dr) if not defined $otype or not defined $ovalue;
    return _badValue($dr) if $type ne $otype;
    $self->{_values}{$oid} = $value;
  }
  return NSNMP->encode(
    request_id => $dr->request_id,
    type => NSNMP::GET_RESPONSE,
    varbindlist => [$dr->varbindlist],
  );
}

sub handle_request {
  my ($self, $request) = @_;
  my $dr = NSNMP->decode($request);
  return undef unless $dr and $dr->community eq $self->{community};
  my $type = $dr->type;
  return(($type eq NSNMP::SET_REQUEST) ? handle_set_request($self, $dr) :
	 handle_get_request($self, $dr, $type));
}

sub run {
  my ($self, $socket) = @_;
  my ($request, $requestor);
  for (;;) {
    if ($requestor = recv $socket, $request, 65536, 0) {
      my $response = $self->handle_request($request, $requestor);
      send $socket, $response, 0, $requestor if $response;
    } else {
      warn "Error on receive: $!";
    }
  }
}

# for testing purposes only
# non-testing would require specifying host and returning errors sensibly
sub spawn {
  my ($self, $port) = @_;
  # note we bind socket before forking, which has two advantages:
  # - packets never get lost because they got sent before the child
  #   binds the port
  # - errors kill the main process, not the child.
  my $listensocket = IO::Socket::INET->new(
    Proto => 'udp',
    LocalAddr => "127.0.0.1:$port",
    ReuseAddr => 1,
  );
  die "Can't bind port $port: $!" unless $listensocket;
  my $pid = fork();
  die "Can't fork: $!" if not defined $pid;
  if (not $pid) {
    $self->run($listensocket);
    POSIX::_exit(0);
  }
  $listensocket->close(); # in parent
  return $pid;
}

# temp_agent --- test utility function for reaping agents later
{
  my $port = 16165;
  my @pids;
  sub temp_agent {
    my ($self) = @_;
    $port++;
    my $pid = $self->spawn($port);
    push @pids, $pid;
    return "127.0.0.1:$port";
  }
  sub kill_temp_agents {
    for (@pids) { kill 9, $_; wait() }
    @pids = ();
  }
}

1;
