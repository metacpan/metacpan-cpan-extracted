package ParaDNS;

# This is the query class - it is really just an encapsulation of the
# hosts you want to query, plus the callback. All the hard work is done
# in ParaDNS::Resolver.

our $VERSION = '2.0';
our $TIMEOUT = $ENV{PARADNS_TIMEOUT} || 10;
our $REQUERY = $ENV{PARADNS_REQUERY} || 2;

use fields qw(
    client
    hosts
    num_hosts
    callback
    finished
    results
    start
    type
    nameservers
    );
use strict;

no warnings 'deprecated';

use ParaDNS::Resolver;
# note currently disabled as not everything works right
use constant XS_AVAILABLE => eval { require ParaDNS::XS; };
use constant NO_DNS => ($ENV{NODNS} || 0);

my %RESOLVER;

use constant TRACE_LEVEL => ($ENV{PARADNS_DEBUG} || 0);
use constant INTERNAL_CACHE => !($ENV{PARADNS_NO_CACHE} || 0);

use constant CACHE_CLEAN_INTERVAL => 60;

my %cache;
my $cache_cleanup;

sub trace {
    return unless TRACE_LEVEL;
    my $level = shift;
    print STDERR ("$ENV{PARADNS_DEBUG}/$level [$$] dns lookup: @_");
}

sub get_resolver {
    if (INTERNAL_CACHE) {
        $cache_cleanup ||= Danga::Socket->AddTimer(CACHE_CLEAN_INTERVAL, \&_cache_cleanup);
    }
    if (XS_AVAILABLE) {
        return 1 if $RESOLVER{$$};
        ParaDNS::XS::setup();
        $RESOLVER{$$} = 1;
    }
    else {
        my $servers = shift;
        $RESOLVER{$$} ||= ParaDNS::Resolver->new($servers);
    }
}

sub _cache_cleanup {
    my $now = time;
    
    foreach my $type (keys(%cache)) {
        my @to_delete;
        
        keys %{$cache{$type}}; # reset internal iterator
        for my $query (keys(%{$cache{$type}})) {
            REC:
            for my $rec (@{ $cache{$type}{$query} }) {
                my $t = $rec->{timeout};
                if ($t < $now) {
                    push @to_delete, $query;
                    last REC;
                }
            }
        }
        
        foreach my $q (@to_delete) {
            delete $cache{$type}{$q};
         }
     }

     $cache_cleanup = Danga::Socket->AddTimer(CACHE_CLEAN_INTERVAL, \&_cache_cleanup);
}

sub new {
    my ParaDNS $self = shift;
    my %options = ( type => "A", @_ );

    my $now = time;
    
    my $client = $options{client};
    $client->pause_read() if $client;
    
    $self = fields::new($self) unless ref $self;

    $self->{hosts} = $options{hosts} ? $options{hosts} : [ $options{host} ];
    $self->{nameservers} = $options{nameservers} ? $options{nameservers} : '';
    $self->{num_hosts} = scalar(@{$self->{hosts}}) || "No hosts supplied";
    $self->{client} = $client;
    $self->{callback} = $options{callback} || die "No callback given";
    $self->{finished} = $options{finished};
    $self->{results} = {};
    $self->{start} = $now;
    my $type = $self->{type} = $options{type};
    
    trace(2, "Nameservers set to: @{$self->{nameservers}}\n")
        if $self->{nameservers};

    if (NO_DNS) {
        $self->run_callback("NXDNS", $_) for @{ $self->{hosts} };
        return $self;
    }
    
    my $resolver = get_resolver($self->{nameservers});

    # check for cache hits
    for my $host (@{ $self->{hosts} }) {
        if (INTERNAL_CACHE &&
            exists($cache{$type}{$host}) &&
                   @{$cache{$type}{$host}} > 0 &&
                   $cache{$type}{$host}[0]{timeout} >= $now)
        {
            Danga::Socket->AddTimer(0, sub {
                $self->run_cache_callback($type, $host);
                    });
        }
        else {
            # not cached - do lookup
            if (XS_AVAILABLE) {
                my $callback = sub {
                    $self->run_xs_callback(@_);
                };
                my $id;
                if ($type eq "A" && $host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
                    $id = ParaDNS::XS::dnsquery("PTR", "$4.$3.$2.$1.in-addr.arpa", $callback);
                }
                else {
                    $id = ParaDNS::XS::dnsquery($type, $host, $callback);
                }
                if (!defined($id)) {
                    # lookup failed for some bizarre reason - should never happen
                    $client->continue_read() if $client;
                    return;
                }
            }
            else {
                $cache{$type}{$host} = [];
                if (!$resolver->query_type($self, $type, $host)) {
                    # lookup failed for some bizarre reason - should never happen
                    $client->continue_read() if $client;
                    return;
                }
            }
        }
    }

    return $self;
}

sub run_cache_callback {
    my ParaDNS $self = shift;
    my ($type, $host) = @_;
    for my $rec (@{ $cache{$type}{$host} }) {
        my $result = $rec->{value};
        my $ttl = $rec->{ttl};
        $self->{results}{$host} = $result;
        $ttl ||= 0;
        trace(2, "got cached $type $host => $result\n") if TRACE_LEVEL >= 2;
        $self->{callback}->($result, $host, $ttl);
    }
}

sub run_callback {
    my ParaDNS $self = shift;
    my ($result, $query, $ttl) = @_;
    $self->{results}{$query} = $result;
    if (INTERNAL_CACHE && defined($ttl)) {
        # store in cache
        push @{$cache{$self->{type}}{$query}}, 
            {
                timeout => time + $ttl,
                ttl => $ttl,
                value => $result,
            };
    }
    $ttl ||= 0;
    trace(2, "got $query => $result\n") if TRACE_LEVEL >= 2;
    $self->{callback}->($result, $query, $ttl);
}

my %type_to_host = (
    PTR   => 'dname',
    A     => 'address',
    AAAA  => 'address',
    TXT   => 'txtdata',
    NS    => 'dname',
    CNAME => 'dname',
);

sub run_xs_callback {
    my ParaDNS $self = shift;
    my $data = shift;
#warn("$$ run_xs_callback status: $data->{status} => $data->{error}\n");
    if ($data->{status} > 1) {
        if ($data->{questions}) {
#warn("$$ run_xs_callback $data->{error} with questions\n");
            for my $q (@{$data->{questions}}) {
                trace(2, "got $q->{question} => $data->{error}\n") if TRACE_LEVEL >= 2;
                $self->{results}{$q->{question}} = $data->{error};
                $self->{callback}->($data->{error}, $q->{question});
            }
        }
        else {
#warn("$$ run_xs_callback $data->{error} with no questions\n");
            for my $host (@{$self->{hosts}}) {
                next if exists $self->{results}{$host};
                trace(2, "got $host => $data->{error}\n") if TRACE_LEVEL >= 2;
                $self->{results}{$host} = $data->{error};
                $self->{callback}->($data->{error}, $host);
            }
        }
        return;
    }

    my $query = $data->{questions}[0]{question};
    if ($data->{questions}[0]{type} eq 'PTR') {
        $query =~ s/^(\d+)\.(\d+)\.(\d+)\.(\d+)\.in-addr\.arpa/$4.$3.$2.$1/;
    }
    for my $answer (@{$data->{answers}}) {
        my $result;
        if (my $param = $type_to_host{$answer->{type}}) {
            $result = $answer->{$param};
        }
        elsif ($answer->{type} eq "MX") {
            $result = [$answer->{exchange}, $answer->{preference}];
        }
        else {
            die "Unimplemented query type: $answer->{type}";
        }
        $self->run_callback($result, $query, $answer->{ttl});
    }
    if (!$self->{results}{$query}) {
        $self->{results}{$query} = 'NXDOMAIN';
        trace(2, "got $query => NXDOMAIN\n") if TRACE_LEVEL >= 2;
        $self->{callback}->("NXDOMAIN", $query);
    }
}

sub DESTROY {
    my ParaDNS $self = shift;
    my $now = time;
    my $num_hosts = @{$self->{hosts}};
    if ($num_hosts > keys(%{$self->{results}})) {
        # not enough results came back
            foreach my $host (@{$self->{hosts}}) {
                next if exists($self->{results}{$host});
                if ($host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
                    next if exists($self->{results}{"$4.$3.$2.$1.in-addr.arpa"});
                }
                print STDERR "DNS failure looking for $host after " . ($now - $self->{start}) . " secs (looked for $num_hosts, got " . keys(%{$self->{results}}) . ")\n";
                $self->{callback}->("NXDOMAIN", $host);
            }
    }
    $self->{client}->continue_read() if $self->{client};
    if ($self->{finished}) {
        $self->{finished}->();
    }
}

1;

=head1 NAME

ParaDNS - a DNS lookup class for the Danga::Socket framework

=head1 SYNOPSIS

  ParaDNS->new(
    callback => sub { print "Got result $_[0] for query $_[1]\n" },
    host     => 'google.com',
  );

=head1 DESCRIPTION

This module performs asynchronous DNS lookups, making use of a single UDP
socket (unlike Net::DNS's bgsend/bgread combination). It uses the Danga::Socket
framework for high performance.

Currently this module will only perform A or PTR lookups. A rDNS (PTR) lookup
will be performed if the host matches the regexp: C</^\d+\.\d+\.\d+.\d+$/>.

The lookups time out after 15 seconds.

=head1 API

=head2 C<< ParaDNS->new( %options ) >>

Create a new DNS query. You do not need to store the resulting object as this
class is all done with callbacks.

Example:

  ParaDNS->new(
    callback => sub { print "Got result: $_[0]\n" },
    host => 'google.com',
    );

=over 4

=item B<[required]> C<callback>

The callback to call when results come in. This should be a reference to a
subroutine. The callback receives three parameters - the result of the DNS lookup,
the host that was looked up, and the TTL (in seconds).

=item C<host>

A host name to lookup. Note that if the hostname is a dotted quad of numbers then
a reverse DNS (PTR) lookup is performend.

=item C<hosts>

An array-ref list of hosts to lookup.

B<NOTE:> One of either C<host> or C<hosts> is B<required>.

=item C<client>

It is possible to specify a client object which you wish to "pause" for reading
until your DNS result returns. The client will be issued the C<< ->pause_read >>
method when the query is issued, and the C<< ->continue_read >> method when the
query returns.

This is used in Qpsmtpd where we want to wait until the DNS query returns before
accepting more data from the client.

=item C<type>

You can specify one of: I<"A">, I<"AAAA">, I<"PTR">, I<"CNAME">, I<"NS"> or
I<"TXT"> here. Other types may be supported in the future. See C<%type_to_host>
in C<Resolver.pm> for details, though more complex queries (e.g. SRV) may
require a slightly more complex solution.

A PTR query is automatically issued if the host looks like an IP address.

=item C<nameservers>

Normally, this module uses the name servers that are default for your system.
You can specify an array-ref list of name servers to query. 

=back

=head1 Environment Variables

=head2 PARADNS_TIMEOUT

Default: 10

Number of seconds to wait for a query to come back.

=head2 PARADNS_REQUERY

Default: 2

Number of times to re-send a query when it times out.

=head2 PARADNS_NO_CACHE

Provides the ability to turn off the in-memory cache. Set to 1 to disable.

=head2 PARADNS_DEBUG

Provides internal debugging sent to STDERR. Set to 1 or higher to see more
debugging output.

=head1 Stand-alone Use

Normal usage of ParaDNS is within another application that already uses the
Danga::Socket framework. However if you wish to use this as a script to just
issue thousands of DNS queries then you need to do a little more work.
First, you need to set the SetPostLoopCallback, then issue the appropriate
ParaDNS->new() call with your queries, and then launch the Danga event
loop.

Eg:

    Danga::Socket->SetPostLoopCallback(
        sub {
            my $dmap = shift;
            for my $fd (keys %$dmap) {
                my $pob = $dmap->{$fd};
                if ($pob->isa('ParaDNS::Resolver')) {
                    return 1 if $pob->pending;
                }
            }
            return 0; # causes EventLoop to exit
        });

     # Call ParaDNS->new() with your parameters

     Danga::Socket->EventLoop();

=head1 LICENSE

This module is licensed under the same terms as perl itself.

=head1 AUTHOR

Matt Sergeant, <matt@sergeant.org>.

=cut
