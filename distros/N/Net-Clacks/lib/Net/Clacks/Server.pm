package Net::Clacks::Server;
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

use XML::Simple;
use Time::HiRes qw(sleep usleep time);
use Sys::Hostname;
use Errno;
use IO::Socket::IP;
use IO::Select;
use IO::Socket::SSL;
use YAML::Syck;
use MIME::Base64;
#use Data::Dumper;

# For turning off SSL session cache
use Readonly;
Readonly my $SSL_SESS_CACHE_OFF => 0x0000;

my %overheadflags = (
    A => "auth_token", # Authentication token
    O => "auth_ok", # Authentication OK
    F => "auth_failed", # Authentication FAILED

    C => "close_all_connections",
    D => "discard_message",
    G => "forward_message",
    I => "set_interclacks_mode", # value: true/false, disables 'G' and 'U'
    L => "lock_for_sync", # value: true/false, only available in interclacks client mode
    M => "informal_message", # informal message, no further operation on it
    N => "no_logging",
    S => "shutdown_service", # value: positive number (number in seconds before shutdown). If interclacks clients are present, should be high
                             # enough to flush all buffers to them
    U => "return_to_sender",
    Z => "no_flags", # Only sent when no other flags are set
);

sub new {
    my ($class, $isDebugging, $configfile) = @_;

    croak("Config file $configfile not found!") unless(-f $configfile);

    my $self = bless {}, $class;

    $self->{isDebugging} = $isDebugging;
    $self->{configfile} = $configfile;

    return $self;
}

sub init {
    my ($self) = @_;

    print "Loading config file ", $self->{configfile}, "\n";
    my $config = XMLin($self->{configfile},
                        ForceArray => [ 'ip' ],);

    my $hname = hostname;

    # Copy hostname-specific stuff to root if it exists
    if(defined($config->{hosts}->{$hname})) {
        foreach my $key (keys %{$config->{hosts}->{$hname}}) {
            $config->{$key} = $config->{hosts}->{$hname}->{$key};
        }
    }

    $self->{config} = $config;

    if(!defined($self->{config}->{throttle}->{maxsleep})) {
        $self->{config}->{throttle}->{maxsleep} = 5000;
    }
    if(!defined($self->{config}->{throttle}->{step})) {
        $self->{config}->{throttle}->{step} = 1;
    }

    $self->{usleep} = 0;

    if(!defined($self->{config}->{ssl}) ||
            !defined($self->{config}->{ssl}->{cert}) ||
            !defined($self->{config}->{ssl}->{key})) {
        croak("Missing or incomplete SSL config!");
    }
    if(!-f $self->{config}->{ssl}->{cert}) {
        croak("SSL cert file " . $self->{config}->{ssl}->{cert} . " not found!");
    }
    if(!-f $self->{config}->{ssl}->{key}) {
        croak("SSL key file " . $self->{config}->{ssl}->{key} . " not found!");
    }

    if(!defined($self->{config}->{username})) {
        croak("Username not defined!");
    }
    if(!defined($self->{config}->{password})) {
        croak("Password not defined!");
    }
    $self->{authtoken} = encode_base64($self->{config}->{username}, '') . ':' . encode_base64($self->{config}->{password}, '');

    if(defined($self->{config}->{persistancefile})) {
        $self->{persistance} = 1;
    } else {
        $self->{persistance} = 0;
    }

    my @tcpsockets;

    foreach my $ip (@{$config->{ip}}) {
        my $tcp = IO::Socket::IP->new(
            LocalHost => $ip,
            LocalPort => $config->{port},
            Listen => 1,
            Blocking => 0,
            ReuseAddr => 1,
            Proto => 'tcp',
        ) or croak($ERRNO);
        #binmode($tcp, ':bytes');
        push @tcpsockets, $tcp;
        print "Listening on $ip:18888/tcp\n";
    }

    $self->{tcpsockets} = \@tcpsockets;


    print "Ready.\n";


    return;
}

sub run { ## no critic (Subroutines::ProhibitExcessComplexity)
    my ($self) = @_;

    # Let STDOUT/STDERR settle down first
    sleep(0.1);

    # Need to ignore SIGPIPE, this can screw us over in certain circumstances
    # while writing to the network. We can only detect certain types of disconnects
    # after writing to the socket, but we will get a SIGPIPE if we try. So we just
    # ignore the signal and carry on as usual...
    $SIG{PIPE} = 'IGNORE';

    my @toremove;
    my @outbox;
    my %clients;

    my %clackscache;
    my %clackscachetime;
    my $shutdowntime;
    my $selector = IO::Select->new();
    my $interclackslock = 0;

    my $keepRunning = 1;
    $SIG{INT} = sub { $keepRunning = 0; };
    $SIG{TERM} = sub { $keepRunning = 0; };

    # Restore persistance file if required
    if($self->{persistance} && -f $self->{config}->{persistancefile}) {
        if(open(my $ifh, '<', $self->{config}->{persistancefile})) {
            my $line = <$ifh>;
            my $timestampline = <$ifh>;
            close $ifh;
            chomp $line;
            $line = decode_base64($line);
            $line = Load($line);
            %clackscache = %{$line};

            # Mark all data as current
            my $now = time;
            foreach my $key (keys %clackscache) {
                $clackscachetime{$key} = $now;
            }
            
            # Do we have timestamp data? (need to check for upgrade compatibility
            if(defined($timestampline) && length($timestampline) > 5) {
                chomp $timestampline;
                $timestampline = decode_base64($timestampline);
                $timestampline = Load($timestampline);
                my %clackstemp = %{$timestampline};
                foreach my $key (keys %clackscache) {
                    if(defined($clackstemp{$key})) {
                        $clackscachetime{$key} = $clackstemp{$key};
                    }
                }
            }

        }
    }

    while($keepRunning) {
        my $workCount = 0;
        my $savecache = 0;
        my $lastsavecache = 0;

        # Check for shutdown time
        if($shutdowntime && $shutdowntime < time) {
            print STDERR "Shutdown time has arrived!\n";
            $keepRunning = 0;
        }

        if(defined($self->{config}->{master})) {
            # We are in client mode. We need to add an interclacks link
            my $mcid = $self->{config}->{master}->{ip}->[0] . ':' . $self->{config}->{master}->{port};
            if(!defined($clients{$mcid})) {
                print "Connect to master\n";
                my $msocket = IO::Socket::IP->new(
                    PeerHost => $self->{config}->{master}->{ip}->[0],
                    PeerPort => $self->{config}->{master}->{port},
                    Type => SOCK_STREAM,
                    Timeout => 5,
                );
                if(!defined($msocket)) {
                    print STDERR "Can't connect to MASTER via interclacks!\n";
                } else {
                    print "connected to master\n";

                    my $encrypted = IO::Socket::SSL->start_SSL($msocket,
                                                               SSL_verify_mode => SSL_VERIFY_NONE,
                    );
                    if(!$encrypted) {
                        print "startSSL failed: ", $SSL_ERROR, "\n";
                        next;
                    }

                    $msocket->blocking(0);
                    #binmode($msocket, ':bytes');
                    my %tmp = (
                        buffer  => '',
                        charbuffer => [],
                        listening => {},
                        socket => $msocket,
                        lastping => time,
                        mirror => 0,
                        outbuffer => "CLACKS PageCamel $VERSION in interclacks client mode\r\n" .  # Tell the server we are using PageCamel Interclacks...
                                     "OVERHEAD A " . $self->{authtoken} . "\r\n" .              # ...send Auth token
                                     "OVERHEAD I 1\r\n",                                        # ...and turn interclacks master mode ON on remote side
                        clientinfo => 'Interclacks link',
                        host => $self->{config}->{master}->{ip}->[0],
                        port => $self->{config}->{master}->{port},
                        interclacks => 1,
                        interclacksclient => 1,
                        lastinterclacksping => time,
                        lastmessage => time,
                        authok => 0,
                    );
                    $clients{$mcid} = \%tmp;
                    $selector->add($msocket);

                    $workCount++;
                }
            }
        }

        foreach my $tcpsocket (@{$self->{tcpsockets}}) {
            my $clientsocket = $tcpsocket->accept;
            if(defined($clientsocket)) {
                my ($chost, $cport) = ($clientsocket->peerhost, $clientsocket->peerport);
                my $cid = "$chost:$cport";
                print "Got a new client $chost:$cport!\n";
                foreach my $debugcid (keys %clients) {
                    if($clients{$debugcid}->{mirror}) {
                        $clients{$debugcid}->{outbuffer} .= "DEBUG CONNECTED=" . $cid . "\r\n";
                    }
                }

                my $encrypted = IO::Socket::SSL->start_SSL($clientsocket,
                                                           SSL_server => 1,
                                                           SSL_cert_file => $self->{config}->{ssl}->{cert},
                                                           SSL_key_file => $self->{config}->{ssl}->{key},
                                                           SSL_cipher_list => 'ALL:!ADH:!RC4:+HIGH:+MEDIUM:!LOW:!SSLv2:!SSLv3!EXPORT',
                                                           SSL_create_ctx_callback => sub {
                                                                my $ctx = shift;

                                                                # Enable workarounds for broken clients
                                                                Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL); ## no critic (Subroutines::ProhibitAmpersandSigils)

                                                                # Disable session resumption completely
                                                                Net::SSLeay::CTX_set_session_cache_mode($ctx, $SSL_SESS_CACHE_OFF);

                                                                # Disable session tickets
                                                                Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_NO_TICKET); ## no critic (Subroutines::ProhibitAmpersandSigils)
                                                            },
                );
                if(!$encrypted) {
                    print "startSSL failed: ", $SSL_ERROR, "\n";
                    next;
                }

                $clientsocket->blocking(0);
                #binmode($clientsocket, ':bytes');
                #$clientsocket->{clacks_cid} = $cid;
                my %tmp = (
                    buffer  => '',
                    charbuffer => [],
                    listening => {},
                    socket => $clientsocket,
                    lastping => time,
                    mirror => 0,
                    outbuffer => "CLACKS PageCamel $VERSION\r\n" .
                                 "OVERHEAD M Authentication required\r\n",  # Informal message
                    clientinfo => 'UNKNOWN',
                    host => $chost,
                    port => $cport,
                    interclacks => 0,
                    interclacksclient => 0,
                    lastinterclacksping => 0,
                    lastmessage => time,
                    authok => 0,
                );
                if(0 && $self->{isDebugging}) {
                    $tmp{authok} = 1;
                    $tmp{outbuffer} .= "OVERHEAD M debugmode_auth_not_really_required\r\n"
                }
                $clients{$cid} = \%tmp;
                $selector->add($clientsocket);
                $workCount++;
            }
        }

        # Check if there are any clients to disconnect...

        my $pingtime = time - $self->{config}->{pingtimeout};
        my $interclackspingtime = time - $self->{config}->{interclackspingtimeout};
        my $interclackspinginterval = time - int($self->{config}->{interclackspingtimeout} / 3);
        foreach my $cid (keys %clients) {
            if(!$clients{$cid}->{socket}->connected) {
                push @toremove, $cid;
                next;
            }
            if(!$clients{$cid}->{interclacks}) {
                if($clients{$cid}->{lastping} > 0 && $clients{$cid}->{lastping} < $pingtime) {
                    syswrite($clients{$cid}->{socket}, "\r\nTIMEOUT\r\n");
                    push @toremove, $cid;
                }
            } else {
                if($clients{$cid}->{lastping} < $interclackspingtime) {
                    syswrite($clients{$cid}->{socket}, "\r\nTIMEOUT\r\n");
                    push @toremove, $cid;
                }
            }

            if($clients{$cid}->{interclacks} && $clients{$cid}->{lastinterclacksping} < $interclackspinginterval) {
                $clients{$cid}->{lastinterclacksping} = time;
                $clients{$cid}->{outbuffer} .= "PING\r\n";
            }
        }

        # ...and disconnect them
        while((my $cid = shift @toremove)) {
            # In some circumstances, there may be multiple @toremove entries for the same client. Ignore them...
            if(defined($clients{$cid})) {
                print "Removing client $cid\n";
                foreach my $debugcid (keys %clients) {
                    if($clients{$debugcid}->{mirror}) {
                        $clients{$debugcid}->{outbuffer} .= "DEBUG DISCONNECTED=" . $cid . "\r\n";
                    }
                }

                if($clients{$cid}->{interclacksclient} && $interclackslock) {
                    print "...this is one is interclacks master and has us locked - UNLOCKING mid-sync!\n";
                    $interclackslock = 0;
                }

                $selector->remove($clients{$cid}->{socket});
                delete $clients{$cid};
            }

            $workCount++;
        }

        if(!(scalar keys %clients)) {
            # No clients to handle, let's sleep and try again later
            sleep(0.2);
            next;
        }


        my $hasoutbufferwork = 0;
        foreach my $cid (keys %clients) {
            if(length($clients{$cid}->{buffer}) > 0) {
                # Found some work to do
                $hasoutbufferwork = 1;
                last;
            }
        }
        my $selecttimeout = 0.5; # Half a second
        if($hasoutbufferwork) {
            $selecttimeout = 0.01;
        }

        my @inclients = $selector->can_read($selecttimeout);
        foreach my $clientsocket (@inclients) {
            my ($chost, $cport) = ($clientsocket->peerhost, $clientsocket->peerport);
            my $cid = "$chost:$cport";

            while(1) {
                my $rawbuffer;
                sysread($clients{$cid}->{socket}, $rawbuffer, 10_000); # Read at most 10kB at a time
                if(defined($rawbuffer) && length($rawbuffer)) {
                    push @{$clients{$cid}->{charbuffer}}, split//, $rawbuffer;
                    next;
                }
                last;
            }
        }

        foreach my $cid (keys %clients) {
            if($interclackslock && !$clients{$cid}->{interclacksclient}) {
                # We are locked into interclacks sync lock, but this is not the connection to master,
                # so we don't handle the inputr buffer for this client at the moment.
                next;
            }

            while(@{$clients{$cid}->{charbuffer}}) {
                my $buf = shift @{$clients{$cid}->{charbuffer}};

                $workCount++;
                if($buf eq "\r") {
                    next;
                } elsif($buf eq "\n") {
                    next if($clients{$cid}->{buffer} eq ''); # Empty lines

                    #print "<", $clients{$cid}->{buffer}, "\n";

                    # Handle CLACKS identification header
                    if($clients{$cid}->{buffer} =~ /^CLACKS\ (.+)/) {
                        $clients{$cid}->{clientinfo} = $1;
                        $clients{$cid}->{clientinfo} =~ s/\;/\_/g;
                        print "Client at ", $clients{$cid}->{host}, ':', $clients{$cid}->{port}, " identified as ", $clients{$cid}->{clientinfo}, "\n";
                        $clients{$cid}->{buffer} = '';
                        next;
                    }

                    my $nodebug = 0;
                    my $sendinterclacks = 1;
                    my $discardafterlogging = 0;
                    # Handle OVERHEAD messages before logging (for handling 'N' flag correctly)
                    if($clients{$cid}->{buffer} =~ /^OVERHEAD\ (.+?)\ (.+)/) {
                        my ($flags, $value) = ($1, $2);
                        $sendinterclacks = 0;
                        my @flagparts = split//, $flags;
                        my %parsedflags;
                        my %newflags;
                        foreach my $key (sort keys %overheadflags) {
                            if(contains($key, \@flagparts)) {
                                $parsedflags{$overheadflags{$key}} = 1;
                                $newflags{$overheadflags{$key}} = 1;
                            } else {
                                $parsedflags{$overheadflags{$key}} = 0;
                                $newflags{$overheadflags{$key}} = 0;
                            }
                        }

                        if($parsedflags{auth_token}) {
                            if($value eq $self->{authtoken}) {
                                $clients{$cid}->{authok} = 1;
                                $clients{$cid}->{outbuffer} .= "OVERHEAD O Welcome!\r\n";
                            } else {
                                $clients{$cid}->{authok} = 0;
                                $clients{$cid}->{outbuffer} .= "OVERHEAD F Login failed!\r\n";
                            }
                        }

                        # Ignore other command when not authenticated
                        if(!$clients{$cid}->{authok}) {
                            $clients{$cid}->{buffer} = '';
                            next;
                        }

                        if($parsedflags{lock_for_sync} && $clients{$cid}->{interclacksclient}) {
                            if($value) {
                                print "Interclacks sync lock ON.\n";
                                $interclackslock = 1;
                                
                                # Send server our keys to the server
                                foreach my $ckey (sort keys %clackscache) {
                                    $clients{$cid}->{outbuffer} .= "KEYSYNC " . $clackscachetime{$ckey} . " U $ckey=" . $clackscache{$ckey} . "\r\n";
                                }
                                foreach my $ckey (sort keys %clackscachetime) {
                                    next if(defined($clackscache{$ckey}));
                                    $clients{$cid}->{outbuffer} .= "KEYSYNC " . $clackscachetime{$ckey} . " D $ckey=REMOVED\r\n";
                                }

                            } else {
                                print "Interclacks sync lock OFF.\n";
                                $interclackslock = 0;
                            }
                            $parsedflags{forward_message} = 0; # Don't forward
                            $newflags{return_to_sender} = 0; # Don't return to sender
                        }

                        if($parsedflags{close_all_connections} && $value) {
                            foreach my $closecid (keys %clients) {
                                if($clients{$closecid}->{interclacks} && $parsedflags{forward_message}) {
                                    syswrite($clients{$closecid}->{socket}, "\r\nOVERHEAD GC 1\r\n");
                                }
                                syswrite($clients{$closecid}->{socket}, "\r\nQUIT\r\n");
                                push @toremove, $closecid;
                            }
                            $parsedflags{forward_message} = 0; # Already forwarded where needed
                        }

                        if($parsedflags{shutdown_service}) {
                            $value = 0 + $value;
                            if($value > 0) {
                                $shutdowntime = $value + time;
                                print STDERR "Shutting down in $value seconds\n";
                            }
                        }
                        if($parsedflags{discard_message}) {
                            $discardafterlogging = 1;
                        }
                        if($parsedflags{no_logging}) {
                            $nodebug = 1;
                        }
                        if($parsedflags{set_interclacks_mode}) {
                            $newflags{forward_message} = 0;
                            $newflags{return_to_sender} = 0;

                            if($value) {
                                $clients{$cid}->{interclacks} = 1;
                                $clients{$cid}->{lastping} = time;


                                $clients{$cid}->{outbuffer} .= "CLACKS PageCamel $VERSION in interclacks master mode\r\n" .  # Tell client we are in interclacks master mode
                                                               "OVERHEAD M Authentication required\r\n" .                 # Informal message
                                                               "OVERHEAD A " . $self->{authtoken} . "\r\n" .              # ...and send Auth token...
                                                               "OVERHEAD L 1\r\n";                                            # ...and lock client for sync

                                # Make sure our new interclacks client has an *exact* copy of our buffer
                                #$clients{$cid}->{outbuffer} .= "CLEARCACHE\r\n";
                                foreach my $ckey (sort keys %clackscache) {
                                    $clients{$cid}->{outbuffer} .= "KEYSYNC " . $clackscachetime{$ckey} . " U $ckey=" . $clackscache{$ckey} . "\r\n";
                                }
                                foreach my $ckey (sort keys %clackscachetime) {
                                    next if(defined($clackscache{$ckey}));
                                    $clients{$cid}->{outbuffer} .= "KEYSYNC " . $clackscachetime{$ckey} . " D $ckey=REMOVED\r\n";
                                }
                                $clients{$cid}->{outbuffer} .= "OVERHEAD L 0\r\n"; # unlock client after sync
                                $clients{$cid}->{outbuffer} .= "PING\r\n";
                                $clients{$cid}->{lastinterclacksping} = time;
                            } else {
                                $clients{$cid}->{interclacks} = 0;
                                $clients{$cid}->{lastping} = time;
                            }
                        }

                        my $newflagstring = '';
                        $newflags{return_to_sender} = 0;

                        foreach my $key (sort keys %overheadflags) {
                            next if($key eq 'Z');
                            if($newflags{$overheadflags{$key}}) {
                                $newflagstring .= $key;
                            }
                        }
                        if($newflagstring eq '') {
                            $newflagstring = 'Z';
                        }

                        if($parsedflags{forward_message}) {
                            foreach my $overheadcid (keys %clients) {
                                next if($cid eq $overheadcid && !$parsedflags{return_to_sender});

                                $clients{$overheadcid}->{outbuffer} .= "OVERHEAD $newflagstring $value\r\n";
                            }
                        }
                    }

                    # Ignore other command when not authenticated
                    if(!$clients{$cid}->{authok}) {
                        $clients{$cid}->{buffer} = '';
                        next;
                    }

                    if(!$nodebug) {
                        # Add ALL incoming messages as debug-type messages to the outbox
                        my %tmp = (
                            sender => $cid,
                            type => 'DEBUG',
                            data => $clients{$cid}->{buffer},
                        );

                        push @outbox, \%tmp;
                    }

                    if($discardafterlogging) {
                        $clients{$cid}->{buffer} = '';
                        next;
                    }


                    if($clients{$cid}->{buffer} =~ /^OVERHEAD\ /) {
                        # Already handled
                    } elsif($clients{$cid}->{buffer} =~ /^LISTEN\ (.*)/) {
                        $clients{$cid}->{listening}->{$1} = 1;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^UNLISTEN\ (.*)/) {
                        delete $clients{$cid}->{listening}->{$1};
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^MONITOR/) {
                        $clients{$cid}->{mirror} = 1;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^UNMONITOR/) {
                        $clients{$cid}->{mirror} = 0;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^QUIT/) {
                        push @toremove, $cid;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^TIMEOUT/ && $clients{$cid}->{interclacks}) {
                        print STDERR "Ooops, didn't send timely PINGS through interclacks link!\n";
                        push @toremove, $cid;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^PING/) {
                        $clients{$cid}->{lastping} = time;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^NOPING/) {
                        # Disable PING check until next PING recieved
                        $clients{$cid}->{lastping} = 0;
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^NOTIFY\ (.*)/) {
                        my %tmp = (
                            sender => $cid,
                            type => 'NOTIFY',
                            name => $1,
                        );
                        push @outbox, \%tmp;
                    } elsif($clients{$cid}->{buffer} =~ /^SET\ (.+?)\=(.*)/) {
                        my %tmp = (
                            sender => $cid,
                            type => 'SET',
                            name => $1,
                            value => $2,
                        );
                        push @outbox, \%tmp;
                    } elsif($clients{$cid}->{buffer} =~ /^KEYSYNC\ (.+?)\ (.+?)\ (.+?)\=(.*)/) {
                        print $clients{$cid}->{buffer}, "\n";
                        my ($ctimestamp, $cmode, $ckey, $cval) = ($1, $2, $3, $4);

                        if(!defined($clackscachetime{$ckey})) {
                            $clackscachetime{$ckey} = 0;
                        }
                        if($cmode eq "U") { # "Update"
                            if($ctimestamp > $clackscachetime{$ckey}) {
                                $clackscache{$ckey} = $cval;
                                $clackscachetime{$ckey} = $ctimestamp;
                            }
                        } else { # REMOVE request from server
                            if($ctimestamp > $clackscachetime{$ckey}) {
                                delete $clackscache{$ckey};
                                $clackscachetime{$ckey} = $ctimestamp;
                            } else { # check if we have a value that happened after deletion at the server end
                                if(!defined($clackscache{$ckey})) {
                                    delete $clackscache{$ckey};
                                    $clackscachetime{$ckey} = $ctimestamp;
                                }
                            }
                        }

                        $savecache = 1;
                        $sendinterclacks = 1;
                    } elsif($clients{$cid}->{buffer} =~ /^STORE\ (.+?)\=(.*)/) {
                        $clackscache{$1} = $2;
                        $clackscachetime{$1} = time;
                        $savecache = 1;
                    } elsif($clients{$cid}->{buffer} =~ /^RETRIEVE\ (.+)/) {
                        #$clients{$cid}->{outbuffer} .= "SET ". $line->{name} . "=" . $line->{value} . "\r\n";
                        my $ckey = $1;
                        if(defined($clackscache{$ckey})) {
                            $clients{$cid}->{outbuffer} .= "RETRIEVED $ckey=" . $clackscache{$ckey} . "\r\n";
                        } else {
                            $clients{$cid}->{outbuffer} .= "NOTRETRIEVED $ckey\r\n";
                        }
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^REMOVE\ (.+)/) {
                        my $ckey = $1;
                        if(defined($clackscache{$ckey})) {
                            delete $clackscache{$ckey};
                            $clackscachetime{$ckey} = time;
                        }
                        $savecache = 1;
                    } elsif($clients{$cid}->{buffer} =~ /^INCREMENT\ (.+)/) {
                        my $ckey = $1;
                        my $cval = 1;
                        if($ckey =~ /(.+)\=(.+)/) {
                            ($ckey, $cval) = ($1, $2);
                            $cval = 0 + $cval;
                        }
                        if(defined($clackscache{$ckey})) {
                            $clackscache{$ckey} += $cval;
                        } else {
                            $clackscache{$ckey} = $cval;
                        }
                        $clackscachetime{$ckey} = time;
                        $savecache = 1;
                    } elsif($clients{$cid}->{buffer} =~ /^DECREMENT\ (.+)/) {
                        my $ckey = $1;
                        my $cval = 1;
                        if($ckey =~ /(.+)\=(.+)/) {
                            ($ckey, $cval) = ($1, $2);
                            $cval = 0 + $cval;
                        }
                        if(defined($clackscache{$ckey})) {
                            $clackscache{$ckey} -= $cval;
                        } else {
                            $clackscache{$ckey} = 0 - $cval;
                        }
                        $clackscachetime{$ckey} = time;
                        $savecache = 1;
                    } elsif($clients{$cid}->{buffer} =~ /^KEYLIST/) {
                        $clients{$cid}->{outbuffer} .= "KEYLISTSTART\r\n";
                        foreach my $ckey (sort keys %clackscache) {
                            $clients{$cid}->{outbuffer} .= "KEY $ckey\r\n";
                        }
                        $clients{$cid}->{outbuffer} .= "KEYLISTEND\r\n";
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^CLEARCACHE/) {
                        %clackscache = ();
                        %clackscachetime = ();
                        $savecache = 1;

                    # local managment commands
                    } elsif($clients{$cid}->{buffer} =~ /^CLIENTLIST/) {
                        $clients{$cid}->{outbuffer} .= "CLIENTLISTSTART\r\n";
                        foreach my $lmccid (sort keys %clients) {
                            $clients{$cid}->{outbuffer} .= "CLIENT CID=$lmccid;" .
                                                                "HOST=" . $clients{$lmccid}->{host} . ";" .
                                                                "PORT=" . $clients{$lmccid}->{port} . ";" .
                                                                "CLIENTINFO=" . $clients{$lmccid}->{clientinfo} . ";" .
                                                                "OUTBUFFER_LENGTH=" . length($clients{$lmccid}->{outbuffer}) . ";" .
                                                                "INBUFFER_LENGTH=" . length($clients{$lmccid}->{buffer}) . ";" .
                                                                "INTERCLACKS=" . $clients{$lmccid}->{interclacks} . ";" .
                                                                "MONITOR=" . $clients{$lmccid}->{mirror} . ";" .
                                                                "LASTPING=" . $clients{$lmccid}->{lastping} . ";" .
                                                                "LASTINTERCLACKSPING=" . $clients{$lmccid}->{lastinterclacksping} . ";" .
                                                                "\r\n";
                        }
                        $clients{$cid}->{outbuffer} .= "CLIENTLISTEND\r\n";
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^CLIENTDISCONNECT\ (.+)/) {
                        my $lmccid = $1;
                        if(defined($clients{$lmccid})) {
                            # Try to notify the client (may or may not work);
                            syswrite($clients{$lmccid}->{socket}, "\r\nQUIT\r\n");
                            push @toremove, $lmccid;
                        }
                        $sendinterclacks = 0;
                    } elsif($clients{$cid}->{buffer} =~ /^FLUSH\ (.+)/) {
                        my $retid = $1;
                        $clients{$cid}->{outbuffer} .= "FLUSHED $retid\r\n";
                        $sendinterclacks = 0;
                    } else {
                        print STDERR "ERROR Unknown_command ", $clients{$cid}->{buffer}, "\r\n";
                        $sendinterclacks = 0;
                    }

                    # forward interclacks messages
                    if($sendinterclacks) {
                        foreach my $interclackscid (keys %clients) {
                            if($cid eq $interclackscid || !$clients{$interclackscid}->{interclacks}) {
                                next;
                            }
                            $clients{$interclackscid}->{outbuffer} .= $clients{$cid}->{buffer} . "\r\n";
                        }
                    }


                    $clients{$cid}->{buffer} = '';
                } else {
                    $clients{$cid}->{buffer} .= $buf;
                }
            }

        }

        # clean up very old "deleted" entries
        my $stillvalidtime = time - (7 * 24 * 60 * 60); # 1 week
        foreach my $key (keys %clackscachetime) {
            next if($clackscachetime{$key} > $stillvalidtime);
            next if(defined($clackscache{$key})); # Still has data
            delete $clackscachetime{$key};
            $savecache = 1;
        }


        while((my $line = shift @outbox)) {
            $workCount++;
            foreach my $cid (keys %clients) {
                if($line->{type} eq 'DEBUG' && $clients{$cid}->{mirror}) {
                    $clients{$cid}->{outbuffer} .= "DEBUG " . $line->{sender} . "=". $line->{data} . "\r\n";
                }

                if($cid eq $line->{sender}) {
                    next;
                }

                if($line->{type} ne 'DEBUG' && defined($clients{$cid}->{listening}->{$line->{name}})) {
                    # Just buffer in the clients outbuffers
                    if($line->{type} eq 'NOTIFY') {
                        $clients{$cid}->{outbuffer} .= "NOTIFY ". $line->{name} . "\r\n";
                    } elsif($line->{type} eq 'SET') {
                        $clients{$cid}->{outbuffer} .= "SET ". $line->{name} . "=" . $line->{value} . "\r\n";
                    } elsif($line->{type} eq 'STORE' && $clients{$cid}->{interclacks}) {
                        $clients{$cid}->{outbuffer} .= "STORE ". $line->{name} . "=" . $line->{value} . "\r\n";
                    } elsif($line->{type} eq 'REMOVE' && $clients{$cid}->{interclacks}) {
                        $clients{$cid}->{outbuffer} .= "REMOVE ". $line->{name} . "\r\n";
                    }
                }
            }
        }

        # Send as much as possible
        foreach my $cid (keys %clients) {
            #if(!$clients{$cid}->{socket}->connected) {
            #    print "Client disconnected: $ERRNO\n";
            #    push @toremove, $cid;
            #    next;
            #}

            if(length($clients{$cid}->{outbuffer})) {
                $clients{$cid}->{lastmessage} = time;
            } elsif(($clients{$cid}->{lastmessage} + 60) < time) {
                $clients{$cid}->{lastmessage} = time;
                $clients{$cid}->{outbuffer} .= "NOP\r\n"; # send "No OPerations" command, just to
                                                          # check if socket is still open
            }

            next if(!length($clients{$cid}->{outbuffer}));

            # Output bandwidth-limited stuff, in as big chunks as possible
            my $written;
            $workCount++;
            eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
                $written = syswrite($clients{$cid}->{socket}, $clients{$cid}->{outbuffer});
            };
            if($EVAL_ERROR) {
                print STDERR "Write error: $EVAL_ERROR\n";
                push @toremove, $cid;
                next;
            }
            if(!$clients{$cid}->{socket}->opened || $clients{$cid}->{socket}->error || ($ERRNO ne '' && !$ERRNO{EWOULDBLOCK})) {
                print STDERR "webPrint write failure: $ERRNO\n";
                push @toremove, $cid;
                next;
            }

            if(defined($written) && $written) {
                #my $whatwaswritten = substr($clients{$cid}->{outbuffer}, 0, $written);
                #print STDERR "> $whatwaswritten\n--\n";
                $clients{$cid}->{outbuffer} = substr($clients{$cid}->{outbuffer}, $written);
            }
        }

        if($savecache && time > ($lastsavecache + 10)) { # only every 10 seconds
            $savecache = 0;
            $lastsavecache = time;
            if($self->{persistance}) {
                my $line = Dump(\%clackscache);
                $line = encode_base64($line, '');
                my $timestampline = Dump(\%clackscachetime);
                $timestampline = encode_base64($timestampline, '');

                if(open(my $ofh, '>', $self->{config}->{persistancefile})) {
                    print $ofh $line, "\n";
                    print $ofh $timestampline, "\n";
                    close $ofh;
                }
            }
        }

        if($workCount) {
            $self->{usleep} = 0;
        } elsif($self->{usleep} < $self->{config}->{throttle}->{maxsleep}) {
            $self->{usleep} += $self->{config}->{throttle}->{step};
        }
        usleep($self->{usleep});
    }

    print "Shutting down...\n";
    sleep(0.5);
    foreach my $cid (keys %clients) {
        print "Removing client $cid\n";
        # Try to notify the client (may or may not work);
        syswrite($clients{$cid}->{socket}, "\r\nQUIT\r\n");

        delete $clients{$cid};
    }
    print "All clients removed\n";


    return;
}

sub deref {
    my ($self, $val) = @_;

    return if(!defined($val));

    while(ref($val) eq "SCALAR" || ref($val) eq "REF") {
        $val = ${$val};
        last if(!defined($val));
    }

    return $val;
}

1;
__END__

=head1 NAME

Net::Clacks::Server - server for CLACKS interprocess messaging

=head1 SYNOPSIS

  use Net::Clacks::Server;



=head1 DESCRIPTION

This implements the server for the CLACKS interprocess messaging protocol. It supports Interclacks mode,
for a master/client server architecture.

=head2 new

Create a new instance.

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
