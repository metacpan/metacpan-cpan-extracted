#!/usr/bin/env perl
#
# t/mutant_killers.t -- Explicit mutant-killer tests
#
# Targets surviving mutants from xt/mutant_20260918_130941.t:
#
#   BOOL_NEGATE_308_18 + RETURN_UNDEF_308_18:
#       Event.pm line 309, sub nwc_label -- return negated / return undef
#
#   COND_INV_354_2:
#       NWC.pm line 365, sub decode -- "if" inverted to "unless" on the
#       utf8::decode() check, flipping which encoding path fires.
#
# Fermata annotation mutants (_annotate_fermatas in MusicXML.pm):
#
#   COND_INV_FERMATA_STYLE:
#       Remove/invert the `eq 'Fermata'` guard -> non-Fermata TempoVariance
#       would annotate the next note.
#
#   PENDING_FLAG_CLEAR:
#       Never clear $pending_fermata -> every note after the first TV:Fermata
#       would get annotated.
#
#   PREV_NOT_NEXT:
#       Annotate the previous note instead of the next -> fermata on the
#       wrong note.

use strict;
use warnings;

use Test::Most;
use Compress::Zlib ();
use Readonly;

use lib 'lib';
use Music::NWC2MusicXML::Event;
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::MusicXML;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $NWC_MAGIC   => '[NWZ]';
Readonly::Scalar my $NWC_VERSION => '2.751';

# Label used to distinguish nwc_label results from boolean conversions:
# '!'  (boolean-not) of a truthy string is always '' -- never 'MyOriginalLabel'.
Readonly::Scalar my $KNOWN_LABEL => 'MyOriginalLabel';

# ---------------------------------------------------------------------------
# Helper: compress NWCTXT bytes and prepend NWC magic.
# $nwctxt_bytes must be a raw byte string (no utf8 flag) to test encoding paths.
# ---------------------------------------------------------------------------

sub _binary_from_nwctxt {
	my ($nwctxt_bytes) = @_;
	my $compressed = Compress::Zlib::compress(\$nwctxt_bytes);
	return $NWC_MAGIC . $compressed;
}

# ---------------------------------------------------------------------------
# 1a. BOOL_NEGATE_308_18 -- UnsupportedEvent path
#
# Mutation: sub nwc_label { return !$_[0]->{_nwc_label} }
#
# For a truthy stored label 'MyOriginalLabel':
#   !$_[0]->{_nwc_label} => '' (empty string)
#
# Kill: assert the exact string, not just truthiness.
# ---------------------------------------------------------------------------

subtest 'BOOL_NEGATE_308_18: nwc_label returns exact string for UnsupportedEvent' => sub {
	# An unknown type causes the constructor to store the original label in
	# _nwc_label.  We pass a known distinct string so the assertion is precise.
	my $ev;
	warning_like {
		$ev = Music::NWC2MusicXML::Event->new(
			type      => 'ZZZUnknownFutureObject',
			nwc_label => $KNOWN_LABEL,
		);
	} qr/Unknown event type/i, 'constructor warns about unknown type';

	# BOOL_NEGATE mutant returns '' (not $KNOWN_LABEL).
	is $ev->nwc_label, $KNOWN_LABEL,
		'nwc_label returns stored string, not its boolean negation';

	# RETURN_UNDEF mutant returns undef.
	ok defined $ev->nwc_label,
		'nwc_label is defined (kills RETURN_UNDEF)';

	# Belt-and-braces: confirm it is not the negation of a truthy string.
	isnt $ev->nwc_label, '',
		'nwc_label is not empty-string (the value of !truthy_string)';
};

# ---------------------------------------------------------------------------
# 1b. BOOL_NEGATE_308_18 -- known type path
#
# For a recognised Event type the constructor stores the type name in
# _nwc_label (via $_[0]->{_nwc_label} = $args->{nwc_label} // $args->{type}).
#
# BOOL_NEGATE mutant: !'Note' => ''.  Kill: is $ev->nwc_label, 'Note'.
# ---------------------------------------------------------------------------

subtest 'BOOL_NEGATE_308_18: nwc_label returns type name for known Event type' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Note');

	is $ev->nwc_label, 'Note',
		'nwc_label returns "Note", not the boolean negation of "Note"';

	ok defined $ev->nwc_label,
		'nwc_label is defined for a known type';
};

# ---------------------------------------------------------------------------
# 1c. RETURN_UNDEF_308_18 -- two distinct objects return distinct values
#
# A constant 'return undef' would make two different labels look identical.
# Confirming they are different kills the undef-return mutant.
# ---------------------------------------------------------------------------

subtest 'RETURN_UNDEF_308_18: nwc_label round-trips two distinct stored values' => sub {
	my ($ev_a, $ev_b);
	warnings_exist {
		$ev_a = Music::NWC2MusicXML::Event->new(type => 'FutureThing_Alpha');
		$ev_b = Music::NWC2MusicXML::Event->new(type => 'FutureThing_Beta');
	} [qr/Unknown event type/i, qr/Unknown event type/i],
		'two unknown types each trigger a warning';

	isnt $ev_a->nwc_label, $ev_b->nwc_label,
		'distinct stored labels return distinct values (undef would be equal)';

	is $ev_a->nwc_label, 'FutureThing_Alpha', 'ev_a: exact label returned';
	is $ev_b->nwc_label, 'FutureThing_Beta',  'ev_b: exact label returned';
};

# ---------------------------------------------------------------------------
# 2a. COND_INV_354_2 -- valid UTF-8 must NOT trigger the encoding warning
#
# Original code:  if (!utf8::decode($nwctxt)) { carp bad_utf8; utf8::upgrade }
# Mutation:       unless (!utf8::decode($nwctxt)) { ... }
#                 = if (utf8::decode($nwctxt)) { ... }
#
# With mutation: valid UTF-8 decode succeeds -> 'unless (false)' is true
# -> the block fires -> an encoding warning is issued.  Kill: assert no warning.
# ---------------------------------------------------------------------------

subtest 'COND_INV_354_2: valid UTF-8 NWCTXT produces no encoding warning' => sub {
	# Pure ASCII is always valid UTF-8.  utf8::decode returns true, so the
	# fallback block must remain silent.  The mutant would fire the block here.
	my $nwctxt = "!NoteWorthyComposer($NWC_VERSION)\n"
		. "|AddStaff|Name:\"Violin\"\n"
		. "|Clef|Type:Treble\n"
		. "|Key|Signature:Concert\n"
		. "|TimeSig|Signature:4/4\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "!NoteWorthyComposer-End\n";

	my $binary = _binary_from_nwctxt($nwctxt);

	my @enc_warns;
	local $SIG{__WARN__} = sub {
		push @enc_warns, $_[0] if $_[0] =~ /utf.?8/i;
	};

	my $result;
	lives_ok { $result = Music::NWC2MusicXML::NWC->decode($binary, 'ascii.nwc') }
		'decode does not croak on valid UTF-8 input';

	is scalar @enc_warns, 0,
		'valid UTF-8: no encoding warning fired (mutation fires one -> killed)';

	like $result, qr/!NoteWorthyComposer/,
		'valid UTF-8: NWCTXT content is returned';

	diag "captured enc_warns: @enc_warns" if $ENV{TEST_VERBOSE} && @enc_warns;
};

# ---------------------------------------------------------------------------
# 2b. COND_INV_354_2 -- Latin-1 NWCTXT MUST trigger the encoding warning
#
# \xE9 is 'e-acute' in Latin-1; as a lone byte it is not a valid UTF-8
# sequence (0xE9 starts a 3-byte sequence but has no continuation bytes).
# utf8::decode must fail -> the fallback block fires -> carp is called.
#
# With mutation: decode fails -> 'unless (true)' is false -> block skipped
# -> no warning -> test fails -> mutant killed.
# ---------------------------------------------------------------------------

subtest 'COND_INV_354_2: Latin-1 NWCTXT triggers encoding warning and returns content' => sub {
	# Build raw byte string without the utf8 flag.
	# \xE9 as a lone byte is invalid UTF-8: utf8::decode will return false.
	my $nwctxt_raw = "!NoteWorthyComposer($NWC_VERSION)\n"
		. "|SongInfo|Title:Caf\xE9\n"
		. "|AddStaff|Name:Piano\n"
		. "!NoteWorthyComposer-End\n";

	my $binary = _binary_from_nwctxt($nwctxt_raw);

	my @enc_warns;
	local $SIG{__WARN__} = sub {
		push @enc_warns, $_[0] if $_[0] =~ /utf.?8/i;
	};

	my $result;
	lives_ok { $result = Music::NWC2MusicXML::NWC->decode($binary, 'latin1.nwc') }
		'decode does not croak on Latin-1 input (fallback handles it gracefully)';

	ok scalar @enc_warns > 0,
		'Latin-1 NWCTXT: encoding warning is issued (mutation suppresses it -> killed)';

	like $enc_warns[0], qr/utf.?8/i,
		'warning message mentions UTF-8 encoding';

	ok defined $result,
		'Latin-1 NWCTXT: content is still returned after fallback';

	diag "Latin-1 warning: $enc_warns[0]" if $ENV{TEST_VERBOSE} && @enc_warns;
};

# ---------------------------------------------------------------------------
# Fermata annotation mutant killers
# ---------------------------------------------------------------------------

# Helper: build a score XML from an event list, returning the XML string.
sub _score_xml_from_events {
	my (@events) = @_;
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event($_) for @events;
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Bar', data => { style => 'normal' }));
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);
	return Music::NWC2MusicXML::MusicXML->new->generate($score);
}

sub _mk_tv_fermata {
	Music::NWC2MusicXML::Event->new(
		type => 'TempoVariance',
		data => { style => 'Fermata', placement => 'above' });
}

sub _mk_note {
	Music::NWC2MusicXML::Event->new(
		type => 'Note', duration => [1, 4],
		data => { nwc_pos => '0', base_dur => '4th', dots => 0,
		          articulations => [], opts => {} });
}

# COND_INV_FERMATA_STYLE: the `eq 'Fermata'` guard must reject non-Fermata styles.
# Mutation: remove the style check -> Ritardando would also annotate the next note.
# Kill: Ritardando before a note -> no <fermata/> in output.
subtest 'COND_INV_FERMATA_STYLE: non-Fermata TempoVariance does not emit fermata' => sub {
	my $tv_rit = Music::NWC2MusicXML::Event->new(
		type => 'TempoVariance',
		data => { style => 'Ritardando', placement => 'above' });
	my $xml = _score_xml_from_events($tv_rit, _mk_note());
	unlike $xml, qr/<fermata\/>/, 'Ritardando before note: no <fermata/> emitted';
	like   $xml, qr/<words[^>]*>rit\./, 'Ritardando still emits rit. words direction';
};

# PENDING_FLAG_CLEAR: $pending_fermata must be cleared after annotating one note.
# Mutation: never clear the flag -> all subsequent notes also get <fermata/>.
# Kill: TV:Fermata -> note1 -> note2: only note1 has <fermata/>, note2 does not.
subtest 'PENDING_FLAG_CLEAR: fermata annotates only the immediately following note' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $tv    = _mk_tv_fermata();
	my $note1 = _mk_note();
	my $note2 = _mk_note();
	my %ann;
	$gen->_annotate_fermatas([$tv, $note1, $note2], \%ann);
	ok  $ann{"$note1"}{fermata},  'note1 (immediately after TV:Fermata) gets fermata';
	ok !$ann{"$note2"}{fermata},  'note2 (second after TV:Fermata) does NOT get fermata';
};

# PREV_NOT_NEXT: the fermata must go on the note AFTER the TV:Fermata record,
# not the note before it.
# Mutation: annotate $last_sounding_key (previous) instead of next -> wrong note.
# Kill: note1 -> TV:Fermata -> note2: note2 gets <fermata/>, note1 does not.
subtest 'PREV_NOT_NEXT: fermata annotates the note AFTER the TempoVariance record' => sub {
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $note1 = _mk_note();
	my $tv    = _mk_tv_fermata();
	my $note2 = _mk_note();
	my %ann;
	$gen->_annotate_fermatas([$note1, $tv, $note2], \%ann);
	ok !$ann{"$note1"}{fermata}, 'note1 (before TV:Fermata) does NOT get fermata';
	ok  $ann{"$note2"}{fermata}, 'note2 (after TV:Fermata) gets fermata';
};

done_testing();
