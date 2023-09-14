#!perl
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp 'croak';
use Getopt::Long;

use Term::Output::List;

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Net::Async::OSC;
use Music::VoiceGen;
use Music::Scales;
use Music::Chord::Note;

GetOptions(
    'mute=s' => \my @do_mute,
    'seed=s' => \my $seed,
    'voice'  => \my $voice,
    'dry-run|n'  => \my $dry_run,
) or pod2usage(2);

if( $dry_run ) {
    undef $voice;
}

@do_mute = map { split /,/ } @do_mute;

if( $seed ) {
    srand($seed);
}

my $loop = IO::Async::Loop->new();
my $osc = Net::Async::OSC->new(
    loop => $loop,
);

if( ! $dry_run ) {
    $osc->connect('127.0.0.1', 4560)->get;
}

my @track_names = (qw(
    <harmony>
    chord
    hh
    snare
    bassdrum
    bass
    melody
    777
));

my $t = Term::Output::List->new();
my $input;
if( $^O eq 'MSWin32') {
    $input = Win32::Console->new(Win32::Console::STD_INPUT_HANDLE());
}
sub msg($msg) {
    $t->output_permanent($msg);
}

my $bpm    = 94;
my $beats  = 4; # 4/4
my $ticks  = 4; # ticks per beat, means 1/16th notes
my $tracks = 8; # so far...

sub loc($tick, $track) {
    $tick*$tracks+$track
}

sub beat($beat, $track) {
    return loc($ticks*$beat,$track)
}

# create_sequencer() ?
#my $sequencer = [];

sub random_melody( $sequencer, $track ) {
    for my $beat (0..7) {
        $sequencer->[beat($beat*8+4,$track)] = [
        # Maybe we should pre-cook the OSC message even, to take
        # load out of the output loop
        "/trigger/tb303" => 'iiffi',
            #(70+int(rand(12)), 0.125, 60+int(rand(50)), 0.8, 0)
            (40+int(rand(24)), 130, 0.1, 0.8+rand(0.15), 0)
        ];
    }
}

sub wailers($base) {
        my @harmonies = (
                    [$base,  'major'], #C
                    [$base,  'major'],
                    #[$base,  'M7'],
                    [$base+7,'major'], #G
                    [$base+7,'major'], #G
                    [$base+9,'min'],   #A
                    [$base+9,'min'],
                    [$base+5,'major'], #F
                    [$base+5,'major'], #F
                    #[$base+5,'M7'],
                    [$base,  'major'], #C
                    [$base,  'major'], #C
                    [$base+7,'major'], #G
                    [$base+7,'major'], #G
                    [$base,  'major'], #C
                    [$base,  'major'], #C
                    [$base+7,'major'], #G
                    [$base+7,'major'], #G
    );
    return \@harmonies;
}

sub tosh($base) {
        my @harmonies = ([$base,  'major'], #C
                    [$base,  'major'],
                    #[$base,  'M7'],
                    [$base+7,'major'], #G
                    [$base+7,'major'], #G
    );
    return \@harmonies;
}

sub get_harmonies( $base = 50 + int(rand(32)) ) {
    # The harmonies
    # Maybe we want markov-style progressions, or some other weirdo set?
    my $base = 50 + int(rand(32));

    #if( rand(1) >= 0.5 ) {
    #    return tosh($base)
    #} else {
        return wailers($base)
    #}
}

my $chord_track = 1;
my $info_track = 0;

sub generate_bassline( $sequencer, $harmonies, $bassline, $chord_track, $info_track ) {
    my $bass_harmony = -1;

    my @bassline = (split //, $bassline);
    my $bass_ofs = 0;
    for my $beat (0..$#$harmonies) {
        $bass_harmony = ($bass_harmony+1)%@$harmonies;
        my $ofs = beat($beat*8+4,$info_track);
        $sequencer->[$ofs+$_*$tracks] = sprintf "%d %s", $harmonies->[ $bass_harmony ]->@*
            for 0..$ticks*$beats-1;
        $sequencer->[beat($beat*8+4,$chord_track)] = [
            # Maybe we should pre-cook the OSC message even, to take
            # load out of the output loop
            "/trigger/chord" => 'is', ($harmonies->[ $bass_harmony ]->@* )
        ];

        # Bassline
        for my $ofs (0..7) {
            if( $bassline[ $bass_ofs ] ne '-' ) {
                $sequencer->[beat($beat*8+$ofs,5)] = [
                    "/trigger/bass" => 'i', ($harmonies->[ $bass_harmony ]->[0] - 24 )
                ];
            };
            $bass_ofs = (($bass_ofs+1) % scalar @bassline)
        }
    }
}

# Another track with a "bassline" based on the harmonies above
# Should we model the bass like a drum?!
my %chord_names = (
    'M7'  => 'M7',
    min   => 'm',
    major => 'base',
);

sub octave($note) {
    return int($note/12)-1
}

sub melody_step( $sequencer, $tick, $harmonies, $curr_harmony, $next_harmony, $last_note, $chord_track, $bass_track ) {
    my $h = $harmonies->[ $curr_harmony ];
    my $chord_name = $chord_names{ $h->[1]} // $h->[1];
    my $base = $h->[0];
    #my $cn = Music::Chord::Note->new();

    # Cache this?!
    #my @scale = map { $_ + $h->[0], $_ + $h->[0]+12 } $cn->chord_num( $chord_name );
    # these are only the boring notes, but I'm not sure how to bring half-tones
    # and harmonic progression stuff in here

    # For the harmonic stuff, we know what scales match to our chords:
    my %scales = (
        major => 'major',
        min   => 'minor',
        'M7'  => 'major',
    );
    my $scale_name = $scales{ $h->[1] }
        or die "Unknown harmony '$h->[1]'";
    my $chord_name = $chord_names{ $h->[1] }
        or die "Unknown harmony '$h->[1]' for chord";
    my @scale;

    my $cn = Music::Chord::Note->new();
    my %chord = map { $base + $_ => 1 } $cn->chord_num($chord_name);

    if(    $sequencer->[beat($tick,$chord_track)]
        or $sequencer->[beat($tick,$bass_track)]
    ) {
        # Use a note in line with the currently playing chord
        @scale = map { $base + $_ } $cn->chord_num($chord_name);

    } else {
        # Use a random note, that is not too far from the current note

        @scale = grep {     $_ != $last_note }
                 grep {  1
                 #       and  ! exists $chord{ $_ +1 }
                 #       and ! exists $chord{ $_ -1 }
                        and ! exists $chord{ $_ +6 } # tritone
                        and ! exists $chord{ $_ -6 }
                      }
                 grep { abs($_ - $last_note) < 7 }
                      get_scale_MIDI($base, octave($base), $scale_name, 0),
                      get_scale_MIDI($base, octave($base)-1, $scale_name, 0),
                      ;
    }
    return $scale[ int rand @scale ];
}

# Another track with a "melody" based on the harmonies above
sub generate_melody( $base, $harmonies, $sequencer, $track, $chord_track, $bass_track ) {
    #my @melody = (split //, "--o-o---o-o-o---o-o-o---o-o-o---");
    my @melody = (split //, "o---o---");

    my $harmony = -1;

    my $rhythm_ofs = 0;
    my $last_note = $base;
    for my $beat (0..$#$harmonies) {
        # Select the next harmony
        $harmony = ($harmony+1)%@$harmonies;
        my $next_harmony = ($harmony+1)%@$harmonies;
        for my $ofs (0..$#melody) {
            if( $melody[ $rhythm_ofs ] ne '-' ) {
                my $note = melody_step( $sequencer, $ofs, $harmonies, $harmony, $next_harmony, $last_note, $chord_track, $bass_track );
                $sequencer->[beat($beat*8+$ofs,$track)] = [
                    "/trigger/melody" => 'ii', ($note,1) # legato
                ];
                $last_note = $note;
            };
            $rhythm_ofs = (($rhythm_ofs+1) % scalar @melody)
        }
    }
}

sub generate_intro( $base, $harmonies, $sequencer, $track ) {
    # Clean out all the melody, add FX into it

    my $harmony = -1;

    # Kill off the melody
    for my $ofs (0..(@$sequencer / $tracks)) {
        my $l = loc($ofs, $track);
        undef $sequencer->[loc($ofs, $track)];
    }

    my $rhythm_ofs = 0;
    my $last_note = $base;
    for my $beat (0..$#$harmonies) {
        # Select the next harmony
        $harmony = ($harmony+1)%@$harmonies;
        my $next_harmony = ($harmony+1)%@$harmonies;
        for my $ofs (int rand($beats)) {
            my $note = int rand(8)+1; # 1..8
            $sequencer->[loc($ofs,$track)] = [
                "/trigger/fx" => 'i', ($note)
            ];
        }
    }
}

# we expect each char to be a 32th note (?!)
# We need to repeat the pattern until it fills the longest other pattern!
sub parse_drum_pattern( $sequencer, $total_bars, $track, $pattern, $osc_message,$vol=1,$ticks_per_note=undef) {
    $pattern =~ m!^\s*\w+\s*\|((?:[\w\-]{16})+)\|+!
        or croak "Invalid pattern '$pattern'";
    $ticks_per_note //= length($1) / 4;
    my $p = $1;
    my $target_len = $total_bars*$beats*$ticks*2 / $ticks_per_note; # the 2 is because each total_bar is 2 bars
    while( length $p < $target_len) {
        $p .= $1;
    }
    #msg( $p );
    my @beats = split //, $p;
    my $ofs = 0;

    while( $ofs < @beats ) {
        if( $beats[ $ofs ] ne '-' ) {
            $sequencer->[loc($ofs*$ticks_per_note,$track)] =
                $osc->osc->message($osc_message, 'f' => $vol);
        } else {
            $sequencer->[loc($ofs*$ticks_per_note,$track)] =
                undef;
        }
        $ofs++;
    }
}

# Half Drop
sub generate_half_drop( $sequencer, $total_bars ) {
    parse_drum_pattern($sequencer, $total_bars, 2, 'HH|x-x-x-x-x-x-x-x-||', '/trigger/hh');
    parse_drum_pattern($sequencer, $total_bars, 3, ' S|--------o-------||', '/trigger/sn');
    parse_drum_pattern($sequencer, $total_bars, 4, ' B|o-------o-------||', '/trigger/bd');
}

# One Drop
sub generate_one_drop( $sequencer, $total_bars ) {
    parse_drum_pattern($sequencer, $total_bars, 2, 'HH|x-x-x-x-x-x-x-x-||', '/trigger/hh',1,4);
    parse_drum_pattern($sequencer, $total_bars, 3, ' S|--------o-------||', '/trigger/sn',1,4);
    parse_drum_pattern($sequencer, $total_bars, 4, ' B|--------o-------||', '/trigger/bd',1,4);
}

# Reggaeton
sub generate_reggaeton( $sequencer, $total_bars ) {
    parse_drum_pattern($sequencer, $total_bars, 2, 'HH|x---x---x---x---x---x---x---x---||', '/trigger/hh',0.25,2);
    parse_drum_pattern($sequencer, $total_bars, 3, ' B|o-------o-------o-------o-------||', '/trigger/bd',1,2);
    parse_drum_pattern($sequencer, $total_bars, 4, ' S|----------------------o-----o---||', '/trigger/sn',1,2);
}

sub generate_lyrics($sequencer, $track) {
    my $p = beat(0,7);
    while( $p < @$sequencer ) {
        $sequencer->[$p] = \&sing;
        $p += beat(16,0); # XXX fix the 16 to $beats*4 ?!
    }
}

sub fresh_pattern($base, $harmonies, %options) {
    my $sequencer = [];
    my $harmonies = get_harmonies();

    $options{ bassline } //= "o-------o---------------o---o---";

    generate_bassline($sequencer, $harmonies, $options{bassline}, $chord_track, $info_track);
    generate_one_drop($sequencer, scalar @$harmonies);

    generate_melody( $base, $harmonies, $sequencer, 6, $chord_track,5 );

    if( $options{ voice }) {
        generate_lyrics($sequencer, 7);
    }

    # "Expand" the array to the full length
    # This should simply be the next multiple of $beats*$ticks*$tracks, no?!
    my $last = beat(16,0) -1;
    $sequencer->[$last]= undef;

    # Round up to a 4/4 bar
    #msg( $last );
    #msg( scalar @$sequencer );
    my $ticks_in_bar = @$sequencer / $tracks;
    while( int( $ticks_in_bar ) != $ticks_in_bar ) {
        $ticks_in_bar = int($ticks_in_bar)+1;

        while( $ticks_in_bar % 16 != 0 ) {
            $ticks_in_bar += (16 - ($ticks_in_bar % 16));
        }

        # expand
        $sequencer->[loc($ticks_in_bar,0)-1] = undef;

        #msg(@$sequencer / $tracks);
    }

    my $tick = 0;
    $ticks_in_bar = @$sequencer / $tracks;

    die "data structure is not a complete bar ($ticks_in_bar)" if int($ticks_in_bar) != $ticks_in_bar;
    #msg( "You have defined $ticks_in_bar ticks" );

    return $sequencer, $ticks_in_bar;
}

my $sapi;
if( $^O eq 'MSWin32' ) {
    require Win32::OLE;
    $sapi = Win32::OLE->CreateObject('SAPI.SpVoice');
};

my @lyrics = map { qq{<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='EN'>$_</speak>} } (
# Intro-ish
'','','','','','','','',

"We're no strangers to love",
'',
"You know the rules and so do I",
'',
"A full commitment's what I'm thinking of",
"You wouldn't get this from any other guy",

# pre-chorus
"I just wanna tell you how I'm feeling",
"Gotta make you understand",

# Chorus
"Never gonna give you up",
"Never gonna let you down",
"Never gonna run around and desert you",
'',
"Never gonna make you cry",
"Never gonna say goodbye",
"Never gonna tell a lie and hurt you",
'',
"Thank you everybody",
'',
"You are a wonderful audience",
'',
"It's been a pleasure to sing for you today",
'',
"Also, a round of applause for the band!",
'',
# Chorus
"Never gonna give you up",
"Never gonna let you down",
"Never gonna run around and desert you",
'',
"Never gonna make you cry",
"Never gonna say goodbye",
"Never gonna tell a lie and hurt you",
'',
);
sub sing($ofs) {
    state $line = 0;
    if( $line >= @lyrics ) {
        $line = 0;
    }
    my $l = $lyrics[$line++];
    #if( $l !~ /></ ) {
        $sapi->Speak($l, 1);
        $l =~ s!<.*?>!!g;
        if( $l ) {
            msg($l);
        }
    #}
    return (); # we don't want to generate sound with OSC
}

$| = 1;

# Periodically swap $sequencer for the next bar/ set of 16 beats / whatever
# Also bridge, breakdown, drop

# We should be able to pause / restart / resume / resync the code
# For resync, we need to keep track of the start time or increase our tick counter
# Currently we simply increase our tick counter while we are silent. This means
# we have no real "pause". We need to store two tick states.

my $output_state = '';

my @playing = ('' x (1+$tracks));
my @mute    = ('' x (1+$tracks));

for my $m (@do_mute) {
    my $i;
    for (0..$#track_names) {
        if( $m eq $track_names[$_] ) {
            $i = $_;
            last;
        }
    };
    $mute[ $i ] = 1;
}

sub toggle_mute($track, $mute=undef) {
    my $val = $mute;

    if( ! defined $val ) {
        if( $mute[ $track ] ) {
            $val = '';
        } else {
            $val = 'mute';
        }
    }

    $mute[ $track ] = $val;
}

sub handle_keyboard {
    # Win32 specific...
    while( $input and $input->GetEvents ) {
        #msg( sprintf "Pending: %d", $input->GetEvents );
        my @ev = $input->Input();
        if( $ev[0] == 1 and $ev[1] ) {
            my $key = chr($ev[5]);
            if( $key =~ /\d/ ) {
                toggle_mute($key);
            } elsif( $key eq 'm' ) {
                toggle_mute($_, 'mute') for 0..$tracks-1;
            } elsif( $key eq 'u' ) {
                toggle_mute($_, '') for 0..$tracks-1;
            } elsif( $key eq 'r' ) {
                return undef;

            } elsif( $key eq 'x' ) {
                dump_state();
                $loop->stop;

            } elsif( $key eq 'q' ) {
                #warn "Sending music stop";
                $mute[6] = 1;
                if( ! $dry_run ) {
                    $osc->send_osc(
                        "/trigger/melody" => 'ii',
                        1,0);
                }
                $loop->watch_time( after => 1,
                code => sub {
                    $loop->stop;
                });
            } else {
                msg("Keypress '$key' ($ev[5])")
                    if $ev[5];
            }
        }
    }
    return 1;
}

sub generate_song {
    my @phrases;

    my $harmonies = get_harmonies();
    my $base = int( 60+rand 24 );

    # Verse
    my ($seq,$ticks_in_bar) = fresh_pattern($base, $harmonies, voice => $voice);
    my $verse = {
        sequencer => $seq,
        ticks     => $ticks_in_bar,
        name      => 'Verse',
    };

    # Copy first half of verse into Intro
    my($seq_intro) = [@$seq];
    my @harmonies_i = @{$harmonies}[0..1];
    splice @$seq_intro, $tracks*$ticks_in_bar / 2; # Leave only two bars
    # Now, zero out the melody and put in some fx
    generate_intro( $base, \@harmonies_i, $seq_intro, 6 );
    #use Data::Dumper; warn Dumper $seq_intro; exit;
    my $intro = {
        sequencer => $seq_intro,
        ticks     => $ticks_in_bar,
        name      => 'Intro',
    };

    # Chorus
    ($seq,$ticks_in_bar) = fresh_pattern($base, $harmonies, voice => $voice);
    my $chorus = {
        sequencer => $seq,
        ticks     => $ticks_in_bar,
        name      => 'Chorus',
    };

    push @phrases, $intro, $verse, $chorus, $verse, $chorus, $chorus;

    return \@phrases
}

sub play_sounds {
    state $tick;
    state $sequencer;
    state $ticks_in_bar;
    state $song;
    state $song_pos;
    state $playing;

    if( ! $song ) {
        $song = generate_song();
        $song_pos = 0;
        undef $playing;
    };

    if( ! $playing ) {
        $playing = $song->[$song_pos];
        ($sequencer, $ticks_in_bar) = ($playing->{sequencer}, $playing->{ticks});
        msg("Playing $playing->{name}");
    }

    my $loc = loc($tick, 0) % @$sequencer;
    if( ! handle_keyboard()) {
        undef $song;
        goto &play_sounds;
    }

    if( $output_state eq 'silent' ) {
        # do nothing
    } else {
        for my $s ($loc..$loc+$tracks-1) {
            my $track = $s-$loc;
            my $n = $sequencer->[$s];
            if( $n ) {
                $playing[ $track ] = $n;
                if( ! $mute[ $track ]) {
                    my $r = ref $n;
                    if( $r and not $mute[$track] ) {
                        my @osc_msg;

                        if( $r eq 'CODE' ) {
                            # Can we pass any meaningful parameters here?
                            # Like maybe the current tick?!
                            @osc_msg = $n->($tick);
                        } elsif( $r eq 'ARRAY' ) {
                            @osc_msg = @$n;
                        }

                        if( @osc_msg and ! $dry_run ) {
                            $osc->send_osc( @osc_msg );
                        }

                    } elsif( $track == 0 ) {
                        $playing[0] = $n;

                    } else {
                        if( !$dry_run ) {
                            $osc->send_osc_msg( $n );
                        }
                    }
                }
            } else {
                $playing[ $track ] = '';
            }
        }

        my @output = map {
            sprintf "%d| %8s | % 12s | %s", $_, $mute[$_], $track_names[$_], $playing[$_];
        } 0..$tracks-1;
        $t->output_list(@output);
    }
    # Consider calculating the tick from the start of the
    # playtime instead of blindly increasing it?!
    $tick = ($tick+1)%$ticks_in_bar;

    if( $tick == 0 ) {
        # move to the next part of the song
        $song_pos = ($song_pos+1) % @$song;
        undef $playing;

        # Should we wrap to the intro, or after it?!
    }
}

my $timer = IO::Async::Timer::Periodic->new(
    reschedule => 'skip',
    first_interval => 0,
    interval => 60/$bpm/$beats/$ticks,
    on_tick => \&play_sounds,
);

# send_osc "/loader/require", "tempfile" ?!
# send_osc "/eval", "ruby code"?!

$timer->start;
$loop->add( $timer );
$loop->run;

__END__

[x] Have multiple progressions, and switch between those
    [ ] intro, lyrics, chorus, outro, bridge
[ ] Patterns can then become expand_pattern("AABA"), which calls expand_progression()
[ ] Songs are patterns like "IIAABBAABBCCBBCxAABBAABBAABBCCBBCCBBCCBBCCBBOO"
    where "II" are intro patterns (without melody)
          "OO" are outro patterns
          "xx" are breakdown patterns
[ ] Have bass/melody pause at some times
[ ] Insert a breakdown/bridge pattern
