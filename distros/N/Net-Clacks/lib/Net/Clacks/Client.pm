package Net::Clacks::Client;
#---AUTOPRAGMASTART---
use 5.010_001;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp;
our $VERSION = 6.0;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use IO::Socket::IP;
use Time::HiRes qw[sleep usleep];
use Sys::Hostname;
use IO::Select;
use IO::Socket::SSL;
use MIME::Base64;

sub new {
    my ($class, $server, $port, , $username, $password, $clientname, $iscaching) = @_;
    my $self = bless {}, $class;

    $self->{server} = $server;
    $self->{port} = $port;

    if(!defined($username) || $username eq '') {
        croak("Username not defined!");
    }
    if(!defined($password) || $password eq '') {
        croak("Password not defined!");
    }

    if(!defined($clientname || $password eq '')) {
        croak("Clientname not defined!");
    }
    $self->{clientname} = $clientname;

    $self->{authtoken} = encode_base64($username, '') . ':' . encode_base64($password, '');

    if(!defined($iscaching)) {
        $iscaching = 0;
    }
    $self->{iscaching} = $iscaching;
    if($iscaching) {
        $self->{cache} = {};
    }

    $self->{needreconnect} = 1;
    $self->{inlines} = [];

    $self->{memcached_compatibility} = 0;

    $self->{remembrancenames} = [
        'Ivy Bdubs',
        'Terry Pratchett',
    ];
    $self->{remembranceinterval} = 3600; # One hour
    $self->{nextremembrance} = time + $self->{remembranceinterval};

    $self->reconnect();

    return $self;
}

sub reconnect {
    my ($self) = @_;

    if(defined($self->{socket})) {
        delete $self->{socket};
    }

    my $socket = IO::Socket::IP->new(
        PeerHost => $self->{server},
        PeerPort => $self->{port},
        Type => SOCK_STREAM,
    ) or croak("Failed to connect to Clacks message service: $ERRNO");

    #binmode($socket, ':bytes');
    $socket->blocking(0);

    IO::Socket::SSL->start_SSL($socket,
                               SSL_verify_mode => SSL_VERIFY_NONE,
                               ) or croak("Can't use SSL: " . $SSL_ERROR);

    $self->{socket} = $socket;
    $self->{lastping} = time;
    $self->{inbuffer} = '';
    $self->{incharbuffer} = [];
    $self->{outbuffer} = '';
    $self->{serverinfo} = 'UNKNOWN';
    $self->{needreconnect} = 0;

    # Do *not* nuke "inlines" array, since it may hold "QUIT" messages that the client wants to handle, for example, to re-issue
    # "LISTEN" commands.
    # $self->{inlines} = ();

    # Startup "handshake". As everything else, this is asyncronous, both server and
    # client send their respective version strings and then wait to recieve their counterparts
    # Also, this part is REQUIRED, just to make sure we actually speek to CLACKS protocol
    #
    # In this implementation, we wait until we recieve the server header. If we don't recieve it within
    # 20 seconds, we time out and fail.
    $self->{outbuffer} .= 'CLACKS ' . $self->{clientname} . "\r\n";
    $self->{outbuffer} .= 'OVERHEAD A ' . $self->{authtoken} . "\r\n";
    my $timeout = time + 20;

    return;
}

sub activate_memcached_compat {
    my ($self) = @_;

    $self->{memcached_compatibility} = 1;
    return;
}

sub doNetwork {
    my ($self, $readtimeout) = @_;

    if($self->{needreconnect}) {
        $self->reconnect();
    }

    if($self->{nextremembrance} && time > $self->{nextremembrance}) {
        # A person is not dead while their name is still spoken.
        $self->{nextremembrance} = time + $self->{remembranceinterval} + int(rand($self->{remembranceinterval} / 10));
        my $neverforget = $self->{remembrancenames}->[rand @{$self->{remembrancenames}}];
        $self->{outbuffer} .= 'OVERHEAD GNU ' . $neverforget . "\r\n";
    }

    # doNetwork interleaves handling incoming and outgoing traffic.
    # This is only relevant on slow links.
    #
    # It returns even if the outgoing or incoming buffers are not empty
    # (meaning that partially buffered data can exists). This way we use the
    # available bandwidth without blocking unduly the application (we assume it's a realtime
    # application with multiple things going on at the same time)-
    #
    # The downside of this is that doNetwork() needs to be called on a regular basis and sending
    # and recieving might be delayed until the next cycle. This delay can be minimized by simply
    # not transfering huge values over clacks, but instead using it the way it was intended to be used:
    # Small variables can be SET directly by clacks, huge datasets should be stored in the
    # database and the recievers only NOTIFY'd that a change has taken place.
    #
    # The big exception here is the here is the ClacksCache part of the story. These functions
    # call doNetwork() in a loop until the outbuffer is empty. And depending on requirement, they
    # KEEP on calling doNetwork() until the answer is recieved. This makes ClacksCache functions
    # syncronous and causes some delay in the calling function. But doing these asyncronous will
    # cause more headaches, maybe even leading up to insanity. Believe me, i tried, but those pink
    # elephants stomping about my rubber-padded room are such a distraction...

    my $workCount = 0;

    if(length($self->{outbuffer})) {
        my $brokenpipe = 0;
        local $SIG{PIPE} = sub { $brokenpipe = 1; };
        my $written = syswrite($self->{socket}, $self->{outbuffer});
        if(defined($written) && $written) {
            $workCount += $written;
            $self->{outbuffer} = substr($self->{outbuffer}, $written);
        }

        if($brokenpipe) {
            $self->{needreconnect} = 1;
            push @{$self->{inlines}}, "TIMEOUT";
            return;
        }
    }

    if(defined($readtimeout) && $readtimeout > 0) {
        my $select = IO::Select->new($self->{socket});
        my @temp = $select->can_read($readtimeout);
        if(scalar @temp == 0) {
            # Timeout
            return $workCount;
        }
    }

    while(1) {
        my $buf;
        sysread($self->{socket}, $buf, 10_000); # Read in at most 10kB at once
        if(defined($buf) && length($buf)) {
            #print STDERR "+ $buf\n--\n";
            push @{$self->{incharbuffer}}, split//, $buf;
            next;
        }
        last;
    }
    while(@{$self->{incharbuffer}}) {
        my $char = shift @{$self->{incharbuffer}};
        $workCount++;
        if($char eq "\r") {
            next;
        } elsif($char eq "\n") {
            if($self->{inbuffer} ne 'NOP') { # Just drop "No OPerations" packets, only used by server to
                                             # verify that the connection is still active
                #print STDERR "GOT ", $self->{inbuffer}, "\n";
                push @{$self->{inlines}}, $self->{inbuffer};
            }
            $self->{inbuffer} = '';
        } else {
            $self->{inbuffer} .= $char;
        }
    }

    return $workCount;
}

my %overheadflags = (
    A => "auth_token", # Authentication token
    O => "auth_ok", # Authentication OK
    F => "auth_failed", # Authentication FAILED

    C => "close_all_connections",
    D => "discard_message",
    G => "forward_message",
    I => "set_interclacks_mode", # value: true/false, disables 'G' and 'U'
    M => "informal_message", # informal message
    N => "no_logging",
    S => "shutdown_service", # value: positive number (number in seconds before shutdown). If interclacks clients are present, should be high
                             # enough to flush all buffers to them
    U => "return_to_sender",
    Z => "no_flags", # Only sent when no other flags are set
);

sub getNext {
    my ($self) = @_;

    # Recieve next incoming message (if any)

restartgetnext:
    my $line = shift @{$self->{inlines}};

    if(!defined($line)) {
        return;
    }

    my %data;
    #print STDERR "> $line\n";
    if($line =~ /^NOTIFY\ (.+)/) {
        %data = (
            type => 'notify',
            name => $1,
        );
    } elsif($line =~ /^SET\ (.+?)\=(.*)/) {
        %data = (
            type => 'set',
            name => $1,
            data => $2,
        );
    } elsif($line =~ /^CLACKS\ (.+)/) {
        %data = (
            type => 'serverinfo',
            data => $1,
        );
    } elsif($line =~ /^DEBUG\ (.+?)\=(.*)/) {
        %data = (
            type => 'debug',
            host => $1,
            command => $2,
        );
    } elsif($line =~ /^QUIT/) {
        %data = (
            type => 'disconnect',
            data => 'quit',
        );
        $self->{needreconnect} = 1;
    } elsif($line =~ /^TIMEOUT/) {
        %data = (
            type => 'disconnect',
            data => 'timeout',
        );
        $self->{needreconnect} = 1;
    } elsif($line =~ /^OVERHEAD\ (.+?)\ (.+)/) {
        # Minimal handling of OVERHEAD flags
        my ($flags, $value) = ($1, $2);
        my @flagparts = split//, $flags;
        my %parsedflags;
        foreach my $key (sort keys %overheadflags) {
            if(contains($key, \@flagparts)) {
                $parsedflags{$overheadflags{$key}} = 1;
            } else {
                $parsedflags{$overheadflags{$key}} = 0;
            }
        }

        if($parsedflags{auth_ok}) {
            #print STDERR "Clacks AUTH OK\n";
            goto restartgetnext; # try the next message
        } elsif($parsedflags{auth_failed}) {
            croak("Clacks Authentication failed!");
        } elsif($parsedflags{informal_message}) {
            if($parsedflags{forward_message}) {
                %data = (
                    type => 'informal',
                    data => $value,
                );
            }
            if($parsedflags{return_to_sender}) {
                my $uturn = 'OVERHEAD M';
                if($parsedflags{no_logging}) {
                    $uturn .= 'N';
                }
                $uturn .= ' ' . $value;
                $self->{outbuffer} .= $uturn;
            }
        }

    } else {
        # UNKNOWN, ignore
        goto restartgetnext; # try the next message
    }

    if(!defined($data{type})) {
        return;
    }

    $data{rawline} = $line;

    return \%data;
}


sub ping {
    my ($self) = @_;

    if($self->{lastping} < (time - 120)) {
        # Only send a ping every 120 seconds or less
        $self->{outbuffer} .= "PING\r\n";
        $self->{lastping} = time;
    }

    return;
}

sub disablePing {
    my ($self) = @_;

    $self->{outbuffer} .= "NOPING\r\n";

    return;
}


sub notify {
    my ($self, $varname) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "NOTIFY $varname\r\n";

    if($self->{memcached_compatibility}) {
        while(1) {
            $self->doNetwork();
            if($self->{needreconnect}) {
                # Nothing we can do, really...
                return;
            }
            last if(!length($self->{outbuffer}));
            usleep(1000);
        }
        $self->autohandle_messages();
    }

    return;
}

sub set { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    my ($self, $varname, $value, $forcesend) = @_;

    if(!defined($forcesend)) {
        $forcesend = 0;
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    # Handle caching to lower output volumne
    if($self->{iscaching} && !$forcesend && defined($self->{cache}->{$varname}) && $self->{cache}->{$varname} eq $value) {
        # Already the same value send
        return;
    }

    if($self->{iscaching}) {
        $self->{cache}->{$varname} = $value;
    }

    $self->{outbuffer} .= "SET $varname=$value\r\n";

    if($self->{memcached_compatibility}) {
        while(1) {
            $self->doNetwork();
            if($self->{needreconnect}) {
                # Nothing we can do, really...
                return;
            }
            last if(!length($self->{outbuffer}));
            usleep(1000);
        }

        $self->autohandle_messages();
    }

    return;
}

sub listen { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self, $varname) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "LISTEN $varname\r\n";

    return;
}

sub unlisten {
    my ($self, $varname) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "UNLISTEN $varname\r\n";

    return;
}

sub setMonitormode {
    my ($self, $active) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    if(!defined($active) || !$active) {
        $self->{outbuffer} .= "UNMONITOR\r\n";
    } else {
        $self->{outbuffer} .= "MONITOR\r\n";
    }

    return;
}

sub getServerinfo {
    my ($self) = @_;

    return $self->{serverinfo};
}

# ---------------- ClackCache handling --------------------
# ClacksCache handling always implies doNetwork()
# Also, we do NOT use the caching system used for SET
sub store {
    my ($self, $varname, $value) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "STORE $varname=$value\r\n";
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return;
}

sub retrieve {
    my ($self, $varname) = @_;

    my $value;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "RETRIEVE $varname\r\n";

    # Make sure we send everything
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
    }

    # Now, wait for the answer
    my $answerline;
    while(1) {
        $self->doNetwork(0.5);
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        for(my $i = 0; $i < scalar @{$self->{inlines}}; $i++) {
            if($self->{inlines}->[$i] =~ /^RETRIEVED\ $varname/ || $self->{inlines}->[$i] =~ /^NOTRETRIEVED\ $varname/) {
                # Remove the answer from in in-queue directly (out of sequence), because we don't need in in the getNext function
                $answerline = splice @{$self->{inlines}}, $i, 1;
                last;
            }
        }
        last if(defined($answerline));
    }

    if($answerline =~ /^RETRIEVED\ (.+?)\=(.*)/) {
        my ($key, $val) = ($1, $2);
        if($key ne $varname) {
            print STDERR "Retrieved clacks key $key does not match requested varname $varname!\n";
            return;
        }
        return $val;
    }

    # No matching key
    return;
}

sub remove {
    my ($self, $varname) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "REMOVE $varname\r\n";
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return;
}

sub increment {
    my ($self, $varname, $stepsize) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    if(!defined($stepsize)) {
        $self->{outbuffer} .= "INCREMENT $varname\r\n";
    } else {
        $stepsize = 0 + $stepsize;
        $self->{outbuffer} .= "INCREMENT $varname=$stepsize\r\n";
    }

    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return;
}

sub decrement {
    my ($self, $varname, $stepsize) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    if(!defined($stepsize)) {
        $self->{outbuffer} .= "DECREMENT $varname\r\n";
    } else {
        $stepsize = 0 + $stepsize;
        $self->{outbuffer} .= "DECREMENT $varname=$stepsize\r\n";
    }
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return;
}

sub clearcache {
    my ($self) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "CLEARCACHE\r\n";
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return;
}

sub keylist {
    my ($self) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    my $value;

    $self->{outbuffer} .= "KEYLIST\r\n";

    # Make sure we send everything
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    # Now, wait for the answer
    my $liststartfound = 0;
    my $listendfound = 0;
    while(1) {
        $self->doNetwork(0.5);
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        $liststartfound = 0;
        $listendfound = 0;
        for(my $i = 0; $i < scalar @{$self->{inlines}}; $i++) {
            if($self->{inlines}->[$i] =~ /^KEYLISTSTART/) {
                $liststartfound = 1;
                next;
            }
            next unless($liststartfound);
            if($self->{inlines}->[$i] =~ /^KEYLISTEND/) {
                $listendfound = 1;
                last;
            }
        }
        last if($listendfound);
    }

    # Now, grab the keys from inlines buffer
    my @keys;
    my $idx = 0;
    my $listfound = 0;
    while($idx < scalar @{$self->{inlines}}) {
        if($self->{inlines}->[$idx] =~ /^KEYLISTSTART/) {
            # Just remove this line
            splice @{$self->{inlines}}, $idx, 1;
            $listfound = 1;
            next;
        }

        if(!$listfound) {
            $idx++;
            next;
        }

        if($self->{inlines}->[$idx] =~ /^KEYLISTEND/) {
            # End of list
            last;
        }

        if($self->{inlines}->[$idx] =~ /^KEY\ (.+)/) {
            push @keys, $1;
            # Don't increment $idx, but the rest of the array one element down
            splice @{$self->{inlines}}, $idx, 1;
        } else {
            $idx++;
        }
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return @keys;
}

sub clientlist {
    my ($self) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    my $value;

    $self->{outbuffer} .= "CLIENTLIST\r\n";

    # Make sure we send everything
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
        usleep(1000);
    }

    # Now, wait for the answer
    my $liststartfound = 0;
    my $listendfound = 0;
    while(1) {
        $self->doNetwork(0.5);
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        $liststartfound = 0;
        $listendfound = 0;
        for(my $i = 0; $i < scalar @{$self->{inlines}}; $i++) {
            if($self->{inlines}->[$i] =~ /^CLIENTLISTSTART/) {
                $liststartfound = 1;
                next;
            }
            next unless($liststartfound);
            if($self->{inlines}->[$i] =~ /^CLIENTLISTEND/) {
                $listendfound = 1;
                last;
            }
        }
        last if($listendfound);
    }

    # Now, grab the keys from inlines buffer
    my @keys;
    my $idx = 0;
    my $listfound = 0;
    while($idx < scalar @{$self->{inlines}}) {
        if($self->{inlines}->[$idx] =~ /^CLIENTLISTSTART/) {
            # Just remove this line
            splice @{$self->{inlines}}, $idx, 1;
            $listfound = 1;
            next;
        }

        if(!$listfound) {
            $idx++;
            next;
        }

        if($self->{inlines}->[$idx] =~ /^CLIENTLISTEND/) {
            # End of list
            last;
        }

        if($self->{inlines}->[$idx] =~ /^CLIENT\ (.+)/) {
            my @parts = split/\;/, $1;
            my %data;
            foreach my $part (@parts) {
                my ($datakey, $datavalue) = split/\=/, $part, 2;
                #$datakey = lc $datakey;
                $data{lc $datakey} = $datavalue;
            }
            push @keys, \%data;
            # Don't increment $idx, but the rest of the array one element down
            splice @{$self->{inlines}}, $idx, 1;
        } else {
            $idx++;
        }
    }

    if($self->{memcached_compatibility}) {
        $self->autohandle_messages();
    }

    return @keys;
}

sub flush {
    my ($self, $flushid) = @_;

    if(!defined($flushid) || $flushid eq '') {
        $flushid = 'AUTO' . int(rand(1_000_000)) . int(rand(1_000_000));
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "FLUSH $flushid\r\n";

    # Make sure we send everything
    while(1) {
        $self->doNetwork();
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        last if(!length($self->{outbuffer}));
    }

    # Now, wait for the answer
    my $answerline;
    while(1) {
        $self->doNetwork(0.5);
        if($self->{needreconnect}) {
            # Nothing we can do, really...
            return;
        }
        for(my $i = 0; $i < scalar @{$self->{inlines}}; $i++) {
            if($self->{inlines}->[$i] =~ /^FLUSHED\ $flushid/) {
                # Remove the answer from in in-queue directly (out of sequence), because we don't need in in the getNext function
                $answerline = splice @{$self->{inlines}}, $i, 1;
                last;
            }
        }
        last if(defined($answerline));
    }

    return;
}


sub autohandle_messages {
    my ($self) = @_;

    $self->doNetwork();

    while((my $line = $self->getNext())) {
        if($line->{type} eq 'disconnect') {
            $self->{needreconnect} = 1;
        }
    }

    return;
}

# ---------------- ClackCache handling --------------------

sub sendRawCommand {
    my ($self, $command) = @_;

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= $command . "\r\n";

    return;
}

# Meta function that internally calls both SET and STORE
sub setAndStore {
    my ($self, $varname, $value, $forcesend) = @_;

    if(!defined($forcesend)) {
        $forcesend = 0;
    }

    $self->set($varname, $value, $forcesend);
    $self->store($varname, $value);
    return;
}


sub DESTROY {
    my ($self) = @_;

    # Notify server we are leaving and make sure we send everything in our outgoing buffer
    $self->flush();
    $self->{outbuffer} .= "QUIT\r\n";
    my $endtime = time + 1; # Wait a maximum of one second to send
    while(1) {
        last if(time > $endtime);
        $self->doNetwork();
        last if(!length($self->{outbuffer}));
        sleep(0.05);
    }
    sleep(0.5); # Wait another half second for the OS to flush the socket

    delete $self->{socket};

    return;
}

1;
__END__

=head1 NAME

Net::Clacks::Client - client for CLACKS interprocess messaging

=head1 SYNOPSIS

  use Net::Clacks::Client;


=head1 DESCRIPTION

This implements the client network protocol for the CLACKS interprocess messaging. This is
used a lot in PageCamel projects to let different processes (workers, webgui, PageCamelSVC) communicate
with each other

=head2 new

Create a new instance.

=head2 reconnect

Reconnect to the CLACKS server when something went wrong.

=head2 doNetwork

Process incoming and outpoing messages.

=head2 ping

Send a PING (keepalive) packet.

=head2 disablePing

Temporarly disable auto-disconnects by the server (NOPING command). Useful before doing something with indeterminate length (long running functions and such).

=head2 notify

NOTIFY other clients via CLACKS that an event happened.

=head2 set

SET a value for a CLACKS variable to other clients.

=head2 listen

LISTEN to specific NOTIFY and SET events.

=head2 unlisten

Stop listening to specific NOTIFY and SET events.

=head2 setMonitormode

Enable/Disable monitor mode. When enabled, the server sends all events it sees as DEBUG events (events LISTENed to also get send the normal way).

=head2 getServerinfo

Get server name and version.

=head2 getNext

Get the next incoming event in the queue.

=head2 setAndStore

Meta-function that both calls set() and store() internally with a single library call.
Useful in some circumstances when you both want to remember the variable and also 
tell everyone interested immediately that it has changed.

=head2 DESTROY

Automatically closes the connection.

=head1 IMPORTANT NOTE

Please make sure and read the documentations for L<Net::Clacks> as it contains important information
pertaining to upgrades and general changes!

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
