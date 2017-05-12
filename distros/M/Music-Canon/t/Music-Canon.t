#!perl
#
# Weaving a safety net being a tedious and thankless task in the
# short term... but then you rewrite the module to use Moo and
# hey hey tests are great!

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

########################################################################
#
# Defaults and Initial Mode Setup

use Music::Canon;

my $mc = Music::Canon->new;

# defaults
is( $mc->get_transpose,  0, 'default transpose' );
is( $mc->get_contrary,   1, 'default contrary' );
is( $mc->get_retrograde, 1, 'default retrograde' );

# major/major the default
$deeply->(
  [ $mc->get_modal_scale_in ],
  [ [qw(2 2 1 2 2 2 1)], [qw(2 2 1 2 2 2 1)] ],
  'major intervals check input'
);
$deeply->(
  [ $mc->get_modal_scale_out ],
  [ [qw(2 2 1 2 2 2 1)], [qw(2 2 1 2 2 2 1)] ],
  'major intervals check output'
);

# set intervals by scale name (via Music::Scales)
$mc->set_modal_scale_in( 'aeolian' );

# or by interval (aeolian again)
$mc->set_modal_scale_out( [qw/2 1 2 2 1 2 2/] );

$deeply->(
  [ $mc->get_modal_scale_in ],
  [ [qw(2 1 2 2 1 2 2)], [qw(2 1 2 2 1 2 2)] ],
  'minor intervals check input'
);
$deeply->(
  [ $mc->get_modal_scale_out ],
  [ [qw(2 1 2 2 1 2 2)], [qw(2 1 2 2 1 2 2)] ],
  'minor intervals check output'
);

########################################################################
#
# Exact Mappings

$mc = Music::Canon->new;

$deeply->( [ $mc->exact_map(qw/0 1 2/) ], [qw/-2 -1 0/], 'exact map' );

$mc->set_transpose(60);
$deeply->(
  [ $mc->exact_map(qw/2 9 5 2 1 2 4 5/) ],
  [qw/59 60 62 63 62 59 55 62/]
);

########################################################################
#
# getters/setters

$mc = Music::Canon->new;

$mc->set_contrary(0);
is( $mc->get_contrary, 0, 'set contrary false' );
$mc->set_contrary(1);
is( $mc->get_contrary, 1, 'set contrary true' );

$mc->set_retrograde(0);
is( $mc->get_retrograde, 0, 'set retrograde false' );
$mc->set_retrograde(1);
is( $mc->get_retrograde, 1, 'set retrograde true' );

# transpose to a note defers the conversion to a pitch until have the
# starting pitch of the input phrase so can convert from that pitch to
# the desired lilypond note
$mc->set_transpose(q{c'});
is( $mc->get_transpose, q{c'}, 'transpose to lilypond note' );

$mc = Music::Canon->new( keep_state => 0 );

# some value that is probably not set by default
my $rand_transpose = 200 + int rand 100;
$mc->set_transpose($rand_transpose);
is( $mc->get_transpose, $rand_transpose, 'get rand transpose' );

my @phrase = qw/0 1 2 1 0 -1 -2 -1 0/;
$mc->set_contrary(0);
$mc->set_retrograde(0);
$deeply->(
  [ $mc->exact_map( \@phrase ) ],
  [ map { $_ += $rand_transpose } @phrase ],
  'exact map via rand transpose'
);

$mc->set_transpose(0);
is( $mc->get_transpose, 0, 'reset transpose' );

# phrase that does not start on zero, as there shouldn't be anything
# special about what the starting pitch is.
@phrase = map { $_ += 10 + int rand 10 } @phrase;
$deeply->( [ $mc->exact_map( \@phrase ) ], \@phrase,
  'start on non-zero pitch' );

########################################################################
#
# Yet More Tests

$mc = Music::Canon->new;

# Forte Numbers!
$mc->set_modal_scale_in( '5-35', '5-25' );
$deeply->(
  [ $mc->get_modal_scale_in ],
  [ [qw/2 2 3 2 3/], [qw/2 1 2 3 4/] ],
  'scale intervals by Forte'
);

$mc = Music::Canon->new( non_octave_scales => 1 );
my @run_up   = 59 .. 86;
my @run_down = 32 .. 59;
$deeply->( [ $mc->exact_map(@run_up) ], \@run_down, 'exact run up' );
$deeply->(
  [ $mc->exact_map( reverse @run_down ) ],
  [ reverse @run_up ],
  'exact run down'
);

plan tests => 21;
