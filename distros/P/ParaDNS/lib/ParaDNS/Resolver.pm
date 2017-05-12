package ParaDNS::Resolver;
use base qw(Danga::Socket);

use fields qw(res dst queries);

use Net::DNS;
use Socket;
use strict;

no warnings 'deprecated';

use constant TRACE_LEVEL => ($ENV{PARADNS_DEBUG} || 0);
use constant NO_DNS0x20 => ($ENV{NO_DNS0x20} || 0);
*trace = \&ParaDNS::trace;

sub new {
    my ParaDNS::Resolver $self = shift;
    my $servers = shift;
    
    $self = fields::new($self) unless ref $self;
    
    my $res = Net::DNS::Resolver->new;
    
    my $sock = IO::Socket::INET->new(       
            Proto => 'udp',
            LocalAddr => $res->{'srcaddr'},
            LocalPort => ($res->{'srcport'} || undef),
    ) || die "Cannot create socket: $!";
    IO::Handle::blocking($sock, 0);
    
    $self->{dst} = [];
    
    if ($servers) {
        foreach my $ns (@{$servers}) {
            my ($s, $p) = split(/:/, $ns);
            $p = 53 if !$p;
            my $dst_sockaddr = sockaddr_in($p, inet_aton($s));
            push @{$self->{dst}}, $dst_sockaddr;
            trace(2, "Using override nameserver $s:$p\n");
        }
    } 
    else {
        foreach my $ns (@{ $res->{nameservers} }) {
            trace(2, "Using nameserver $ns:$res->{port}\n");
            my $dst_sockaddr = sockaddr_in($res->{'port'}, inet_aton($ns));
            push @{$self->{dst}}, $dst_sockaddr;
        }
    }
 
    $self->{res} = $res;
    
    # copied from SpamAssassin (I think all are irrelevant, but just in case...)
    $self->{res}->retry(1);           # If it fails, it fails
    $self->{res}->retrans(0);         # If it fails, it fails
    $self->{res}->dnsrch(0);          # ignore domain search-list
    $self->{res}->defnames(0);        # don't append stuff to end of query
    # I think these values are irrelevant...
    $self->{res}->tcp_timeout($ParaDNS::TIMEOUT);     # timeout
    $self->{res}->udp_timeout($ParaDNS::TIMEOUT);     # timeout
    $self->{res}->persistent_tcp(0);  # bug 3997
    $self->{res}->persistent_udp(0);  # bug 3997
    
    $self->{queries} = {};
    
    $self->SUPER::new($sock);
    
    Danga::Socket->AddTimer(1, sub { $self->_do_cleanup });
    
    $self->watch_read(1);
    
    return $self;
}

sub ns {
    my ParaDNS::Resolver $self = shift;
    my $index = shift;
    return if $index > $#{$self->{dst}};
    return $self->{dst}->[$index];
}

sub pending {
    my ParaDNS::Resolver $self = shift;
    
    return keys(%{$self->{queries}});
}

# implements draft-vixie-dnsext-dns0x20-00
sub dnsext_dns0x20 {
  my ($string) = @_;
  my $rnd;
  my $have_rnd_bits = 0;
  my $result = '';
  for my $ic (unpack("C*",$string)) {
    if (chr($ic) =~ /^[A-Za-z]\z/) {
      if ($have_rnd_bits < 1) {
        $rnd = rand(0x7fffffff);  $have_rnd_bits = 31;
      }
      $ic ^= 0x20  if $rnd & 1;  # flip the 0x20 bit in name if dice says so
      $rnd = $rnd >> 1;  $have_rnd_bits--;
    }
    $result .= chr($ic);
  }
  return $result;
}

sub _query {
    my ParaDNS::Resolver $self = shift;
    my ($asker, $host, $type, $now) = @_;
    
    $host = dnsext_dns0x20($host) unless NO_DNS0x20;
    
    my $packet = $self->{res}->make_query_packet($host, $type);
    
    my $id = $packet->header->id;
    while ($self->{queries}->{$id}) {
        # ID already in use, try again :-(
        trace(2, "Query ID $id already in use. Trying another\n") if TRACE_LEVEL >= 2;
        $packet = $self->{res}->make_query_packet($host, $type);
        $id = $packet->header->id;
    }
    my $packet_data = $packet->data;
    
    my $query = ParaDNS::Resolver::Query->new(
        $self, $asker, $host, $type, $now, $id, $packet_data,
        ) or return;
    $self->{queries}->{$id} = $query;
    
    return 1;
}

sub query_type {
    my ParaDNS::Resolver $self = shift;
    my ($asker, $type, @hosts) = @_;
    
    my $now = time();
    
    trace(2, "Trying to resolve $type: @hosts\n") if TRACE_LEVEL >= 2;

    foreach my $host (@hosts) {
        $self->_query($asker, $host, $type, $now) || return;
    }
    
    return 1;
}

sub query_txt {
    my ParaDNS::Resolver $self = shift;
    my ($asker, @hosts) = @_;
    return $self->query_type($asker, "TXT", @hosts);
}

sub query_mx {
    my ParaDNS::Resolver $self = shift;
    my ($asker, @hosts) = @_;
    return $self->query_type($asker, "MX", @hosts);
}

sub query {
    my ParaDNS::Resolver $self = shift;
    my ($asker, @hosts) = @_;
    
    my $now = time();
    
    trace(2, "trying to resolve A/PTR: @hosts\n") if TRACE_LEVEL >= 2;

    foreach my $host (@hosts) {
        $self->_query($asker, $host, 'A', $now) || return;
    }
    
    return 1;
}

sub _do_cleanup {
    my ParaDNS::Resolver $self = shift;
    my $now = time;
    
    my $idle = $ParaDNS::TIMEOUT;
    
    my $t0 = $now - $idle;
    
    my @to_delete;
    keys %{$self->{queries}}; # reset internal iterator
    while (my ($id, $obj) = each(%{$self->{queries}})) {
        if ($obj->{timeout} < $t0) {
            push @to_delete, $id;
        }
    }
    
    foreach my $id (@to_delete) {
        my $query = delete $self->{queries}{$id};
        $query->timeout() and next;
        # add back in if timeout caused us to loop to next server
        $self->{queries}->{$id} = $query;
    }

    $self->AddTimer(1, sub { $self->_do_cleanup } );
}

# ParaDNS
sub event_err { shift->close("dns socket error") }
sub event_hup { shift->close("dns socket error") }

my %type_to_host = (
    PTR   => 'ptrdname',
    A     => 'address',
    AAAA  => 'address',
    TXT   => 'txtdata',
    NS    => 'nsdname',
    CNAME => 'cname',
);

sub event_read {
    my ParaDNS::Resolver $self = shift;

    my $sock = $self->sock;
    my $res = $self->{res};
    
    while (my $packet = $res->bgread($sock)) {
        my $err = $res->errorstring;
        my $answers = 0;
        my $header = $packet->header;
        my $id = $header->id;
        
        my $qobj = delete $self->{queries}->{$id};
        if (!$qobj) {
            trace(1, "No query for id: $id\n") if TRACE_LEVEL;
            return;
        }
        
        my $query = $qobj->{host};
        
        my ($question) = $packet->question; # only ever send one question
        if (!$question) {
            trace(1, "No question for id: $id. Should be: $query\n") if TRACE_LEVEL;
            return;
        }
        
        if ($question->qtype eq 'A' && $question->qname ne $query) {
            trace(1, "Query mismatch for id: $id. $query ne " . $question->qname . "\n") if TRACE_LEVEL;
            return;
        }
        
        my $now = time();
        foreach my $rr ($packet->answer) {
            if (my $host_method = $type_to_host{$rr->type}) {
                my $host = $rr->$host_method;
                trace(2, "Answer: " . $rr->type . " $host\n") if TRACE_LEVEL;
                if ($rr->type eq 'CNAME' && $qobj->recurse_cname) {
                    # TODO: Should probably loop over the other answers here to check
                    # for an answer to the question we're just about to ask...
                    # (on the other hand, this works)
                    
                    my $packet = $res->make_query_packet($host, $qobj->type);

                    my $packet_data = $packet->data;
                    my $id = $packet->header->id;

                    my $query = ParaDNS::Resolver::Query->new(
                        $self, $qobj->asker, $host, $qobj->type, time, $id, $packet_data,
                        ) or next;
                    $self->{queries}->{$id} = $query;
                    next;
                }
                #my $type = $rr->type;
                #$type = 'A' if $type eq 'PTR';
                # print "DNS Lookup $type $query = $host; TTL = ", $rr->ttl, "\n";
                $qobj->run_callback($host, $rr->ttl);
            }
            elsif ($rr->type eq "MX") {
                my $host = $rr->exchange;
                my $preference = $rr->preference;
                $qobj->run_callback([$host, $preference], $rr->ttl);
            }
            else {
                # came back, but not a PTR or A record
                $qobj->run_callback("UNKNOWN");
            }
            $answers++;
        }
        if (!$answers) {
            if ($err eq "NXDOMAIN") {
                # trace("found => NXDOMAIN\n");
                $qobj->run_callback("NXDOMAIN");
            }
            elsif ($err eq "SERVFAIL") {
                # try again???
                # print "SERVFAIL looking for $query\n";
                #$self->query($asker, $query);
                $qobj->error($err) and next;
                # add back in if error() resulted in query being re-issued
                $self->{queries}->{$id} = $qobj;
            }
            elsif ($err eq "NOERROR") {
                $qobj->run_callback($err);
            }
            elsif($err) {
                #print("Unknown error: $err\n");
                $qobj->error($err) and next;
                $self->{queries}->{$id} = $qobj;
            }
            else {
                # trace("no answers\n");
                $qobj->run_callback("NOANSWER");
            }
        }
    }
}

use Carp qw(confess);

sub close {
    my ParaDNS::Resolver $self = shift;
    
    $self->SUPER::close(shift);
    # confess "ParaDNS::Resolver socket should never be closed!";
}

package ParaDNS::Resolver::Query;

use fields qw( resolver asker host type timeout id data repeat ns nqueries );

use constant MAX_QUERIES => 10;

use constant TRACE_LEVEL => ($ENV{PARADNS_DEBUG} || 0);
*trace = \&ParaDNS::trace;

sub new {
    my ParaDNS::Resolver::Query $self = shift;
    $self = fields::new($self) unless ref $self;
    
    @$self{qw( resolver asker host type timeout id data )} = @_;
    # repeat is number of retries
    @$self{qw( repeat ns nqueries )} = ($ParaDNS::REQUERY,0,0);
    
    trace(2, "NS Query: $self->{host} ($self->{id})\n") if TRACE_LEVEL >= 2;
    
    $self->send_query || return;
    
    return $self;
}

sub type {
    my ParaDNS::Resolver::Query $self = shift;
    $self->{type};
}

sub asker {
    my ParaDNS::Resolver::Query $self = shift;
    $self->{asker};
}

sub recurse_cname {
    my ParaDNS::Resolver::Query $self = shift;
    
    if ($self->{type} eq 'A' || $self->{type} eq 'AAAA') {
        if ($self->{nqueries} <= MAX_QUERIES) {
            return 1;
        }
    }

    return 0;
}

#sub DESTROY {
#    my $self = shift;
#    trace(2, "DESTROY $self\n");
#}

sub timeout {
    my ParaDNS::Resolver::Query $self = shift;
    
    trace(2, "NS Query timeout. Trying next host\n") if TRACE_LEVEL >= 2;
    if ($self->send_query) {
        # had another NS to send to, reset timeout
        $self->{timeout} = time();
        return;
    }
    
    # can we loop/repeat?
    if (($self->{nqueries} <= MAX_QUERIES) &&
        ($self->{repeat} > 1))
    {
        trace(2, "NS Query timeout. Next host failed. Trying loop\n") if TRACE_LEVEL >= 2;
        $self->{repeat}--;
        $self->{ns} = 0;
        return $self->timeout();
    }
    
    trace(2, "NS Query timeout. All failed. Running callback(TIMEOUT)\n") if TRACE_LEVEL >= 2;
    # otherwise we really must timeout.
    $self->run_callback("TIMEOUT");
    return 1;
}

sub error {
    my ParaDNS::Resolver::Query $self = shift;
    my ($error) = @_;
    
    trace(2, "NS Query error. Trying next host\n") if TRACE_LEVEL >= 2;
    if ($self->send_query) {
        # had another NS to send to, reset timeout
        $self->{timeout} = time();
        return;
    }
    
    # can we loop/repeat?
    if (($self->{nqueries} <= MAX_QUERIES) &&
        ($self->{repeat} > 1))
    {
        trace(2, "NS Query error. Next host failed. Trying loop\n") if TRACE_LEVEL >= 2;
        $self->{repeat}--;
        $self->{ns} = 0;
        return $self->error($error);
    }
    
    trace(2, "NS Query error. All failed. Running callback($error)\n") if TRACE_LEVEL >= 2;
    # otherwise we really must timeout.
    $self->run_callback($error);
    return 1;
}

sub run_callback {
    my ParaDNS::Resolver::Query $self = shift;
    trace(2, "NS Query callback($self->{host} = $_[0]\n") if TRACE_LEVEL >= 2;
    $self->{asker}->run_callback($_[0], lc($self->{host}), $_[1]);
}

sub send_query {
    my ParaDNS::Resolver::Query $self = shift;
    
    my $res = $self->{resolver};
    my $dst = $res->ns($self->{ns}++);
    return unless defined $dst;
    if (!$res->sock->send($self->{data}, 0, $dst)) {
        warn("socket send failed: $!");
        return;
    }
    
    $self->{nqueries}++;
    return 1;
}

1;

=head1 NAME

ParaDNS::Resolver - an asynchronous DNS resolver class

=head1 SYNOPSIS

  my $res = ParaDNS::Resolver->new();
  
  $res->query($obj, @hosts); # $obj implements $obj->run_callback()

=head1 DESCRIPTION

This is a low level DNS resolver class that works within the Danga::Socket
asynchronous I/O framework. Do not attempt to use this class standalone - use
the C<ParaDNS> class instead.

=cut
