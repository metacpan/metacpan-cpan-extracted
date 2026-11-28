use strict;
use warnings;

use Test::Most;

use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::MusicXML;

sub convert {
	my @records = @_;
	my $text = join "\n", '!NoteWorthyComposer(2.751)', '|AddStaff|Name:"S"',
		'|Clef|Type:Treble', '|TimeSig|Signature:4/4', @records,
		'!NoteWorthyComposer-End';
	my $score = Music::NWC2MusicXML::Parser->new->parse($text);
	return ($score, Music::NWC2MusicXML::MusicXML->new->generate($score));
}

sub count {
	my ($xml, $re) = @_;
	my $n = () = $xml =~ /$re/g;
	return $n;
}

subtest 'triplet quavers fill one crotchet' => sub {
	my ($score, $xml) = convert(
		'|Note|Dur:8th,Triplet=First|Pos:0',
		'|Note|Dur:8th,Triplet|Pos:1',
		'|Note|Dur:8th,Triplet=End|Pos:2',
		'|Note|Dur:4th|Pos:0',
	);
	is_deeply $score->staves->[0]->events->[0]->duration, [ 1, 3 ], 'duration is 1/3';
	like $xml, qr{<divisions>3</divisions>}, 'divisions allow thirds';
	is count($xml, qr{<duration>1</duration>}), 3, 'each member is one tick';
	is count($xml, qr{<type>eighth</type>}), 3, 'written value stays a quaver';
	is count($xml, qr{<actual-notes>3</actual-notes>}), 3, 'time-modification on members only';
	is count($xml, qr{<tuplet type="start"/>}), 1, 'one bracket start';
	is count($xml, qr{<tuplet type="stop"/>}), 1, 'one bracket stop';
};

subtest 'rests and chords in triplets' => sub {
	my ($score, $xml) = convert(
		'|Rest|Dur:8th,Triplet=First',
		'|Chord|Dur:8th,Triplet|Pos:0,2',
		'|Chord|Dur:8th,Triplet=End|Pos:0,2',
	);
	is_deeply [ map { $_->duration } @{ $score->staves->[0]->events } ],
		[ ([ 1, 3 ]) x 3 ], 'all scaled';
	is count($xml, qr{<time-modification>}), 5, 'rest and every chord pitch';
	is count($xml, qr{<tuplet type="start"/>}), 1, 'start on the rest';
	is count($xml, qr{<tuplet type="stop"/>}), 1, 'stop once per chord';
};

subtest 'dotted triplet duration is reduced' => sub {
	my ($score) = convert('|Note|Dur:8th,Dotted,Triplet|Pos:0');
	is_deeply $score->staves->[0]->events->[0]->duration, [ 1, 2 ], '3/4 * 2/3';
};

done_testing;
