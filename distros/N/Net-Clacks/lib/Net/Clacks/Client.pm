package Net::Clacks::Client;
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 30;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
#---AUTOPRAGMAEND---

use IO::Socket::IP;
#use IO::Socket::UNIX;
use Time::HiRes qw[sleep usleep];
use Sys::Hostname;
use IO::Select;
use IO::Socket::SSL;
use MIME::Base64;

sub new($class, $server, $port, $username, $password, $clientname, $iscaching = 0) {
    my $self = bless {}, $class;

    if(!defined($server) || !length($server)) {
        croak("server not defined!");
    }
    if(!defined($port) || !length($port)) {
        croak("port not defined!");
    }
    if(!defined($username) || !length($username)) {
        croak("username not defined!");
    }
    if(!defined($password) || !length($password)) {
        croak("password not defined!");
    }
    if(!defined($clientname) || !length($clientname)) {
        croak("clientname not defined!");
    }

    $self->{server} = $server;
    $self->{port} = $port;

    $self->init($username, $password, $clientname, $iscaching);

    return $self;
}

sub newSocket($class, $socketpath, $username, $password, $clientname, $iscaching = 0) {
    my $self = bless {}, $class;

    if(!defined($socketpath) || !length($socketpath)) {
        croak("socketpath not defined!");
    }
    if(!defined($username) || !length($username)) {
        croak("username not defined!");
    }
    if(!defined($password) || !length($password)) {
        croak("password not defined!");
    }
    if(!defined($clientname) || !length($clientname)) {
        croak("clientname not defined!");
    }

    my $udsloaded = 0;
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        require IO::Socket::UNIX;
        $udsloaded = 1;
    };
    if(!$udsloaded) {
        croak("Specified a unix domain socket, but i couldn't load IO::Socket::UNIX!");
    }

    $self->{socketpath} = $socketpath;

    $self->init($username, $password, $clientname, $iscaching);

    return $self;
}

sub init($self, $username, $password, $clientname, $iscaching) {
    if(!defined($username) || $username eq '') {
        croak("Username not defined!");
    }
    if(!defined($password) || $password eq '') {
        croak("Password not defined!");
    }

    if(!defined($clientname || $clientname eq '')) {
        croak("Clientname not defined!");
    }
    $self->{clientname} = $clientname;

    $self->{authtoken} = encode_base64($username, '') . ':' . encode_base64($password, '');

    if(!defined($iscaching)) {
        $iscaching = 0;
    }
    $self->{iscaching} = $iscaching;

    if($self->{iscaching}) {
        $self->{cache} = {};
    }

    $self->{needreconnect} = 1;
    $self->{inlines} = [];
    $self->{firstconnect} = 1;

    $self->{memcached_compatibility} = 0;

    $self->{remembrancenames} = [
        'Ivy Bdubs',
        'Terry Pratchett',
        'Sven Guckes',
        'Sheila', # faithful four-legged family member of @NightStorm_KPC
    ];
    $self->{remembranceinterval} = 3600; # One hour
    $self->{nextremembrance} = time + $self->{remembranceinterval};

    $self->reconnect();

    return;
}

sub reconnect($self) {
    if(defined($self->{socket})) {
        delete $self->{socket};
    }

    if(!$self->{firstconnect}) {
        # Not our first connection (=real reconnect).
        # wait a short random time before reconnecting. In case all
        # clients got disconnected, we want to avoid having all clients reconnect
        # at the exact same time
        my $waittime = rand(4000)/1000;
        sleep($waittime);
    }

    my $socket;
    if(defined($self->{server}) && defined($self->{port})) {
        $socket = IO::Socket::IP->new(
            PeerHost => $self->{server},
            PeerPort => $self->{port},
            Type => SOCK_STREAM,
        ) or croak("Failed to connect to Clacks TCP message service: $ERRNO");
    } elsif(defined($self->{socketpath})) {
        $socket = IO::Socket::UNIX->new(
            Peer => $self->{socketpath},
            Type => SOCK_STREAM,
        ) or croak("Failed to connect to Clacks Unix Domain Socket message service: $ERRNO");
    } else {
        croak("Neither TCP nor Unix domain socket specified. Don't know where to connect to.");
    }

    #binmode($socket, ':bytes');
    $socket->blocking(0);


    if(ref $socket ne 'IO::Socket::UNIX') {
        # ONLY USE SSL WHEN RUNNING OVER THE NETWORK
        # There is simply no point in running it over a local socket.
        IO::Socket::SSL->start_SSL($socket,
                                   SSL_verify_mode => SSL_VERIFY_NONE,
                                   ) or croak("Can't use SSL: " . $SSL_ERROR);
    }

    $self->{socket} = $socket;
    $self->{selector} = IO::Select->new($self->{socket});
    $self->{failcount} = 0;
    $self->{lastping} = time;
    $self->{inbuffer} = '';
    $self->{incharbuffer} = [];
    $self->{outbuffer} = '';
    $self->{serverinfo} = 'UNKNOWN';
    $self->{needreconnect} = 0;
    $self->{firstline} = 1;
    $self->{headertimeout} = time + 15;

    # Do *not* nuke "inlines" array, since it may hold "QUIT" messages that the client wants to handle, for example, to re-issue
    # "LISTEN" commands.
    # $self->{inlines} = ();

    if($self->{firstconnect}) {
        $self->{firstconnect} = 0;
    } else {
        push @{$self->{inlines}}, "RECONNECTED";
    }

    # Startup "handshake". As everything else, this is asyncronous, both server and
    # client send their respective version strings and then wait to recieve their counterparts
    # Also, this part is REQUIRED, just to make sure we actually speek to CLACKS protocol
    $self->{outbuffer} .= 'CLACKS ' . $self->{clientname} . "\r\n";
    $self->{outbuffer} .= 'OVERHEAD A ' . $self->{authtoken} . "\r\n";
    $self->doNetwork();

    return;
}

sub activate_memcached_compat($self) {
    $self->{memcached_compatibility} = 1;
    return;
}

sub getRawSocket($self) {
    if($self->{needreconnect}) {
        $self->reconnect();
    }

    return $self->{socket};
}

sub doNetwork($self, $readtimeout = 0) {
    if(!defined($readtimeout)) {
        # Don't wait
        $readtimeout = 0;
    }

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
        my $writeok = 0;
        my $written;
        eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            local $SIG{PIPE} = sub { $brokenpipe = 1; };
            $written = syswrite($self->{socket}, $self->{outbuffer});
            $writeok = 1;
        };

        if($brokenpipe || !$writeok) {
            $self->{needreconnect} = 1;
            push @{$self->{inlines}}, "TIMEOUT";
            return;
        }

        if(defined($written) && $written) {
            $workCount += $written;
            if(length($self->{outbuffer}) == $written) {
                $self->{outbuffer} = '';
            } else {
                $self->{outbuffer} = substr($self->{outbuffer}, $written);
            }
        }

    }

    {
        my $select = IO::Select->new($self->{socket});
        my @temp;
        eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            @temp = $self->{selector}->can_read($readtimeout);
        };
        if(scalar @temp == 0) {
            # Timeout
            return $workCount;
        }
    }

    my $totalread = 0;
    while(1) {
        my $buf;
        my $readok = 0;
        eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            sysread($self->{socket}, $buf, 10_000); # Read in at most 10kB at once
            $readok = 1;
        };
        if(!$readok) {
            $self->{needreconnect} = 1;
            push @{$self->{inlines}}, "TIMEOUT";
            return;
        }
        if(defined($buf) && length($buf)) {
            $totalread += length($buf);
            #print STDERR "+ $buf\n--\n";
            push @{$self->{incharbuffer}}, split//, $buf;
            next;
        }
        last;
    }
    
    # Check if we actually got data after checking with can_read() first
    if($totalread) {
        $self->{failcount} = 0;
    } else {
        # This should normally not happen, but thanks to SSL, it sometimes does
        # We ignore single instances of those but disconnect if many happen in a row
        $self->{failcount}++;
        sleep(0.05);
        
        if($self->{failcount} > 5) {
            $self->{needreconnect} = 1;
            return;
        }
    }
    while(@{$self->{incharbuffer}}) {
        my $char = shift @{$self->{incharbuffer}};
        $workCount++;
        if($char eq "\r") {
            next;
        } elsif($char eq "\n") {
            if($self->{inbuffer} eq 'NOP') { # Just drop "No OPerations" packets, only used by server to
                                             # verify that the connection is still active
                #$self->{firstline}
                $self->{inbuffer} = '';
                next;
            }

            if($self->{firstline}) {
                if($self->{inbuffer} !~ /^CLACKS\ /) {
                    # Whoops, not a clacks server or something gone wrong with the protocol
                    $self->{needreconnect} = 1;
                    return 0;
                } else {
                    $self->{firstline} = 0;
                }
            }

            push @{$self->{inlines}}, $self->{inbuffer};
            $self->{inbuffer} = '';
        } else {
            $self->{inbuffer} .= $char;
        }
    }

    if($self->{firstline} && $self->{headertimeout} < time) {
        $self->{needreconnect} = 1;
        return 0;
    }

    return $workCount;
}

my %overheadflags = (
    A => "auth_token", # Authentication token
    O => "auth_ok", # Authentication OK
    F => "auth_failed", # Authentication FAILED

    E => 'error_message', # Server to client error message

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

sub getNext($self) {
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
    } elsif($line =~ /^RECONNECTED/) {
        %data = (
            type => 'reconnected',
            data => 'send your LISTEN requests again',
        );
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
        } elsif($parsedflags{error_message}) {
            %data = (
                type => 'error_message',
                data => $value,
            );
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


sub ping($self) {
    if($self->{lastping} < (time - 120)) {
        # Only send a ping every 120 seconds or less
        $self->{outbuffer} .= "PING\r\n";
        $self->{lastping} = time;
    }

    return;
}

sub disablePing($self) {
    $self->{outbuffer} .= "NOPING\r\n";

    return;
}


sub notify($self, $varname) {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

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

sub set($self, $varname, $value, $forcesend = 0) { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }
    if(!defined($value)) {
        carp("value not defined!");
        return;
    }

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

sub listen($self, $varname) { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "LISTEN $varname\r\n";

    return;
}

sub unlisten($self, $varname) {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= "UNLISTEN $varname\r\n";

    return;
}

sub setMonitormode($self, $active) {
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

sub getServerinfo($self) {
    return $self->{serverinfo};
}

# ---------------- ClackCache handling --------------------
# ClacksCache handling always implies doNetwork()
# Also, we do NOT use the caching system used for SET
sub store($self, $varname, $value) {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }
    if(!defined($value)) {
        carp("value not defined!");
        return;
    }

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

sub retrieve($self, $varname) {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

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

sub remove($self, $varname) {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

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

sub increment($self, $varname, $stepsize = '') {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    if(!defined($stepsize) || $stepsize eq '') {
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

sub decrement($self, $varname, $stepsize = '') {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    if(!defined($stepsize) || $stepsize eq '') {
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

sub clearcache($self) {
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

sub keylist($self) {
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

sub clientlist($self) {
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

sub flush($self, $flushid = '') {
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


sub autohandle_messages($self) {
    $self->doNetwork();

    while((my $line = $self->getNext())) {
        if($line->{type} eq 'disconnect') {
            $self->{needreconnect} = 1;
        }
    }

    return;
}

# ---------------- ClackCache handling --------------------

sub sendRawCommand($self, $command) {
    if(!defined($command) || !length($command)) {
        carp("command not defined!");
        return;
    }

    if($self->{needreconnect}) {
        $self->reconnect;
    }

    $self->{outbuffer} .= $command . "\r\n";

    return;
}

# setAndStore combines the SET and STORE command into the SETANDSTORE server command. This is mostly done
# for optimizing interclacks connections
# Other clients will only get a SET notification, but the server also runs a STORE operation
sub setAndStore($self, $varname, $value, $forcesend = 0) {
    if(!defined($varname) || !length($varname)) {
        carp("varname not defined!");
        return;
    }

    if(!defined($value)) {
        carp("value not defined!");
        return;
    }

    if(!defined($forcesend)) {
        $forcesend = 0;
    }

    $self->{outbuffer} .= "SETANDSTORE $varname=$value\r\n";

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

sub disconnect($self) {
    if($self->{needreconnect}) {
        # We are not connected, just do nothing
        return;
    }

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
    $self->{needreconnect} = 1;

    return;
}

sub DESTROY($self) {
    # Try to disconnect cleanly, but socket might already be DESTROYed, so catch any errors
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        $self->disconnect();
    };

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

=head2 newSocket

Create a new instance, but use a Unix domain socket instead of tcp/ip

=head2 init

Internal function

=head2 reconnect

Reconnect to the CLACKS server when something went wrong.

=head2 getRawSocket

Returns the raw socket. You MUST NOT send or read data from because this will mess up the connection. Access to the raw
socket is only useful in speciality cases, like you want to wait on multiple Clacks sockets for incoming data using
IO::Select. In most cases, you wont need this.

=head2 doNetwork

Process incoming and outpoing messages. L<doNetwork> tries to send as much as possible. But due to network congestion it might not be able to send everything in one go and it will try not to hold up the caller for too long. Thats why it's important to call doNetwork from the cyclic loop of your programm at least every few seconds or so (depending on what you are trying to do).

doNetwork takes one optional argument, the timeout time to wait for incoming traffic. The default is not to wait at all.

=head2 flush

Send everything in the client out queue to the server and wait for a confirmation from the server it has recieved everything. This is a syncronous operation and will hold up the calling program.

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

=head2 store

STORE a value in clacks for later retrieval.

=head2 retrieve

RETRIEVE a values from clacks that has been stored earlier.

=head2 increment

INCREMENT a stored value by one. Takes an optional argument to say how much to increment.

=head2 decrement

DECREMENT a stored value by one. Takes an optional argument to say how much to decrement.

=head2 remove

REMOVE/DELETE a stored key from clacks

=head2 keylist

Get a list of all keys stored in clacks.

=head2 clearcache

Remove all keys stored in clacks.

=head2 setAndStore

Meta-function that both calls set() and store() internally with a single library call.
Useful in some circumstances when you both want to remember the variable and also 
tell everyone interested immediately that it has changed.

=head2 setMonitormode

Enable/Disable monitor mode. When enabled, the server sends all events it sees as DEBUG events (events LISTENed to also get send the normal way).

=head2 getServerinfo

Get server name and version.

=head2 getNext

Get the next incoming event in the queue.

=head2 clientlist

Get a list of all clients connected to the server. If the server is using interclacks (multiple servers in a pool), it will only list the clients connected to the server you are connected to.

=head2 sendRawCommand

Adds whatever you want to the out queue, to be send to the server. This is mostly useful when debugging and/or enhancing your server or if you want to implement a command line shell to your clacks server-

=head2 activate_memcached_compat

This activates a sort of memcached compatibility setup. Don't use this directly, it's an internal wonky
workaround. Use L<Net::Clacks::ClacksCache> instead.

=head2 autohandle_messages

This is also part of the internal memcached compatibility setup. Don't use this directly.

=head2 disconnect

Tries to send all remaining data in the output buffers and then disconnect cleanly from the server. Of course, if
the connection already has gone the way of the dodo, any chance of cleanly disconnecting has already passed.

=head2 DESTROY

This tries to close the connection cleanly but there is a good chance it wont succeed under certain circumstances,
especially on program exit. Use disconnect() before exiting your program for a better controlled behaviour.

=head1 IMPORTANT NOTE

Please make sure and read the documentations for L<Net::Clacks> as it contains important information
pertaining to upgrades and general changes!

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2024 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
