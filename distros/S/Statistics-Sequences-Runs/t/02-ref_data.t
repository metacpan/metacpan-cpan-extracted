use Test::More tests => 39;
use constant EPS     => 1e-2;
use Array::Compare;

BEGIN {
    use_ok('Statistics::Sequences::Runs') || print "Bail out!\n";
}

my $runs = Statistics::Sequences::Runs->new();

my %refdat = (
    sw2 => {
        observed => 4,
        p_value  => 0.0099,
        data     => [qw//],
    },
    siegal_p142 => {
        observed => 6,
        expected => 12.586206896551724137931034482759,
        variance => 103152 / 23548,                      # 4.38
        z_value  => -2.9,
        data => [qw/c c c c c c c c c c c c c c e c c c c c c e c e e e e e e/],
        ztest_ok => 1,                                   # Siegal's rule
        p_value  => 0.001819,
    },
    swed_1943 => {
        observed => 5,
        expected => 9,
        z_value  => -2.29,
        p_value  => .010973,
        p_exact  => .0183512,
        data     => [qw/H H H H H H H H H H D H D D D D H H H H H H H H H/],
    },
    reiter => {    # sample from reiter1.com
        data     => [qw/m m w w m w m m w w m w m w m w m m w m m w m w m/],
        observed => 19,
        expected => 13.32,
        stdev    => 2.41,
        variance => 2.41**2,
        z_value  => 2.15,
        p_value  => 1 - .984,
        ztest_ok => 0,    # Siegal's rule
    },
);
my @raw_data = ();
my $val;

for my $src (qw/siegal_p142 reiter/) {
    eval { $runs->load( $refdat{$src}->{'data'} ); };
    ok(
        !$@,
        do { chomp $@; "Data load failed: $@"; }
    );

    $val = $runs->observed();
    ok(
        equal( $val, $refdat{$src}->{'observed'} ),
        "observed  $val != $refdat{$src}->{'observed'}"
    );

    $val = $runs->expected();
    ok(
        equal( $val, $refdat{$src}->{'expected'} ),
        "expected  $val != $refdat{$src}->{'expected'}"
    );

    $val = $runs->variance();
    ok(
        equal( $val, $refdat{$src}->{'variance'} ),
        "variance  $val != $refdat{$src}->{'variance'}"
    );

    my $stdev = sqrt($val);
    $val = $runs->stdev();
    ok( equal( $val, $stdev ), "runcount stdev observed  $val != $stdev" );

    my $obsdev = $refdat{$src}->{'observed'} - $refdat{$src}->{'expected'};
    $val = $runs->obsdev();
    ok( equal( $val, $obsdev ), "runcount obsdev observed  $val != $obsdev" );

    $val = $runs->z_value( ccorr => 1 );
    ok(
        equal( $val, $refdat{$src}->{'z_value'} ),
        "z_value  $val != $refdat{$src}->{'z_value'}"
    );

    $val = $runs->ztest_ok();
    ok(
        equal( $val, $refdat{$src}->{'ztest_ok'} ),
        "run ztest_ok  $val != $refdat{$src}->{'ztest_ok'}"
    );

    $val = $runs->p_value( tails => 1 );
    ok(
        equal( $val, $refdat{$src}->{'p_value'} ),
        "$val = $refdat{$src}->{'p_value'}"
    );

}

# using labelled data:
eval { $runs->load( reiterdata => $refdat{'reiter'}->{'data'} ); };
ok(
    !$@,
    do { chomp $@; "Data load failed: $@"; }
);
$val = $runs->observed( label => 'reiterdata' );
ok(
    equal( $val, $refdat{'reiter'}->{'observed'} ),
    "observed  $val != $refdat{'reiter'}->{'observed'}"
);

# trying to access by index:
eval { $runs->load( 'somedata' => $refdat{'reiter'}->{'data'} ); };
ok( !$@ );
$val = $runs->observed( index => 0 );
ok(
    equal( $val, $refdat{'reiter'}->{'observed'} ),
    "observed  $val != $refdat{'reiter'}->{'observed'}"
);

# don't use load() but give data within this module's methods
$val = $runs->observed( data => $refdat{'reiter'}->{'data'} );
ok(
    equal( $val, $refdat{'reiter'}->{'observed'} ),
    "observed  $val != $refdat{'reiter'}->{'observed'}"
);

# -- even works all the way to deviation p_value?
$val = $runs->p_value(
    data  => $refdat{'reiter'}->{'data'},
    exact => 0,
    ccorr => 1,
    tails => 1
);
ok(
    equal( $val, $refdat{'reiter'}->{'p_value'} ),
    "p_value  $val != $refdat{'reiter'}->{'p_value'}"
);

eval { $runs->load( $refdat{'swed_1943'}->{'data'} ); };
ok(
    !$@,
    do { chomp $@; "Data load failed: $@"; }
);
$val = $runs->observed();
ok(
    equal( $val, $refdat{'swed_1943'}->{'observed'} ),
    "observed  $val != $refdat{'swed_1943'}->{'observed'}"
);

# observed_per_state():
# -- wantarray:
my @runs_per_state = $runs->observed_per_state();
ok( equal( $runs_per_state[0], 3 ),
    "runcount observed_per_state 'H'; $runs_per_state[0] != 2" );
ok( equal( $runs_per_state[1], 2 ),
    "runcount observed_per_state 'D': $runs_per_state[1] != 2" );

## -- expect hashref:
my $h_runs_per_state = $runs->observed_per_state();
ok( equal( $h_runs_per_state->{'H'}, 3 ),
    "runcount observed_per_state 'H': $h_runs_per_state->{'H'} != 2" );
ok( equal( $h_runs_per_state->{'D'}, 2 ),
    "runcount observed_per_state 'D': $h_runs_per_state->{'D'} != 2" );
   

# expected():
$val = $runs->expected();
ok(
    equal( $val, $refdat{'swed_1943'}->{'expected'} ),
    "expected  $val != $refdat{'swed_1943'}->{'expected'}"
);

$val = $runs->z_value();
ok(
    equal( $val, $refdat{'swed_1943'}->{'z_value'} ),
    "z_value  $val != $refdat{'swed_1943'}->{'z_value'}"
);

$val = $runs->p_value( tails => 1 );
ok(
    equal( $val, $refdat{'swed_1943'}->{'p_value'} ),
    "$val = $refdat{'swed_1943'}->{'p_value'}"
);

$runs->unload();

# Data from Swed & Eisenhart after pooling:
@raw_data = ( 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0 );
eval { $runs->load(@raw_data); };
ok( !$@ );

$val = $runs->observed();
ok(
    equal( $val, $refdat{'sw2'}->{'observed'} ),
    "observed  $val != $refdat{'sw2'}->{'observed'}"
);

@runs_per_state = $runs->observed_per_state();
ok( equal( $runs_per_state[0], 2 ),
    "runcount observed_per_state $runs_per_state[0] != 2" );
ok( equal( $runs_per_state[1], 2 ),
    "runcount observed_per_state $runs_per_state[0] != 2" );

$val = $runs->p_value( tails => 1, ccorr => 1 );
ok(
    equal( $val, $refdat{'sw2'}->{'p_value'} ),
    "p_value  $val != $refdat{'sw2'}->{'p_value'}"
);

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
