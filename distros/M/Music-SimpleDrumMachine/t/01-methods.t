use Test2::V0;

ok lives { require Music::SimpleDrumMachine }, 'Music::SimpleDrumMachine loads'
    or bail_out('cannot load Music::SimpleDrumMachine');

{
    package Test::FakeLoop;
    our @ADDED;   # timers handed to the loop, so tests can drive them by hand
    our @SIGNALS; # signal names watched
    sub new          { bless {}, shift }
    sub add          { push @ADDED, $_[1]; 1 }
    sub watch_signal { push @SIGNALS, $_[1]; 1 }
    sub run          { 1 } # return immediately instead of blocking forever
    sub stop         { 1 }
}

{
    package Test::FakeMidi;
    our @CALLS; # [ method, @args ] for every message "sent"
    sub new { bless {}, shift }
    for my $method (qw(clock note_on note_off cc stop)) {
        no strict 'refs';
        *{$method} = sub { shift; push @CALLS, [ $method, @_ ]; 1 };
    }
}

sub new_obj {
    my (%args) = @_;
    my $obj;
    # autoplay is off by default so new() returns instead of running a loop
    ok lives { $obj = Music::SimpleDrumMachine->new( autoplay => 0, %args ) }, 'new() lives'
        or diag $@;
    isa_ok $obj, ['Music::SimpleDrumMachine'], 'object';
    return $obj;
}

subtest defaults => sub {
    my $obj = new_obj( port_name => 'test' );
    is $obj->beats,      16,              'beats';
    is $obj->bars,       4,               'bars';
    is $obj->bpm,        120,             'bpm';
    is $obj->chan,       9,               'chan';
    is $obj->divisions,  4,               'divisions';
    is $obj->fill_crash, 1,               'fill_crash';
    is $obj->filling,    1,               'filling';
    is $obj->next_fill,  '_default_fill', 'next_fill';
    is $obj->next_part,  '_default_part', 'next_part';
    is $obj->port_name,  'test',          'port_name';
    is $obj->ppqn,       24,              'ppqn';
    is $obj->velo_max,   10,              'velo_max';
    is $obj->velo_min,   -10,             'velo_min';
    is $obj->velo_off,   110,             'velo_off';
    is $obj->verbose,    0,               'verbose';
    is $obj->add_drums,  [],              'add_drums';

    ref_ok $obj->drums, 'HASH', 'drums';
    ref_ok $obj->parts, 'HASH', 'parts';
    ref_ok $obj->fills, 'HASH', 'fills';
    ref_ok $obj->loop,  'IO::Async::Loop', 'loop defaults to a real loop'
        if 0; # skipped: the default loop is not constructed in tests

    is $obj->parts, hash { field _default_part => D(); etc }, 'default parts exist';
    is $obj->fills, hash { field _default_fill => D(); etc }, 'default fills exist';
};

subtest drums => sub {
    my $obj   = new_obj( port_name => 'test' );
    my $drums = $obj->drums;
    is $drums->{kick}{num},   36, 'kick num';
    is $drums->{snare}{num},  38, 'snare num';
    is $drums->{closed}{num}, 42, 'closed num';
    is $drums->{kick}{chan},  9,  'kick chan uses the shared chan by default';
    is $drums->{snare}{chan}, 9,  'snare chan uses the shared chan by default';

    $obj = new_obj( port_name => 'test', chan => -1 );
    isnt $obj->drums->{kick}{chan}, $obj->drums->{snare}{chan},
        'multi-timbral mode (chan => -1) assigns distinct channels';
};

subtest add_drums => sub {
    my $obj = new_obj(
        port_name => 'test',
        add_drums => [ { drum => 'gong', num => 99 } ],
    );
    is $obj->drums, hash { field gong => D(); etc }, 'added drum exists';
    is $obj->drums->{gong}{num},  99, 'added drum num';
    is $obj->drums->{gong}{chan}, 9,  'added drum uses the shared chan by default';

    $obj = new_obj(
        port_name => 'test',
        chan      => -1,
        add_drums => [ { drum => 'gong', num => 99, chan => 5 } ],
    );
    is $obj->drums->{gong}{chan}, 5, 'added drum honors an explicit chan';
};

subtest velocity => sub {
    my $obj = new_obj(
        port_name => 'test',
        velo_min  => 0,
        velo_max  => 0,
        velo_off  => 127,
    );
    is $obj->velocity, 127, 'fixed velocity when min == max == 0';

    $obj = new_obj(
        port_name => 'test',
        velo_min  => -10,
        velo_max  => 10,
        velo_off  => 110,
    );
    my $got = $obj->velocity;
    ok $got >= 100 && $got <= 120, "velocity in range: $got";
};

subtest parts_and_fills => sub {
    my $obj = new_obj(port_name => 'test');

    my ($next, $patterns) = $obj->_default_part;
    is $next, '_default_part', '_default_part next';
    is $patterns, hash {
        field kick   => D();
        field snare  => D();
        field closed => D();
        etc;
    }, '_default_part has kick, snare and closed patterns';

    my ($fnext, $fpatterns);
    for (1 .. 20) {
        last if lives { ($fnext, $fpatterns) = $obj->_default_fill };
    }
    is $fnext, '_default_fill', '_default_fill next';
    is $fpatterns, hash { field snare => D(); etc },
        '_default_fill has a snare pattern';
};

subtest bars => sub {
    is new_obj(port_name => 'test', bars => 1)->bars, 1, 'bars accepts 1';
    is new_obj(port_name => 'test', bars => 2)->bars, 2, 'bars accepts 2';

    for my $bad (0, -1, 2.5, 'abc') {
        ok dies { Music::SimpleDrumMachine->new( port_name => 'test', bars => $bad, autoplay => 0 ) },
            "'$bad' is rejected";
    }

    # Drive tick() by hand. One bar is 96 clock ticks (ppqn 24 x 4
    # quarter-notes), and a step (16th-note) is every 6 ticks.
    my $ticks_per_bar = 96;
    my $measures      = 4;

    for my $case ( [1,4,0], [2,2,2], [4,1,1] ) {
        my ($bars, $want_parts, $want_fills) = @$case;

        my ($parts, $fills) = (0, 0);

        my $dm = new_obj(
            port_name => 'test',
            bars      => $bars,
            filling   => 1,
            next_part => 'count_part',
            next_fill => 'count_fill',
            parts     => { count_part => sub { $parts++; return 'count_part', { kick  => [ (1) x 16 ] } } },
            fills     => { count_fill => sub { $fills++; return 'count_fill', { snare => [ (1) x 16 ] } } },
            _midi_out => Test::FakeMidi->new,
        );

        $dm->tick for 1 .. $measures * $ticks_per_bar;

        is $parts, $want_parts,
            "bars: $bars - a part chosen $want_parts time(s) in $measures measures";
        is $fills, $want_fills,
            "bars: $bars - $want_fills fill(s) in $measures measures";
    }
};

subtest weighted_parts => sub {
    my $obj = new_obj(port_name => 'test');

    is $obj->_choose_part('part_A'), 'part_A', 'a plain name passes through';
    is $obj->_choose_part({ only => 5 }), 'only', 'a single weighted entry is always chosen';

    my %seen;
    $seen{ $obj->_choose_part({ A => 1, B => 1, C => 0, D => -1 }) }++ for 1 .. 200;
    is [ sort keys %seen ], [qw(A B)], 'zero and negative weights are never chosen';

    %seen = ();
    $seen{ $obj->_choose_part({ heavy => 99, light => 1 }) }++ for 1 .. 1000;
    ok +( $seen{heavy} // 0 ) > ( $seen{light} // 0 ), 'a heavier weight is chosen more often';

    like dies { $obj->_choose_part({ A => 0, B => -2 }) },
        qr/positive weight/, 'dies when no part has a positive weight';

    # Drive tick() by hand: one bar is 96 ticks and bars => 1 means
    # a part is chosen every bar, so 4 measures choose a part 4 times.
    my $pats = sub { +{ kick => [ (1) x 16 ] } };
    my $play = sub {
        my ($next_part, $returns) = @_;
        my %count;
        my $dm = new_obj(
            port_name => 'test',
            bars      => 1,
            filling   => 0,
            next_part => $next_part,
            parts     => {
                map { my $n = $_; $n => sub { $count{$n}++; return $returns->{$n}, $pats->() } } qw(a b)
            },
            _midi_out => Test::FakeMidi->new,
        );
        $dm->tick for 1 .. 4 * 96;
        return \%count;
    };

    my $stay_on_a = { a => 1, b => 0 };
    is $play->( $stay_on_a, { a => $stay_on_a, b => $stay_on_a } ), { a => 4 },
        'a weighted hash as next_part only ever plays the part with weight';

    is $play->( 'a', { a => { b => 1 }, b => { b => 1 } } ), { a => 1, b => 3 },
        'a part can return a weighted hash as its next part';

    my $dm = new_obj(
        port_name => 'test',
        bars      => 1,
        filling   => 0,
        next_part => 'nope',
        _midi_out => Test::FakeMidi->new,
    );
    like dies { $dm->tick },
        qr/Unknown part: nope/, 'an unknown part name dies with a clear message';
};

subtest tick => sub {
    local @Test::FakeMidi::CALLS = ();
    my $dm = new_obj(
        port_name => 'test',
        bars      => 1,
        filling   => 0,
        next_part => 'p',
        parts     => { p => sub { return 'p', { kick => [ (1) x 16 ] } } },
        _midi_out => Test::FakeMidi->new,
    );

    $dm->tick;
    my @on = grep { $_->[0] eq 'note_on' } @Test::FakeMidi::CALLS;
    is scalar(@on), 1, 'the very first tick plays the first step';
    is [ @{ $on[0] }[1, 2] ], [ 9, 36 ], 'on the shared channel, with the kick number';

    $dm->tick;
    my @off = grep { $_->[0] eq 'note_off' } @Test::FakeMidi::CALLS;
    is scalar(@off), 1, 'the next tick releases the note';

    ok !( grep { $_->[0] eq 'clock' } @Test::FakeMidi::CALLS ),
        'tick() does not send MIDI clock';
};

subtest ppqn => sub {
    local @Test::FakeMidi::CALLS = ();
    my $dm = new_obj(
        port_name => 'test',
        ppqn      => 96,
        bars      => 1,
        filling   => 0,
        next_part => 'p',
        parts     => { p => sub { return 'p', { kick => [ (1) x 16 ] } } },
        _midi_out => Test::FakeMidi->new,
    );

    # a step is a 16th-note: 96 / 4 = 24 ticks, so 4 steps per quarter-note
    $dm->tick for 1 .. 96;
    my @on = grep { $_->[0] eq 'note_on' } @Test::FakeMidi::CALLS;
    is scalar(@on), 4, 'ppqn => 96 plays four 16th-note steps per quarter-note';
};

subtest clock => sub {
    local @Test::FakeMidi::CALLS = ();
    my $dm = new_obj( port_name => 'test', _midi_out => Test::FakeMidi->new );
    $dm->clock;
    is [ map { $_->[0] } @Test::FakeMidi::CALLS ], ['clock'], 'clock() sends one MIDI clock';
};

subtest stop => sub {
    local @Test::FakeMidi::CALLS = ();
    my $dm = new_obj( port_name => 'test', _midi_out => Test::FakeMidi->new );
    $dm->stop;
    is [ grep { $_->[0] eq 'cc' } @Test::FakeMidi::CALLS ], [ ['cc', 9, 123, 0] ],
        'all-notes-off (CC 123) on the shared channel';
    ok( (grep { $_->[0] eq 'stop' } @Test::FakeMidi::CALLS), 'a MIDI stop is sent' );

    @Test::FakeMidi::CALLS = ();
    $dm = new_obj( port_name => 'test', chan => -1, _midi_out => Test::FakeMidi->new );
    $dm->stop;
    my @cc = grep { $_->[0] eq 'cc' } @Test::FakeMidi::CALLS;
    is [ map { $_->[1] } @cc ], [ 0 .. 8, 10 .. 15 ],
        'multi-timbral: CC 123 on each used channel, none above 15';
    ok !( grep { $_->[2] != 123 || $_->[3] != 0 } @cc ), 'always controller 123, value 0';
};

subtest autoplay => sub {
    local @Test::FakeLoop::ADDED   = ();
    local @Test::FakeLoop::SIGNALS = ();
    local @Test::FakeMidi::CALLS   = ();

    my $dm = new_obj(
        port_name => 'test',
        autoplay  => 1,
        loop      => Test::FakeLoop->new,
        _midi_out => Test::FakeMidi->new,
    );
    is scalar(@Test::FakeLoop::ADDED), 1, 'autoplay: new() adds a timer to the loop';
    is [ @Test::FakeLoop::SIGNALS ], ['INT'], 'autoplay: new() watches SIGINT on the loop';

    my ($timer) = @Test::FakeLoop::ADDED;
    $timer->invoke_event('on_tick');
    is $Test::FakeMidi::CALLS[0][0], 'clock', 'the timer sends clock, then ticks';

    # autoplay defaults to on
    @Test::FakeLoop::ADDED = ();
    ok lives {
        Music::SimpleDrumMachine->new(
            port_name => 'test',
            loop      => Test::FakeLoop->new,
            _midi_out => Test::FakeMidi->new,
        )
    }, 'new() without autoplay lives with a fake loop' or diag $@;
    is scalar(@Test::FakeLoop::ADDED), 1, 'autoplay defaults to on';

    # and off means nothing is started
    @Test::FakeLoop::ADDED = ();
    new_obj( port_name => 'test', loop => Test::FakeLoop->new );
    is scalar(@Test::FakeLoop::ADDED), 0, 'autoplay => 0 starts nothing';
};

done_testing;