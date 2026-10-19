package Peta::Synth::Server;
# ABSTRACT: the synthesizer behind a web page

# The synthesizer behind a web page: one process, one loop (Mojolicious's
# server and event loop, on EV where there is EV). It serves the page, talks
# to it over a WebSocket (JSON for control, binary frames of sound), and
# renders the synth just ahead of what the browsers have played.
#
# The clock is the listener's: a browser that plays the sound says how many
# frames it has played; the server keeps every listener `ahead` seconds in
# front of that and renders nothing while nobody listens.
#
# Messages from the page (JSON, by 'type'):
#
#   hello                                   -> init
#   note {channel key velocity on}          a key pressed or let go
#   cc {channel number value}  bend {channel value}
#   program {channel program bank}          a bank (GS's) selected first, if given
#   midi {data}                             a device's message, its bytes (Web MIDI)
#   mute {channel on}
#   patch_get {kind number bank}            -> patch    (kind: program or drum; bank: a
#                                           program's variation, by GS bank, or a drum's kit)
#   patch_set {kind number field value}     changes a field, for the next notes; formants,
#                                           partials and mods take lists (partials null:
#                                           the harmonic series)
#   patch_reset {kind number bank}          -> patch
#   reverb {name value}                     time size damp level predelay on
#   eq {band what value}                    the master equalizer: band low mid1 mid2 high,
#                                           what freq gain q
#   channel_eq {channel band what value}    a channel's equalizer, the same bands
#   arp {channel name value}                a channel's arpeggiator: on mode rate tempo
#                                           octaves gate swing latch
#   let_go {channel what}                   a setting held against the file let go (what:
#                                           program, cc 7, arp mode ...; none: all the channel's)
#   synth {name value}                      partials voices gain auto fidelity (low mid high)
#   play {file position}                    a file from the start, or from a position (seconds)
#   pause {on}  seek {position}  stop  panic
#   reset                                   all as the server started, the instruments
#                                           as changed -> init (to every page)
#   files                                   -> files
#   record {on}                             what is played live into a MIDI file -> recorded
#   bank_save                               -> saved
#   audio {on}                              the page plays the sound (or not)
#   played {frames}                         how much it has played
#
# To the page: init, state (five times a second), patch, files, saved,
# recorded, error, and binary frames: interleaved stereo 32-bit floats.

use v5.36;
use Mojolicious;
use Mojo::Server::Daemon;
use Mojo::IOLoop;
use JSON::PP;
use Scalar::Util qw(weaken);
use File::Basename qw(dirname basename);
use File::Spec;
use Encode qw(encode decode);
use POSIX qw(strftime);
use Time::HiRes qw(time);
use Peta::Synth::Synth;
use Peta::Synth::MIDI;
use Peta::Synth::Engine;
use Peta::Synth::Patch;
use Peta::Synth::EQ;
use Peta::Synth::Output;

our $VERSION = '0.2610180';

my $MAX_UPLOAD  = 4 * 1024 * 1024;
my $MAX_BACKLOG = 2 * 1024 * 1024;    # bytes queued for a client before its sound is dropped
my $MIDI_FILE   = qr/\.(?:mid|midi|kar|rmi)\z/i;
my $NUMBER      = qr/\A\s*-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*\z/;

# The reverb's settings, each with its range.
my %REVERB = (
    time     => [ 0.1, 20 ],
    size     => [ 0.2, 3 ],
    damp     => [ 0,   0.95 ],
    level    => [ 0,   2 ],
    predelay => [ 0,   0.2 ],
    on       => [ 0,   1 ],
);

# The lists of rows: the most rows, and each column's range. Formants are
# [centre Hz, gain, width in octaves]; partials [ratio, amplitude, decay factor].
my %LIST = (
    formants => [ 8,  [ 20, 20000 ], [ -1, 10 ], [ 0.05, 4 ] ],
    partials => [ 64, [ 0.05, 64 ],  [ 0, 1 ],   [ 0, 20 ] ],
);

sub new ($class, %arg) {
    my $rate     = $arg{rate}     // 48000;
    my $partials = $arg{partials} // 48;
    my $self     = bless {
        host      => $arg{host}     // '127.0.0.1',
        port      => $arg{port}     // 8360,
        rate      => $rate,
        quantum   => $arg{quantum}  // 512,
        ahead     => $arg{ahead}    // 0.12,
        midi_dir  => $arg{midi_dir} // '.',
        bank      => $arg{bank},
        partials  => $partials,
        auto      => $arg{auto}     // 1,
        fidelity  => $arg{fidelity} // 'mid',
        log       => $arg{log}      // sub ($line) { say STDERR $line },
        web_dir   => File::Spec->catdir(dirname(__FILE__), 'Server', 'web'),
        clients   => {},
        json      => JSON::PP->new->canonical->allow_nonref,
        playing   => undef,
        recording => undef,
    }, $class;

    if (defined $arg{in}) {
        # MIDI as it is played, besides the page's (see Peta::Synth::Input).
        require Peta::Synth::Input;
        $self->{input} = Peta::Synth::Input->open($arg{in});
    }
    my $engine = Peta::Synth::Engine::create($arg{engine} // 'auto', rate => $rate, partials => $partials);
    $self->{start} = { partials => $partials, auto => $self->{auto} };    # what Reset comes back to
    $self->{synth} = $self->_new_synth(undef, engine => $engine);
    $self->{log}->("instrument changes loaded from $self->{bank}") if $self->{bank} && -e $self->{bank};
    return $self;
}

# The synthesizer as the server starts it: the bank's settings, and its
# instruments' changes unless others are given (as edits has them); %arg:
# the engine, waves.
sub _new_synth ($self, $instruments, %arg) {
    my $bank = $self->_bank // {};
    $instruments //= $bank;
    my $synth = Peta::Synth::Synth->new(rate => $self->{rate}, partials => $self->{start}{partials}, fidelity => $self->{fidelity}, %arg);
    $synth->apply_edits({ master => $bank->{master}, programs => $instruments->{programs}, drums => $instruments->{drums} });
    return $synth;
}

# The bank file's changes, if there is one.
sub _bank ($self) { return $self->{bank} && -e $self->{bank} ? $self->_read_json($self->{bank}) : undef }

sub synth ($self) { return $self->{synth} }

sub url ($self) { return "http://$self->{host}:$self->{port}/" }

sub run ($self) {
    my $loop   = Mojo::IOLoop->singleton;
    my $daemon = Mojo::Server::Daemon->new(app => $self->_app, listen => ["http://$self->{host}:$self->{port}"], silent => 1);
    eval { $daemon->start; 1 }
        or die "cannot listen on $self->{host}:$self->{port}: " . ($@ =~ s/^Can't create listen socket: //r =~ s/ at \S+ line \d+.*//sr) . "\n";
    $self->{log}->('Peta::Synth on ' . $self->url . ' (engine ' . $self->{synth}->engine->name . ')');

    my $in = $self->{input};
    if ($in) {
        $loop->reactor->io($in->handle => sub { $self->_live($_) for $in->events })->watch($in->handle, 1, 0);
        my @from = $in->connected;
        $self->{log}->('MIDI in at ' . $in->address . (@from ? ' from ' . join(', ', @from) : ''));
    }

    # Render while the listeners are less than 'ahead' in front, a few quanta at a time.
    my @timers = (
        $loop->recurring(0.005 => sub {
            for (1 .. 4) {
                last unless $self->_behind;
                $self->_render;
            }
        }),
        $loop->recurring(0.2 => sub { $self->_broadcast_state }),
    );
    $loop->start unless $self->{quit};

    $loop->remove($_) for @timers;
    $loop->reactor->remove($in->handle) if $in;
    $daemon->stop;
    return;
}

sub stop ($self) {
    $self->{quit} = 1;
    Mojo::IOLoop->stop;
    return;
}

# The listeners furthest behind: true when one has less than 'ahead' queued.
sub _behind ($self) {
    my $target = $self->{ahead} * $self->{rate};
    for my $client (values %{ $self->{clients} }) {
        next unless $client->{audio};
        return 1 if $client->{sent} - $client->{played} < $target;
    }
    return 0;
}

# A quantum rendered and sent to every listener.
sub _render ($self) {
    my $synth   = $self->{synth};
    my $n       = $self->{quantum};
    my $started = time;
    my ($left, $right) = $synth->render_arrays($n);
    my $took  = time - $started;
    my $sound = pack 'f<*', @{ Peta::Synth::Output::interleave($left, $right) };

    for my $client (values %{ $self->{clients} }) {
        next unless $client->{audio};
        $client->{sent} += $n;
        if ($client->{stream}->bytes_waiting > $MAX_BACKLOG) {
            $client->{played} += $n;    # it cannot take more: what is dropped counts as played
            next;
        }
        $client->{tx}->send({ binary => $sound });
    }

    $synth->account($took, $n);
    $synth->adapt($self->{partials}) if $self->{auto};
    my $playing = $self->{playing};
    $self->{playing} = undef if $playing && !defined $playing->{paused} && !$synth->pending && !$synth->active;
    return;
}

# The page's files (looked at again by the browser each time: they are
# small, and a new version shows at once), uploads of MIDI files, the
# WebSocket.
sub _app ($self) {
    my $app = Mojolicious->new(mode => 'production');
    $app->log->level('error');
    $app->log->unsubscribe('message')->on(message => sub ($log, $level, @lines) { $self->{log}->("@lines") });
    $app->static->paths([ $self->{web_dir} ]);
    $app->max_request_size($MAX_UPLOAD);
    $app->hook(after_dispatch => sub ($c) { $c->res->headers->cache_control('no-cache') });

    my $r = $app->routes;
    $r->get('/' => sub ($c) { $c->reply->static('index.html') });
    $r->post('/upload' => sub ($c) { $self->_upload($c) });
    $r->websocket('/ws' => sub ($c) { $self->_connect($c) });
    return $app;
}

# A MIDI file sent from the page, saved into the MIDI directory.
sub _upload ($self, $c) {
    return $c->render(status => 413, text => "too large\n") if $c->req->is_limit_exceeded;
    my $name = basename($c->req->url->query->param('name') // '');
    return $c->render(status => 400, text => "'$name': a MIDI file's name is needed (.mid, .midi, .kar, .rmi; not hidden)\n")
        unless $name =~ /\A[^.\x00-\x1f\\][^\x00-\x1f\\]*$MIDI_FILE/;
    my $body = $c->req->body;
    return $c->render(status => 400, text => "not a MIDI file\n")
        unless eval { Peta::Synth::MIDI->parse($body); 1 };

    my $file = $self->_midi_path($name);
    open my $out, '>:raw', $file or return $c->render(status => 500, text => "cannot save: $!\n");
    print {$out} $body;
    close $out;
    $self->{log}->("uploaded $name");
    $c->render(json => { saved => $name });
    $self->_broadcast({ type => 'files', files => $self->_files });
    return;
}

# A page connected: its messages are JSON for _message.
sub _connect ($self, $c) {
    my $id     = $c->tx->connection;
    my $client = $self->{clients}{$id} = {
        tx     => $c->tx,
        stream => Mojo::IOLoop->stream($id),
        audio  => 0,    # it plays the sound
        sent   => 0,    # frames sent
        played => 0,    # frames it says it has played
    };
    weaken $client->{$_} for qw(tx stream);

    $c->on(message => sub ($c, $text) {
        my $data = eval { $self->{json}->decode($text) };
        return unless ref $data eq 'HASH';
        eval { $self->_message($client, $data); 1 }
            or $self->_reply($client, { type => 'error', message => "$@" =~ s/\s+\z//r });
    });
    $c->on(finish => sub { delete $self->{clients}{$id} });
    return;
}

sub _reply ($self, $client, $data) {
    $client->{tx}->send($self->{json}->encode($data));
    return;
}

sub _broadcast ($self, $data, $except = undef) {
    my $text = $self->{json}->encode($data);
    for my $client (values %{ $self->{clients} }) {
        next if $except && $client == $except;
        $client->{tx}->send($text);
    }
    return;
}

# What the page asks for: a sub for each type of message, called with
# ($self, the client, the message).

my %MESSAGE = (
    hello       => \&_hello,
    played      => \&_played,
    audio       => \&_audio,
    note        => \&_note,
    cc          => \&_cc,
    program     => \&_program,
    bend        => \&_bend,
    midi        => \&_midi,
    mute        => \&_mute,
    patch_get   => \&_patch_get,
    patch_set   => \&_patch_set,
    patch_reset => \&_patch_reset,
    reverb      => \&_reverb,
    eq          => \&_eq,
    channel_eq  => \&_channel_eq,
    arp         => \&_arp,
    let_go      => \&_let_go,
    synth       => \&_synth,
    files       => \&_list_files,
    play        => \&_play,
    pause       => \&_pause,
    seek        => \&_seek,
    stop        => \&_stop,
    record      => \&_record,
    panic       => \&_panic,
    reset       => \&_reset,
    bank_save   => \&_bank_save,
);

sub _message ($self, $client, $m) {
    my $type    = $m->{type} // '';
    my $handler = $MESSAGE{$type} or die "unknown message '$type'\n";
    $self->$handler($client, $m);
    return;
}

sub _hello ($self, $client, $m) {
    $self->_reply($client, $self->_init);
    return;
}

sub _played ($self, $client, $m) {
    my $frames = $m->{frames};
    $client->{played} = $frames if defined $frames && $frames =~ /\A\d+\z/ && $frames > $client->{played};
    return;
}

sub _audio ($self, $client, $m) {
    $client->{audio}  = $m->{on} ? 1 : 0;
    $client->{sent}   = 0;
    $client->{played} = 0;
    return;
}

# What is played live: the page's keys and controls, a device's MIDI; what
# it sets is held against the file (see Peta::Synth::Synth::by_hand).
sub _live ($self, $event) {
    $self->{synth}->by_hand($event);
    push @{ $self->{recording}{events} }, [ time - $self->{recording}{started}, $event ] if $self->{recording};
    return;
}

sub _note ($self, $client, $m) {
    $self->_live({
        type     => $m->{on} ? 'note_on' : 'note_off',
        channel  => _channel($m),
        key      => _clamp($m->{key}, 0, 127),
        velocity => _clamp($m->{velocity} // 100, 1, 127),
    });
    return;
}

sub _cc ($self, $client, $m) {
    $self->_live({
        type    => 'controller',
        channel => _channel($m),
        number  => _clamp($m->{number}, 0, 127),
        value   => _clamp($m->{value},  0, 127),
    });
    return;
}

sub _program ($self, $client, $m) {
    my $channel = _channel($m);
    if (defined $m->{bank}) {
        $self->_live({ type => 'controller', channel => $channel, number => 0,  value => _clamp($m->{bank}, 0, 127) });
        $self->_live({ type => 'controller', channel => $channel, number => 32, value => 0 });
    }
    $self->_live({ type => 'program', channel => $channel, program => _clamp($m->{program}, 0, 127) });
    return;
}

sub _bend ($self, $client, $m) {
    $self->_live({ type => 'pitch_bend', channel => _channel($m), value => _clamp($m->{value}, -8192, 8191) });
    return;
}

# A device's message as the page's Web MIDI passed it: bytes.
sub _midi ($self, $client, $m) {
    my $data = $m->{data};
    die "midi: a list of at most 1024 bytes\n" if ref $data ne 'ARRAY' || @$data > 1024;

    my $event = Peta::Synth::MIDI::message(pack 'C*', map { _clamp($_, 0, 255) } @$data);
    $self->_live($event) if $event;
    return;
}

sub _mute ($self, $client, $m) {
    $self->{synth}->channel(_channel($m))->{mute} = $m->{on} ? 1 : 0;
    return;
}

sub _patch_get ($self, $client, $m) {
    $self->_reply($client, $self->_patch_message(_patch_id($m)));
    return;
}

# A patch as it was at the start; every page is told.
sub _patch_reset ($self, $client, $m) {
    my @id = _patch_id($m);
    $self->{synth}->restore_patch(@id);
    $self->_broadcast($self->_patch_message(@id));
    return;
}

# A field of a patch set, for the notes that start from now on; the other
# pages are told.
sub _patch_set ($self, $client, $m) {
    my ($kind, $number, $bank) = _patch_id($m);
    my $name  = $m->{field} // '';
    my $value = $name eq 'mods' ? _mods($m->{value})
              : $LIST{$name}    ? _rows($name, $m->{value})
              :                   _field_value($name, $m->{value});
    $self->_patch($kind, $number, $bank)->{$name} = $value;

    my $change = { type => 'patch_field', kind => $kind, number => $number, bank => $bank, field => $name, value => $value };
    $self->_broadcast($change, $client);
    return;
}

sub _reverb ($self, $client, $m) {
    my $name  = $m->{name} // '';
    my $range = $REVERB{$name} or die "the reverb has no '$name'\n";
    $self->{synth}->reverb->set($name => _clamp($m->{value}, @$range));
    return;
}

sub _eq ($self, $client, $m) {
    $self->{synth}->eq->set(_eq_setting($m));
    return;
}

sub _channel_eq ($self, $client, $m) {
    $self->{synth}->set_channel_eq(int _channel($m), _eq_setting($m));
    return;
}

# A setting of a channel's arpeggiator, kept to what it may be; held against
# the file.
sub _arp ($self, $client, $m) {
    my $channel = int _channel($m);
    my $name    = $m->{name} // '';
    my ($field) = grep { $_->{name} eq $name } @{ Peta::Synth::Arpeggiator::field_info() };
    die "the arpeggiator has no '$name'\n" unless $field;

    my $value = $m->{value};
    if ($field->{scale} eq 'choice') {
        die "'" . ($value // '') . "' is not one of @{ $field->{choices} }\n" unless grep { $_ eq ($value // '') } @{ $field->{choices} };
    }
    else {
        $value = _clamp($value, $field->{min}, $field->{max});
        $value = int($value + 0.5) if $field->{scale} eq 'int';
    }
    $self->{synth}->by_hand({ type => 'arp', channel => $channel, name => $name, value => $value });
    return;
}

# A setting held against the file let go, or all of a channel's: as the file has it.
sub _let_go ($self, $client, $m) {
    my $channel = int _channel($m);
    my $what    = $m->{what};
    die "channel $channel does not hold '$what'\n" if defined $what && !grep { $_ eq $what } @{ $self->{synth}->held($channel) };
    $self->{synth}->let_go($channel, $what);
    return;
}

sub _synth ($self, $client, $m) {
    my $synth = $self->{synth};
    my $name  = $m->{name} // '';
    my $value = $m->{value};

    if ($name eq 'partials') {
        $self->{partials} = _clamp(int $value, 1, 256);
        $synth->set(partials => $self->{partials});
    }
    elsif ($name eq 'voices') {
        $synth->set(voices => _clamp(int $value, 1, 1024));
    }
    elsif ($name eq 'gain') {
        $synth->set(gain => _clamp($value, 0, 2));
    }
    elsif ($name eq 'fidelity') {
        $synth->set(fidelity => $value // '');
    }
    elsif ($name eq 'auto') {
        # Off, the partials it took away are given back.
        $self->{auto} = $value ? 1 : 0;
        $synth->set(partials => $self->{partials}) unless $self->{auto};
    }
    else {
        die "cannot set '$name'\n";
    }
    return;
}

sub _list_files ($self, $client, $m) {
    $self->_reply($client, { type => 'files', files => $self->_files });
    return;
}

use constant LEAD => 0.05;    # seconds before a file's first event: time to render it

# A file from the MIDI directory, played from its start or from a
# position (seconds); what played before stops.
sub _play ($self, $client, $m) {
    my $name = basename($m->{file} // '');
    my $file = $self->_midi_path($name);
    die "no such file: $name\n" unless -f $file;

    my $timeline = _instruments_first(Peta::Synth::MIDI->read($file)->timeline);
    $self->{synth}->forget_held if ($self->{last_file} // '') ne $name;    # held against that file, not this one
    $self->{last_file} = $name;
    $self->{playing}   = {
        file     => $name,
        timeline => $timeline,
        length   => @$timeline ? $timeline->[-1]{time} : 0,
    };
    $self->_play_from(_clamp($m->{position} // 0, 0, $self->{playing}{length}));
    return;
}

# The file with each channel's instrument chosen from its start, so that
# the page shows what the file plays before it is heard: the bank selects
# and program changes that come before a channel's first note are moved to
# the start, or to the system exclusive message last before them (a reset
# there would undo them). No note of the channel sounds before them, so
# nothing sounds otherwise.
sub _instruments_first ($timeline) {
    my ($from, $moved, %sounded) = (0, 0);
    my @events;
    for my $event (@$timeline) {
        my ($type, $c) = @$event{qw(type channel)};
        $from = $event->{time} if $type eq 'sysex';
        $sounded{$c} = 1       if $type eq 'note_on';
        my $sets = $type eq 'program' || $type eq 'controller' && ($event->{number} == 0 || $event->{number} == 32);
        if ($sets && !$sounded{$c} && $event->{time} > $from) {
            push @events, { %$event, time => $from };
            $moved++;
            next;
        }
        push @events, $event;
    }
    return $timeline if !$moved;
    return [ sort { $a->{time} <=> $b->{time} } @events ];    # sort is stable: the order kept
}

# The file playing on from $position seconds: what sounds is silenced, the
# channels are as the file has them there.
sub _play_from ($self, $position) {
    my $synth   = $self->{synth};
    my $playing = $self->{playing};
    $synth->panic;
    $synth->reset_channels;
    $synth->schedule($playing->{timeline}, LEAD, $position);
    $playing->{start}  = $synth->now + (LEAD - $position) * $self->{rate};
    $playing->{from}   = $position;
    $playing->{paused} = undef;
    $self->_broadcast_channels;
    return;
}

# Where the file is (seconds): as far as it is rendered (where it was played
# from, during the lead before it), or where it is paused.
sub _position ($self) {
    my $playing = $self->{playing};
    return $playing->{paused} if defined $playing->{paused};
    my $position = ($self->{synth}->now - $playing->{start}) / $self->{rate};
    return $position < $playing->{from} ? $playing->{from} : $position;
}

# Paused, the file holds where it is and what sounds is let go; it goes on
# from there, or from where it was sought to meanwhile.
sub _pause ($self, $client, $m) {
    my $playing = $self->{playing} or return;
    if (!$m->{on}) {
        $self->_play_from($playing->{paused}) if defined $playing->{paused};
        return;
    }
    return if defined $playing->{paused};
    $playing->{paused} = $self->_position;
    $self->{synth}->stop;
    return;
}

sub _seek ($self, $client, $m) {
    my $playing  = $self->{playing} or return;
    my $position = _clamp($m->{position}, 0, $playing->{length});
    if (defined $playing->{paused}) {
        $playing->{paused} = $position;
        return;
    }
    $self->_play_from($position);
    return;
}

sub _stop ($self, $client, $m) {
    $self->{synth}->stop;
    $self->{playing} = undef;
    return;
}

sub _panic ($self, $client, $m) {
    $self->{synth}->panic;
    $self->{playing} = undef;
    return;
}

# Everything as the server started it (the channels, the mixer, the
# effects, the arpeggiators, the bank's settings again), but the instruments
# as they have been changed; the file stopped; every page told.
sub _reset ($self, $client, $m) {
    my $old = $self->{synth};
    $old->panic;
    $self->{synth} = $self->_new_synth($old->edits, engine => $old->engine, waves => $old->waves // 0);
    $self->{$_} = $self->{start}{$_} for qw(partials auto);
    $self->{playing} = undef;
    $self->_broadcast($self->_init);
    return;
}

# Recording: what is played live (see _live), at the times it comes, into
# a MIDI file in the MIDI directory; a file's events are not recorded.
sub _record ($self, $client, $m) {
    if ($m->{on}) {
        $self->{recording} //= { started => time, events => [], setup => [ map { [ $self->_channel_setup($_) ] } 0 .. 15 ] };
        return;
    }
    my $recording = delete $self->{recording} or return;
    my $name      = $self->_save_recording($recording);
    $self->{log}->("recorded $name");
    $self->_reply($client, { type => 'recorded', file => $name });
    $self->_broadcast({ type => 'files', files => $self->_files });
    return;
}

use constant TICKS => 960;    # ticks a second: 480 a quarter note at 120 a minute

# The recording as a file of one track: the channels it plays set up as
# they were when it began, then what was played. Keys and pedals still held
# when it stops are let go there.
sub _save_recording ($self, $recording) {
    my $events = $recording->{events};
    die "nothing was played: no recording saved\n" unless grep { $_->[1]{type} eq 'note_on' } @$events;

    my %used  = map { defined $_->[1]{channel} ? ($_->[1]{channel} => 1) : () } @$events;
    my @track = ({ tick => 0, type => 'tempo', usec => 500_000 }, map { @{ $recording->{setup}[$_] } } sort { $a <=> $b } keys %used);
    my (%held, %pedal);
    for (@$events) {
        my ($time, $event) = @$_;
        push @track, { %$event, tick => int($time * TICKS + 0.5) };
        my ($type, $c) = @$event{qw(type channel)};
        if    ($type eq 'note_on')  { $held{$c}{ $event->{key} }++ }
        elsif ($type eq 'note_off') { delete $held{$c}{ $event->{key} } if $held{$c}{ $event->{key} } && !--$held{$c}{ $event->{key} } }
        elsif ($type eq 'controller' && $event->{number} >= 64 && $event->{number} <= 67) {
            $pedal{$c}{ $event->{number} } = $event->{value};
        }
    }

    my $end = int((time - $recording->{started}) * TICKS + 0.5);
    for my $c (sort { $a <=> $b } keys %held) {
        push @track, map { +{ tick => $end, type => 'note_off', channel => $c, key => $_, velocity => 64 } } sort { $a <=> $b } keys %{ $held{$c} };
    }
    for my $c (sort { $a <=> $b } keys %pedal) {
        my $down = $pedal{$c};
        push @track, map { +{ tick => $end, type => 'controller', channel => $c, number => $_, value => 0 } } grep { $down->{$_} >= 64 } sort { $a <=> $b } keys %$down;
    }

    my $stamp = strftime('recording-%Y%m%d-%H%M%S', localtime $recording->{started});
    my ($name, $more) = ("$stamp.mid", 1);
    $name = "$stamp-" . ++$more . '.mid' while -e $self->_midi_path($name);
    Peta::Synth::MIDI->new(format => 0, division => TICKS / 2, tracks => [ \@track ])->write($self->_midi_path($name));
    return $name;
}

# A channel as it is: its bank (its variation, or drums), program,
# volume, pan, expression, reverb and chorus, as events at the start of a
# file.
sub _channel_setup ($self, $n) {
    my $c    = $self->{synth}->channel($n);
    my $bank = $c->{drum} != ($n == 9 ? 1 : 0) ? ($c->{drum} ? 120 : 121)
             : $c->{drum}                       ? 0
             :                                    $c->{variation};
    my @cc = ([ 7 => $c->{volume} ], [ 10 => $c->{pan} ], [ 11 => $c->{expression} ], [ 91 => $c->{send} ], [ 93 => $c->{chorus} ]);
    unshift @cc, [ 0 => $bank ] if $bank;
    return (
        (map { +{ tick => 0, type => 'controller', channel => $n, number => $_->[0], value => $_->[1] } } @cc),
        { tick => 0, type => 'program', channel => $n, program => $c->{program} },
    );
}

sub _bank_save ($self, $client, $m) {
    die "the server was started without a bank file (--bank)\n" unless $self->{bank};
    $self->_write_json($self->{bank}, $self->{synth}->edits);
    $self->_reply($client, { type => 'saved', file => $self->{bank} });
    return;
}

# What the page sends, held to what it may be.

sub _clamp ($value, $low, $high) {
    $value = 0 unless defined $value && $value =~ $NUMBER;
    return $low  if $value < $low;
    return $high if $value > $high;
    return 0 + $value;
}

sub _channel ($m) { return _clamp($m->{channel} // 0, 0, 15) }

# (kind, number, bank): a program, the piano unless told, and its variation
# (by GS bank; 0 where there is none); or a drum, the bass drum unless told,
# and the kit whose patch it is in the kit asked for (the standard kit's,
# 0, where the kit does not have the key as its own).
sub _patch_id ($m) {
    my $kind   = ($m->{kind} // '') eq 'drum' ? 'drum' : 'program';
    my $number = _clamp(int($m->{number} // ($kind eq 'drum' ? 36 : 0)), 0, 127);
    my $bank   = _clamp(int($m->{bank} // 0), 0, 127);
    $bank = $kind eq 'drum' ? Peta::Synth::Patch::kit_key(Peta::Synth::Patch::kit($bank), $number)
          :                   Peta::Synth::Patch::variation($bank, 0, $number);
    return ($kind, $number, $bank);
}

# A plain field's value: one of its choices, or a number in its range.
sub _field_value ($name, $value) {
    my ($field) = grep { $_->{name} eq $name } @{ Peta::Synth::Patch::field_info() };
    die "no field '$name' can be set\n" unless $field;

    if ($field->{scale} eq 'choice') {
        die "'$value' is not one of @{ $field->{choices} }\n" unless grep { $_ eq ($value // '') } @{ $field->{choices} };
        return $value;
    }
    $value = _clamp($value, $field->{min}, $field->{max});
    return $field->{scale} eq 'int' ? int($value + 0.5) : $value;
}

# Formants or partials. No rows: no formants; partials undef, the harmonic series.
sub _rows ($name, $value) {
    my ($most, @range) = @{ $LIST{$name} };
    if (ref $value ne 'ARRAY' || !@$value) {
        return $name eq 'partials' ? undef : [];
    }
    die "$name: at most $most\n" if @$value > $most;

    my @rows;
    for my $row (@$value) {
        die "$name: each a list of three numbers\n" if ref $row ne 'ARRAY' || @$row != 3;
        push @rows, [ map { _clamp($row->[$_], @{ $range[$_] }) } 0 .. 2 ];
    }
    return \@rows;
}

# Modulation routes: at most 16 of [source, destination, amount], the amount
# held to -24 .. 24.
sub _mods ($value) {
    return [] if ref $value ne 'ARRAY';
    die "mods: at most 16\n" if @$value > 16;

    my %source      = map { $_ => 1 } @{ Peta::Synth::Patch::mod_sources() };
    my %destination = map { $_ => 1 } @{ Peta::Synth::Patch::mod_destinations() };
    my @routes;
    for my $row (@$value) {
        die "mods: each a list of source, destination, amount\n" if ref $row ne 'ARRAY' || @$row != 3;
        my ($from, $to, $amount) = @$row;
        die "mods: no source '$from'\n"    unless $source{ $from // '' };
        die "mods: no destination '$to'\n" unless $destination{ $to // '' };
        push @routes, [ $from, $to, _clamp($amount, -24, 24) ];
    }
    return \@routes;
}

sub _eq_setting ($m) {
    my ($band, $what) = ($m->{band} // '', $m->{what} // '');
    die "the equalizer has no band '$band'\n" unless grep { $_ eq $band } Peta::Synth::EQ::names();
    die "an equalizer band has no '$what'\n"  unless $what =~ /\A(?:freq|gain|q)\z/;
    return ($band => { $what => _clamp($m->{value}, -1e6, 1e6) });
}

# What the page is told.

sub _patch ($self, $kind, $number, $bank) {
    my $synth = $self->{synth};
    return $kind eq 'drum' ? $synth->drum_patch($number, $bank) : $synth->program_patch($number, $bank);
}

# A patch as it is, and its fields as they were at the start.
sub _patch_message ($self, $kind, $number, $bank) {
    my $drum  = $kind eq 'drum';
    my $patch = $self->_patch($kind, $number, $bank);
    my $base  = $drum ? Peta::Synth::Patch::drum($number, $bank) : Peta::Synth::Patch::program($number, $bank);
    my @names = map { $_->{name} } @{ Peta::Synth::Patch::field_info() };
    return {
        type     => 'patch',
        kind     => $kind,
        number   => $number,
        bank     => $bank,
        name     => $drum ? Peta::Synth::Patch::kit_name($bank) . ' kit: ' . Peta::Synth::Patch::drum_name($number)
                  :         Peta::Synth::Patch::program_name($number, $bank),
        partials => $patch->{partials},
        formants => $patch->{formants},
        mods     => $patch->{mods},
        fields   => { map { $_ => $patch->{$_} } @names },
        defaults => { map { $_ => $base->{$_} } @names },
    };
}

# The MIDI files of the directory, their names as text (UTF-8 on the disk).
sub _files ($self) {
    opendir my $dh, $self->{midi_dir} or return [];
    my @files = map { decode('UTF-8', $_) } grep { /$MIDI_FILE/ && -f File::Spec->catfile($self->{midi_dir}, $_) } readdir $dh;
    closedir $dh;
    return [ sort { lc $a cmp lc $b } @files ];
}

# Where a MIDI file of the directory is, by its name (text).
sub _midi_path ($self, $name) { return File::Spec->catfile($self->{midi_dir}, encode('UTF-8', $name)) }

sub _init ($self) {
    my $synth = $self->{synth};
    return {
        type       => 'init',
        rate       => $self->{rate},
        quantum    => $self->{quantum},
        engine     => $synth->engine->name,
        perl       => Peta::Synth::Engine::perl_info(),
        programs   => Peta::Synth::Patch::program_names(),
        variations => Peta::Synth::Patch::variations(),
        drums      => Peta::Synth::Patch::drum_names(),
        kits       => Peta::Synth::Patch::kits(),
        fields     => Peta::Synth::Patch::field_info(),
        mod        => Peta::Synth::Patch::mod_info(),
        files      => $self->_files,
        reverb     => $synth->reverb->params,
        eq         => $synth->eq->params,
        channel_eq => [ map { $synth->channel_eq($_)->params } 0 .. 15 ],
        arp        => { fields => Peta::Synth::Arpeggiator::field_info(), channels => [ map { $synth->arpeggiator($_)->params } 0 .. 15 ] },
        bank       => $self->{bank} ? basename($self->{bank}) : undef,
        channels   => $self->_channels,
        synth      => {
            partials => $self->{partials},
            voices   => $synth->{voices},
            gain     => $synth->{gain},
            fidelity => $synth->{fidelity},
            auto     => $self->{auto},
        },
    };
}

my @CHANNEL_FIELDS = qw(program variation kit drum volume expression pan send chorus mute);

sub _channels ($self) {
    my $synth = $self->{synth};
    return [ map { my $c = $synth->channel($_); +{ (map { $_ => $c->{$_} } @CHANNEL_FIELDS), held => $synth->held($_) } } 0 .. 15 ];
}

sub _broadcast_channels ($self) {
    $self->_broadcast({ type => 'channels', channels => $self->_channels });
    return;
}

# Five times a second: the voices and the loudest of them on each channel,
# the load (none while no page plays the sound: nothing renders), the
# channels (and what each holds against the file) and arpeggiators as they
# are, how far the file has played.
sub _broadcast_state ($self) {
    return unless %{ $self->{clients} };

    my $synth   = $self->{synth};
    my $playing = $self->{playing};
    my $load    = (grep { $_->{audio} } values %{ $self->{clients} }) ? $synth->load : 0;
    my @level   = (0) x 16;
    my @voices  = (0) x 16;
    for my $voice (@{ $synth->{active} }) {
        my $c = $voice->{channel};
        my $l = ($voice->{raw_env} // 0) * $voice->{level};
        $voices[$c]++;
        $level[$c] = $l if $l > $level[$c];
    }

    $self->_broadcast({
        type        => 'state',
        voices      => scalar @{ $synth->{active} },
        load        => 0 + sprintf('%.3f', $load),
        partials    => $synth->{partials},
        level       => [ map { 0 + sprintf '%.3f', $_ } @level ],
        per_channel => \@voices,
        channels    => $self->_channels,
        arps        => [ map { $synth->arpeggiator($_)->params } 0 .. 15 ],
        playing     => $playing ? {
            file     => $playing->{file},
            length   => $playing->{length},
            position => $self->_position,
            paused   => defined $playing->{paused} ? 1 : 0,
        } : undef,
        recording   => $self->{recording} ? time - $self->{recording}{started} : undef,
    });
    return;
}

sub _read_json ($self, $file) {
    open my $fh, '<:raw', $file or die "cannot read '$file': $!\n";
    local $/;
    return $self->{json}->decode(scalar <$fh>);
}

# Written to a file beside it, then moved over it: never half a file.
sub _write_json ($self, $file, $data) {
    my $temp = "$file.tmp";
    open my $fh, '>:raw', $temp or die "cannot write '$temp': $!\n";
    print {$fh} JSON::PP->new->canonical->pretty->encode($data);
    close $fh or die "cannot write '$temp': $!\n";
    rename $temp, $file or die "cannot write '$file': $!\n";
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Server - the synthesizer behind a web page

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Synth::Server;
    Peta::Synth::Server->new(port => 8360, midi_dir => 'songs', bank => 'my-bank.json')->run;

or C<peta-synth serve>.

=head1 DESCRIPTION

Serves a page from which the synthesizer is played and set up while it
sounds: every instrument's and drum's patch, the channels (instrument,
volume, pan, reverb send, mute, arpeggiator), the reverb, the quality; MIDI files are
played from a directory or dropped onto the page, and keys come from the
page's keyboard, the computer's keyboard, or a MIDI device through the
browser's Web MIDI.

A file is played from its start or from a position, paused and played on;
each channel shows its first instrument from the file's start, not only when
its first note comes;
from a position, the channels are set up as the file has them there (its
programs, controllers and system exclusive before it), and its notes begin
from there. What is played live (the page's keys and controls, Web MIDI,
C<in>) can be recorded: into a MIDI file of the directory, named by when
the recording began, the channels it plays set up as they were then.

What is set by hand (on the page, or by MIDI played live) is held against
the file's events on that channel until it is let go (see
L<Peta::Synth::Synth/by_hand, held, let_go, forget_held>); another file
forgets it.

The sound goes to the browser over a WebSocket and is played there; the
browser's clock paces the rendering. When the render takes most of the
time there is, new notes get fewer partials, and more again when there is
room (C<auto>). The messages are listed at the top of the source.

It listens on 127.0.0.1 unless told otherwise: whoever reaches the port
can play the synth and save MIDI files into its directory.

=head1 METHODS

=head2 new

    Peta::Synth::Server->new(
        host     => '127.0.0.1',
        port     => 8360,
        rate     => 48000,
        partials => 48,
        engine   => 'auto',
        fidelity => 'mid',
        midi_dir => '.',
        bank     => $file,
        in       => 'all',
        auto     => 1,
        ahead    => 0.12,
        quantum  => 512,
    );

C<bank> is a JSON file of instrument changes, read at the start and written
when the page saves; C<in>, MIDI read besides the page's, as
L<Peta::Synth::Input> takes it (none unless given); C<ahead> is how far, in
seconds, the sound is rendered in front of what the browser has played.

=head2 run, stop

Serves until C<stop>.

=head2 url, synth

The address served, and the L<Peta::Synth::Synth> that plays.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
