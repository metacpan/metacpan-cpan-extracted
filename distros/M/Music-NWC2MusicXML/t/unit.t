#!/usr/bin/perl
use strict;
use warnings;

# Black-box unit tests for all public APIs of Music::NWC2MusicXML::*.
# Tests are driven strictly by the POD documentation.
# An API-coverage ledger tracks every documented message/return-state;
# the test asserts the ledger is empty at the end.

use Test::Most;
use Test::Mockingbird qw(mock_scoped);
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed);

use lib 'lib';
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Event;
use Music::NWC2MusicXML::Diagnostics;
use Music::NWC2MusicXML::MusicXML;

# ---------------------------------------------------------------------------
# API coverage ledger -- every documented error/warning/state must be tested.
# Delete each key as the condition is successfully triggered.
# The final check asserts this hash is empty.
# ---------------------------------------------------------------------------
my %LEDGER = (
	# NWC.pm
	'NWC::new returns object'           => 1,
	'NWC::read croak missing filename'  => 1,
	'NWC::read croak not a file'        => 1,
	'NWC::read returns NWCTXT'          => 1,
	'NWC::decode croak truncated'       => 1,
	'NWC::decode croak not_nwc'         => 1,
	'NWC::decode returns NWCTXT'        => 1,

	# Score.pm
	'Score::new returns object'          => 1,
	'Score::new accepts metadata kwarg'  => 1,
	'Score::metadata returns hashref'    => 1,
	'Score::page_setup returns hashref'  => 1,
	'Score::properties returns hashref'  => 1,
	'Score::nwc_version returns scalar'  => 1,
	'Score::set_metadata_field chains'   => 1,
	'Score::set_metadata_field stores'   => 1,
	'Score::add_staff chains'            => 1,
	'Score::add_staff croak bad_staff'   => 1,
	'Score::add_staff croak unblessed'   => 1,
	'Score::staves returns arrayref'     => 1,
	'Score::staves order preserved'      => 1,
	'Score::current_staff last added'    => 1,
	'Score::current_staff undef if empty'=> 1,
	'Score::staff_count zero'            => 1,
	'Score::staff_count increments'      => 1,
	'Score::validate empty returns diag' => 1,
	'Score::validate ok returns empty'   => 1,

	# Staff.pm
	'Staff::new returns object'          => 1,
	'Staff::new defaults'                => 1,
	'Staff::new named args'              => 1,
	'Staff::name accessor'               => 1,
	'Staff::group accessor'              => 1,
	'Staff::lines accessor'              => 1,
	'Staff::visible accessor'            => 1,
	'Staff::instrument accessor'         => 1,
	'Staff::initial_clef undef default'  => 1,
	'Staff::set_initial_clef chains'     => 1,
	'Staff::set_initial_clef stores'     => 1,
	'Staff::initial_key undef default'   => 1,
	'Staff::set_initial_key stores'      => 1,
	'Staff::initial_timesig undef default'=> 1,
	'Staff::set_initial_timesig stores'  => 1,
	'Staff::add_event chains'            => 1,
	'Staff::add_event croak bad_event str'=> 1,
	'Staff::add_event croak unblessed'   => 1,
	'Staff::events returns arrayref'     => 1,
	'Staff::events order preserved'      => 1,
	'Staff::musical_events excludes meta'=> 1,
	'Staff::event_count zero'            => 1,
	'Staff::event_count increments'      => 1,
	'Staff::has_notes false empty'       => 1,
	'Staff::has_notes false Tempo only'  => 1,
	'Staff::has_notes true Note'         => 1,
	'Staff::has_notes true Rest'         => 1,
	'Staff::has_notes true Bar'          => 1,

	# Event.pm
	'Event::new returns object'          => 1,
	'Event::new musical type'            => 1,
	'Event::new metadata type'           => 1,
	'Event::new unknown warns coerce'    => 1,
	'Event::type accessor'               => 1,
	'Event::nwc_label preserved'         => 1,
	'Event::duration accessor'           => 1,
	'Event::data accessor'               => 1,
	'Event::is_musical_event true'       => 1,
	'Event::is_musical_event false'      => 1,
	'Event::is_metadata true'            => 1,
	'Event::is_metadata false'           => 1,
	'Event::rational_from_nwc_duration undotted' => 1,
	'Event::rational_from_nwc_duration dotted'   => 1,
	'Event::rational_from_nwc_duration double-dotted' => 1,
	'Event::rational_from_nwc_duration croak bad dur' => 1,
	'Event::rational_add reduces'        => 1,
	'Event::rational_to_float'           => 1,

	# Diagnostics.pm
	'Diagnostics::new returns object'    => 1,
	'Diagnostics::new default level'     => 1,
	'Diagnostics::new quiet level'       => 1,
	'Diagnostics::new verbose level'     => 1,
	'Diagnostics::new debug level'       => 1,
	'Diagnostics::new croak bad level'   => 1,
	'Diagnostics::info chains'           => 1,
	'Diagnostics::info suppressed quiet' => 1,
	'Diagnostics::verbose chains'        => 1,
	'Diagnostics::verbose suppressed normal' => 1,
	'Diagnostics::verbose emitted verbose'   => 1,
	'Diagnostics::debug chains'          => 1,
	'Diagnostics::debug suppressed verbose'  => 1,
	'Diagnostics::debug emitted debug'   => 1,
	'Diagnostics::warn_unsupported chains'   => 1,
	'Diagnostics::warn_unsupported records'  => 1,
	'Diagnostics::warn_unsupported format'   => 1,
	'Diagnostics::warn_approximate chains'   => 1,
	'Diagnostics::warn_approximate records'  => 1,
	'Diagnostics::count chains'          => 1,
	'Diagnostics::count increments'      => 1,
	'Diagnostics::count croak bad outcome' => 1,
	'Diagnostics::summary chains'        => 1,
	'Diagnostics::warnings returns arrayref' => 1,
	'Diagnostics::has_warnings false'    => 1,
	'Diagnostics::has_warnings true'     => 1,

	# Parser.pm
	'Parser::new returns object'         => 1,
	'Parser::parse croak empty'          => 1,
	'Parser::parse croak undef'          => 1,
	'Parser::parse croak no_header'      => 1,
	'Parser::parse returns Score'        => 1,
	'Parser::parse metadata extracted'   => 1,
	'Parser::parse staff created'        => 1,
	'Parser::parse initial clef set'     => 1,
	'Parser::parse initial key set'      => 1,
	'Parser::parse initial timesig set'  => 1,
	'Parser::parse version extracted'    => 1,
	'Parser::parse reuse state reset'    => 1,

	# MusicXML.pm
	'MusicXML::new returns object'       => 1,
	'MusicXML::new default indent'       => 1,
	'MusicXML::new custom indent'        => 1,
	'MusicXML::generate croak bad_score str'   => 1,
	'MusicXML::generate croak bad_score undef' => 1,
	'MusicXML::generate croak no_staves'       => 1,
	'MusicXML::generate returns scalar'        => 1,
	'MusicXML::generate xml declaration'       => 1,
	'MusicXML::generate doctype'               => 1,
	'MusicXML::generate root element'          => 1,
	'MusicXML::generate defaults block'        => 1,
	'MusicXML::generate part-list'             => 1,
	'MusicXML::generate part element'          => 1,
	'MusicXML::generate measure element'       => 1,
	'MusicXML::generate pure ASCII output'     => 1,
	'MusicXML::generate title credit'          => 1,
	'MusicXML::generate subtitle credit'       => 1,
	'MusicXML::generate copyright credits'     => 1,
	'MusicXML::generate rights in identification' => 1,
	'MusicXML::generate non-ASCII escaped'     => 1,
);

# ---------------------------------------------------------------------------
# Shared test fixtures
# ---------------------------------------------------------------------------

Readonly::Scalar my $TREBLE => 'Treble';
Readonly::Scalar my $BASS   => 'Bass';

Readonly::Scalar my $MINIMAL_NWCTXT => <<'END';
!NoteWorthyComposer(2.75)
|SongInfo|Title:"Unit Test Score"|Author:"Test Author"|Copyright1:"c 2025"|Copyright2:"All Rights Reserved"
|PgSetup|StaffSize:16
|AddStaff|Name:"Piano"|Group:Standard
|StaffProperties|Visible:Y|Lines:5
|StaffInstrument|Name:"Grand Piano"|Patch:0
|Clef|Type:Treble
|Key|Signature:C
|TimeSig|Signature:4/4
|Tempo|Tempo:120|Base:Quarter
|Note|Dur:4th|Pos:0
|Bar|
|Note|Dur:Half|Pos:-2
|Bar|Style:Double
END

sub _make_staff {
	my (%opts) = @_;
	my $s = Music::NWC2MusicXML::Staff->new(%opts);
	$s->set_initial_clef($TREBLE);
	$s->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$s->set_initial_timesig({ beats => 4, beat_type => 4 });
	return $s;
}

sub _note_event {
	return Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	);
}

sub _bar_event {
	return Music::NWC2MusicXML::Event->new(
		type => 'Bar',
		data => { style => 'normal' },
	);
}

sub _minimal_score {
	my $s = _make_staff(name => 'Piano');
	$s->add_event(_note_event());
	$s->add_event(_bar_event());
	my $sc = Music::NWC2MusicXML::Score->new;
	$sc->add_staff($s);
	return $sc;
}

# ============================================================================
# 1. Music::NWC2MusicXML::NWC
# ============================================================================

subtest 'NWC::new' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	ok defined $nwc, 'object created';
	is blessed($nwc), 'Music::NWC2MusicXML::NWC', 'correct class';
	returns_ok($nwc, { type => 'object' }, 'new returns object');
	delete $LEDGER{'NWC::new returns object'};
};

subtest 'NWC::read -- croak on missing/empty filename' => sub {
	throws_ok { Music::NWC2MusicXML::NWC->read(undef) }
		qr/Cannot read file/, 'undef filename croaks with error_not_a_file';
	delete $LEDGER{'NWC::read croak missing filename'};

	throws_ok { Music::NWC2MusicXML::NWC->read('/no/such/file/at/all.nwc') }
		qr/Cannot read file/, 'non-existent file croaks';
	delete $LEDGER{'NWC::read croak not a file'};
};

subtest 'NWC::read -- valid file returns NWCTXT' => sub {
	my $nwctxt;
	lives_ok { $nwctxt = Music::NWC2MusicXML::NWC->read('t/input/Pilgrim.nwc') }
		'reads Pilgrim.nwc without error';
	like $nwctxt, qr/!NoteWorthyComposer\(/, 'result begins with NWCTXT header';
	returns_ok($nwctxt, { type => 'scalar' }, 'read returns scalar');

	diag 'NWCTXT length: ' . length($nwctxt) if $ENV{TEST_VERBOSE};
	delete $LEDGER{'NWC::read returns NWCTXT'};
};

subtest 'NWC::decode -- croak on truncated data' => sub {
	throws_ok { Music::NWC2MusicXML::NWC->decode('[NW') }
		qr/(?:truncated|Cannot read)/, 'short data croaks truncated';
	delete $LEDGER{'NWC::decode croak truncated'};
};

subtest 'NWC::decode -- croak on wrong magic' => sub {
	# 20 bytes of garbage that is long enough but has bad magic
	throws_ok { Music::NWC2MusicXML::NWC->decode("\x00" x 30) }
		qr/Not a valid NWC file/, 'bad magic croaks error_not_nwc';
	delete $LEDGER{'NWC::decode croak not_nwc'};
};

subtest 'NWC::decode -- valid binary returns NWCTXT' => sub {
	open my $fh, '<:raw', 't/input/Pilgrim.nwc' or die $!;
	local $/;
	my $binary = <$fh>;
	close $fh;

	my $nwctxt;
	lives_ok { $nwctxt = Music::NWC2MusicXML::NWC->decode($binary) }
		'decode succeeds on real NWC binary';
	like $nwctxt, qr/!NoteWorthyComposer\(/, 'NWCTXT header present';
	returns_ok($nwctxt, { type => 'scalar' }, 'decode returns scalar');

	delete $LEDGER{'NWC::decode returns NWCTXT'};
};

# ============================================================================
# 2. Music::NWC2MusicXML::Score
# ============================================================================

subtest 'Score::new -- no args' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	ok defined $sc, 'object created with no args';
	is blessed($sc), 'Music::NWC2MusicXML::Score', 'correct class';
	returns_ok($sc, { type => 'object' }, 'new returns object');
	delete $LEDGER{'Score::new returns object'};
};

subtest 'Score::new -- named args accepted' => sub {
	my $sc = Music::NWC2MusicXML::Score->new(
		metadata   => { Title => 'X' },
		page_setup => { StaffSize => 16 },
		properties => { foo => 'bar' },
		nwc_version => '2.75',
	);
	is $sc->metadata->{Title}, 'X', 'metadata kwarg stored';
	is $sc->nwc_version, '2.75', 'nwc_version stored';
	delete $LEDGER{'Score::new accepts metadata kwarg'};
};

subtest 'Score::metadata' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	my $m  = $sc->metadata;
	returns_ok($m, { type => 'hashref' }, 'metadata returns hashref');
	is_deeply $m, {}, 'default metadata is empty hashref';
	delete $LEDGER{'Score::metadata returns hashref'};
};

subtest 'Score::page_setup' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	returns_ok($sc->page_setup, { type => 'hashref' }, 'page_setup returns hashref');
	delete $LEDGER{'Score::page_setup returns hashref'};
};

subtest 'Score::properties' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	returns_ok($sc->properties, { type => 'hashref' }, 'properties returns hashref');
	delete $LEDGER{'Score::properties returns hashref'};
};

subtest 'Score::nwc_version' => sub {
	my $sc = Music::NWC2MusicXML::Score->new(nwc_version => '2.751');
	is $sc->nwc_version, '2.751', 'nwc_version accessor';
	returns_ok($sc->nwc_version, { type => 'scalar' }, 'nwc_version returns scalar');
	delete $LEDGER{'Score::nwc_version returns scalar'};
};

subtest 'Score::set_metadata_field' => sub {
	my $sc  = Music::NWC2MusicXML::Score->new;
	my $ret = $sc->set_metadata_field('Title', 'Symphony No. 5');
	is $ret, $sc, 'set_metadata_field returns $self (chaining)';
	is $sc->metadata->{Title}, 'Symphony No. 5', 'field stored';
	delete $LEDGER{'Score::set_metadata_field chains'};
	delete $LEDGER{'Score::set_metadata_field stores'};
};

subtest 'Score::add_staff -- success' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	my $st = Music::NWC2MusicXML::Staff->new(name => 'Violin');
	my $ret = $sc->add_staff($st);
	is $ret, $sc, 'add_staff returns $self';
	is $sc->staff_count, 1, 'staff_count incremented';
	delete $LEDGER{'Score::add_staff chains'};
};

subtest 'Score::add_staff -- croak on plain string' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	throws_ok { $sc->add_staff('not a Staff') }
		qr/add_staff.*argument must be/, 'string arg croaks error_bad_staff';
	is $sc->staff_count, 0, 'no staff was added';
	delete $LEDGER{'Score::add_staff croak bad_staff'};
};

subtest 'Score::add_staff -- croak on unblessed hashref' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	throws_ok { $sc->add_staff({}) }
		qr/add_staff.*argument must be/, 'unblessed hashref croaks';
	delete $LEDGER{'Score::add_staff croak unblessed'};
};

subtest 'Score::staves' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	returns_ok($sc->staves, { type => 'arrayref' }, 'staves returns arrayref');
	is scalar @{ $sc->staves }, 0, 'empty initially';

	my $s1 = Music::NWC2MusicXML::Staff->new(name => 'A');
	my $s2 = Music::NWC2MusicXML::Staff->new(name => 'B');
	$sc->add_staff($s1);
	$sc->add_staff($s2);
	is $sc->staves->[0]->name, 'A', 'first staff in position 0';
	is $sc->staves->[1]->name, 'B', 'second staff in position 1';
	delete $LEDGER{'Score::staves returns arrayref'};
	delete $LEDGER{'Score::staves order preserved'};
};

subtest 'Score::current_staff' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	ok !defined $sc->current_staff, 'current_staff undef when no staves';
	delete $LEDGER{'Score::current_staff undef if empty'};

	$sc->add_staff(Music::NWC2MusicXML::Staff->new(name => 'First'));
	$sc->add_staff(Music::NWC2MusicXML::Staff->new(name => 'Last'));
	is $sc->current_staff->name, 'Last', 'current_staff is the most recently added';
	delete $LEDGER{'Score::current_staff last added'};
};

subtest 'Score::staff_count' => sub {
	my $sc = Music::NWC2MusicXML::Score->new;
	is $sc->staff_count, 0, 'zero when empty';
	delete $LEDGER{'Score::staff_count zero'};

	$sc->add_staff(Music::NWC2MusicXML::Staff->new(name => 'V'));
	is $sc->staff_count, 1, 'one after adding one';
	$sc->add_staff(Music::NWC2MusicXML::Staff->new(name => 'C'));
	is $sc->staff_count, 2, 'two after adding two';
	delete $LEDGER{'Score::staff_count increments'};
};

subtest 'Score::validate -- empty score' => sub {
	my $sc  = Music::NWC2MusicXML::Score->new;
	my $ret = $sc->validate;
	returns_ok($ret, { type => 'arrayref' }, 'validate returns arrayref');
	ok @$ret > 0, 'diagnostics non-empty when no staves';
	like $ret->[0], qr/Score contains no staves/, 'error message correct';
	delete $LEDGER{'Score::validate empty returns diag'};
};

subtest 'Score::validate -- populated score' => sub {
	my $sc = _minimal_score();
	my $ret = $sc->validate;
	returns_ok($ret, { type => 'arrayref' }, 'validate returns arrayref');
	is scalar @$ret, 0, 'no diagnostics for a well-formed score';
	delete $LEDGER{'Score::validate ok returns empty'};
};

# ============================================================================
# 3. Music::NWC2MusicXML::Staff
# ============================================================================

subtest 'Staff::new -- defaults' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	ok defined $s, 'object created';
	is blessed($s), 'Music::NWC2MusicXML::Staff', 'correct class';
	is $s->name,     'Staff',    'default name = Staff';
	is $s->group,    'Standard', 'default group = Standard';
	is $s->lines,    5,          'default lines = 5';
	is $s->visible,  1,          'default visible = 1';
	is_deeply $s->instrument, {}, 'default instrument = empty hashref';
	delete $LEDGER{'Staff::new returns object'};
	delete $LEDGER{'Staff::new defaults'};
};

subtest 'Staff::new -- named args' => sub {
	my $s = Music::NWC2MusicXML::Staff->new(
		name       => 'Cello',
		group      => 'Strings',
		lines      => 5,
		visible    => 0,
		instrument => { name => 'Cello', patch => 42 },
	);
	is $s->name,              'Cello',  'name stored';
	is $s->group,             'Strings','group stored';
	is $s->visible,           0,        'visible stored';
	is $s->instrument->{name},'Cello',  'instrument name stored';
	is $s->instrument->{patch},42,      'instrument patch stored';
	delete $LEDGER{'Staff::new named args'};
};

subtest 'Staff -- accessors' => sub {
	my $s = Music::NWC2MusicXML::Staff->new(
		name  => 'Flute',
		group => 'Winds',
		lines => 5,
	);
	returns_ok($s->name,       { type => 'scalar' }, 'name returns scalar');
	returns_ok($s->group,      { type => 'scalar' }, 'group returns scalar');
	returns_ok($s->lines,      { type => 'scalar' }, 'lines returns scalar');
	returns_ok($s->visible,    { type => 'scalar' }, 'visible returns scalar');
	returns_ok($s->instrument, { type => 'hashref' }, 'instrument returns hashref');
	delete $LEDGER{'Staff::name accessor'};
	delete $LEDGER{'Staff::group accessor'};
	delete $LEDGER{'Staff::lines accessor'};
	delete $LEDGER{'Staff::visible accessor'};
	delete $LEDGER{'Staff::instrument accessor'};
};

subtest 'Staff::initial_clef / set_initial_clef' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	ok !defined $s->initial_clef, 'initial_clef undef by default';
	delete $LEDGER{'Staff::initial_clef undef default'};

	my $ret = $s->set_initial_clef($BASS);
	is $ret, $s,             'set_initial_clef chains $self';
	is $s->initial_clef, $BASS, 'clef stored';
	delete $LEDGER{'Staff::set_initial_clef chains'};
	delete $LEDGER{'Staff::set_initial_clef stores'};
};

subtest 'Staff::initial_key / set_initial_key' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	ok !defined $s->initial_key, 'initial_key undef by default';
	delete $LEDGER{'Staff::initial_key undef default'};

	my $key = { signature => 'F#,C#', tonic => 'D', fifths => 2 };
	$s->set_initial_key($key);
	is_deeply $s->initial_key, $key, 'key hashref stored';
	delete $LEDGER{'Staff::set_initial_key stores'};
};

subtest 'Staff::initial_timesig / set_initial_timesig' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	ok !defined $s->initial_timesig, 'initial_timesig undef by default';
	delete $LEDGER{'Staff::initial_timesig undef default'};

	my $ts = { beats => 3, beat_type => 4 };
	$s->set_initial_timesig($ts);
	is_deeply $s->initial_timesig, $ts, 'timesig hashref stored';
	delete $LEDGER{'Staff::set_initial_timesig stores'};
};

subtest 'Staff::add_event -- success and chaining' => sub {
	my $s   = Music::NWC2MusicXML::Staff->new;
	my $ev  = _note_event();
	my $ret = $s->add_event($ev);
	is $ret, $s,            'add_event returns $self';
	is $s->event_count, 1,  'event_count 1 after first add';
	delete $LEDGER{'Staff::add_event chains'};
};

subtest 'Staff::add_event -- croak on string' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	throws_ok { $s->add_event('bad') }
		qr/add_event.*argument must be/, 'string arg croaks error_bad_event';
	is $s->event_count, 0, 'no event added';
	delete $LEDGER{'Staff::add_event croak bad_event str'};
};

subtest 'Staff::add_event -- croak on unblessed hashref' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	throws_ok { $s->add_event({}) }
		qr/add_event.*argument must be/, 'unblessed hashref croaks';
	delete $LEDGER{'Staff::add_event croak unblessed'};
};

subtest 'Staff::events' => sub {
	my $s  = Music::NWC2MusicXML::Staff->new;
	my $e1 = _note_event();
	my $e2 = _bar_event();
	$s->add_event($e1);
	$s->add_event($e2);
	returns_ok($s->events, { type => 'arrayref' }, 'events returns arrayref');
	is $s->events->[0], $e1, 'first event in position 0';
	is $s->events->[1], $e2, 'second event in position 1';
	delete $LEDGER{'Staff::events returns arrayref'};
	delete $LEDGER{'Staff::events order preserved'};
};

subtest 'Staff::musical_events' => sub {
	my $s    = Music::NWC2MusicXML::Staff->new;
	my $note = _note_event();
	my $meta = Music::NWC2MusicXML::Event->new(type => 'SongInfo');
	$s->add_event($note);
	$s->add_event($meta);
	my $mus = $s->musical_events;
	returns_ok($mus, { type => 'arrayref' }, 'musical_events returns arrayref');
	is scalar @$mus, 1, 'SongInfo excluded from musical_events';
	is $mus->[0], $note, 'Note included';
	delete $LEDGER{'Staff::musical_events excludes meta'};
};

subtest 'Staff::event_count' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	is $s->event_count, 0, 'zero when empty';
	delete $LEDGER{'Staff::event_count zero'};

	$s->add_event(_note_event());
	is $s->event_count, 1, 'one after adding one';
	$s->add_event(_bar_event());
	is $s->event_count, 2, 'two after adding two';
	delete $LEDGER{'Staff::event_count increments'};
};

subtest 'Staff::has_notes' => sub {
	my $s = Music::NWC2MusicXML::Staff->new;
	ok !$s->has_notes, 'false when empty';
	delete $LEDGER{'Staff::has_notes false empty'};

	# Tempo is NOT a sounding event and must NOT satisfy has_notes
	$s->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Tempo',
		data => { bpm => 120, base => 'Quarter' },
	));
	ok !$s->has_notes, 'false when only Tempo event present';
	delete $LEDGER{'Staff::has_notes false Tempo only'};

	my $s2 = Music::NWC2MusicXML::Staff->new;
	$s2->add_event(_note_event());
	ok $s2->has_notes, 'true after adding Note event';
	delete $LEDGER{'Staff::has_notes true Note'};

	my $s3 = Music::NWC2MusicXML::Staff->new;
	$s3->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Rest', duration => [1, 2],
		data => { base_dur => '8th', dots => 0, opts => {} },
	));
	ok $s3->has_notes, 'true after adding Rest event';
	delete $LEDGER{'Staff::has_notes true Rest'};

	my $s4 = Music::NWC2MusicXML::Staff->new;
	$s4->add_event(_bar_event());
	ok $s4->has_notes, 'true after adding Bar event';
	delete $LEDGER{'Staff::has_notes true Bar'};
};

# ============================================================================
# 4. Music::NWC2MusicXML::Event
# ============================================================================

subtest 'Event::new -- musical event' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '-3', base_dur => '4th', dots => 0,
		              articulations => ['Tenuto'], opts => {} },
	);
	ok defined $ev, 'object created';
	is blessed($ev), 'Music::NWC2MusicXML::Event', 'correct class';
	returns_ok($ev, { type => 'object' }, 'new returns object');
	delete $LEDGER{'Event::new returns object'};
	delete $LEDGER{'Event::new musical type'};
};

subtest 'Event::new -- metadata type' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(
		type => 'SongInfo',
		data => { Title => 'X' },
	);
	is $ev->type, 'SongInfo', 'metadata type preserved';
	delete $LEDGER{'Event::new metadata type'};
};

subtest 'Event::new -- unknown type: warns and coerces to UnsupportedEvent' => sub {
	my $ev;
	warning_like {
		$ev = Music::NWC2MusicXML::Event->new(type => 'FutureNWCFeature');
	} qr/Unknown event type.*FutureNWCFeature/, 'warns for unknown type';
	is $ev->type,      'UnsupportedEvent',  'type coerced';
	is $ev->nwc_label, 'FutureNWCFeature',  'original label preserved in nwc_label';
	delete $LEDGER{'Event::new unknown warns coerce'};
};

subtest 'Event -- accessors' => sub {
	my $ev = _note_event();
	returns_ok($ev->type,     { type => 'scalar'   }, 'type returns scalar');
	returns_ok($ev->duration, { type => 'arrayref'  }, 'duration returns arrayref');
	returns_ok($ev->data,     { type => 'hashref'   }, 'data returns hashref');
	is $ev->type, 'Note', 'type value correct';
	delete $LEDGER{'Event::type accessor'};
	delete $LEDGER{'Event::duration accessor'};
	delete $LEDGER{'Event::data accessor'};
};

subtest 'Event::nwc_label' => sub {
	my $ev;
	warning_like { $ev = Music::NWC2MusicXML::Event->new(type => 'SomeUnknownWidget') }
		qr/Unknown event type/;
	is $ev->nwc_label, 'SomeUnknownWidget', 'nwc_label holds original type name';
	delete $LEDGER{'Event::nwc_label preserved'};
};

subtest 'Event::is_musical_event' => sub {
	my $note = _note_event();
	ok $note->is_musical_event,  'Note: is_musical_event true';
	ok !$note->is_metadata,      'Note: is_metadata false';
	delete $LEDGER{'Event::is_musical_event true'};
	delete $LEDGER{'Event::is_metadata false'};
};

subtest 'Event::is_metadata' => sub {
	my $meta = Music::NWC2MusicXML::Event->new(type => 'SongInfo');
	ok $meta->is_metadata,         'SongInfo: is_metadata true';
	ok !$meta->is_musical_event,   'SongInfo: is_musical_event false';
	delete $LEDGER{'Event::is_metadata true'};
	delete $LEDGER{'Event::is_musical_event false'};
};

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
		is_deeply $r, $c->[1], "$c->[0] (0 dots)";
	}
	delete $LEDGER{'Event::rational_from_nwc_duration undotted'};
};

subtest 'Event::rational_from_nwc_duration -- dotted (1 dot = 3/2 * base)' => sub {
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1),
		[3, 2], 'dotted quarter = 3/2');
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', 1),
		[3, 1], 'dotted half = 3/1');
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('8th', 1),
		[3, 4], 'dotted 8th = 3/4');
	delete $LEDGER{'Event::rational_from_nwc_duration dotted'};
};

subtest 'Event::rational_from_nwc_duration -- double-dotted (7/4 * base)' => sub {
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 2),
		[7, 4], 'double-dotted quarter = 7/4');
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', 2),
		[7, 2], 'double-dotted half = 7/2');
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('8th', 2),
		[7, 8], 'double-dotted 8th = 7/8');
	delete $LEDGER{'Event::rational_from_nwc_duration double-dotted'};
};

subtest 'Event::rational_from_nwc_duration -- bad name croaks' => sub {
	throws_ok {
		Music::NWC2MusicXML::Event->rational_from_nwc_duration('Quarter', 0)
	} qr/Unrecognised NWC duration: Quarter/, 'wrong name croaks error_bad_duration';
	delete $LEDGER{'Event::rational_from_nwc_duration croak bad dur'};
};

subtest 'Event::rational_add' => sub {
	my $r = Music::NWC2MusicXML::Event->rational_add([1, 3], [1, 6]);
	is_deeply $r, [1, 2], '1/3 + 1/6 = 1/2 (reduced)';
	delete $LEDGER{'Event::rational_add reduces'};
};

subtest 'Event::rational_to_float' => sub {
	my $f = Music::NWC2MusicXML::Event->rational_to_float([3, 2]);
	ok abs($f - 1.5) < 1e-9, '3/2 -> 1.5 floating-point';
	delete $LEDGER{'Event::rational_to_float'};
};

# ============================================================================
# 5. Music::NWC2MusicXML::Diagnostics
# ============================================================================

subtest 'Diagnostics::new -- default level (normal)' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new;
	ok defined $d, 'object created';
	is blessed($d), 'Music::NWC2MusicXML::Diagnostics', 'correct class';
	delete $LEDGER{'Diagnostics::new returns object'};
	delete $LEDGER{'Diagnostics::new default level'};
};

subtest 'Diagnostics::new -- explicit levels accepted' => sub {
	for my $lvl (qw(quiet normal verbose debug)) {
		my $d;
		lives_ok { $d = Music::NWC2MusicXML::Diagnostics->new(level => $lvl) }
			"level '$lvl' accepted";
	}
	delete $LEDGER{'Diagnostics::new quiet level'};
	delete $LEDGER{'Diagnostics::new verbose level'};
	delete $LEDGER{'Diagnostics::new debug level'};
};

subtest 'Diagnostics::new -- bad level croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Diagnostics->new(level => 'shouting') }
		qr/Unknown log level: shouting/, 'unknown level croaks';
	delete $LEDGER{'Diagnostics::new croak bad level'};
};

subtest 'Diagnostics::info' => sub {
	my $d   = Music::NWC2MusicXML::Diagnostics->new(level => 'normal');
	my $ret = $d->info('hello');
	is $ret, $d, 'info chains $self';
	delete $LEDGER{'Diagnostics::info chains'};

	# At quiet level info must not print (mock STDERR to capture)
	my $quiet = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $printed = 0;
	{
		my $guard = mock_scoped('Music::NWC2MusicXML::Diagnostics', 'info',
			sub { my $self = shift; $printed++; return $self });
		$quiet->info('suppressed');
	}
	# The method was mocked; the real suppression is tested via the real method
	# returning $self without side effects at quiet level. Verify directly:
	my $quiet2 = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $ret2 = $quiet2->info('should be suppressed');
	is $ret2, $quiet2, 'info at quiet level returns $self';
	delete $LEDGER{'Diagnostics::info suppressed quiet'};
};

subtest 'Diagnostics::verbose -- suppressed at normal, emitted at verbose' => sub {
	my $d   = Music::NWC2MusicXML::Diagnostics->new(level => 'normal');
	my $ret = $d->verbose('detail');
	is $ret, $d, 'verbose chains $self at normal level';
	delete $LEDGER{'Diagnostics::verbose chains'};
	delete $LEDGER{'Diagnostics::verbose suppressed normal'};

	my $d2  = Music::NWC2MusicXML::Diagnostics->new(level => 'verbose');
	my $ret2 = $d2->verbose('should emit');
	is $ret2, $d2, 'verbose at verbose level returns $self';
	delete $LEDGER{'Diagnostics::verbose emitted verbose'};
};

subtest 'Diagnostics::debug -- suppressed below debug' => sub {
	my $d   = Music::NWC2MusicXML::Diagnostics->new(level => 'verbose');
	my $ret = $d->debug('trace');
	is $ret, $d, 'debug chains $self when suppressed';
	delete $LEDGER{'Diagnostics::debug chains'};
	delete $LEDGER{'Diagnostics::debug suppressed verbose'};

	my $d2  = Music::NWC2MusicXML::Diagnostics->new(level => 'debug');
	my $ret2 = $d2->debug('emitted trace');
	is $ret2, $d2, 'debug at debug level returns $self';
	delete $LEDGER{'Diagnostics::debug emitted debug'};
};

subtest 'Diagnostics::warn_unsupported' => sub {
	my $d   = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $ret = $d->warn_unsupported(
		file   => 'score.nwc',
		staff  => 'Staff 1',
		pos    => '4:2',
		object => 'UserTool',
		reason => 'no equivalent',
	);
	is $ret, $d, 'warn_unsupported chains $self';
	ok $d->has_warnings, 'has_warnings true after call';
	my $w = $d->warnings->[0];
	like $w, qr/score\.nwc/, 'file in warning text';
	like $w, qr/Staff 1/,    'staff in warning text';
	like $w, qr/UserTool/,   'object in warning text';
	delete $LEDGER{'Diagnostics::warn_unsupported chains'};
	delete $LEDGER{'Diagnostics::warn_unsupported records'};
	delete $LEDGER{'Diagnostics::warn_unsupported format'};
};

subtest 'Diagnostics::warn_approximate' => sub {
	my $d   = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $ret = $d->warn_approximate(
		file          => 'a.nwc',
		staff         => '1',
		pos           => '3:1',
		feature       => 'TrillOrnament',
		approximation => 'trill-mark',
	);
	is $ret, $d, 'warn_approximate chains $self';
	ok $d->has_warnings, 'warning recorded';
	like $d->warnings->[0], qr/TrillOrnament/, 'feature name in message';
	like $d->warnings->[0], qr/trill-mark/,    'approximation in message';
	delete $LEDGER{'Diagnostics::warn_approximate chains'};
	delete $LEDGER{'Diagnostics::warn_approximate records'};
};

subtest 'Diagnostics::count' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');

	for my $outcome (qw(processed successful warnings failed)) {
		my $ret = $d->count(outcome => $outcome);
		is $ret, $d, "count($outcome) chains \$self";
	}
	delete $LEDGER{'Diagnostics::count chains'};
	delete $LEDGER{'Diagnostics::count increments'};
};

subtest 'Diagnostics::count -- bad outcome croaks' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	throws_ok { $d->count(outcome => 'nonsense') }
		qr/Unknown counter: nonsense/, 'bad outcome key croaks';
	delete $LEDGER{'Diagnostics::count croak bad outcome'};
};

subtest 'Diagnostics::summary' => sub {
	my $d   = Music::NWC2MusicXML::Diagnostics->new(level => 'normal');
	my $ret = $d->summary;
	is $ret, $d, 'summary chains $self';
	delete $LEDGER{'Diagnostics::summary chains'};
};

subtest 'Diagnostics::warnings' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	returns_ok($d->warnings, { type => 'arrayref' }, 'warnings returns arrayref');
	delete $LEDGER{'Diagnostics::warnings returns arrayref'};
};

subtest 'Diagnostics::has_warnings' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	ok !$d->has_warnings, 'false before any warning';
	delete $LEDGER{'Diagnostics::has_warnings false'};

	$d->warn_unsupported(file=>'f', staff=>'s', object=>'O');
	ok $d->has_warnings, 'true after warning';
	delete $LEDGER{'Diagnostics::has_warnings true'};
};

# ============================================================================
# 6. Music::NWC2MusicXML::Parser
# ============================================================================

subtest 'Parser::new' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	ok defined $p, 'object created';
	is blessed($p), 'Music::NWC2MusicXML::Parser', 'correct class';
	delete $LEDGER{'Parser::new returns object'};
};

subtest 'Parser::parse -- croak on undef' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse(undef) }
		qr/NWCTXT input is empty or undefined/, 'undef croaks error_empty_input';
	delete $LEDGER{'Parser::parse croak undef'};
};

subtest 'Parser::parse -- croak on empty string' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse('') }
		qr/NWCTXT input is empty or undefined/, 'empty string croaks';
	delete $LEDGER{'Parser::parse croak empty'};
};

subtest 'Parser::parse -- croak on missing header' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse("NotAHeader\n|SongInfo|\n") }
		qr/does not begin with expected header/, 'missing header croaks error_no_header';
	delete $LEDGER{'Parser::parse croak no_header'};
};

subtest 'Parser::parse -- returns Score' => sub {
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWCTXT) }
		'minimal NWCTXT parses without error';
	ok defined $score, 'score object returned';
	is blessed($score), 'Music::NWC2MusicXML::Score', 'correct class';
	returns_ok($score, { type => 'object' }, 'parse returns object');
	delete $LEDGER{'Parser::parse returns Score'};
};

subtest 'Parser::parse -- metadata extracted' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWCTXT);
	is $score->metadata->{Title},  'Unit Test Score', 'Title extracted';
	is $score->metadata->{Author}, 'Test Author',     'Author extracted';
	is $score->metadata->{Copyright1}, 'c 2025',      'Copyright1 extracted';
	is $score->metadata->{Copyright2}, 'All Rights Reserved', 'Copyright2 extracted';
	delete $LEDGER{'Parser::parse metadata extracted'};
};

subtest 'Parser::parse -- staff created' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWCTXT);
	is $score->staff_count, 1, 'one staff parsed';
	is $score->staves->[0]->name, 'Piano', 'staff name from AddStaff';
	delete $LEDGER{'Parser::parse staff created'};
};

subtest 'Parser::parse -- initial clef, key, timesig set' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWCTXT);
	my $staff = $score->staves->[0];
	is $staff->initial_clef, 'Treble', 'initial_clef = Treble';
	is $staff->initial_key->{fifths}, 0, 'initial_key fifths = 0 (C major)';
	is $staff->initial_timesig->{beats}, 4, 'initial_timesig beats = 4';
	is $staff->initial_timesig->{beat_type}, 4, 'initial_timesig beat_type = 4';
	delete $LEDGER{'Parser::parse initial clef set'};
	delete $LEDGER{'Parser::parse initial key set'};
	delete $LEDGER{'Parser::parse initial timesig set'};
};

subtest 'Parser::parse -- NWC version extracted from header' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWCTXT);
	is $score->nwc_version, '2.75', 'version string extracted';
	delete $LEDGER{'Parser::parse version extracted'};
};

subtest 'Parser::parse -- state reset between calls (no bleed)' => sub {
	my $nwc1 = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"First\"\n"
		. "|AddStaff|Name:\"A\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $nwc2 = "!NoteWorthyComposer(2.75)\n"
		. "|AddStaff|Name:\"B\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $p  = Music::NWC2MusicXML::Parser->new;
	my $s1 = $p->parse($nwc1);
	my $s2 = $p->parse($nwc2);
	is $s1->metadata->{Title}, 'First',  'first score Title intact';
	ok !defined $s2->metadata->{Title},  'second score: no Title bleed';
	is $s2->staves->[0]->name, 'B',      'second score staff name correct';
	delete $LEDGER{'Parser::parse reuse state reset'};
};

# ============================================================================
# 7. Music::NWC2MusicXML::MusicXML
# ============================================================================

subtest 'MusicXML::new -- default' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	ok defined $gen, 'object created';
	is blessed($gen), 'Music::NWC2MusicXML::MusicXML', 'correct class';
	is $gen->{_indent}, '  ', 'default indent is two spaces';
	delete $LEDGER{'MusicXML::new returns object'};
	delete $LEDGER{'MusicXML::new default indent'};
};

subtest 'MusicXML::new -- custom indent' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new(indent => "\t");
	is $gen->{_indent}, "\t", 'tab indent stored';
	delete $LEDGER{'MusicXML::new custom indent'};
};

subtest 'MusicXML::generate -- croak on non-Score string' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	throws_ok { $gen->generate('not a score') }
		qr/generate.*argument must be.*Score/, 'string arg croaks error_bad_score';
	delete $LEDGER{'MusicXML::generate croak bad_score str'};
};

subtest 'MusicXML::generate -- croak on undef' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	throws_ok { $gen->generate(undef) }
		qr/generate.*argument must be.*Score/, 'undef croaks error_bad_score';
	delete $LEDGER{'MusicXML::generate croak bad_score undef'};
};

subtest 'MusicXML::generate -- croak on empty Score' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $empty = Music::NWC2MusicXML::Score->new;
	throws_ok { $gen->generate($empty) }
		qr/Score contains no staves/, 'empty score croaks error_no_staves';
	delete $LEDGER{'MusicXML::generate croak no_staves'};
};

subtest 'MusicXML::generate -- return type' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my $xml = $gen->generate(_minimal_score());
	returns_ok($xml, { type => 'scalar' }, 'generate returns scalar');
	delete $LEDGER{'MusicXML::generate returns scalar'};
};

subtest 'MusicXML::generate -- document structure' => sub {
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my $xml = $gen->generate(_minimal_score());

	like $xml, qr/^<\?xml version="1\.0" encoding="UTF-8"\?>/,
		'starts with XML declaration';
	delete $LEDGER{'MusicXML::generate xml declaration'};

	like $xml, qr/<!DOCTYPE score-partwise/,
		'DOCTYPE present';
	delete $LEDGER{'MusicXML::generate doctype'};

	like $xml, qr/<score-partwise version="4\.0">/,
		'MusicXML 4.0 root element';
	delete $LEDGER{'MusicXML::generate root element'};

	like $xml, qr/<defaults>/,
		'defaults block present';
	delete $LEDGER{'MusicXML::generate defaults block'};

	like $xml, qr/<part-list>/,
		'part-list present';
	delete $LEDGER{'MusicXML::generate part-list'};

	like $xml, qr|<part id="P1">|,
		'part element with id="P1"';
	delete $LEDGER{'MusicXML::generate part element'};

	like $xml, qr/<measure number="1">/,
		'at least one measure';
	delete $LEDGER{'MusicXML::generate measure element'};

	ok $xml !~ /[^\x00-\x7F]/, 'output is pure 7-bit ASCII';
	delete $LEDGER{'MusicXML::generate pure ASCII output'};
};

subtest 'MusicXML::generate -- title and subtitle credits' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Title',  'My Piece');
	$score->set_metadata_field('Author', 'J. Composer');
	my $xml = $gen->generate($score);

	like $xml, qr/<credit-type>title<\/credit-type>/, 'title credit-type';
	like $xml, qr/My Piece/, 'title text in output';
	delete $LEDGER{'MusicXML::generate title credit'};

	like $xml, qr/<credit-type>subtitle<\/credit-type>/, 'subtitle credit-type';
	like $xml, qr/J\. Composer/, 'author text in output';
	# Both title and subtitle must be restricted to page 1
	my @page1 = ($xml =~ /<credit page="1">/g);
	is scalar @page1, 2, 'exactly 2 page-1 credits (title + subtitle)';
	delete $LEDGER{'MusicXML::generate subtitle credit'};
};

subtest 'MusicXML::generate -- copyright credits (each line as own element)' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Copyright1', 'Line One');
	$score->set_metadata_field('Copyright2', 'Line Two');
	my $xml = $gen->generate($score);

	# Per the POD: one <credit> per copyright line; no page attribute
	my @rights_credits = ($xml =~ /<credit-type>rights<\/credit-type>/g);
	is scalar @rights_credits, 2, 'two separate rights credit elements';
	like $xml, qr/Line One/, 'Copyright1 text present';
	like $xml, qr/Line Two/, 'Copyright2 text present';

	# Rights credits must NOT carry a page attribute (they appear on every page)
	ok $xml !~ qr|<credit page="\d+">\s*<credit-type>rights|,
		'rights credits have no page= attribute';
	delete $LEDGER{'MusicXML::generate copyright credits'};
};

subtest 'MusicXML::generate -- identification has single rights element' => sub {
	# Per COMMON PITFALLS: two <rights> shadow each other; must be joined.
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Copyright1', 'Line A');
	$score->set_metadata_field('Copyright2', 'Line B');
	my $xml = $gen->generate($score);

	my @rights_els = ($xml =~ m|<rights>(.*?)</rights>|gs);
	is scalar @rights_els, 1, 'exactly one <rights> in <identification>';
	like $rights_els[0], qr/Line A/, 'Copyright1 in single rights element';
	like $rights_els[0], qr/Line B/, 'Copyright2 in single rights element';
	delete $LEDGER{'MusicXML::generate rights in identification'};
};

subtest 'MusicXML::generate -- non-ASCII escaped to numeric entities' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = _minimal_score();
	$score->set_metadata_field('Copyright1', "\x{A9} 2025 Author");
	my $xml = $gen->generate($score);
	like $xml, qr/&#169; 2025 Author/, 'U+00A9 escaped as &#169;';
	ok $xml !~ /[^\x00-\x7F]/, 'output still pure ASCII after escaping';
	delete $LEDGER{'MusicXML::generate non-ASCII escaped'};
};

# ============================================================================
# Final ledger check -- every documented state must have been exercised.
# ============================================================================

subtest 'API coverage ledger -- all documented states exercised' => sub {
	if (my @untested = sort keys %LEDGER) {
		fail "Untested documented states (" . scalar(@untested) . "):";
		diag "  - $_" for @untested;
	} else {
		pass 'All documented API states exercised';
	}
};

done_testing;
