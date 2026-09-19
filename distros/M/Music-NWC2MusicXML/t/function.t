#!/usr/bin/perl
use strict;
use warnings;

# White-box function tests for all Music::NWC2MusicXML::* modules.
# Private helpers are invoked via fully-qualified package names.
# Mocks are applied only where behaviour under test requires isolating
# a dependency (e.g. verifying carp is reached without actually printing).

use Test::Most;
use Test::Mockingbird qw(mock_scoped);
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(blessed);

use lib 'lib';
use Music::NWC2MusicXML::Event;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Diagnostics;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::MusicXML;

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

Readonly::Scalar my $TREBLE  => 'Treble';
Readonly::Scalar my $BASS    => 'Bass';
Readonly::Scalar my $ALTO    => 'Alto';
Readonly::Scalar my $TENOR   => 'Tenor';

# Build a minimal but valid Score (one staff, one bar, one note)
sub _minimal_score {
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Piano');
	$staff->set_initial_clef($TREBLE);
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Bar',
		data => { style => 'normal' },
	));
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);
	return $score;
}

# Short alias for package-local private functions
sub _event_gcd  { Music::NWC2MusicXML::Event::_gcd(@_)          }
sub _event_add  { Music::NWC2MusicXML::Event::_add_rationals(@_) }
sub _event_red  { Music::NWC2MusicXML::Event::_reduce_rational(@_) }
sub _event_val  { Music::NWC2MusicXML::Event::_validate_rational(@_) }

sub _parser_fth { Music::NWC2MusicXML::Parser::_fifths_from_signature(@_) }
sub _parser_dur { Music::NWC2MusicXML::Parser::_parse_dur_tokens(@_)      }
sub _parser_opt { Music::NWC2MusicXML::Parser::_parse_opts(@_)            }

sub _xml_esc    { Music::NWC2MusicXML::MusicXML::_xml_escape(@_)          }
sub _mxml_lcm   { Music::NWC2MusicXML::MusicXML::_lcm(@_)                 }
sub _mxml_gcd   { Music::NWC2MusicXML::MusicXML::_gcd(@_)                 }
sub _mxml_ticks { Music::NWC2MusicXML::MusicXML::_rational_to_ticks(@_)   }
sub _mxml_lay   { Music::NWC2MusicXML::MusicXML::_compute_page_layout(@_) }

# ============================================================================
# 1. Music::NWC2MusicXML::Event -- private arithmetic helpers
# ============================================================================

subtest 'Event::_gcd' => sub {
	is _event_gcd(12, 8), 4,  'gcd(12,8) = 4';
	is _event_gcd(7,  0), 7,  'gcd(7,0) = 7  (any number divides 0)';
	is _event_gcd(0,  5), 5,  'gcd(0,5) = 5';
	is _event_gcd(9,  3), 3,  'gcd(9,3) = 3';
	is _event_gcd(1,  1), 1,  'gcd(1,1) = 1';
	is _event_gcd(17, 13), 1, 'gcd of two primes = 1';

	diag 'gcd values verified' if $ENV{TEST_VERBOSE};
};

subtest 'Event::_add_rationals' => sub {
	my $r = _event_add([1, 2], [1, 3]);
	is_deeply $r, [5, 6], '1/2 + 1/3 = 5/6 (before reduction)';

	$r = _event_add([1, 1], [1, 2]);
	is_deeply $r, [3, 2], '1 + 1/2 = 3/2';

	$r = _event_add([0, 1], [3, 4]);
	is_deeply $r, [3, 4], '0 + 3/4 = 3/4';
};

subtest 'Event::_reduce_rational' => sub {
	is_deeply _event_red([4, 8]),  [1, 2], '4/8 reduces to 1/2';
	is_deeply _event_red([6, 4]),  [3, 2], '6/4 reduces to 3/2';
	is_deeply _event_red([1, 1]),  [1, 1], '1/1 stays 1/1';
	is_deeply _event_red([0, 1]),  [0, 1], '0/1 stays 0/1';
	is_deeply _event_red([7, 4]),  [7, 4], 'already reduced 7/4';
};

subtest 'Event::_validate_rational -- valid inputs' => sub {
	lives_ok { _event_val([0, 1]) }  'zero numerator is valid';
	lives_ok { _event_val([3, 2]) }  'positive numerator and denominator';
	lives_ok { _event_val([100, 7]) } 'large values valid';
};

subtest 'Event::_validate_rational -- invalid inputs' => sub {
	# Denominator must be a positive integer (not zero)
	throws_ok { _event_val([1, 0]) }
		qr/Rational arguments must be positive integers/,
		'zero denominator croaks';

	# Negative numerator is not a non-negative integer
	throws_ok { _event_val([-1, 2]) }
		qr/Rational arguments must be positive integers/,
		'negative numerator croaks';

	# Non-arrayref
	throws_ok { _event_val('bad') }
		qr/Rational arguments/,
		'scalar argument croaks';

	# Wrong array length
	throws_ok { _event_val([1, 2, 3]) }
		qr/Rational arguments/,
		'three-element array croaks';
};

# ============================================================================
# 2. Music::NWC2MusicXML::Event -- rational_from_nwc_duration
# ============================================================================

subtest 'Event::rational_from_nwc_duration -- undotted' => sub {
	my @cases = (
		['Whole',  [4, 1]],
		['Half',   [2, 1]],
		['4th',    [1, 1]],
		['8th',    [1, 2]],
		['16th',   [1, 4]],
		['32nd',   [1, 8]],
		['64th',   [1, 16]],
	);
	for my $c (@cases) {
		my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration($c->[0], 0);
		is_deeply $r, $c->[1], "$c->[0] (0 dots) = $c->[1][0]/$c->[1][1]";
	}
};

subtest 'Event::rational_from_nwc_duration -- dotted' => sub {
	# Dotted note = base * 3/2
	my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1);
	is_deeply $r, [3, 2], 'dotted quarter = 3/2';

	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', 1);
	is_deeply $r, [3, 1], 'dotted half = 3/1';

	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('8th', 1);
	is_deeply $r, [3, 4], 'dotted 8th = 3/4';

	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('Whole', 1);
	is_deeply $r, [6, 1], 'dotted whole = 6/1';
};

subtest 'Event::rational_from_nwc_duration -- double-dotted' => sub {
	# Double-dotted = base + base/2 + base/4 = base * 7/4
	my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 2);
	is_deeply $r, [7, 4], 'double-dotted quarter = 7/4';

	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', 2);
	is_deeply $r, [7, 2], 'double-dotted half = 7/2';

	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('8th', 2);
	is_deeply $r, [7, 8], 'double-dotted 8th = 7/8';
};

subtest 'Event::rational_from_nwc_duration -- bad duration croaks' => sub {
	throws_ok {
		Music::NWC2MusicXML::Event->rational_from_nwc_duration('Quarter', 0)
	} qr/Unrecognised NWC duration: Quarter/,
	'NWC uses "4th" not "Quarter" -- wrong name croaks';
};

# ============================================================================
# 3. Music::NWC2MusicXML::Event -- constructor and accessors
# ============================================================================

subtest 'Event::new -- musical event' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '-3', base_dur => '4th', dots => 0,
		              articulations => ['Tenuto'] },
	);

	ok defined $ev,                  'object created';
	is blessed($ev), 'Music::NWC2MusicXML::Event', 'correct class';
	is $ev->type,    'Note',         'type accessor';
	is_deeply $ev->duration, [1, 1], 'duration accessor';
	is $ev->data->{nwc_pos}, '-3',   'data accessor';
	ok $ev->is_musical_event,        'is_musical_event true for Note';
	ok !$ev->is_metadata,            'is_metadata false for Note';

	returns_ok($ev->type,     { type => 'scalar'  }, 'type returns scalar');
	returns_ok($ev->duration, { type => 'arrayref' }, 'duration returns arrayref');
	returns_ok($ev->data,     { type => 'hashref'  }, 'data returns hashref');
};

subtest 'Event::new -- unknown type becomes UnsupportedEvent with warning' => sub {
	my $ev;
	# _validate_rational requires arrayref; use defaults by omitting duration
	warning_like {
		$ev = Music::NWC2MusicXML::Event->new(type => 'SomeFutureNWCObject');
	} qr/Unknown event type.*SomeFutureNWCObject/, 'warns about unknown type';

	is $ev->type,      'UnsupportedEvent',     'type coerced to UnsupportedEvent';
	is $ev->nwc_label, 'SomeFutureNWCObject',  'original label preserved in nwc_label';
};

subtest 'Event::new -- metadata type recognised' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(
		type => 'SongInfo',
		data => { Title => 'My Song' },
	);
	ok $ev->is_metadata,         'is_metadata true for SongInfo';
	ok !$ev->is_musical_event,   'is_musical_event false for SongInfo';
};

subtest 'Event::rational_add class method' => sub {
	my $r = Music::NWC2MusicXML::Event->rational_add([1, 3], [1, 6]);
	is_deeply $r, [1, 2], '1/3 + 1/6 = 1/2 (reduced)';
};

subtest 'Event::rational_to_float class method' => sub {
	my $f = Music::NWC2MusicXML::Event->rational_to_float([3, 2]);
	ok abs($f - 1.5) < 1e-9, '3/2 -> 1.5';
};

subtest 'Event -- memory cycle' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Rest', duration => [1,2]);
	memory_cycle_ok($ev, 'Event object has no circular references');
};

# ============================================================================
# 4. Music::NWC2MusicXML::Score
# ============================================================================

subtest 'Score::new -- defaults' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	ok defined $score,                  'object created';
	is blessed($score), 'Music::NWC2MusicXML::Score', 'correct class';
	is $score->staff_count, 0,          'no staves initially';
	is_deeply $score->metadata,   {},   'metadata starts empty';
	is_deeply $score->page_setup, {},   'page_setup starts empty';

	returns_ok($score->staves,     { type => 'arrayref' }, 'staves returns arrayref');
	returns_ok($score->metadata,   { type => 'hashref'  }, 'metadata returns hashref');
	returns_ok($score->page_setup, { type => 'hashref'  }, 'page_setup returns hashref');
};

subtest 'Score::set_metadata_field and metadata' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $ret   = $score->set_metadata_field('Title', 'Pilgrim');
	is $ret, $score,                   'set_metadata_field returns $self for chaining';
	is $score->metadata->{Title}, 'Pilgrim', 'Title stored';

	$score->set_metadata_field('Copyright1', 'c 2025');
	is $score->metadata->{Copyright1}, 'c 2025', 'Copyright1 stored';
};

subtest 'Score::add_staff -- success' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $s1    = Music::NWC2MusicXML::Staff->new(name => 'Violin');
	my $s2    = Music::NWC2MusicXML::Staff->new(name => 'Cello');

	$score->add_staff($s1);
	is $score->staff_count, 1, 'one staff after first add';
	$score->add_staff($s2);
	is $score->staff_count, 2, 'two staves after second add';

	is $score->current_staff->name, 'Cello', 'current_staff is the last added';
	is scalar @{ $score->staves }, 2, 'staves arrayref has 2 entries';
};

subtest 'Score::add_staff -- rejects non-Staff' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	throws_ok { $score->add_staff('not a staff') }
		qr/add_staff.*argument must be/, 'plain string croaks';
	throws_ok { $score->add_staff(42) }
		qr/add_staff.*argument must be/, 'integer croaks';
	is $score->staff_count, 0, 'no staves added after failures';
};

subtest 'Score::validate -- empty score' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $diags = $score->validate;
	returns_ok($diags, { type => 'arrayref' }, 'validate returns arrayref');
	ok @$diags > 0, 'diagnostics populated when no staves';
};

subtest 'Score -- memory cycle' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff(Music::NWC2MusicXML::Staff->new(name => 'A'));
	memory_cycle_ok($score, 'Score with staff has no circular references');
};

# ============================================================================
# 5. Music::NWC2MusicXML::Staff
# ============================================================================

subtest 'Staff::new -- defaults' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	is $s->name,           'Staff',    'default name';
	is $s->group,          'Standard', 'default group';
	is $s->lines,          5,          'default 5 lines';
	is $s->visible,        1,          'default visible';
	is_deeply $s->instrument, {},      'default empty instrument';
	ok !defined $s->initial_clef,      'no initial clef';
	ok !defined $s->initial_key,       'no initial key';
	ok !defined $s->initial_timesig,   'no initial timesig';
};

subtest 'Staff::new -- named args' => sub {
	my $s = Music::NWC2MusicXML::Staff->new(
		name       => 'Violin I',
		group      => 'Strings',
		lines      => 5,
		instrument => { name => 'Violin', patch => 40 },
	);
	is $s->name,               'Violin I',  'name stored';
	is $s->group,              'Strings',   'group stored';
	is $s->instrument->{name}, 'Violin',    'instrument name stored';
	is $s->instrument->{patch}, 40,         'instrument patch stored';
};

subtest 'Staff::set_initial_clef / initial_clef' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	my $ret = $s->set_initial_clef($BASS);
	is $ret, $s,             'returns $self for chaining';
	is $s->initial_clef, $BASS, 'clef stored';
};

subtest 'Staff::set_initial_key / initial_key' => sub {
	my $s    = Music::NWC2MusicXML::Staff->new;
	my $key  = { signature => 'F#,C#', tonic => 'D', fifths => 2 };
	$s->set_initial_key($key);
	is_deeply $s->initial_key, $key, 'key data stored';
};

subtest 'Staff::set_initial_timesig / initial_timesig' => sub {
	my $s  = Music::NWC2MusicXML::Staff->new;
	my $ts = { beats => 3, beat_type => 4 };
	$s->set_initial_timesig($ts);
	is_deeply $s->initial_timesig, $ts, 'timesig stored';
};

subtest 'Staff::add_event -- success and chaining' => sub {
	my $s  = Music::NWC2MusicXML::Staff->new;
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Rest', duration => [1,1]);
	my $ret = $s->add_event($ev);
	is $ret, $s,             'add_event returns $self';
	is $s->event_count, 1,   'event_count 1 after add';
};

subtest 'Staff::add_event -- rejects non-Event' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	throws_ok { $s->add_event('bad') }
		qr/add_event.*argument must be/, 'string rejected';
	throws_ok { $s->add_event({}) }
		qr/add_event.*argument must be/, 'hashref rejected';
	is $s->event_count, 0, 'no events added';
};

subtest 'Staff::events and musical_events' => sub {
	my $s    = Music::NWC2MusicXML::Staff->new;
	my $note = Music::NWC2MusicXML::Event->new(type => 'Note',
		duration => [1,1], data => { nwc_pos=>'0', base_dur=>'4th',
		dots=>0, articulations=>[], opts=>{} });
	my $meta = Music::NWC2MusicXML::Event->new(type => 'SongInfo');
	$s->add_event($note);
	$s->add_event($meta);

	is $s->event_count, 2, 'event_count includes all';
	returns_ok($s->events,          { type => 'arrayref' }, 'events returns arrayref');
	returns_ok($s->musical_events,  { type => 'arrayref' }, 'musical_events returns arrayref');

	# SongInfo is metadata, not musical -- should be excluded
	is scalar @{ $s->musical_events }, 1, 'musical_events excludes metadata';
};

subtest 'Staff::has_notes' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	ok !$s->has_notes, 'empty staff has no notes';

	# Tempo alone does not count as a sounding event
	$s->add_event(Music::NWC2MusicXML::Event->new(type => 'Tempo',
		data => { bpm => 120, base => 'Quarter' }));
	ok !$s->has_notes, 'Tempo event alone does not satisfy has_notes';

	# A Rest counts
	$s->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Rest', duration => [1,1],
		data => { base_dur => '4th', dots => 0, opts => {} }));
	ok $s->has_notes, 'Rest event satisfies has_notes';

	# Bar counts
	my $s2 = Music::NWC2MusicXML::Staff->new;
	$s2->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Bar', data => { style => 'normal' }));
	ok $s2->has_notes, 'Bar event satisfies has_notes';
};

subtest 'Staff -- memory cycle' => sub {
	my $s = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$s->add_event(Music::NWC2MusicXML::Event->new(type => 'Rest', duration => [1,2]));
	memory_cycle_ok($s, 'Staff with events has no circular references');
};

# ============================================================================
# 6. Music::NWC2MusicXML::Diagnostics
# ============================================================================

subtest 'Diagnostics::new -- default level' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new;
	ok defined $d, 'object created';
	is blessed($d), 'Music::NWC2MusicXML::Diagnostics', 'correct class';
	ok !$d->has_warnings, 'no warnings on creation';
	returns_ok($d->warnings, { type => 'arrayref' }, 'warnings returns arrayref');
};

subtest 'Diagnostics::new -- explicit levels' => sub {
	for my $lvl (qw(quiet normal verbose debug)) {
		my $d = Music::NWC2MusicXML::Diagnostics->new(level => $lvl);
		ok defined $d, "level '$lvl' accepted";
	}
};

subtest 'Diagnostics::new -- bad level croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Diagnostics->new(level => 'loud') }
		qr/Unknown log level: loud/, 'unknown level croaks';
};

subtest 'Diagnostics::warn_unsupported' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $ret = $d->warn_unsupported(
		file   => 'score.nwc',
		staff  => 'Staff 1',
		object => 'UserTool',
	);
	is $ret, $d, 'returns $self for chaining';
	ok $d->has_warnings, 'has_warnings true after recording';
	is scalar @{ $d->warnings }, 1, 'one warning recorded';
	like $d->warnings->[0], qr/UserTool/, 'warning contains object name';
	like $d->warnings->[0], qr/score\.nwc/, 'warning contains filename';
};

subtest 'Diagnostics::warn_approximate' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	$d->warn_approximate(
		file          => 'a.nwc',
		staff         => '1',
		feature       => 'TrillOrnament',
		approximation => 'trill-mark',
	);
	is scalar @{ $d->warnings }, 1, 'warning recorded';
	like $d->warnings->[0], qr/TrillOrnament/, 'feature in message';
};

subtest 'Diagnostics::count -- valid outcomes' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	for my $outcome (qw(processed successful warnings failed)) {
		lives_ok { $d->count(outcome => $outcome) } "outcome '$outcome' accepted";
	}
};

subtest 'Diagnostics::count -- invalid outcome croaks' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	throws_ok { $d->count(outcome => 'nonsense') }
		qr/Unknown counter: nonsense/, 'bad outcome key croaks';
};

subtest 'Diagnostics -- memory cycle' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	$d->warn_unsupported(file=>'x', staff=>'S', object=>'O');
	memory_cycle_ok($d, 'Diagnostics has no circular references');
};

# ============================================================================
# 7. Music::NWC2MusicXML::Parser -- private helpers
# ============================================================================

subtest 'Parser::_fifths_from_signature -- C and empty' => sub {
	is _parser_fth('C'),  0, '"C" = 0 fifths';
	is _parser_fth(''),   0, 'empty string = 0 fifths';
	is _parser_fth(undef),0, 'undef = 0 fifths';
};

subtest 'Parser::_fifths_from_signature -- sharps' => sub {
	is _parser_fth('F#'),              1, '1 sharp  (G major)';
	is _parser_fth('F#,C#'),           2, '2 sharps (D major)';
	is _parser_fth('F#,C#,G#'),        3, '3 sharps (A major)';
	is _parser_fth('F#,C#,G#,D#,A#,E#,B#'), 7, '7 sharps (C# major)';
};

subtest 'Parser::_fifths_from_signature -- flats' => sub {
	is _parser_fth('Bb'),              -1, '1 flat  (F major)';
	is _parser_fth('Bb,Eb'),           -2, '2 flats (Bb major)';
	is _parser_fth('Bb,Eb,Ab'),        -3, '3 flats (Eb major)';
	is _parser_fth('Bb,Eb,Ab,Db,Gb,Cb,Fb'), -7, '7 flats (Cb major)';
};

subtest 'Parser::_parse_dur_tokens -- base duration only' => sub {
	my ($base, $dots, $trip, $artic) = _parser_dur('4th');
	is $base,  '4th', 'base duration parsed';
	is $dots,  0,     'no dots';
	ok !defined $trip, 'no triplet';
	is_deeply $artic, [], 'no articulations';
};

subtest 'Parser::_parse_dur_tokens -- dotted' => sub {
	my ($base, $dots, $trip, $artic) = _parser_dur('Half,Dotted');
	is $base, 'Half', 'base = Half';
	is $dots, 1,      'one dot';
};

subtest 'Parser::_parse_dur_tokens -- double-dotted' => sub {
	my ($base, $dots) = _parser_dur('Whole,DblDotted');
	is $base, 'Whole', 'base = Whole';
	is $dots, 2,       'two dots';
};

subtest 'Parser::_parse_dur_tokens -- triplet' => sub {
	my ($base, $dots, $trip, $artic) = _parser_dur('8th,Triplet');
	is $base,  '8th',    'base = 8th';
	is $trip,  'Middle', 'default triplet position = Middle';
	is_deeply $artic, [], 'no articulations';
};

subtest 'Parser::_parse_dur_tokens -- articulations' => sub {
	my ($base, $dots, $trip, $artic) = _parser_dur('4th,Tenuto,Slur');
	is $base,    '4th', 'base = 4th';
	is_deeply $artic, ['Tenuto', 'Slur'], 'articulations extracted';
};

subtest 'Parser::_parse_dur_tokens -- combined' => sub {
	my ($base, $dots, $trip, $artic) = _parser_dur('8th,Dotted,Triplet=End,Staccato');
	is $base, '8th',    'base';
	is $dots, 1,        'dotted';
	is $trip, 'End',    'triplet position';
	is_deeply $artic, ['Staccato'], 'articulation';
};

subtest 'Parser::_parse_opts -- various forms' => sub {
	is_deeply _parser_opt(undef),  {}, 'undef -> empty hash';
	is_deeply _parser_opt(''),     {}, 'empty string -> empty hash';

	my $h = _parser_opt('Crescendo');
	is $h->{Crescendo}, 1, 'bare flag -> 1';

	$h = _parser_opt('Volume=80');
	is $h->{Volume}, '80', 'key=value parsed';

	$h = _parser_opt('Crescendo,Volume=80,Color=red');
	is $h->{Crescendo}, 1,     'flag in compound opts';
	is $h->{Volume},    '80',  'key=value in compound opts';
	is $h->{Color},     'red', 'second key=value';
};

# ============================================================================
# 8. Music::NWC2MusicXML::Parser -- _tokenise_record and _fields_to_hash
# ============================================================================

subtest 'Parser::_tokenise_record -- basic' => sub {
	my $p      = Music::NWC2MusicXML::Parser->new;
	my $fields = $p->_tokenise_record('|Note|Dur:4th|Pos:0');
	is_deeply $fields, ['Note', 'Dur:4th', 'Pos:0'], 'three fields tokenised';
};

subtest 'Parser::_tokenise_record -- quoted pipe' => sub {
	my $p      = Music::NWC2MusicXML::Parser->new;
	# A quoted string may contain | without splitting
	my $fields = $p->_tokenise_record('|SongInfo|Title:"Song|With|Pipes"');
	is scalar @$fields, 2, 'quoted pipe does not create extra fields';
	is $fields->[1], 'Title:Song|With|Pipes', 'pipe preserved inside quotes';
};

subtest 'Parser::_tokenise_record -- quoted escape' => sub {
	my $p      = Music::NWC2MusicXML::Parser->new;
	my $fields = $p->_tokenise_record('|SongInfo|Title:"He said \\"hi\\""');
	like $fields->[1], qr/He said "hi"/, 'backslash-quote unescaped inside token';
};

subtest 'Parser::_fields_to_hash -- key:value fields' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $h = $p->_fields_to_hash(['Title:My Song', 'Author:Trad']);
	is $h->{Title},  'My Song', 'Title parsed';
	is $h->{Author}, 'Trad',    'Author parsed';
};

subtest 'Parser::_fields_to_hash -- positional (no colon)' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $h = $p->_fields_to_hash(['SectionClose']);
	is $h->{_positional}, 'SectionClose', 'positional token stored under _positional';
};

# ============================================================================
# 9. Music::NWC2MusicXML::Parser -- parse (public)
# ============================================================================

Readonly::Scalar my $MINIMAL_NWCTXT => <<'END_NWC';
!NoteWorthyComposer(2.75)
|SongInfo|Title:"Test Score"|Author:"Trad"
|PgSetup|StaffSize:16|Zoom:3
|AddStaff|Name:"Piano"|Group:Standard
|StaffProperties|EndingBar:Section Close|Visible:Y|BoundaryTop:14|BoundaryBottom:14|Lines:5|Color:Default
|StaffInstrument|Name:"Grand Piano"|Patch:0
|Clef|Type:Treble
|Key|Signature:C
|TimeSig|Signature:4/4
|Tempo|Tempo:120|Base:Quarter
|Note|Dur:4th|Pos:0
|Bar|
|Note|Dur:Half|Pos:-2
|Bar|Style:Double
END_NWC

subtest 'Parser::parse -- empty / undef input croaks' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	throws_ok { $p->parse(undef) }
		qr/NWCTXT input is empty or undefined/, 'undef croaks';
	throws_ok { $p->parse('') }
		qr/NWCTXT input is empty or undefined/, 'empty string croaks';
};

subtest 'Parser::parse -- missing header croaks' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	throws_ok { $p->parse("Not a header\n|SongInfo|Title:X\n") }
		qr/does not begin with expected header/, 'bad header croaks';
};

subtest 'Parser::parse -- minimal valid NWCTXT' => sub {
	my $p     = Music::NWC2MusicXML::Parser->new;
	my $score;
	lives_ok { $score = $p->parse($MINIMAL_NWCTXT) } 'minimal NWCTXT parses without error';

	ok defined $score, 'score object returned';
	is blessed($score), 'Music::NWC2MusicXML::Score', 'correct class';

	is $score->metadata->{Title},  'Test Score', 'Title extracted';
	is $score->metadata->{Author}, 'Trad',        'Author extracted';
	is $score->staff_count, 1, 'one staff parsed';

	my $staff = $score->staves->[0];
	is $staff->name, 'Piano',   'staff name';
	is $staff->initial_clef, $TREBLE, 'initial clef';
	ok defined $staff->initial_key,    'initial key set';
	is $staff->initial_key->{fifths}, 0, 'C major = 0 fifths';
	is $staff->initial_timesig->{beats}, 4, 'time sig beats';

	diag 'event count: ' . $staff->event_count if $ENV{TEST_VERBOSE};
};

subtest 'Parser::parse -- Copyright1 and Copyright2 extracted' => sub {
	my $nwc = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Copyright1:\"Line One\"|Copyright2:\"Line Two\"\n"
		. "|AddStaff|Name:\"Flute\"\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n";
	my $p    = Music::NWC2MusicXML::Parser->new;
	my $score = $p->parse($nwc);
	is $score->metadata->{Copyright1}, 'Line One', 'Copyright1 stored';
	is $score->metadata->{Copyright2}, 'Line Two', 'Copyright2 stored';
};

subtest 'Parser::parse -- clef before notes sets initial_clef' => sub {
	my $nwc = "!NoteWorthyComposer(2.75)\n"
		. "|AddStaff|Name:\"Bass\"\n"
		. "|Clef|Type:Bass\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n";
	my $p     = Music::NWC2MusicXML::Parser->new;
	my $score = $p->parse($nwc);
	is $score->staves->[0]->initial_clef, $BASS, 'Bass clef before notes -> initial_clef';
};

subtest 'Parser::parse -- clef after notes emitted as event' => sub {
	my $nwc = "!NoteWorthyComposer(2.75)\n"
		. "|AddStaff|Name:\"Piano\"\n"
		. "|Clef|Type:Treble\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n"
		. "|Clef|Type:Bass\n"    # mid-staff clef change
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n";
	my $p     = Music::NWC2MusicXML::Parser->new;
	my $score = $p->parse($nwc);
	my $staff = $score->staves->[0];
	is $staff->initial_clef, $TREBLE, 'initial clef is Treble';
	my @clef_events = grep { $_->type eq 'Clef' } @{ $staff->events };
	is scalar @clef_events, 1, 'mid-staff Bass clef emitted as Clef event';
	is $clef_events[0]->data->{nwc_clef}, $BASS, 'Clef event carries Bass';
};

subtest 'Parser::parse -- TempoVariance produces TempoVariance event' => sub {
	my $nwc = "!NoteWorthyComposer(2.75)\n"
		. "|AddStaff|Name:\"Vln\"\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|TempoVariance|Style:Accelerando|Pos:7\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n";
	my $p     = Music::NWC2MusicXML::Parser->new;
	my $score = $p->parse($nwc);
	my @tv    = grep { $_->type eq 'TempoVariance' } @{ $score->staves->[0]->events };
	is scalar @tv, 1, 'one TempoVariance event emitted';
	is $tv[0]->data->{style}, 'Accelerando', 'style stored';
	is $tv[0]->data->{placement}, 'above', 'positive Pos -> above';
};

subtest 'Parser::parse -- reuse across calls (state reset)' => sub {
	# Verify that calling parse() twice on the same parser object does not
	# bleed state from the first call into the second.
	my $nwc1 = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"First\"\n"
		. "|AddStaff|Name:\"A\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $nwc2 = "!NoteWorthyComposer(2.75)\n"
		. "|AddStaff|Name:\"B\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $p = Music::NWC2MusicXML::Parser->new;
	my $s1 = $p->parse($nwc1);
	my $s2 = $p->parse($nwc2);
	is $s1->metadata->{Title}, 'First', 'first score title intact';
	ok !defined $s2->metadata->{Title}, 'second score has no title bleed';
	is $s2->staves->[0]->name, 'B', 'second score staff name correct';
};

subtest 'Parser -- memory cycle' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	memory_cycle_ok($p, 'Parser has no circular references before parse');
	$p->parse($MINIMAL_NWCTXT);
	memory_cycle_ok($p, 'Parser has no circular references after parse');
};

# ============================================================================
# 10. Music::NWC2MusicXML::MusicXML -- private helpers
# ============================================================================

subtest 'MusicXML::_xml_escape -- XML special characters' => sub {
	is _xml_esc('&'),  '&amp;',  'ampersand escaped';
	is _xml_esc('<'),  '&lt;',   'less-than escaped';
	is _xml_esc('>'),  '&gt;',   'greater-than escaped';
	is _xml_esc('"'),  '&quot;', 'double-quote escaped';
	is _xml_esc("'"),  '&apos;', 'single-quote escaped';
	is _xml_esc('A & B < C'), 'A &amp; B &lt; C', 'combined escaping';
};

subtest 'MusicXML::_xml_escape -- non-ASCII' => sub {
	# Copyright sign U+00A9 must be numeric-entity escaped to keep output ASCII
	my $copy = "\x{A9}";
	is _xml_esc($copy), '&#169;', 'copyright sign -> &#169;';

	# Multi-char non-ASCII
	my $two = "\x{C9}\x{E0}";   # E-acute, a-grave
	is _xml_esc($two), '&#201;&#224;', 'two non-ASCII chars escaped separately';
};

subtest 'MusicXML::_xml_escape -- undef and empty' => sub {
	is _xml_esc(undef), '', 'undef -> empty string';
	is _xml_esc(''),    '', 'empty string -> empty string';
	is _xml_esc('abc'), 'abc', 'plain ASCII unchanged';
};

subtest 'MusicXML::_lcm and _gcd' => sub {
	is _mxml_gcd(12, 8), 4,  'gcd(12,8) = 4';
	is _mxml_gcd(7,  1), 1,  'gcd(7,1) = 1';
	is _mxml_lcm(4,  6), 12, 'lcm(4,6) = 12';
	is _mxml_lcm(3,  5), 15, 'lcm(3,5) = 15 (coprime)';
	is _mxml_lcm(8, 12), 24, 'lcm(8,12) = 24';
};

subtest 'MusicXML::_rational_to_ticks' => sub {
	# ticks = round(num * divisions / den)
	is _mxml_ticks([1, 1], 24), 24, 'quarter at div=24 -> 24 ticks';
	is _mxml_ticks([1, 2], 24), 12, 'eighth at div=24 -> 12 ticks';
	is _mxml_ticks([3, 2], 24), 36, 'dotted quarter at div=24 -> 36 ticks';
	is _mxml_ticks([1, 4], 24),  6, '16th at div=24 -> 6 ticks';
	is _mxml_ticks([4, 1], 24), 96, 'whole at div=24 -> 96 ticks';
};

subtest 'MusicXML::_compute_page_layout -- defaults (A4, 1.27 cm margin)' => sub {
	my $lay = _mxml_lay({});
	# A4: 297 mm tall, 210 mm wide; TENTHS_PER_MM = 40/7.2175 ~= 5.5425
	my $tpm = 40 / 7.2175;
	ok abs($lay->{page_height} - 297 * $tpm) < 0.1, 'page_height ~= A4';
	ok abs($lay->{page_width}  - 210 * $tpm) < 0.1, 'page_width  ~= A4';
	ok abs($lay->{center_x} - $lay->{page_width} / 2) < 0.01, 'center_x = half width';
	ok $lay->{margin_t} > 0, 'margin_t positive';

	returns_ok($lay, { type => 'hashref' }, '_compute_page_layout returns hashref');
	diag "page_height=$lay->{page_height} center_x=$lay->{center_x}" if $ENV{TEST_VERBOSE};
};

subtest 'MusicXML::_compute_page_layout -- custom margin' => sub {
	my $lay_default = _mxml_lay({});
	my $lay_wide    = _mxml_lay({ Left => 2.54 });   # 2.54 cm = 1 inch
	ok $lay_wide->{margin_t} > $lay_default->{margin_t}, 'wider margin produces larger margin_t';
};

subtest 'MusicXML::_pos_to_pitch -- Treble clef reference' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	# NWC pos is relative to the middle line (3rd line from bottom) of the staff.
	# Treble middle line = B4 (ref [6,4], index=34). pos -9 -> index 25 -> G3.
	# Bass middle line = D3 (ref [1,3], index=22). pos -7 -> index 15 -> D2.
	my $p = $gen->_pos_to_pitch('-9', $TREBLE, 0);
	is $p->{step},   'G', 'Treble pos -9 -> step G';
	is $p->{octave}, 3,   'Treble pos -9 -> octave 3';

	my $p2 = $gen->_pos_to_pitch('-7', $BASS, 0);
	is $p2->{step},   'D', 'Bass pos -7 -> step D';
	is $p2->{octave}, 2,   'Bass pos -7 -> octave 2';
};

subtest 'MusicXML::_pos_to_pitch -- accidental prefixes' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;

	my $p = $gen->_pos_to_pitch('#-9', $TREBLE, 0);
	is $p->{step},        'G',     'sharp: step unchanged';
	is $p->{alter},       1,       'sharp: alter = 1';
	is $p->{accidental},  'sharp', 'sharp: accidental = sharp';

	$p = $gen->_pos_to_pitch('b-9', $TREBLE, 0);
	is $p->{alter},       -1,     'flat: alter = -1';
	is $p->{accidental},  'flat', 'flat: accidental = flat';

	$p = $gen->_pos_to_pitch('n-9', $TREBLE, 0);
	is $p->{alter},       0,         'natural: alter = 0';
	is $p->{accidental},  'natural', 'natural: accidental';
};

subtest 'MusicXML::_pos_to_pitch -- tie suffix stripped' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	# '^' suffix marks a tie; pitch parsing should ignore it
	my $tied  = $gen->_pos_to_pitch('-9^',  $TREBLE, 0);
	my $plain = $gen->_pos_to_pitch('-9',   $TREBLE, 0);
	is $tied->{step},   $plain->{step},   'tied pos: same step as plain';
	is $tied->{octave}, $plain->{octave}, 'tied pos: same octave';
};

subtest 'MusicXML::_pos_to_pitch -- key signature alters' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	# With 2 sharps (D major): F and C are sharp.
	# Treble middle line = B4 (ref [6,4], index=34).
	# F4 is step_i=3, octave=4: index = 4*7+3 = 31. pos = 31 - 34 = -3.
	# So pos=-3 on Treble -> F4. In D major, F# -> alter=1.
	my $p = $gen->_pos_to_pitch('-3', $TREBLE, 2);   # D major, 2 sharps
	is $p->{step},  'F', 'pos -3 on Treble -> step F';
	is $p->{alter}, 1,   'F in D major gets alter=1 from key sig';
	ok !defined $p->{accidental}, 'no explicit accidental (from key)';
};

# ============================================================================
# 11. Music::NWC2MusicXML::MusicXML -- annotation passes
# ============================================================================

subtest 'MusicXML::_annotate_events -- empty list' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my $ann = $gen->_annotate_events([]);
	is_deeply $ann, {}, 'empty event list -> empty annotation hash';
	returns_ok($ann, { type => 'hashref' }, 'returns hashref');
};

subtest 'MusicXML::_annotate_events -- slur arc detection' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;

	my $mk_note = sub {
		my ($artic) = @_;
		return Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
			              articulations => $artic, opts => {} },
		);
	};

	# Three-note slur: notes 1-3 carry Slur; note 4 does not.
	my $n1 = $mk_note->(['Slur']);
	my $n2 = $mk_note->(['Slur']);
	my $n3 = $mk_note->(['Slur']);
	my $n4 = $mk_note->([]);

	my $ann = $gen->_annotate_events([$n1, $n2, $n3, $n4]);

	ok $ann->{"$n1"}{slur_start}, 'n1: slur_start set (first in run)';
	ok !$ann->{"$n2"}{slur_start}, 'n2: no second slur_start';
	ok !$ann->{"$n2"}{slur_stop},  'n2: no slur_stop mid-run';
	ok $ann->{"$n3"}{slur_stop},  'n3: slur_stop set (last in run)';
	ok !$ann->{"$n4"}{slur_start}, 'n4: no slur involvement';

	diag 'slur annotation: ' . join(' ', map { "[$_]" } keys %$ann) if $ENV{TEST_VERBOSE};
};

subtest 'MusicXML::_annotate_events -- tie detection' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;

	my $tied = Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '-9^', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	);
	my $target = Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '-9', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	);
	my $ann = $gen->_annotate_events([$tied, $target]);

	ok $ann->{"$tied"}{tie_start_keys}{'-9'},  'tied note has tie_start_keys for pos -9';
	ok $ann->{"$target"}{tie_stop_keys}{'-9'}, 'target note has tie_stop_keys for pos -9';
};

subtest 'MusicXML::_annotate_wedges -- crescendo arc' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my %ann;

	my $mk = sub {
		my ($flag) = @_;
		return Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
			              articulations => [],
			              opts => $flag ? { Crescendo => 1 } : {} },
		);
	};

	my ($n1, $n2, $n3, $n4) = ($mk->(1), $mk->(1), $mk->(1), $mk->(0));
	$gen->_annotate_wedges([$n1, $n2, $n3, $n4], \%ann);

	is $ann{"$n1"}{wedge_start}, 'Crescendo', 'n1: wedge_start = Crescendo';
	ok !$ann{"$n2"}{wedge_start}, 'n2: no second wedge_start';
	ok $ann{"$n3"}{wedge_stop_after}, 'n3: wedge_stop_after (last under arc)';
	ok !$ann{"$n4"}{wedge_stop_after}, 'n4: not part of arc';
};

subtest 'MusicXML::_annotate_wedges -- diminuendo arc' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my %ann;

	my $mk = sub {
		my ($flag) = @_;
		return Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
			              articulations => [],
			              opts => $flag ? { Diminuendo => 1 } : {} },
		);
	};

	my ($n1, $n2) = ($mk->(1), $mk->(0));
	$gen->_annotate_wedges([$n1, $n2], \%ann);

	is $ann{"$n1"}{wedge_start}, 'Diminuendo', 'wedge_start = Diminuendo';
	ok $ann{"$n1"}{wedge_stop_after}, 'arc of 1 note: start and stop on same note';
};

subtest 'MusicXML::_annotate_wedges -- arc open at end of staff' => sub {
	# An arc that runs to the end of the staff (no closing note) must still
	# get a wedge_stop_after so the output stays valid.
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my %ann;
	my $n = Music::NWC2MusicXML::Event->new(
		type => 'Note', duration => [1,1],
		data => { nwc_pos=>'0', base_dur=>'4th', dots=>0,
		          articulations=>[], opts=>{ Crescendo => 1 } },
	);
	$gen->_annotate_wedges([$n], \%ann);
	ok $ann{"$n"}{wedge_stop_after}, 'unclosed arc at EOF gets wedge_stop_after';
};

# ============================================================================
# 12. Music::NWC2MusicXML::MusicXML -- _resolve_part_names
# ============================================================================

subtest 'MusicXML::_resolve_part_names -- unique NWC names used' => sub {
	my $s1 = Music::NWC2MusicXML::Staff->new(name => 'Violin');
	my $s2 = Music::NWC2MusicXML::Staff->new(name => 'Cello');
	my @names = Music::NWC2MusicXML::MusicXML::_resolve_part_names([$s1, $s2]);
	is $names[0], 'Violin', 'non-generic name kept';
	is $names[1], 'Cello',  'non-generic name kept';
};

subtest 'MusicXML::_resolve_part_names -- generic NWC name falls back' => sub {
	my $s1 = Music::NWC2MusicXML::Staff->new(name => 'Staff');
	my $s2 = Music::NWC2MusicXML::Staff->new(name => 'Staff-1');
	my @names = Music::NWC2MusicXML::MusicXML::_resolve_part_names([$s1, $s2]);
	is $names[0], 'Staff-1', 'generic "Staff" -> positional fallback Staff-1';
	is $names[1], 'Staff-2', 'generic "Staff-1" -> positional fallback Staff-2';
};

subtest 'MusicXML::_resolve_part_names -- duplicate non-generic names get positional' => sub {
	# Two staves both called "Piano" must be disambiguated
	my $s1 = Music::NWC2MusicXML::Staff->new(name => 'Piano');
	my $s2 = Music::NWC2MusicXML::Staff->new(name => 'Piano');
	my @names = Music::NWC2MusicXML::MusicXML::_resolve_part_names([$s1, $s2]);
	is $names[0], 'Staff-1', 'duplicate Piano -> Staff-1';
	is $names[1], 'Staff-2', 'duplicate Piano -> Staff-2';
};

subtest 'MusicXML::_resolve_part_names -- instrument name fallback' => sub {
	my $s = Music::NWC2MusicXML::Staff->new(
		name       => 'Staff',   # generic
		instrument => { name => 'Grand Piano', patch => 0 },
	);
	my @names = Music::NWC2MusicXML::MusicXML::_resolve_part_names([$s]);
	is $names[0], 'Grand Piano', 'instrument name used when NWC name is generic';
};

# ============================================================================
# 13. Music::NWC2MusicXML::MusicXML -- generate (public)
# ============================================================================

subtest 'MusicXML::new' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	ok defined $gen, 'object created';
	is blessed($gen), 'Music::NWC2MusicXML::MusicXML', 'correct class';
	# default indent is two spaces
	is $gen->{_indent}, '  ', 'default indent is two spaces';

	my $tab_gen = Music::NWC2MusicXML::MusicXML->new(indent => "\t");
	is $tab_gen->{_indent}, "\t", 'custom tab indent stored';
};

subtest 'MusicXML::generate -- bad argument croaks' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	throws_ok { $gen->generate('not a score') }
		qr/argument must be a Music::NWC2MusicXML::Score/, 'string arg croaks';
	throws_ok { $gen->generate(undef) }
		qr/argument must be a Music::NWC2MusicXML::Score/, 'undef arg croaks';
};

subtest 'MusicXML::generate -- no staves croaks' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	throws_ok { $gen->generate($score) }
		qr/Score contains no staves/, 'empty score croaks';
};

subtest 'MusicXML::generate -- valid output structure' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	my $xml;
	lives_ok { $xml = $gen->generate($score) } 'generates without error';

	returns_ok($xml, { type => 'scalar' }, 'generate returns scalar');
	like $xml, qr/^<\?xml version="1\.0" encoding="UTF-8"\?>/,
		'starts with XML declaration';
	like $xml, qr/<!DOCTYPE score-partwise/, 'has DOCTYPE';
	like $xml, qr/<score-partwise version="4\.0">/, 'MusicXML 4.0 root';
	like $xml, qr/<defaults>/, 'defaults block present';
	like $xml, qr/<scaling>/, 'scaling inside defaults';
	like $xml, qr/<part-list>/, 'part-list present';
	like $xml, qr|<part id="P1">|, 'part element present';
	like $xml, qr/<measure number="1">/, 'at least one measure';
	like $xml, qr|</score-partwise>|, 'root element closed';

	# Pure ASCII: no byte above 0x7F should appear in the output
	ok $xml !~ /[^\x00-\x7F]/, 'output is pure 7-bit ASCII';

	diag substr($xml, 0, 200) if $ENV{TEST_VERBOSE};
};

subtest 'MusicXML::generate -- title and subtitle credits' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Title',  'My Piece');
	$score->set_metadata_field('Author', 'J. Composer');
	my $xml = $gen->generate($score);

	like $xml, qr/<credit-type>title<\/credit-type>/,    'title credit-type';
	like $xml, qr/My Piece/,                             'title text in output';
	like $xml, qr/<credit-type>subtitle<\/credit-type>/, 'subtitle credit-type';
	like $xml, qr/J\. Composer/,                         'author text in output';
	# Both must be page="1" so they appear only on the first page
	my @page1_credits = ($xml =~ /<credit page="1">/g);
	is scalar @page1_credits, 2, 'exactly 2 page-1 credits (title + subtitle)';
};

subtest 'MusicXML::generate -- copyright on every page' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Copyright1', 'Line One');
	$score->set_metadata_field('Copyright2', 'Line Two');
	my $xml = $gen->generate($score);

	# Each copyright line must be in its OWN <credit> with no page attribute
	my @rights_credits = ($xml =~ /<credit-type>rights<\/credit-type>/g);
	is scalar @rights_credits, 2, 'two separate rights credit elements';
	like $xml, qr/Line One/, 'Copyright1 text present';
	like $xml, qr/Line Two/, 'Copyright2 text present';

	# No page attribute on rights credits -> appears on every page
	ok $xml !~ qr/<credit page="\d+">\s*<credit-type>rights/,
		'rights credits have no page attribute';
};

subtest 'MusicXML::generate -- non-ASCII copyright escaped' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Copyright1', "\x{A9} 2025 Author");
	my $xml = $gen->generate($score);
	like $xml, qr/&#169; 2025 Author/, 'copyright symbol escaped to &#169;';
	ok $xml !~ /[^\x00-\x7F]/, 'output still pure ASCII';
};

subtest 'MusicXML::generate -- identification rights combined' => sub {
	# Two copyright lines must appear as one <rights> element in <identification>
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Copyright1', 'Line A');
	$score->set_metadata_field('Copyright2', 'Line B');
	my $xml = $gen->generate($score);

	my @rights_els = ($xml =~ m|<rights>(.*?)</rights>|gs);
	is scalar @rights_els, 1, 'exactly one <rights> element in identification';
	like $rights_els[0], qr/Line A/, 'Copyright1 in rights element';
	like $rights_els[0], qr/Line B/, 'Copyright2 in rights element';
};

subtest 'MusicXML -- memory cycle' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$gen->generate($score);
	memory_cycle_ok($gen, 'MusicXML generator has no circular references after generate');
};

# ============================================================================
# 14. Mock: verify carp is called for unsupported articulations
# ============================================================================

subtest 'MusicXML::generate -- unsupported articulation emits carp' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef($TREBLE);
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => ['UnknownArt'], opts => {} },
	));
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Bar', data => { style => 'normal' }));
	$score->add_staff($staff);

	my $warned = 0;
	my $guard  = mock_scoped('Music::NWC2MusicXML::MusicXML', 'carp',
		sub { $warned++ });
	$gen->generate($score);
	undef $guard;

	ok $warned > 0, 'carp invoked for unsupported articulation token';
};

done_testing();
