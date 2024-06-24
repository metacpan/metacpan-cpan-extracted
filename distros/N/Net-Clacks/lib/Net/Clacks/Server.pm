package Net::Clacks::Server;
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 29;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
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
use File::Copy;
use Scalar::Util qw(looks_like_number);

# For turning off SSL session cache
use Readonly;
Readonly my $SSL_SESS_CACHE_OFF => 0x0000;

my %overheadflags = (
    A => "auth_token", # Authentication token
    O => "auth_ok", # Authentication OK
    F => "auth_failed", # Authentication FAILED

    E => 'error_message', # Server to client error message

    C => "close_all_connections",
    D => "discard_message",
    G => "forward_message",
    I => "set_interclacks_mode", # value: true/false, disables 'G' and 'U'
    L => "lock_for_sync", # value: true/false, only available in interclacks client mode
    M => "informal_message", # informal message, no further operation on it
    N => "no_logging",
    S => "shutdown_service", # value: positive number (number in seconds before shutdown). If interclacks clients are present, should be high
                             # enough to flush all buffers to them

    T => 'timestamp',        # Used before KEYSYNC to compensate for time drift between different systems
    U => "return_to_sender",
    Z => "no_flags", # Only sent when no other flags are set
);

BEGIN {
    {
        # We need to add some extra function to IO::Socket::SSL so we can track the client ID
        # on both TCP and Unix Domain Sockets
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{"IO::Socket::SSL::_setClientID"} = sub {
            my ($self, $cid) = @_;
    
            ${*$self}{'__client_id'} = $cid; ## no critic (References::ProhibitDoubleSigils)
            return;
        };
        
        *{"IO::Socket::SSL::_getClientID"} = sub {
            my ($self) = @_;
    
            return ${*$self}{'__client_id'} || ''; ## no critic (References::ProhibitDoubleSigils)
        };

    }
    
}

sub new($class, $isDebugging, $configfile) {

    my $self = bless {}, $class;

    $self->{isDebugging} = $isDebugging;
    $self->{configfile} = $configfile;

    $self->{timeoffset} = 0;

    if(defined($ENV{CLACKS_SIMULATED_TIME_OFFSET})) {
        $self->{timeoffset} = 0 + $ENV{CLACKS_SIMULATED_TIME_OFFSET};
        print "****** RUNNING WITH A SIMULATED TIME OFFSET OF ", $self->{timeoffset}, " seconds ******\n";
    }

    $self->{cache} = {};

    return $self;
}

sub init($self) {
    # Dummy function for backward compatibility
    carp("Deprecated call to init(), you can remove that function from your code");
    return;
}

sub run($self) {
    if(!defined($self->{initHasRun}) || !$self->{initHasRun}) {
        $self->_init();
    }

    while($self->{keepRunning}) {
        # Check for shutdown time
        if($self->{shutdowntime} && $self->{shutdowntime} < time) {
            print STDERR "Shutdown time has arrived!\n";
            $self->{keepRunning} = 0;
        }

        $self->runOnce();

        if($self->{workCount}) {
            $self->{usleep} = 0;
        } elsif($self->{usleep} < $self->{config}->{throttle}->{maxsleep}) {
            $self->{usleep} += $self->{config}->{throttle}->{step};
        }
        if($self->{usleep}) {
            sleep($self->{usleep} / 1000);
        }
    }

    $self->runShutdown();

    return;
}

sub runOnce($self) {
    if(!defined($self->{initHasRun}) || !$self->{initHasRun}) {
        $self->_init();
    }

    $self->{workCount} = 0;

    my $now = $self->_getTime();
    if($self->{savecache} && $now > ($self->{lastsavecache} + $self->{persistanceinterval})) {
        $self->{lastsavecache} = $now;
        $self->_savePersistanceFile();
        $self->{savecache} = 0;
    }

    # We are in client mode. We need to add an interclacks link
    if(defined($self->{config}->{master}->{socket}) || defined($self->{config}->{master}->{ip})) {
        $self->_addInterclacksLink();
    }

    $self->_addNewClients();

    $self->_disconnectClients();

    if(!(scalar keys %{$self->{clients}})) {
        # No clients to handle, let's sleep and try again later
        sleep(0.1);
        return $self->{workCount};
    }

    $self->_clientInput();


    foreach my $cid (keys %{$self->{clients}}) {
        while(@{$self->{clients}->{$cid}->{charbuffer}}) {
            my $buf = shift @{$self->{clients}->{$cid}->{charbuffer}};

            $self->{workCount}++;
            if($buf eq "\r") {
                next;
            } elsif($buf eq "\n") {
                next if($self->{clients}->{$cid}->{buffer} eq ''); # Empty lines

                my %inmsg = (
                    message => $self->{clients}->{$cid}->{buffer},
                    releasetime => $now + $self->{clients}->{$cid}->{inmessagedelay},
                );
                push @{$self->{clients}->{$cid}->{inmessages}}, \%inmsg;
                $self->{clients}->{$cid}->{buffer} = '';
            } else {
                $self->{clients}->{$cid}->{buffer} .= $buf;
            }
        }

        if($self->{interclackslock} && !$self->{clients}->{$cid}->{interclacksclient}) {
            # We are locked into interclacks sync lock, but this is not the connection to master,
            # so we don't handle the input buffer for this client at the moment.
            next;
        }


        while(scalar @{$self->{clients}->{$cid}->{inmessages}}) {
            last if($self->{clients}->{$cid}->{inmessages}->[0]->{releasetime} > $now);
            my $inmsgtmp = shift @{$self->{clients}->{$cid}->{inmessages}};
            my $inmsg = $inmsgtmp->{message};

            # Handle CLACKS identification header
            if($inmsg =~ /^CLACKS\ (.+)/) {
                $self->{clients}->{$cid}->{clientinfo} = $1;
                $self->{clients}->{$cid}->{clientinfo} =~ s/\;/\_/g;
                print "Client at ", $cid, " identified as ", $self->{clients}->{$cid}->{clientinfo}, "\n";
                next;
            }

            $self->{nodebug} = 0;
            $self->{sendinterclacks} = 1;
            $self->{discardafterlogging} = 0;
            # Handle OVERHEAD messages before logging (for handling 'N' flag correctly)
            $self->_handleMessageOverhead($cid, $inmsg);

            # Ignore other command when not authenticated
            if(!$self->{clients}->{$cid}->{authok}) {
                next;
            }

            if(!$self->{nodebug}) {
                # Add ALL incoming messages as debug-type messages to the outbox
                my %tmp = (
                    sender => $cid,
                    type => 'DEBUG',
                    data => $inmsg,
                );

                push @{$self->{outbox}}, \%tmp;
            }

            if($self->{discardafterlogging}) {
                next;
            }



            if($inmsg =~ /^OVERHEAD\ /) {
                # Already handled
                next;
            } elsif($self->_handleMessageDirect($cid, $inmsg)) {
                # Fallthrough
            } elsif($self->_handleMessageCaching($cid, $inmsg)) {
                # Fallthrough
            } elsif($self->_handleMessageControl($cid, $inmsg)) {
                # Fallthrough
            # local managment commands
            } else {
                print STDERR "ERROR Unknown_command ", $inmsg, "\r\n";
                $self->{sendinterclacks} = 0;
                $self->{clients}->{$cid}->{outbuffer} .= "OVERHEAD E unknown_command " . $inmsg . "\r\n";
            }

            # forward interclacks messages
            if($self->{sendinterclacks}) {
                foreach my $interclackscid (keys %{$self->{clients}}) {
                    if($cid eq $interclackscid || !$self->{clients}->{$interclackscid}->{interclacks}) {
                        next;
                    }
                    $self->{clients}->{$interclackscid}->{outbuffer} .= $inmsg . "\r\n";
                }
            }

        }

    }

    # Clean up algorithm, only run every so often
    if($self->{nextcachecleanup} < $now) {
        $self->_cacheCleanup();
        $self->{nextcachecleanup} = $now + $self->{config}->{cachecleaninterval};

    }

    $self->_outboxToClientBuffer();
    $self->_clientOutput();

    return $self->{workCount};
}

sub runShutdown($self) {
    print "Shutting down...\n";

    # Make sure we save the latest version of the persistance file
    $self->_savePersistanceFile();

    sleep(0.5);
    foreach my $cid (keys %{$self->{clients}}) {
        print "Removing client $cid\n";
        # Try to notify the client (may or may not work);
        $self->_evalsyswrite($self->{clients}->{$cid}->{socket}, "\r\nQUIT\r\n");

        delete $self->{clients}->{$cid};
    }
    print "All clients removed\n";

    return;
}

sub _savePersistanceFile($self) {
    if(!$self->{persistance}) {
        return;
    }

    print "Saving persistance file\n";

    my $tempfname = $self->{config}->{persistancefile} . '_';
    my $backfname = $self->{config}->{persistancefile} . '_bck';
    if($self->{savecache} == 1) {
        # Normal savecache operation only
        copy($self->{config}->{persistancefile}, $backfname);
    }

    my $persistancedata = chr(0) . 'CLACKSV3' . Dump($self->{cache}) . chr(0) . 'CLACKSV3';
    $self->_writeBinFile($tempfname, $persistancedata);
    move($tempfname, $self->{config}->{persistancefile});

    if($self->{savecache} == 2) {
        # Need to make sure we have a valid backup file, since we had a general problem while loading
        copy($self->{config}->{persistancefile}, $backfname);
    }

    return;
}

sub _evalsyswrite($self, $socket, $buffer) {
    return false unless(length($buffer));

    my $written = 0;
    my $ok = 0;
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        $written = syswrite($socket, $buffer);
        $ok = 1;
    };
    if($EVAL_ERROR || !$ok) {
        print STDERR "Write error: $EVAL_ERROR\n";
        return -1;
    }

    return $written;
}

sub _getTime($self) {
    my $now = time + $self->{timeoffset};

    return $now;
}

sub _slurpBinFile($self, $fname) {
    # Read in file in binary mode, slurping it into a single scalar.
    # We have to make sure we use binmode *and* turn on the line termination variable completly
    # to work around the multiple idiosynchrasies of Perl on Windows
    open(my $fh, "<", $fname) or croak($ERRNO);
    local $INPUT_RECORD_SEPARATOR = undef;
    binmode($fh);
    my $data = <$fh>;
    close($fh);

    return $data;
}

sub _writeBinFile($self, $fname, $data) {
    # Write file in binmode
    # We have to make sure we use binmode *and* turn on the line termination variable completly
    # to work around the multiple idiosynchrasies of Perl on Windows
    open(my $fh, ">", $fname) or croak($ERRNO);
    local $INPUT_RECORD_SEPARATOR = undef;
    binmode($fh);
    print $fh $data;
    close($fh);

    return true;
}

sub _restorePersistanceFile($self) {
    my $previousfname = $self->{config}->{persistancefile} . '_bck';
    my $tempfname = $self->{config}->{persistancefile} . '_';
    my $loadok = 0;
    if(-f $self->{config}->{persistancefile}) {
        print "Trying to load persistance file ", $self->{config}->{persistancefile}, "\n";
        $loadok = $self->_loadPersistanceFile($self->{config}->{persistancefile});
    }

    if(!$loadok && -f $previousfname) {
        print "Trying to load backup (previous) persistance file ", $previousfname, "\n";
        $loadok = $self->_loadPersistanceFile($previousfname);
        if($loadok) {
            $self->{savecache} = 2; # Force saving a new persistance file plus a new backup
        }
    }
    if(!$loadok && -f $tempfname) {
        print "Oh no. As a final, desperate solution, trying to load a 'temporary file while saving' persistance file ", $tempfname, "\n";
        $loadok = $self->_loadPersistanceFile($tempfname);
        if($loadok) {
            $self->{savecache} = 2; # Force saving a new persistance file plus a new backup
        }
    }

    if(!$loadok) {
        print "Sorry, no valid persistance file found. Starting server 'blankety-blank'\n";
        $self->{savecache} = 2;
    } else {
        print "Persistance file loaded\n";
    }
    
    return;
}

sub _init($self) {
    if(defined($self->{initHasRun}) && $self->{initHasRun}) {
        # NOT ALLOWED!
        croak("Multiple calls to _init() are not allowed!");
    }

    my @paths;
    if(defined($ENV{'PC_CONFIG_PATHS'})) {
        push @paths, split/\:/, $ENV{'PC_CONFIG_PATHS'};
        print "Found config paths:\n", Dumper(\@paths), " \n";
    } else {
        print("PC_CONFIG_PATHS undefined, falling back to legacy mode\n");
        @paths = ('', 'configs/');
    }

    my $filedata;
    my $fname = $self->{configfile};
    foreach my $path (@paths) {
        if($path ne '' && $path !~ /\/$/) {
            $path .= '/';
        }
        my $fullfname = $path . $fname;
        next unless (-f $fullfname);
        print "   Loading config file $fullfname\n";

        $filedata = $self->_slurpBinFile($fullfname);

        foreach my $varname (keys %ENV) {
            next unless $varname =~ /^PC\_/;

            my $newval = $ENV{$varname};
            $filedata =~ s/$varname/$newval/g;
        }

        last;
    }

    if(!defined($filedata) || $filedata eq "") {
        croak("Can't load config file: Not found or empty!");
    }

    print "------- Parsing config file $fname ------\n";
    my $config = XMLin($filedata, ForceArray => [ 'ip', 'socket', 'user' ]);

    my $hname = hostname;

    # Copy hostname-specific stuff to root if it exists
    if(defined($config->{hosts}->{$hname})) {
        foreach my $key (keys %{$config->{hosts}->{$hname}}) {
            $config->{$key} = $config->{hosts}->{$hname}->{$key};
        }
    }

    $self->{config} = $config;

    if(!defined($self->{config}->{throttle}->{maxsleep})) {
        $self->{config}->{throttle}->{maxsleep} = 100;
    }
    if(!defined($self->{config}->{throttle}->{step})) {
        $self->{config}->{throttle}->{step} = 10;
    }

    $self->{usleep} = 0;

    if(defined($config->{ip})) {
        # SSL only needed for TCP. Unix domain sockets are unencrypted
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
    }

    if(!defined($self->{config}->{username})) {
        croak("Username not defined!");
    }
    if(!defined($self->{config}->{password})) {
        croak("Password not defined!");
    }
    $self->{authtoken} = encode_base64($self->{config}->{username}, '') . ':' . encode_base64($self->{config}->{password}, '');

    # Add authtoken to the list of authorized users, giving it full permissions
    $self->{userlist} = {};
    $self->{userlist}->{$self->{authtoken}} = {
        read => 1,
        write => 1,
        manage => 1,
        interclacks => 1,
    };

    # Configure additional users. They can NOT be used for interclacks connections, only the default user can
    if(defined($self->{config}->{user})) {
        foreach my $user (@{$self->{config}->{user}}) {
            if(!defined($user->{username}) || !defined($user->{password})) {
                croak("User config is missing username/password");
            }
            my $authtoken = encode_base64($user->{username}, '') . ':' . encode_base64($user->{password}, '');
            $self->{userlist}->{$authtoken} = {
                read => 0,
                write => 0,
                manage => 0,
                interclacks => 0,
            };
            foreach my $key (qw[read write manage]) {
                if(defined($user->{$key}) && $user->{$key}) {
                    $self->{userlist}->{$authtoken}->{$key} = 1;
                }
            }
        }
    }

    if(defined($self->{config}->{persistancefile})) {
        $self->{persistance} = 1;
    } else {
        $self->{persistance} = 0;
    }

    if(!defined($self->{config}->{persistanceinterval})) {
        $self->{persistanceinterval} = 10;
    } else {
        $self->{persistanceinterval} = $self->{config}->{persistanceinterval};
    }

    if(!defined($self->{config}->{interclacksreconnecttimeout})) {
        $self->{config}->{interclacksreconnecttimeout} = 30;
    }

    if(!defined($self->{config}->{authtimeout})) {
        $self->{config}->{authtimeout} = 15;
    }

    if(!defined($self->{config}->{deletedcachetime})) {
        $self->{config}->{deletedcachetime} = 60 * 60; # 1 hour
    }
    if(!defined($self->{config}->{stalecachetime})) {
        $self->{config}->{stalecachetime} = 60 * 60 * 24; # 1 day
    }

    if(!defined($self->{config}->{cachecleaninterval})) {
        $self->{config}->{cachecleaninterval} = 60; # 1 minute
    }

    # Init run() variables
    $self->{savecache} = 0;
    $self->{lastsavecache} = 0;
    $self->{outbox} = [];
    $self->{toremove} = [];
    $self->{clients} = {};
    $self->{shutdowntime} = 0;
    $self->{selector} = IO::Select->new();
    $self->{interclackslock} = 0;
    $self->{nextinterclackscheck} = 0;
    $self->{keepRunning} = 1;
    $self->{nextcachecleanup} = 0;
    $self->{initHasRun} = 1;

    my @tcpsockets;

    if(defined($config->{ip})) {
        if(!defined($config->{port})) {
            croak("At least one IP defined, but no TCP port!");
        }
        foreach my $ip (@{$config->{ip}}) {
            my $tcp = IO::Socket::IP->new(
                LocalHost => $ip,
                LocalPort => $config->{port},
                Listen => 20, # Listen queue of 20, just in case multiple clients try to connect at the same time
                Blocking => 0,
                ReuseAddr => 1,
                Proto => 'tcp',
            ) or croak($ERRNO);
            #binmode($tcp, ':bytes');
            push @tcpsockets, $tcp;
            print "Listening on $ip:", $config->{port}, "/tcp\n";
        }
    }

    if(defined($config->{socket}) || defined($self->{config}->{master}->{socket})) {
        my $udsloaded = 0;
        eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            require IO::Socket::UNIX;
            $udsloaded = 1;
        };
        if(!$udsloaded) {
            croak("Specified a unix domain socket, but i couldn't load IO::Socket::UNIX!");
        }

        # Add the ClientID stuff to Unix domain sockets as well. We don't do this in the BEGIN{} block
        # since we are not yet sure we are going to load IO::Socket::UNIX in the first place
        {
            no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
            *{"IO::Socket::UNIX::_setClientID"} = sub {
                my ($self, $cid) = @_;
        
                ${*$self}{'__client_id'} = $cid; ## no critic (References::ProhibitDoubleSigils)
                return;
            };
            
            *{"IO::Socket::UNIX::_getClientID"} = sub {
                my ($self) = @_;
        
                return ${*$self}{'__client_id'} || ''; ## no critic (References::ProhibitDoubleSigils)
            };
        }
    }

    if(defined($config->{socket})) {
        foreach my $socket (@{$config->{socket}}) {
            if(-S $socket) {
                print "Removing old unix domain socket file $socket\n";
                unlink $socket;
            }
            my $tcp = IO::Socket::UNIX->new(
                Type => SOCK_STREAM(),
                Local => $socket,
                Listen => 20, # Listen queue of 20, just in case multiple clients try to connect at the same time
                #Blocking => 0,
            ) or croak($ERRNO);
            $tcp->blocking(0);
            #binmode($tcp, ':bytes');
            push @tcpsockets, $tcp;
            print "Listening on Unix domain socket $socket\n";

            if(defined($config->{socketchmod}) && $config->{socketchmod} ne '') {
                my $cmd = 'chmod ' . $config->{socketchmod} . ' ' . $socket;
                print $cmd, "\n";
                `$cmd`;
            }
        }
    }

    $self->{tcpsockets} = \@tcpsockets;

    # Need to ignore SIGPIPE, this can screw us over in certain circumstances
    # while writing to the network. We can only detect certain types of disconnects
    # after writing to the socket, but we will get a SIGPIPE if we try. So we just
    # ignore the signal and carry on as usual...
    $SIG{PIPE} = 'IGNORE';


    $SIG{INT} = sub { $self->{keepRunning} = 0; };
    $SIG{TERM} = sub { $self->{keepRunning} = 0; };

    # Restore persistance file if required
    if($self->{persistance}) {
        $self->_restorePersistanceFile();
    }

    print "Ready.\n";


    return;
}

sub _loadPersistanceFile($self, $fname) {
    my $alreadyupgraded = 0;

retry:
    if(!-f $fname) {
        # Does not exist
        carp("$fname not found");
        return false;
    }

    my $data = $self->_slurpBinFile($fname);
    if(length($data) < 11) {
        carp("$fname too small");
        # Invalid file
        return false;
    }
    if(substr($data, 0, 9) ne chr(0) . 'CLACKSV3') {
        if($alreadyupgraded) {
            carp("Upgrade resulted in invalog file (wrong prefix)");
            # Something went wrong with inplace upgrade
            return;
        }
        $alreadyupgraded = 1;
        if(!$self->_inplaceUpgrade($fname)) {
            carp("Inplace upgrade failed");
            # Could not upgrade
            return false;
        }
        goto retry;
    }

    if(length($data) < 18) {
        carp("Incomplete V3 persistance file " . $fname . " (too small)!");
        return false;
    }

    substr($data, 0, 9, ''); # Remove header

    if(substr($data, -9, 9) ne chr(0) . 'CLACKSV3') {
        # Missing end bytes
        carp("Incomplete V3 persistance file " . $fname . " (missing end bytes)!");
        return false; # Fail
    }
    substr($data, -9, 9, ''); # Remove end bytes

    $self->{cache} = {};
    if(length($data)) {
        my $loadok = 0;
        eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            $self->{cache} = Load($data);
            $loadok = 1;
        };
        if(!$loadok) {
            carp("Invalid V3 persistance file " . $fname . "!");
            return false; # Fail
        }
    }

    return true;
}

sub _inplaceUpgrade($self, $fname) {
    my %clackscache;
    my %clackscachetime;
    my %clackscacheaccesstime;

    print "Inplace-upgrading persistance file $fname...\n";

    my $now = $self->_getTime();

    # Use old loader algorithm to load file
    if(open(my $ifh, '<', $fname)) {
        my $line = <$ifh>;
        my $timestampline = <$ifh>;
        my $accesstimeline = <$ifh>;
        my $endline = <$ifh>;
        my $needupgrade = 0;
        close $ifh;

        chomp $line;
        chomp $timestampline;
        chomp $accesstimeline;

        if(!defined($endline) && $accesstimeline eq 'ENDBYTES') {
            $endline = 'ENDBYTES';
            $accesstimeline = '';
            $needupgrade = 1;
        } else {
            chomp $endline;
        }

        if(!defined($line) || !defined($timestampline) || $endline ne 'ENDBYTES') {
            carp("Invalid persistance file " . $fname . "! File is incomplete!");
            return false; # Fail
        }

        my $loadok = 0;

        if($line ne '') {
            eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
                $line = decode_base64($line);
                $line = Load($line);
                $loadok = 1;
            };
            if(!$loadok) {
                carp("Invalid persistance file " . $fname . "! Failed to decode data line!");
                return false; # Fail
            }
        }
        %clackscache = %{$line};

        # Mark all data as current as a fallback
        foreach my $key (keys %clackscache) {
            $clackscachetime{$key} = $now;
        }

        if($timestampline ne '') {
            $loadok = 0;
            eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
                $timestampline = decode_base64($timestampline);
                $timestampline = Load($timestampline);
                $loadok = 1;
            };
            if(!$loadok) {
                carp("Invalid persistance file " . $fname . "! Failed to decode timestamp line, using current time!");
                return false; # Fail
            } else {
                my %clackstemp = %{$timestampline};
                foreach my $key (keys %clackstemp) {
                    $clackscachetime{$key} = $clackstemp{$key};
                }
            }
        }

        if($needupgrade) {
            print "Pre-Version 22 persistance file detected. Upgrading automatically.\n";
            foreach my $key (keys %clackscache) {
                $clackscacheaccesstime{$key} = $now;
            }
        } elsif($accesstimeline ne '') {
            $loadok = 0;
            eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
                $accesstimeline = decode_base64($accesstimeline);
                $accesstimeline = Load($accesstimeline);
                $loadok = 1;
            };
            if(!$loadok) {
                carp("Invalid persistance file " . $fname . "! Failed to decode timestamp line, using current time!");
                return false; # Fail
            } else {
                %clackscacheaccesstime = %{$accesstimeline};
            }
        }
    } else {
        # Fail
        return false;
    }

    # Turn into new format
    my %cache;
    # not-deleted sets
    foreach my $key (keys %clackscache) {
        my $cachetime = $now;
        my $accesstime = $now;
        if(defined($clackscachetime{$key})) {
            $cachetime = $clackscachetime{$key};
        }
        if(defined($clackscacheaccesstime{$key})) {
            $accesstime = $clackscacheaccesstime{$key};
        }
        $cache{$key} = {
            data => $clackscache{$key},
            cachetime => $cachetime,
            accesstime => $accesstime,
            deleted => 0,
        };
    }

    # deleted sets
    foreach my $key (keys %clackscachetime) {
        if(defined($cache{$key})) {
            # not deleted
            next;
        }

        my $cachetime = $clackscachetime{$key};
        my $accesstime = $now;
        if(defined($clackscacheaccesstime{$key})) {
            $accesstime = $clackscacheaccesstime{$key};
        }
        $cache{$key} = {
            data => '',
            cachetime => $cachetime,
            accesstime => $accesstime,
            deleted => 0,
        };
    }

    my $converted = chr(0) . 'CLACKSV3' . Dump(\%cache) . chr(0) . 'CLACKSV3';
    $self->_writeBinFile($fname, $converted);

    print "...upgrade complete.\n";

    return true;
}

sub _addInterclacksLink($self) {
    my $now = $self->_getTime();

    my $mcid;
    if(defined($self->{config}->{master}->{socket})) {
        $mcid = 'unixdomainsocket:interclacksmaster';
    } else {
        $mcid = $self->{config}->{master}->{ip}->[0] . ':' . $self->{config}->{master}->{port};
    }
    if(!defined($self->{clients}->{$mcid}) && $self->{nextinterclackscheck} < $now) {
        $self->{nextinterclackscheck} = $now + $self->{config}->{interclacksreconnecttimeout} + int(rand(10));

        print "Connect to master\n";
        my $msocket;

        if(defined($self->{config}->{master}->{socket})) {
            $msocket = IO::Socket::UNIX->new(
                Peer => $self->{config}->{master}->{socket}->[0],
                Type => SOCK_STREAM,
            );
        } else {
            $msocket = IO::Socket::IP->new(
                PeerHost => $self->{config}->{master}->{ip}->[0],
                PeerPort => $self->{config}->{master}->{port},
                Type => SOCK_STREAM,
                Timeout => 5,
            );
        }
        if(!defined($msocket)) {
            print STDERR "Can't connect to MASTER via interclacks!\n";
        } else {
            print "connected to master\n";

            if(ref $msocket ne 'IO::Socket::UNIX') {
                # ONLY USE SSL WHEN RUNNING OVER THE NETWORK
                # There is simply no point in running it over a local socket.
                my $encrypted = IO::Socket::SSL->start_SSL($msocket,
                                                           SSL_verify_mode => SSL_VERIFY_NONE,
                );
                if(!$encrypted) {
                    print "startSSL failed: ", $SSL_ERROR, "\n";
                    next;
                }
            }

            $msocket->blocking(0);
            #binmode($msocket, ':bytes');
            my %tmp = (
                buffer  => '',
                charbuffer => [],
                listening => {},
                socket => $msocket,
                lastping => $now,
                mirror => 0,
                outbuffer => "CLACKS PageCamel $VERSION in interclacks client mode\r\n" .  # Tell the server we are using PageCamel Interclacks...
                             "OVERHEAD A " . $self->{authtoken} . "\r\n" .              # ...send Auth token
                             "OVERHEAD I 1\r\n",                                        # ...and turn interclacks master mode ON on remote side
                clientinfo => 'Interclacks link',
                client_timeoffset => 0,
                interclacks => 1,
                interclacksclient => 1,
                lastinterclacksping => $now,
                lastmessage => $now,
                authtimeout => $now + $self->{config}->{authtimeout},
                authok => 0,
                failcount => 0,
                outmessages => [],
                inmessages => [],
                messagedelay => 0,
                inmessagedelay => 0,
                outmessagedelay => 0,
                permissions => {
                    read => 1,
                    write => 1,
                    manage => 1,
                    interclacks => 1,
                },
            );

            if(defined($self->{config}->{master}->{ip})) {
                $tmp{host} = $self->{config}->{master}->{ip}->[0];
                $tmp{port} = $self->{config}->{master}->{port};
            }
            $self->{clients}->{$mcid} = \%tmp;
            $msocket->_setClientID($mcid);
            $self->{selector}->add($msocket);

            $self->{workCount}++;
        }
    }
    return;
}

sub _addNewClients($self) {
    my $now = $self->_getTime();
    foreach my $tcpsocket (@{$self->{tcpsockets}}) {
        my $clientsocket = $tcpsocket->accept;
        if(defined($clientsocket)) {
            $clientsocket->blocking(0);
            my ($cid, $chost, $cport);
            if(ref $tcpsocket eq 'IO::Socket::UNIX') {
                $chost = 'unixdomainsocket';
                $cport = $now . ':' . int(rand(1_000_000));
            } else {
                ($chost, $cport) = ($clientsocket->peerhost, $clientsocket->peerport);
            }
            print "Got a new client $chost:$cport!\n";
            $cid = "$chost:$cport";
            foreach my $debugcid (keys %{$self->{clients}}) {
                if($self->{clients}->{$debugcid}->{mirror}) {
                    $self->{clients}->{$debugcid}->{outbuffer} .= "DEBUG CONNECTED=" . $cid . "\r\n";
                }
            }

            if(ref $clientsocket ne 'IO::Socket::UNIX') {
                # ONLY USE SSL WHEN RUNNING OVER THE NETWORK
                # There is simply no point in running it over a local socket.
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
            }

            $clientsocket->blocking(0);
            #binmode($clientsocket, ':bytes');
            #$clientsocket->{clacks_cid} = $cid;
            my %tmp = (
                buffer  => '',
                charbuffer => [],
                listening => {},
                socket => $clientsocket,
                lastping => $now,
                mirror => 0,
                outbuffer => "CLACKS PageCamel $VERSION\r\n" .
                             "OVERHEAD M Authentication required\r\n",  # Informal message
                clientinfo => 'UNKNOWN',
                client_timeoffset => 0,
                host => $chost,
                port => $cport,
                interclacks => 0,
                interclacksclient => 0,
                lastinterclacksping => 0,
                lastmessage => $now,
                authtimeout => $now + $self->{config}->{authtimeout},
                authok => 0,
                failcount => 0,
                outmessages => [],
                inmessages => [],
                inmessagedelay => 0,
                outmessagedelay => 0,
                permissions => {
                    read => 0,
                    write => 0,
                    manage => 0,
                    interclacks => 0,
                },
            );
            if(0 && $self->{isDebugging}) {
                $tmp{authok} = 1;
                $tmp{outbuffer} .= "OVERHEAD M debugmode_auth_not_really_required\r\n"
            }
            $self->{clients}->{$cid} = \%tmp;
            $clientsocket->_setClientID($cid);
            $self->{selector}->add($clientsocket);
            $self->{workCount}++;
        }
    }
    
    return;
}

sub _disconnectClients($self) {
    my $now = $self->_getTime();

    # Check if there are any clients to disconnect...
    my $pingtime = $now - $self->{config}->{pingtimeout};
    my $interclackspingtime = $now - $self->{config}->{interclackspingtimeout};
    my $interclackspinginterval = $now - int($self->{config}->{interclackspingtimeout} / 3);
    foreach my $cid (keys %{$self->{clients}}) {
        if(!$self->{clients}->{$cid}->{socket}->connected) {
            push @{$self->{toremove}}, $cid;
            next;
        }
        if(!$self->{clients}->{$cid}->{interclacks}) {
            if($self->{clients}->{$cid}->{lastping} > 0 && $self->{clients}->{$cid}->{lastping} < $pingtime) {
                $self->_evalsyswrite($self->{clients}->{$cid}->{socket}, "\r\nTIMEOUT\r\n");
                push @{$self->{toremove}}, $cid;
                next;
            }
        } else {
            if($self->{clients}->{$cid}->{lastping} < $interclackspingtime) {
                $self->_evalsyswrite($self->{clients}->{$cid}->{socket}, "\r\nTIMEOUT\r\n");
                push @{$self->{toremove}}, $cid;
                next;
            }
        }

        if($self->{clients}->{$cid}->{interclacks} && $self->{clients}->{$cid}->{lastinterclacksping} < $interclackspinginterval) {
            $self->{clients}->{$cid}->{lastinterclacksping} = $now;
            $self->{clients}->{$cid}->{outbuffer} .= "PING\r\n";
        }

        if(!$self->{clients}->{$cid}->{authok} && $self->{clients}->{$cid}->{authtimeout} < $now) {
            # Authentication timeout!
            push @{$self->{toremove}}, $cid;
        }
    }

    # ...and disconnect them
    if(scalar @{$self->{toremove}}) {
        # Make sure we handle any last messages, or at least try to. This should allow us to at least try to adhere to the
        # protocol in some cases (auth failure, etc)
        $self->_outboxToClientBuffer();
        for(1..5) {
            my @flushed;
            foreach my $cid (@{$self->{toremove}}) {
                next if(contains($cid, \@flushed));
                push @flushed, $cid;
                next if(!length($self->{clients}->{$cid}->{outbuffer}));
                print "Flushing $cid for removal...\n";
                $self->_clientOutput($cid);
            }
            sleep(0.02);
        }
    }

    while((my $cid = shift @{$self->{toremove}})) {
        # In some circumstances, there may be multiple @{$self->{toremove}} entries for the same client. Ignore them...
        if(defined($self->{clients}->{$cid})) {
            print "Removing client $cid\n";
            foreach my $debugcid (keys %{$self->{clients}}) {
                if($self->{clients}->{$debugcid}->{mirror}) {
                    $self->{clients}->{$debugcid}->{outbuffer} .= "DEBUG DISCONNECTED=" . $cid . " (" . length($self->{clients}->{$cid}->{outbuffer}) . " bytes discarded from outbuffer)\r\n";
                    if($self->{clients}->{$cid}->{interclacksclient} && $self->{interclackslock}) {
                        $self->{clients}->{$debugcid}->{outbuffer} .= "DEBUG DISCONNECTED=" . $cid . " (Unlocking interclacks mid-sync)\r\n";
                    }
                }
            }

            if($self->{clients}->{$cid}->{interclacksclient} && $self->{interclackslock}) {
                print "...this one is interclacks master and has us locked - UNLOCKING mid-sync!\n";
                $self->{interclackslock} = 0;
            }

            $self->{selector}->remove($self->{clients}->{$cid}->{socket});
            delete $self->{clients}->{$cid};
        }

        $self->{workCount}++;
    }

    return;
}

sub _clientInput($self) {
    my $now = $self->_getTime();

    # **** READ FROM CLIENTS ****
    my $hasoutbufferwork = 0;
    foreach my $cid (keys %{$self->{clients}}) {
        if(length($self->{clients}->{$cid}->{buffer}) > 0) {
            # Found some work to do
            $hasoutbufferwork = 1;
            last;
        }
    }
    my $selecttimeout = 0.5; # Half a second
    if($hasoutbufferwork) {
        $selecttimeout = 0.05;
    }

    my @inclients = $self->{selector}->can_read($selecttimeout);
    foreach my $clientsocket (@inclients) {
        my $cid = $clientsocket->_getClientID();

        my $totalread = 0;
        my $readchunksleft = 3;
        while(1) {
            my $rawbuffer;
            my $readok = 0;
            eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
                sysread($self->{clients}->{$cid}->{socket}, $rawbuffer, 1_000_000); # Read at most 1 Meg at a time
                $readok = 1;
            };
            if(!$readok) {
                push @{$self->{toremove}}, $cid;
                last;
            }
            if(defined($rawbuffer) && length($rawbuffer)) {
                $totalread += length($rawbuffer);
                push @{$self->{clients}->{$cid}->{charbuffer}}, split//, $rawbuffer;
                $readchunksleft--;
                if(!$readchunksleft) {
                    last;
                }
                next;
            }
            last;
        }
        
        # Check if we could read data from a socket that was marked as readable.
        # Thanks to SSL, this might ocxasionally fail. Don't bail out at the first
        # error, only if multiple happen one after the other
        if($totalread) {
            $self->{clients}->{$cid}->{failcount} = 0;
        } else {
            $self->{clients}->{$cid}->{failcount}++;
            
            if($self->{clients}->{$cid}->{failcount} > 5) {
                # Socket was active multiple times but delivered no data?
                # EOF, maybe, possible, perhaps?
                push @{$self->{toremove}}, $cid;
            }
        }
    }

    return;
}

# $forceclientid let's us "force" working on a specific client only
sub _clientOutput($self, $forceclientid = '') {
    my $now = $self->_getTime();
    
    # **** WRITE TO CLIENTS ****
    foreach my $cid (keys %{$self->{clients}}) {
        if($forceclientid ne '' && $forceclientid ne $cid) {
            next;
        }
        if($cid ne $forceclientid && contains($cid, $self->{toremove})) {
            next;
        }
        if(length($self->{clients}->{$cid}->{outbuffer})) {
            $self->{clients}->{$cid}->{lastmessage} = $now;
        } elsif(($self->{clients}->{$cid}->{lastmessage} + 60) < $now) {
            $self->{clients}->{$cid}->{lastmessage} = $now;
            $self->{clients}->{$cid}->{outbuffer} .= "NOP\r\n"; # send "No OPerations" command, just to
                                                      # check if socket is still open
        }

        next if(!length($self->{clients}->{$cid}->{outbuffer}));

        # Output bandwidth-limited stuff, in as big chunks as possible
        my $written;
        $self->{workCount}++;
        eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
            $written = syswrite($self->{clients}->{$cid}->{socket}, $self->{clients}->{$cid}->{outbuffer});
        };
        if($EVAL_ERROR) {
            print STDERR "Write error: $EVAL_ERROR\n";
            push @{$self->{toremove}}, $cid;
            next;
        }
        if(!$self->{clients}->{$cid}->{socket}->opened || $self->{clients}->{$cid}->{socket}->error || ($ERRNO ne '' && !$ERRNO{EWOULDBLOCK})) {
            print STDERR "webPrint write failure: $ERRNO\n";
            push @{$self->{toremove}}, $cid;
            next;
        }

        if(defined($written) && $written) {
            if(length($self->{clients}->{$cid}->{outbuffer}) == $written) {
                $self->{clients}->{$cid}->{outbuffer} = '';
            } else {
                $self->{clients}->{$cid}->{outbuffer} = substr($self->{clients}->{$cid}->{outbuffer}, $written);
            }   
        }
    }

    return;
}

sub _cacheCleanup($self) {
    my $now = $self->_getTime();

    my $deletedtime = $now - $self->{config}->{deletedcachetime};
    my $staletime = $now - $self->{config}->{stalecachetime};
    foreach my $ckey (keys %{$self->{cache}}) {
        # Clean deleted entries. Ignore any non-"DELETED" entries as these are run from a different timer
        if($self->{cache}->{$ckey}->{deleted} && $self->{cache}->{$ckey}->{cachetime} < $deletedtime) {
            delete $self->{cache}->{$ckey};

            my %tmp = (
                sender => 'SERVERCACHE',
                type => 'DEBUG',
                data => 'CLEANDELETED=' . $ckey,
            );

            push @{$self->{outbox}}, \%tmp;
            $self->{savecache} = 1;
            next;
        }

        # Forget entries that have not been accesses in a long time (stale entries).
        # Ignore any "DELETED" entries, as these are run from a different timer
        if(!$self->{cache}->{$ckey}->{deleted} && $self->{cache}->{$ckey}->{accesstime} < $staletime) {
            delete $self->{cache}->{$ckey};

            my %tmp = (
                sender => 'SERVERCACHE',
                type => 'DEBUG',
                data => 'CLEANSTALE=' . $ckey,
            );

            push @{$self->{outbox}}, \%tmp;
            $self->{savecache} = 1;
            next;
        }
    }

    return;
}

sub _outboxToClientBuffer($self) {
    my $now = $self->_getTime();

    # Outbox contains the messages that have to be forwarded to the clients when listening (or when the connection is in interclacks mode)
    # We iterate over the outbox and put those messages into the output buffers of the corresponding client connection
    while((my $line = shift @{$self->{outbox}})) {
        $self->{workCount}++;
        foreach my $cid (keys %{$self->{clients}}) {
            if($line->{type} eq 'DEBUG' && $self->{clients}->{$cid}->{mirror}) {
                $self->{clients}->{$cid}->{outbuffer} .= "DEBUG " . $line->{sender} . "=". $line->{data} . "\r\n";
            }

            if($cid eq $line->{sender}) {
                next;
            }

            if($line->{type} ne 'DEBUG' && defined($self->{clients}->{$cid}->{listening}->{$line->{name}})) {
                # Just buffer in the clients outbuffers
                if($line->{type} eq 'NOTIFY') {
                    $self->{clients}->{$cid}->{outbuffer} .= "NOTIFY ". $line->{name} . "\r\n";
                } elsif($line->{type} eq 'SET') {
                    $self->{clients}->{$cid}->{outbuffer} .= "SET ". $line->{name} . "=" . $line->{value} . "\r\n";
                } elsif($line->{type} eq 'SETANDSTORE') {
                    # We forward SETANDSTORE as such only over interclacks connections. Basic clients don't have a cache,
                    # so we only send a SET command
                    if($self->{clients}->{$cid}->{interclacks}) {
                        $self->{clients}->{$cid}->{outbuffer} .= "SETANDSTORE ". $line->{name} . "=" . $line->{value} . "\r\n";
                    } else {
                        $self->{clients}->{$cid}->{outbuffer} .= "SET ". $line->{name} . "=" . $line->{value} . "\r\n";
                    }
                }
            }
        }
    }


    # Push all messages that can be released at this time into the corresponding char based output for each client
    foreach my $cid (keys %{$self->{clients}}) {
        while(scalar @{$self->{clients}->{$cid}->{outmessages}}) {
            last if($self->{clients}->{$cid}->{outmessages}->[0]->{releasetime} > $now);

            my $outmsg = shift @{$self->{clients}->{$cid}->{outmessages}};
            if($outmsg->{message} eq 'EXIT') {
                push @{$self->{toremove}}, $cid; # Disconnect the client
            } else {
                $self->{clients}->{$cid}->{outbuffer} .= $outmsg->{message} . "\r\n";
            }
        }
    }

    return;
}

sub _requirePermission($self, $cid, $type) {
    if(defined($self->{clients}->{$cid}->{permissions}->{$type}) && $self->{clients}->{$cid}->{permissions}->{$type}) {
        # Permission OK
        return 1;
    }

    my $now = $self->_getTime();
    push @{$self->{clients}->{$cid}->{outmessages}}, {releasetime => $now + $self->{clients}->{$cid}->{outmessagedelay}, message => 'OVERHEAD E permission_denied'};

    return 0;
}

sub _handleMessageOverhead($self, $cid, $inmsg) {
    my $now = $self->_getTime();

    if($inmsg =~ /^OVERHEAD\ (.+?)\ (.+)/) {
        my ($flags, $value) = ($1, $2);
        $self->{sendinterclacks} = 0;
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
            if(defined($self->{userlist}->{$value})) {
                $self->{clients}->{$cid}->{authok} = 1;

                # Copy user permissions to client session
                foreach my $key (qw[read write manage interclacks]) {
                    $self->{clients}->{$cid}->{permissions}->{$key} = $self->{userlist}->{$value}->{$key};
                }

                #$self->{clients}->{$cid}->{outbuffer} .= "OVERHEAD O Welcome!\r\n";
                push @{$self->{clients}->{$cid}->{outmessages}}, {releasetime => $now + $self->{clients}->{$cid}->{outmessagedelay}, message => 'OVERHEAD O Welcome!'};
                return true; # NO LOGGING OF CREDENTIALS
            } else {
                $self->{clients}->{$cid}->{authok} = 0;
                #$self->{clients}->{$cid}->{outbuffer} .= "OVERHEAD F Login failed!\r\n";
                push @{$self->{clients}->{$cid}->{outmessages}}, {releasetime => $now + $self->{clients}->{$cid}->{outmessagedelay}, message => 'OVERHEAD F Login failed!'};
                push @{$self->{clients}->{$cid}->{outmessages}}, {releasetime => $now + $self->{clients}->{$cid}->{outmessagedelay}, message => 'EXIT'};
                push @{$self->{toremove}}, $cid; # Disconnect the client
                return true; # NO LOGGING OF CREDENTIALS
            }
        }

        # Ignore other command when not authenticated
        if(!$self->{clients}->{$cid}->{authok}) {
            return true;
        }

        if($parsedflags{timestamp}) {
            $now = $self->_getTime(); # Make sure we are at the "latest" $now. This is one of the very few critical sections
            $self->{clients}->{$cid}->{client_timeoffset} = $now - $value;
            print "**** CLIENT TIME OFFSET: ", $self->{clients}->{$cid}->{client_timeoffset}, "\n";
            return true;
        }

        if($parsedflags{lock_for_sync} && $self->{clients}->{$cid}->{interclacksclient}) {
            return true unless($self->_requirePermission($cid, 'interclacks'));
            if($value) {
                print "Interclacks sync lock ON.\n";
                $self->{interclackslock} = 1;
            } else {
                print "Interclacks sync lock OFF.\n";
                $self->{interclackslock} = 0;

                # Send server our keys AFTER we got everything FROM the server (e.g. after unlock)
                $self->{clients}->{$cid}->{outbuffer} .= "OVERHEAD T " . $self->_getTime() . "\r\n"; # Send local time to server for offset calculation

                $now = $self->_getTime();
                foreach my $ckey (sort keys %{$self->{cache}}) {
                    # Sanity checks 
                    if(!defined($self->{cache}->{$ckey}->{cachetime}) || !looks_like_number($self->{cache}->{$ckey}->{cachetime})) {
                        $self->{cache}->{$ckey}->{cachetime} = $now;
                    }
                    if(!defined($self->{cache}->{$ckey}->{accesstime}) || !looks_like_number($self->{cache}->{$ckey}->{accesstime})) {
                        $self->{cache}->{$ckey}->{accesstime} = $now;
                    }
                    if(!defined($self->{cache}->{$ckey}->{deleted}) || !$self->{cache}->{$ckey}->{deleted}) {
                        $self->{cache}->{$ckey}->{deleted} = 0;
                    }
                    if(!defined($self->{cache}->{$ckey}->{data})) {
                        $self->{cache}->{$ckey}->{data} = '';
                    }
                    
                    # Send KEYSYNC commands
                    if(!$self->{cache}->{$ckey}->{deleted}) {
                        $self->{clients}->{$cid}->{outbuffer} .= "KEYSYNC " . $self->{cache}->{$ckey}->{cachetime} . " " . $self->{cache}->{$ckey}->{accesstime} . " U $ckey=" . $self->{cache}->{$ckey}->{data} . "\r\n";
                    } else {
                        $self->{clients}->{$cid}->{outbuffer} .= "KEYSYNC " . $self->{cache}->{$ckey}->{cachetime} . " 0 D $ckey=REMOVED\r\n";
                    }
                }
            }
            $parsedflags{forward_message} = 0; # Don't forward
            $newflags{return_to_sender} = 0; # Don't return to sender
        }

        if($parsedflags{close_all_connections} && $value) {
            return true unless($self->_requirePermission($cid, 'manage'));
            foreach my $closecid (keys %{$self->{clients}}) {
                if($self->{clients}->{$closecid}->{interclacks} && $parsedflags{forward_message}) {
                    $self->_evalsyswrite($self->{clients}->{$closecid}->{socket}, "\r\nOVERHEAD GC 1\r\n");
                }
                $self->_evalsyswrite($self->{clients}->{$closecid}->{socket}, "\r\nQUIT\r\n");
                push @{$self->{toremove}}, $closecid;
            }
            $parsedflags{forward_message} = 0; # Already forwarded where needed
        }

        if($parsedflags{shutdown_service}) {
            return true unless($self->_requirePermission($cid, 'manage'));
            $value = 0 + $value;
            if($value > 0) {
                $self->{shutdowntime} = $value + $now;
                print STDERR "Shutting down in $value seconds\n";
            }
        }
        if($parsedflags{discard_message}) {
            $self->{discardafterlogging} = 1;
        }
        if($parsedflags{no_logging}) {
            $self->{nodebug} = 1;
        }

        if($parsedflags{error_message}) {
            print STDERR 'ERROR from ', $cid, ': ', $value, "\n";
        }

        if($parsedflags{set_interclacks_mode}) {
            return true unless($self->_requirePermission($cid, 'interclacks'));
            $newflags{forward_message} = 0;
            $newflags{return_to_sender} = 0;

            if($value) {
                $self->{clients}->{$cid}->{interclacks} = 1;
                $self->{clients}->{$cid}->{lastping} = $now;


                $self->{clients}->{$cid}->{outbuffer} .= "CLACKS PageCamel $VERSION in interclacks master mode\r\n" .  # Tell client we are in interclacks master mode
                                               "OVERHEAD M Authentication required\r\n" .                 # Informal message
                                               "OVERHEAD A " . $self->{authtoken} . "\r\n" .              # ...and send Auth token...
                                               "OVERHEAD L 1\r\n" .                                       # ...and lock client for sync
                                               "OVERHEAD T " . time . "\r\n";                             # ... and send local timestamp

                # Make sure our new interclacks client has an *exact* copy of our buffer
                #$self->{clients}->{$cid}->{outbuffer} .= "CLEARCACHE\r\n";
                
                $now = $self->_getTime();
                foreach my $ckey (sort keys %{$self->{cache}}) {
                    # Sanity checks 
                    if(!defined($self->{cache}->{$ckey}->{cachetime}) || !looks_like_number($self->{cache}->{$ckey}->{cachetime})) {
                        $self->{cache}->{$ckey}->{cachetime} = $now;
                    }
                    if(!defined($self->{cache}->{$ckey}->{accesstime}) || !looks_like_number($self->{cache}->{$ckey}->{accesstime})) {
                        $self->{cache}->{$ckey}->{accesstime} = $now;
                    }
                    if(!defined($self->{cache}->{$ckey}->{deleted}) || !$self->{cache}->{$ckey}->{deleted}) {
                        $self->{cache}->{$ckey}->{deleted} = 0;
                    }
                    if(!defined($self->{cache}->{$ckey}->{data})) {
                        $self->{cache}->{$ckey}->{data} = '';
                    }

                    # Send KEYSYNC commands
                    if(!$self->{cache}->{$ckey}->{deleted}) {
                        $self->{clients}->{$cid}->{outbuffer} .= "KEYSYNC " . $self->{cache}->{$ckey}->{cachetime} . " " . $self->{cache}->{$ckey}->{accesstime} . " U $ckey=" . $self->{cache}->{$ckey}->{data} . "\r\n";
                    } else {
                        $self->{clients}->{$cid}->{outbuffer} .= "KEYSYNC " . $self->{cache}->{$ckey}->{cachetime} . " 0 D $ckey=REMOVED\r\n";
                    }
                }
                $self->{clients}->{$cid}->{outbuffer} .= "OVERHEAD L 0\r\n"; # unlock client after sync
                $self->{clients}->{$cid}->{outbuffer} .= "PING\r\n";
                $self->{clients}->{$cid}->{lastinterclacksping} = $now;
            } else {
                $self->{clients}->{$cid}->{interclacks} = 0;
                $self->{clients}->{$cid}->{lastping} = $now;
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
            return true unless($self->_requirePermission($cid, 'write'));
            foreach my $overheadcid (keys %{$self->{clients}}) {
                next if($cid eq $overheadcid && !$parsedflags{return_to_sender});

                $self->{clients}->{$overheadcid}->{outbuffer} .= "OVERHEAD $newflagstring $value\r\n";
            }
        }

        return true;
    }

    return false;
}

sub _handleMessageCaching($self, $cid, $inmsg) {
    my $now = $self->_getTime();

    if($inmsg =~ /^KEYSYNC\ (.+?)\ (.+?)\ (.+?)\ (.+?)\=(.*)/) {
        return true unless($self->_requirePermission($cid, 'interclacks'));
        #print "***** ", $inmsg, "\n";
        my ($ctimestamp, $atimestamp, $cmode, $ckey, $cval) = ($1, $2, $3, $4, $5);
        $self->{clients}->{$cid}->{lastping} = $now; # KEYSYNC acts as a PING as well

        $ctimestamp += $self->{clients}->{$cid}->{client_timeoffset}; # Take client time offset into account
        if($atimestamp) {
            $atimestamp += $self->{clients}->{$cid}->{client_timeoffset}; # Take client time offset into account
        }

        if(!defined($self->{cache}->{$ckey}) || $ctimestamp > $self->{cache}->{$ckey}->{cachetime}) {
            # If *we* have the older entry (or none at all), *only* then work on the keysync command
            $self->{cache}->{$ckey} = {
                data => $cval,
                cachetime => $ctimestamp,
                accesstime => $atimestamp,
                deleted => 0,
            };
            if($cmode eq 'D') {
                $self->{cache}->{$ckey}->{data} = '';
                $self->{cache}->{$ckey}->{deleted} = 1;
            }
        }

        $self->{savecache} = 1;
        $self->{sendinterclacks} = 1;
    } elsif($inmsg =~ /^STORE\ (.+?)\=(.*)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my ($ckey, $cval) = ($1, $2);
        $self->{cache}->{$ckey} = {
            data => $cval,
            cachetime => $now,
            accesstime => $now,
            deleted => 0,
        };
        $self->{savecache} = 1;
    } elsif($inmsg =~ /^SETANDSTORE\ (.+?)\=(.*)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my ($ckey, $cval) = ($1, $2);
        my %tmp = (
            sender => $cid,
            type => 'SETANDSTORE',
            name => $ckey,
            value => $cval,
        );
        push @{$self->{outbox}}, \%tmp;
        $self->{cache}->{$ckey} = {
            data => $cval,
            cachetime => $now,
            accesstime => $now,
            deleted => 0,
        };
        $self->{savecache} = 1;
    } elsif($inmsg =~ /^RETRIEVE\ (.+)/) {
        return true unless($self->_requirePermission($cid, 'read'));
        #$self->{clients}->{$cid}->{outbuffer} .= "SET ". $line->{name} . "=" . $line->{value} . "\r\n";
        my $ckey = $1;
        if(defined($self->{cache}->{$ckey}) && !$self->{cache}->{$ckey}->{deleted}) {
            $self->{clients}->{$cid}->{outbuffer} .= "RETRIEVED $ckey=" . $self->{cache}->{$ckey}->{data} . "\r\n";
            $self->{cache}->{$ckey}->{accesstime} = $now;
            $self->{savecache} = 1;
        } else {
            $self->{clients}->{$cid}->{outbuffer} .= "NOTRETRIEVED $ckey\r\n";
        }
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^REMOVE\ (.+)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my $ckey = $1;
        $self->{cache}->{$ckey} = {
            data => '',
            cachetime => $now,
            accesstime => $now,
            deleted => 1,
        };
        $self->{savecache} = 1;
    } elsif($inmsg =~ /^INCREMENT\ (.+)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my $ckey = $1;
        my $cval = 1;
        if($ckey =~ /(.+)\=(.+)/) {
            ($ckey, $cval) = ($1, $2);
            $cval = 0 + $cval;
        }

        my $oldval = 0;
        if(defined($self->{cache}->{$ckey}) && !$self->{cache}->{$ckey}->{deleted} && looks_like_number($self->{cache}->{$ckey}->{data})) {
            $oldval = $self->{cache}->{$ckey}->{data};
        }

        $self->{cache}->{$ckey} = {
            data => $oldval + $cval,
            cachetime => $now,
            accesstime => $now,
            deleted => 0,
        };

        $self->{savecache} = 1;
    } elsif($inmsg =~ /^DECREMENT\ (.+)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my $ckey = $1;
        my $cval = 1;
        if($ckey =~ /(.+)\=(.+)/) {
            ($ckey, $cval) = ($1, $2);
            $cval = 0 + $cval;
        }

        my $oldval = 0;
        if(defined($self->{cache}->{$ckey}) && !$self->{cache}->{$ckey}->{deleted} && looks_like_number($self->{cache}->{$ckey}->{data})) {
            $oldval = $self->{cache}->{$ckey}->{data};
        }

        $self->{cache}->{$ckey} = {
            data => $oldval - $cval,
            cachetime => $now,
            accesstime => $now,
            deleted => 0,
        };

        $self->{savecache} = 1;
    } elsif($inmsg =~ /^KEYLIST/) {
        return true unless($self->_requirePermission($cid, 'read'));
        $self->{clients}->{$cid}->{outbuffer} .= "KEYLISTSTART\r\n";
        foreach my $ckey (sort keys %{$self->{cache}}) {
            $self->{clients}->{$cid}->{outbuffer} .= "KEY $ckey\r\n";
        }
        $self->{clients}->{$cid}->{outbuffer} .= "KEYLISTEND\r\n";
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^CLEARCACHE/) {
        return true unless $self->_requirePermission($cid, 'manage');
        $self->{cache} = {};
        $self->{savecache} = 1;
    } else {
        # "not handled in this sub"
        return false;
    }

    return true;
}

sub _handleMessageControl($self, $cid, $inmsg) {
    my $now = $self->_getTime();

    if($inmsg =~ /^LISTEN\ (.*)/) {
        return true unless($self->_requirePermission($cid, 'read'));
        $self->{clients}->{$cid}->{listening}->{$1} = 1;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^UNLISTEN\ (.*)/) {
        return true unless($self->_requirePermission($cid, 'read'));
        delete $self->{clients}->{$cid}->{listening}->{$1};
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^MONITOR/) {
        return true unless($self->_requirePermission($cid, 'manage'));
        $self->{clients}->{$cid}->{mirror} = 1;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^UNMONITOR/) {
        return true unless($self->_requirePermission($cid, 'manage'));
        $self->{clients}->{$cid}->{mirror} = 0;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^QUIT/) {
        print STDERR "Client disconnected cleanly!\n";
        push @{$self->{toremove}}, $cid;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^TIMEOUT/ && $self->{clients}->{$cid}->{interclacks}) {
        return true unless($self->_requirePermission($cid, 'interclacks'));
        print STDERR "Ooops, didn't send timely PINGS through interclacks link!\n";
        push @{$self->{toremove}}, $cid;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^PING/) {
        $self->{clients}->{$cid}->{lastping} = $now;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^NOPING/) {
        # Disable PING check until next PING recieved
        $self->{clients}->{$cid}->{lastping} = 0;
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^CLIENTLIST/) {
        return true unless($self->_requirePermission($cid, 'manage'));
        $self->{clients}->{$cid}->{outbuffer} .= "CLIENTLISTSTART\r\n";
        foreach my $lmccid (sort keys %{$self->{clients}}) {
            $self->{clients}->{$cid}->{outbuffer} .= "CLIENT CID=$lmccid;" .
                                                "HOST=" . $self->{clients}->{$lmccid}->{host} . ";" .
                                                "PORT=" . $self->{clients}->{$lmccid}->{port} . ";" .
                                                "CLIENTINFO=" . $self->{clients}->{$lmccid}->{clientinfo} . ";" .
                                                "OUTBUFFER_LENGTH=" . length($self->{clients}->{$lmccid}->{outbuffer}) . ";" .
                                                "INBUFFER_LENGTH=" . length($self->{clients}->{$lmccid}->{buffer}) . ";" .
                                                "INTERCLACKS=" . $self->{clients}->{$lmccid}->{interclacks} . ";" .
                                                "MONITOR=" . $self->{clients}->{$lmccid}->{mirror} . ";" .
                                                "LASTPING=" . $self->{clients}->{$lmccid}->{lastping} . ";" .
                                                "LASTINTERCLACKSPING=" . $self->{clients}->{$lmccid}->{lastinterclacksping} . ";" .
                                                "\r\n";
        }
        $self->{clients}->{$cid}->{outbuffer} .= "CLIENTLISTEND\r\n";
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^CLIENTDISCONNECT\ (.+)/) {
        return true unless($self->_requirePermission($cid, 'manage'));
        my $lmccid = $1;
        if(defined($self->{clients}->{$lmccid})) {
            # Try to notify the client (may or may not work);
            $self->_evalsyswrite($self->{clients}->{$lmccid}->{socket}, "\r\nQUIT\r\n");
            push @{$self->{toremove}}, $lmccid;
        }
        $self->{sendinterclacks} = 0;
    } elsif($inmsg =~ /^FLUSH\ (.+)/) {
        my $retid = $1;
        $self->{clients}->{$cid}->{outbuffer} .= "FLUSHED $retid\r\n";
        $self->{sendinterclacks} = 0;
    } else {
        # "not handled in this sub"
        return false;
    }

    return true;
}


sub _handleMessageDirect($self, $cid, $inmsg) {
    if($inmsg =~ /^NOTIFY\ (.*)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my %tmp = (
            sender => $cid,
            type => 'NOTIFY',
            name => $1,
        );
        push @{$self->{outbox}}, \%tmp;
    } elsif($inmsg =~ /^SET\ (.+?)\=(.*)/) {
        return true unless($self->_requirePermission($cid, 'write'));
        my %tmp = (
            sender => $cid,
            type => 'SET',
            name => $1,
            value => $2,
        );
        push @{$self->{outbox}}, \%tmp;
    } else {
        # "not handled in this sub"
        return false;
    }

    return true;
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

=head2 init

DEPRECATED: Initialize server instance (required before running). This is now a dummy function that will show a deprecation warning and return.
Initialization is now done automatically when calling run().

=head2 run

Run the server instance in it's own event loop. Only returns when server is shutdown.

=head2 runOnce

Run through the event loop once. This allows you to use your own programs event loop, and call runOnce a couple of times per second. It is a good idea to call runShutdown() to cleanly
disconnect clients before exiting your program. runOnce() returns a "work count" number, on which you *may* decide on how busy the server is and when to call runOnce() next.

=head2 runShutdown

Shuts down all connections. This is called automatically if you use run(), but not if you use runOnce()

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
