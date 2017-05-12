package Net::FRN::Client;

require 5.001;

use utf8;
use strict;

use IO::Socket::INET;
use IO::Select;
use Term::ReadKey;
use POSIX;
use Carp;
use Net::FRN::Const;

my $HAS_AUDIO_GSM;
my $HAS_WIN32_SOUND;
my $HAS_WIN32_ACM;

my %EX = ();
my $DEBUG_PTT = 0;

BEGIN {
    $HAS_AUDIO_GSM   = eval("use Audio::GSM 0.03;   \$Audio::GSM::VERSION")   && !$!;
    $HAS_WIN32_SOUND = eval("use Win32::Sound; \$Win32::Sound::VERSION") && !$!;
    $HAS_WIN32_ACM   = eval("use Win32::ACM;   \$Win32::ACM::VERSION")   && !$!;
}

do { # Constants
    use constant STATE_NONE            => 0x00;
    use constant STATE_CONNECTING      => 0x01;
    use constant STATE_PROTO_HANDSHAKE => 0x02;
    use constant STATE_LOGIN_PHASE1    => 0x03;
    use constant STATE_LOGIN_PHASE2    => 0x04;
    use constant STATE_MESSAGE_HEADER  => 0x05;
    use constant STATE_MESSAGE         => 0x06;
    use constant STATE_TX              => 0x07;
    use constant STATE_RX              => 0x08;
    use constant STATE_CLIENTS_HEADER  => 0x09;
    use constant STATE_CLIENTS         => 0x0A;
    use constant STATE_NETWORKS_HEADER => 0x0B;
    use constant STATE_NETWORKS        => 0x0C;
    use constant STATE_SND_FRAME_IN    => 0x0D;
    use constant STATE_KEEPALIVE       => 0x0E;
    use constant STATE_DISCONNECTED    => 0x0F;
    use constant STATE_TX_REQUEST      => 0x10;
    use constant STATE_TX_WAITING      => 0x11;
    use constant STATE_TX_APPROVED     => 0x12;
    use constant STATE_TX_REJECTED     => 0x13;
    use constant STATE_TX_COMPLETE     => 0x14;
    use constant STATE_PING            => 0x15;
    use constant STATE_BANLIST_HEADER  => 0x16;
    use constant STATE_BANLIST         => 0x17;
    use constant STATE_MUTELIST_HEADER => 0x18;
    use constant STATE_MUTELIST        => 0x19;
    use constant STATE_PTT_DOWN        => 0x1A;
    use constant STATE_PTT_UP          => 0x1B;
    use constant STATE_MESSAGE_INPUT   => 0x1C;
    use constant STATE_MESSAGE_SEND    => 0x1D;
    use constant STATE_ABORT           => 0xFE;
    use constant STATE_IDLE            => 0xFF;

    use constant MARKER_KEEPALIVE     => 0x00;
    use constant MARKER_TX_APPROVE    => 0x01;
    use constant MARKER_SOUND         => 0x02;
    use constant MARKER_CLIENTS       => 0x03;
    use constant MARKER_MESSAGE       => 0x04;
    use constant MARKER_NETWORKS      => 0x05;
    use constant MARKER_BAN           => 0x08;
    use constant MARKER_MUTE          => 0x09;

    use constant KEEPALIVE_TIMEOUT    => 1;

    use constant PTT_UP               => 0x00;
    use constant PTT_DOWN             => 0x01;
    use constant PTT_CHANGED          => 0x02;
    use constant PTT_MSG              => 0x04;
    use constant PTT_EXIT             => 0x80;

    use constant PTT_KEY_EXIT         => 0x1B;

};

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my ($peer, %arg);
    if (@_ % 2) {
      $peer = shift;
      %arg  = @_;
    } else {
      %arg  = @_;
      $peer = delete $arg{Host};
    }
    my $gsm;
    if ($HAS_AUDIO_GSM > 0.03) {
        no strict 'subs';
        $gsm = new Audio::GSM;
        $gsm->option(GSM_OPT_WAV49, 1);
    } elsif ($HAS_WIN32_ACM && $HAS_WIN32_SOUND) {
        $gsm = new Win32::ACM;
    } else {
      warn <<WARN;
No suitable sound modules found.
Program will operate in silent mode.
Install either Audio::GSM or Win32::ACM.
WARN
    }
    my $self = {
        _socket        => undef,
        _select        => new IO::Select,
        _gsm           => $gsm,
        _VX            => FRN_PROTO_VERSION,
        _ON            => sprintf("%s, %s", $arg{Callsign}, $arg{Name}),
        _EA            => $arg{Email},
        _PW            => $arg{Password},
        _NT            => $arg{Net},
        _NN            => $arg{Country} || 'N/A',
        _CT            => sprintf("%s - %s", $arg{City} || 'N/A', $arg{Locator} || 'N/A'),
        _BC            => $arg{Type} || FRN_TYPE_PC_ONLY,
        _BN            => undef,
        _BP            => undef,
        _SV            => undef,
        _DS            => $arg{Desc} || '',
        _KP            => undef,
        _clients       => [],
        _networks      => [],
        _banlist       => [],
        _mutelist      => [],
        _inbuffer      => '',
        _outbuffer     => '',
        _msgbuffer     => '',
        _bytesExpected => 0,
        _linesExpected => 0,
        _state         => STATE_NONE,
        _lastKA        => 0,
        _callback      => {
            onConnect          => undef,
            onDisconnect       => undef,
            onPing             => undef,
            onKeepAlive        => undef,
            onLogin            => undef,
            onLoginPhase1      => undef,
            onLoginPhase2      => undef,
            onIdle             => undef,
            onClientList       => undef,
            onNetworkList      => undef,
            onMuteList         => undef,
            onBanList          => undef,
            onMessage          => undef,
            onPrivateMessage   => undef,
            onBroadcastMessage => undef,
            onRX               => undef,
            onGSM              => undef,
            onPCM              => undef,
            onTX               => undef,
            onGSMTX            => undef,
            onPCMTX            => undef,
            onTXRequest        => undef,
            onTXApprove        => undef,
            onTXComplete       => undef,
            onPTTDown          => undef,
            onPTTUp            => undef,
            onMessageInput     => undef,
            onGSMFeedback      => undef,
            onPCMFeedback      => undef,
        },
        _localAddr     => $arg{LocalAddr},
        _Host          => $peer,
        _Port          => $arg{Port},
        _pttKey        => $arg{PTTKey},
        _pttFile       => undef,
        _pttFileName   => $arg{PTTFile},
        _ptt           => PTT_UP,
        _msgKey        => $arg{MessageKey},
        _rxExFlag      => 0,
        _reconnectTimeout   => 10,
    };
    bless($self, $class);
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->_closePTTFile();
    ReadMode('restore');
}

# public methods

sub handler {
    my $self     = shift;
    my $callback = shift;
    my $coderef  = shift;
    return undef unless exists($self->{_callback}{$callback});
    my $oldCoderef = $self->{_callback}{$callback};
    if ($coderef) {
        $self->{_callback}{$callback} = $coderef;
    }
    return $oldCoderef;
}

sub run {
    my $self = shift;
    $self->_init;
    while ($self->{_state} != STATE_ABORT) {
        $self->_step;
    }
}

sub init {
    my $self = shift;
    $self->_init;
}

sub step {
    my $self = shift;
    $self->_step;
}

sub read {
    my $self = shift;
    $self->_read;
}

sub write {
    my $self = shift;
    $self->_write;
}

sub parse {
    my $self = shift;
    $self->_parse;
}

sub status {
    my $self = shift;
    my $status = shift;
    return $self->_status($status);
}

sub message {
    my $self = shift;
    my $text = shift;
    my $ID   = shift;
    my $rv = $self->_message(ID => $ID, MS => $text);
    $rv &= $self->_ping;
    return $rv;
}

# private methods

sub _step {
    my $self = shift;
    $self->_read;
    $self->_parse;
    $self->_write;
}

sub _read {
    my $self = shift;
    my $buff = '';
    my $rv;
    if ($self->{_state} == STATE_CONNECTING) {
        # we're connecting now... state will be checked in _parse()
    } elsif ($self->{_state} == STATE_DISCONNECTED) {
        # we're disconnected and can't read
    } elsif ($self->{_select}->can_read(0.2 * !length($self->{_outbuffer}) * !length($self->{_inbuffer}))) {
        use bytes;
        $rv = $self->{_socket}->read($buff, POSIX::BUFSIZ);
        if (!defined $rv) {
            $self->{_select}->remove($self->{_socket});
            if ($self->{_callback}{onDisconnect}) {
                &{$self->{_callback}{onDisconnect}}();
            }
            $self->{_state} = STATE_DISCONNECTED;
        }
        $self->{_inbuffer} .= $buff;
    }
    return $rv;
}

sub _write {
    my $self = shift;
    my $rv;
    if ($self->{_state} == STATE_CONNECTING) {
        # we're connecting... state will be checked in _parse()
    } elsif ($self->{_state} == STATE_DISCONNECTED) {
        # we're disconnected and can't write
    } elsif (length($self->{_outbuffer}) && $self->{_select}->can_write(0.1)) {
        $rv = $self->{_socket}->write($self->{_outbuffer}, length($self->{_outbuffer}));
        if (!defined $rv) {
            $self->{_select}->remove($self->{_socket});
            if ($self->{_callback}{onDisconnect}) {
                &{$self->{_callback}{onDisconnect}}();
            }
            $self->{_state} = STATE_DISCONNECTED;
        }
        $self->{_outbuffer} = '';
    } elsif (!length($self->{_outbuffer})) {
        $rv = 0;
    }
    return $rv;
}

sub _parse {
    my $self = shift;
    # parsing
    if ($self->{_state} == STATE_DISCONNECTED) {
        printf("Connecting to %s:%i...\n", $self->{_Host}, $self->{_Port});
        $self->_connect;
    } elsif ($self->{_state} == STATE_CONNECTING) {
        if ($self->{_select}->can_write(1)) {
            if ($self->{_callback}{onConnect}) {
                &{$self->{_callback}{onConnect}}($self->{_socket});
            }
            $self->_login();
        }
    } elsif ($self->{_state} == STATE_PROTO_HANDSHAKE) {
        if ($self->_checkLines(1)) {
            my $line = $self->_getLine;
            if (int($line) > FRN_PROTO_VERSION) {
                warn "Protocol has changed! Client may work improperly!\n";
            }
            $self->{_state} = STATE_LOGIN_PHASE1;
        }
    } elsif ($self->{_state} == STATE_LOGIN_PHASE1 && $self->_checkLines(1)) {
        my $line = $self->_getLine;
        my %result = $self->_parseStruct($line);
        $self->{_SV} = $result{SV};
        $self->{_BN} = $result{BN};
        $self->{_BP} = $result{BP};
        $self->{_KP} = $result{KP};
        if ($self->{_callback}{onLoginPhase1}) {
            &{$self->{_callback}{onLoginPhase1}}($result{AL});
        }
        if ($result{AL} eq FRN_RESULT_OK) {
            if ($self->{_pttKey}) {
                ReadMode('raw');
            }
            $self->{_state} = STATE_LOGIN_PHASE2;
            return;
        } elsif ($result{AL} eq FRN_RESULT_WRONG) {
            warn "Password incorrect!\n";
            $self->{_state} = STATE_ABORT;
            return;
        } elsif ($result{AL} eq FRN_RESULT_NOK) {
            warn "Server has rejected your login!";
            $self->{_state} = STATE_ABORT;
            return;
        } else {
            warn "Unknown authorization error!";
            $self->{_state} = STATE_ABORT;
            return;
        }
    } elsif ($self->{_state} == STATE_LOGIN_PHASE2) {
        $self->_phase2;
        if ($self->{_callback}{onLoginPhase2}) {
            &{$self->{_callback}{onLoginPhase2}}();
        }
        if ($self->{_callback}{onLogin}) {
            &{$self->{_callback}{onLogin}}();
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_MESSAGE_HEADER && $self->_checkLines(1)) {
        $self->{_linesExpected} = $self->_getLine;
        $self->{_state} = STATE_MESSAGE;
    } elsif ($self->{_state} == STATE_MESSAGE && $self->_checkLines($self->{_linesExpected})) {
        my $message = {};
        my $line = $self->_getLine;
        $message->{from} = (grep {$_->{ID} eq $line} @{$self->{_clients}})[0];
        foreach(2..($self->{_linesExpected} - 1)) {
            $message->{text} .= $message->{text} ? "\r\n" : '';
            $message->{text} .= $self->_getLine;
        }
        $message->{type} = $self->_getLine;
        if ($message->{type} eq FRN_MESSAGE_PRIVATE && $self->{_callback}{onPrivateMessage}) {
            &{$self->{_callback}{onPrivateMessage}}($message);
        } elsif ($message->{type} eq FRN_MESSAGE_BROADCAST && $self->{_callback}{onBroadcastMessage}) {
            &{$self->{_callback}{onBroadcastMessage}}($message);
        } elsif ($self->{_callback}{onMessage}) {
            &{$self->{_callback}{onMessage}}($message);
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_CLIENTS_HEADER && $self->_checkLines(1)) {
        @{$self->{_clients}} = ();
        $self->_getBytes(2);
        $self->{_linesExpected} = $self->_getLine;
        $self->{_state} = STATE_CLIENTS;
    } elsif ($self->{_state} == STATE_CLIENTS && $self->_checkLines($self->{_linesExpected})) {
        foreach (1..$self->{_linesExpected}) {
            my $line = $self->_getLine;
            my %client = $self->_parseStruct($line);
            push(@{$self->{_clients}}, \%client);
        }
        if ($self->{_callback}{onClientList}) {
            &{$self->{_callback}{onClientList}}($self->{_clients});
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_NETWORKS_HEADER && $self->_checkLines(1)) {
        @{$self->{_networks}} = ();
        my $line = $self->_getLine;
        $self->{_linesExpected} = $line;
        $self->{_state} = STATE_NETWORKS;
    } elsif ($self->{_state} == STATE_NETWORKS && $self->_checkLines($self->{_linesExpected})) {
        foreach (1..$self->{_linesExpected}) {
            push(@{$self->{_networks}}, $self->_getLine);
        }
        if ($self->{_callback}{onNetworkList}) {
            &{$self->{_callback}{onNetworkList}}($self->{_networks});
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_SND_FRAME_IN && $self->_checkBytes(327)) {
        my $bc = $self->_getBytes(2);
        my $clientIdx = unpack('%n', $bc);
        if ($self->{_callback}{onRX}) {
            &{$self->{_callback}{onRX}}($self->{_clients}[$clientIdx - 1]);
        }
        my $gsmBuffer = $self->_getBytes(325);
        if ($self->{_callback}{onGSM}) {
            my $pcmBuffer = &{$self->{_callback}{onGSM}}($gsmBuffer);
            # do something with $pcmBuffer
        } elsif ($self->{_gsm}) { # perform decoding only if GSM codec installed
            my $pcmBuffer = '';
            for (my $i = 0; $i < 5; $i++) {
                $pcmBuffer .= $self->{_gsm}->decode(substr($gsmBuffer, 0, 65, ''));
            }
            if ($self->{_callback}{onPCM}) {
                &{$self->{_callback}{onPCM}}($pcmBuffer);
            }
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_KEEPALIVE) {
        if ($self->{_callback}{onKeepAlive}) {
            &{$self->{_callback}{onKeepAlive}}();
        }
        $self->{_state} = STATE_PING;
    } elsif ($self->{_state} == STATE_PING) {
        $self->_ping;
        if ($self->{_callback}{onPing}) {
            &{$self->{_callback}{onPing}}();
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_RX) {
        $self->{_rxExFlag} = 1;
        $self->_rx;
        $self->{_state} = STATE_IDLE;
        
        
        
    } elsif ($self->{_state} == STATE_PTT_DOWN) {   # when the EA detects PTT down
        $self->{_ptt} = PTT_DOWN;                   # set PTT state to DOWN
        if ($self->{_callback}{onPTTDown}) {
            &{$self->{_callback}{onPTTDown}}();
        }
        $self->{_state} = STATE_TX_REQUEST;         # set EA state to TX request
        #$self->{_state} = STATE_IDLE;
        
        
        
    } elsif ($self->{_state} == STATE_TX_REQUEST) { # when EA in TX request
        $self->_tx(0);                              # send TX0
        if ($self->{_callback}{onTXRequest}) {
            &{$self->{_callback}{onTXRequest}}();
        }
        $self->{_state} = STATE_IDLE;               # set EA state to IDLE
        
        
        
    } elsif ($self->{_state} == STATE_TX) {         # when EA in TX
        my $pcmBuffer;
        if ($self->{_callback}{onTX}) {
            &{$self->{_callback}{onTX}}();
        }
        my $gsmBuffer;
        if ($self->{_callback}{onGSMTX}) {
            $gsmBuffer = &{$self->{_callback}{onGSMTX}}();
            if ($gsmBuffer) {
                $self->_tx(1);
                $self->_pushBytes($gsmBuffer);
            } else {
                $self->{_ptt} = PTT_UP;
            }
        } elsif ($self->{_gsm}) { # perform encoding only if GSM codec installed
            if ($self->{_callback}{onPCMTX}) {
                my $pcmBuffer = &{$self->{_callback}{onPCMTX}}();
                for (my $i = 0; $i < 5; $i++) {
                    $gsmBuffer .= $self->{_gsm}->encode(substr($pcmBuffer, 0, 640, ''));
                }
                $self->_tx(1);
                $self->_pushBytes($gsmBuffer);
                if ($self->{_callback}{onGSMFeedback}) {
                    &{$self->{_callback}{onGSMFeedback}}($gsmBuffer);
                }
                $gsmBuffer = '';
            } else {
                die "No PCM source. Define onPCMTX() handler.\n";
                $self->{_state} = STATE_PTT_UP;
                return;
            }
        } else {
            warn "No GSM source. Define onGSMTX() handler.\n";
            $self->{_state} = STATE_PTT_UP;
            return;
        }
        my $ptt = $self->_readPTT;
        if (!($ptt & PTT_DOWN) && ($ptt & PTT_CHANGED)) {
            $self->{_state} = STATE_PTT_UP;
            return;
        } elsif ($ptt & PTT_EXIT) {
            $self->{_state} = STATE_ABORT;
            return;
        }



    } elsif ($self->{_state} == STATE_PTT_UP) {
        if ($self->{_callback}{onPTTUp}) {
            &{$self->{_callback}{onPTTUp}}();
        }
        while (ReadKey(-1)) {};
        $self->{_state} = STATE_TX_COMPLETE;
        #$self->{_state} = STATE_IDLE;
        
        
        
    } elsif ($self->{_state} == STATE_TX_COMPLETE) {
        $self->_rx;
        if ($self->{_callback}{onTXComplete}) {
            &{$self->{_callback}{onTXComplete}}();
        }
        $self->{_state} = STATE_IDLE;
        
        
        
    } elsif ($self->{_state} == STATE_TX_APPROVED) {
        my $bc = $self->_getBytes(2);
        my $clientIdx = unpack('%n', $bc);
        if ($self->{_callback}{onTXApprove}) {
            &{$self->{_callback}{onTXApprove}}($self->{_clients}[$clientIdx - 1]);
        }
        $self->{_state} = STATE_TX;
        
        
        
    } elsif ($self->{_state} == STATE_BANLIST_HEADER && $self->_checkLines(1)) {
        @{$self->{_banlist}} = ();
        $self->{_linesExpected} = $self->_getLine;
        $self->{_state} = STATE_BANLIST;
    } elsif ($self->{_state} == STATE_BANLIST) {
        foreach (1..$self->{_linesExpected}) {
            my $line = $self->_getLine;
            my %client = $self->_parseStruct($line);
            push(@{$self->{_banlist}}, \%client);
        }
        if ($self->{_callback}{onBanList}) {
            &{$self->{_callback}{onBanList}}($self->{_banlist});
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_MUTELIST_HEADER && $self->_checkLines(1)) {
        @{$self->{_mutelist}} = ();
        $self->{_linesExpected} = $self->_getLine;
        $self->{_state} = STATE_BANLIST;
    } elsif ($self->{_state} == STATE_MUTELIST) {
        foreach (1..$self->{_linesExpected}) {
            my $line = $self->_getLine;
            my %client = $self->_parseStruct($line);
            push(@{$self->{_clients}}, \%client);
        }
        if ($self->{_callback}{onMuteList}) {
            &{$self->{_callback}{onMuteList}}($self->{_mutelist});
        }
        $self->{_state} = STATE_IDLE;
    } elsif ($self->{_state} == STATE_MESSAGE_INPUT) {
        if ($self->{_callback}{onMessageInput}) {
            ReadMode('normal');
            $self->{_msgbuffer} = &{$self->{_callback}{onMessageInput}}();
            ReadMode('raw');
            $self->{_state} = STATE_MESSAGE_SEND;
        } else {
            warn "No message source. Define onMessageInput() handler.\n";
            $self->{_state} = STATE_IDLE;
        }
    } elsif ($self->{_state} == STATE_MESSAGE_SEND) {
        $self->_sendMessage();
    } elsif ($self->{_state} == STATE_IDLE) {
        if ($self->{_pttKey}) {
            my $ptt = $self->_readPTT;
            if (($ptt & PTT_DOWN) && ($ptt & PTT_CHANGED)) {
                $self->{_state} = STATE_PTT_DOWN;
                return;
            #} elsif (!($ptt & PTT_DOWN) && ($ptt & PTT_CHANGED)) {
            #    $self->{_state} = STATE_PTT_UP;
            #    return;
            } elsif ($ptt & PTT_EXIT) {
                $self->{_state} = STATE_ABORT;
                return;
            } elsif ($ptt & PTT_MSG) {
                $self->{_state} = STATE_MESSAGE_INPUT;
                return;
            }
        }
        if (time() - $self->{_lastKA} > KEEPALIVE_TIMEOUT) {
            $self->{_state} = STATE_PING;
        } elsif (!$self->{_rxExFlag} && scalar(@{$self->{_clients}})) {
            $self->{_state} = STATE_RX;
        } elsif ($self->_checkBytes(1)) {
            $self->_parseMarker;
        }
        if ($self->{_callback}{onIdle}) {
            &{$self->{_callback}{onIdle}}();
        }
    }
}

sub _parseMarker {
    my $self = shift;
    my $char = $self->_getBytes(1);
    my $marker = ord($char);
    if ($marker == MARKER_TX_APPROVE) {
        $self->{_state} = STATE_TX_APPROVED
    } elsif ($marker == MARKER_KEEPALIVE) {
        $self->{_state} = STATE_KEEPALIVE
    } elsif ($marker == MARKER_CLIENTS) {
        $self->{_state} = STATE_CLIENTS_HEADER;
    } elsif ($marker == MARKER_NETWORKS) {
        $self->{_state} = STATE_NETWORKS_HEADER;
    } elsif ($marker == MARKER_MESSAGE) {
        $self->{_state} = STATE_MESSAGE_HEADER;
    } elsif ($marker == MARKER_SOUND) {
        $self->{_state} = STATE_SND_FRAME_IN;
    } elsif ($marker == MARKER_BAN) {
        $self->{_state} = STATE_BANLIST_HEADER;
    } elsif ($marker == MARKER_MUTE) {
        $self->{_state} = STATE_MUTELIST_HEADER;
    } elsif ($marker) {
        die(sprintf('Unknown marker 0x%02X', $marker));
    }
    return $char;
}

sub _init {
    my $self = shift;

    # PTT
    if ($self->{_pttKey}) {
        warn "WARNING: Program is in PTT mode. Keyboard will be captured. Use ESC to exit.\n";
        ReadMode('raw');
    }
    if ($self->{_pttFileName}) {
        $self->_openPTTFile();
    }

    # state
    $self->{_state} = STATE_DISCONNECTED;
}

sub _connect {
    my $self = shift;
    $self->{_socket} = IO::Socket::INET->new(
        PeerAddr  => $self->{_Host},
        PeerPort  => $self->{_Port},
        LocalAddr => $self->{_LocalAddr},
        Proto     => 'tcp',
        Timeout   => 30,
    );
    unless ($self->{_socket}) {
        select(undef, undef, undef, $self->{_reconnectTimeout});
        return undef;
    }
    $self->{_select}->add($self->{_socket});
    $self->{_socket}->blocking(0);
    $self->{_socket}->autoflush(1);
    binmode($self->{_socket});
    
    #state
    $self->{_state} = STATE_CONNECTING;
    
    return $self->{_socket}
}

sub _disconnect {
    my $self = shift;
    $self->{_socket}->shutdown(SHUT_RDWR);
    $self->{_state} = STATE_DISCONNECTED;
}

sub _login {
    my $self = shift;
    $self->{_outbuffer} .= $self->_CT;
    $self->{_state} = STATE_PROTO_HANDSHAKE;
}

sub _phase2 {
    my $self = shift;
    $self->{_KP} =~ /^(\d{2})(\d{2})(\d{2})$/;
    my $X = ($1 + 2) * ($2 + 1) + ($3 + 4) * ($3 + 7);
    $X = '0' x (5 - length($X)) . $X;
    my @X = split(//, $X);
    $X = join('', $X[3], $X[0], $X[2], $X[4], $X[1]);
    $self->_pushLine($X);
}

sub _ping {
    my $self = shift;
    $self->{_lastKA} = time();
    $self->{_outbuffer} .= $self->_P;
}

sub _rx {
    my $self = shift;
    $self->{_outbuffer} .= $self->_RX0;
}

sub _tx {
    my $self = shift;
    my $mode = shift;
    $self->{_outbuffer} .= $mode ? $self->_TX1 : $self->_TX0;
}

sub _message {
    my $self = shift;
    my %args = @_;
    $self->{_outbuffer} .= $self->_TM(%args);
}

sub _status {
    my $self = shift;
    my $status = shift;
    $self->{_outbuffer} .= $self->_ST($status);
}

sub _getBytes {
    my $self   = shift;
    my $nBytes = shift;
    use bytes;
    return substr($self->{_inbuffer}, 0, $nBytes, '');
}

sub _getLine {
    my $self = shift;
    $self->{_inbuffer} =~ s/^(.*)\r\n//g;
    return $1;
}

sub _checkBytes {
    my $self   = shift;
    my $nBytes = shift;
    use bytes;
    return(length($self->{_inbuffer}) >= $nBytes);
}

sub _checkLines {
    my $self   = shift;
    my $nLines = shift;
    return(scalar(@{[$self->{_inbuffer} =~ /\r\n/g]}) >= $nLines);
}

sub _pushLine {
    my $self = shift;
    my $line = shift;
    $self->_pushBytes(sprintf("%s\r\n", $line));
}

sub _pushBytes {
    my $self = shift;
    my $bytes = shift;
    $self->{_outbuffer} .= $bytes;
}

sub _parseStruct {
    my $self = shift;
    my $line = shift;
    my %hash;
    while ($line =~ s/<(\w+)>(.*?)(?:<\/\1>)?(?=<\w+>|$)//) {
        $hash{$1} = $2;
    }
    return %hash;
}

sub _openPTTFile {
    my $self = shift;
    open($self->{_pttFile}, $self->{_pttFileName}) || die $!;
}

sub _closePTTFile {
    my $self = shift;
    close($self->{_pttFile}) if ($self->{_pttFile});
}

sub _readPTT {
    my $self = shift;
    if ($self->{_pttKey}) {
        my $char = undef;

        # get first key from buffer
        no warnings;
        $char = ReadKey(0.1);
        use warnings;
        #while (ReadKey(-1)) {};

        # handle it
        if (defined($char) && $char eq chr(PTT_KEY_EXIT)) {
            $self->{_ptt} = PTT_EXIT;
        } elsif ($self->{_pttKey} && defined($char) && $char eq $self->{_pttKey} && !($self->{_ptt} & PTT_DOWN)) {
            $self->{_ptt} = (PTT_DOWN | PTT_CHANGED);
        } elsif ($self->{_msgKey} && defined($char) && $char eq $self->{_msgKey} && !($self->{_ptt} & PTT_DOWN)) {
            $self->{_ptt} = PTT_MSG;
        #} elsif ($self->{_pttKey} && $char eq $self->{_pttKey} && ($self->{_ptt} & PTT_DOWN)) {
        #    # leave PTT as is
        #    $self->{_ptt} = ($self->{_ptt} & (PTT_CHANGED ^ 0xFF));
        } elsif (!defined($char) && ($self->{_ptt} & PTT_DOWN)) {
            $self->{_ptt} = (PTT_UP | PTT_CHANGED);
        } else {
            return PTT_UP;
        }
        return $self->{_ptt};
    } elsif ($self->{_pttFile}) {
        
    }
}

sub _sendMessage {
    my $self = shift;
    $self->_message(ID => '', MS => $self->{_msgbuffer});
    $self->{_msgbuffer} = '';
    $self->{_state} = STATE_IDLE;
}

# Commands

sub _CT {
    my $self = shift;
    my $CT = sprintf(
        "CT:<VX>%s</VX><EA>%s</EA><PW>%s</PW><ON>%s</ON><BC>%s</BC><DS>%s</DS><NN>%s</NN><CT>%s</CT><NT>%s</NT>\r\n",
        $self->{_VX},
        $self->{_EA},
        $self->{_PW},
        $self->{_ON},
        $self->{_BC},
        $self->{_DS},
        $self->{_NN},
        $self->{_CT},
        $self->{_NT}
    );
    return $CT;
}

sub _P {
    my $self = shift;
    return "P\r\n";
}

sub _RX0 {
    my $self = shift;
    return "RX0\r\n";
}

sub _TX0 {
    my $self = shift;
    return "TX0\r\n";
}

sub _TX1 {
    my $self = shift;
    return "TX1\r\n"
}

sub _TM {
    my $self = shift;
    my %args = @_;
    do {
        use bytes;
        $args{MS} .= length($args{MS}) % 2 ? '' : chr(0x00);
    };
    my $TM = sprintf("TM:<ID>%s</ID><MS>%s</MS>\r\n", $args{ID} || '', $args{MS} || '');
    return $TM;
}

sub _ST {
    my $self = shift;
    my $status = shift;
    my $ST = sprintf("ST:%i\r\n", $status);
    return $ST;
}

sub _MC {
    my $self = shift;
    my $ip   = shift;
    my $MC = sprintf("MC:<IP>%s</IP>\r\n", $ip);
    return $MC;
}

sub _UM {
    my $self = shift;
    my $ip   = shift;
    my $UM = sprintf("UM:<IP>%s</IP>\r\n", $ip);
    return $UM;
}

sub _BC {
    my $self = shift;
    my $ip   = shift;
    my $BC = sprintf("BC:<IP>%s</IP>\r\n", $ip);
    return $BC;
}

sub _UC {
    my $self = shift;
    my $ip   = shift;
    my $UC = sprintf("UC:<IP>%s</IP>\r\n", $ip);
    return $UC;
}

1;
