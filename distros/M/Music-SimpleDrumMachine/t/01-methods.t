use Test2::V0;

ok lives { require Music::SimpleDrumMachine }, 'Music::SimpleDrumMachine loads'
    or bail_out('cannot load Music::SimpleDrumMachine');

{
    package Test::FakeLoop;
    our @ADDED; # timers handed to the loop, so tests can drive them by hand
    sub new { bless {}, shift }
    sub add { push @ADDED, $_[1]; 1 }
    sub run { 1 } # return immediately instead of blocking forever
}

{
    package Test::FakeMidi;
    sub new      { bless {}, shift }
    sub clock    { 1 }
    sub note_on  { 1 }
    sub note_off { 1 }
}

# typeglob, symbol-table entry for the name _loop in the package
no warnings 'redefine';
local *Music::SimpleDrumMachine::_loop = sub { Test::FakeLoop->new };

sub new_obj {
    my (%args) = @_;
    my $obj;
    ok lives { $obj = Music::SimpleDrumMachine->new(%args) }, 'new() lives'
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
        ok dies { Music::SimpleDrumMachine->new( port_name => 'test', bars => $bad ) },
            "'$bad' is rejected";
    }

    # Drive the timer's on_tick by hand. One bar is 96 clock ticks
    # (ppqn 24 x 4 quarter-notes), and a step (16th-note) is every 6 ticks.
    my $ticks_per_bar = 96;
    my $measures      = 4;

    for my $case ( [1,4,0], [2,2,2], [4,1,1] ) {
        my ($bars, $want_parts, $want_fills) = @$case;

        my ($parts, $fills) = (0, 0);
        local @Test::FakeLoop::ADDED = ();

        new_obj(
            port_name => 'test',
            bars      => $bars,
            filling   => 1,
            next_part => 'count_part',
            next_fill => 'count_fill',
            parts     => { count_part => sub { $parts++; return 'count_part', { kick  => [ (1) x 16 ] } } },
            fills     => { count_fill => sub { $fills++; return 'count_fill', { snare => [ (1) x 16 ] } } },
            _midi_out => Test::FakeMidi->new,
        );

        my ($timer) = @Test::FakeLoop::ADDED;
        ok $timer, "bars => $bars: a timer added to the loop"
            or next;

        $timer->invoke_event('on_tick') for 1 .. $measures * $ticks_per_bar;

        is $parts, $want_parts,
            "bars: $bars - a part chosen $want_parts time(s) in $measures measures";
        is $fills, $want_fills,
            "bars: $bars - $want_fills fill(s) in $measures measures";
    }
};

done_testing;