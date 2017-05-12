package Music::Scales;
use strict;
use Text::Abbrev;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT);
	$VERSION     = 0.07;
	@ISA         = qw (Exporter);
	@EXPORT      = qw (get_scale_notes get_scale_nums get_scale_offsets is_scale get_scale_PDL get_scale_MIDI);
}


=head1 NAME

 Scales - supply necessary notes / offsets for musical scales

=head1 SYNOPSIS

    use Music::Scales;

    my @maj = get_scale_notes('Eb');           # defaults to major
    print join(" ",@maj);                      # "Eb F G Ab Bb C D"
    my @blues = get_scale_nums('bl');          # 'bl','blu','blue','blues'
    print join(" ",@blues);                    # "0 3 5 6 7 10"
    my %min = get_scale_offsets ('G','mm',1);  # descending melodic minor
    print map {"$_=$min{$_} "} sort keys %min; # "A=0 B=-1 C=0 D=0 E=-1 F=0 G=0"


=head1 DESCRIPTION

 Given a keynote A-G(#/b) and a scale-name, will return the scale, 
 either as an array of notenames or as a hash of semitone-offsets for each note.

=head1 METHODS

=head2 get_scale_nums($scale[,$descending])

returns an array of semitone offsets for the requested scale, ascending/descending the given scale for one octave.
The descending flag determines the direction of the scale, and also affects those scales (such as melodic minor) where the notes vary depending upon the direction.
Scaletypes and valid values for $scale are listed below.

=head2 get_scale_notes($notename[,$scale,$descending,$keypref])

returns an array of notenames, starting from the given keynote.
Enharmonic equivalencies (whether to use F# or Gb, for instance) are calculated based on the keynote and the scale. Basically, it attempts to do the Right Thing if the scale is an 8-note one, 
(the 7th in G harmonic minor being F# rather than Gb, although G minor is a 'flat' key), but for any other scales, (Chromatic, blues etc.) it picks equivalencies based upon the keynote.
This can be overidden with $keypref, setting to be either '#' or 'b' for sharps and flats respectively. Cruftiness abounds here :)

=head2 get_scale_offsets($notename[,$scale,$descending,$keypref])

as get_scale_notes(), except it returns a hash of notenames with the values being a semitone offset (-1, 0 or 1) as shown in the synopsis.

=head2 get_scale_MIDI($notename,$octave[,$scale,$descending])

as get_scale_notes(), but returns an array of MIDI note-numbers, given an octave number (-1..9).

=head2 get_scale_PDL($notename,$octave[,$scale,$descending])

as get_scale_MIDI(), but returns an array of PDL-format notes.

=head2 is_scale($scalename)

returns true if $scalename is a valid scale name used in this module.

=head1 SCALES 

Scales can be passed either by name or number.
The default scale is 'major' if none  / invalid is given.
Text::Abbrev is used on scalenames, so they can be as abbreviated as unambiguously possible ('dor','io' etc.).
Other abbreviations are shown in brackets.

  1 ionian / major / hypolydian
  2 dorian / hypmixolydian
  3 phrygian / hypoaeolian
  4 lydian  / hypolocrian
  5 mixolydian / hypoionian
  6 aeolian / hypodorian / minor / m
  7 locrian / hypophrygian
  8 harmonic minor / hm
  9 melodic minor / mm
 10 blues 
 11 pentatonic (pmajor)
 12 chromatic 
 13 diminished 
 14 wholetone 
 15 augmented 
 16 hungarian minor 
 17 3 semitone 
 18 4 semitone 
 19 neapolitan minor (nmin)
 20 neapolitan major (nmaj)
 21 todi 
 22 marva 
 23 persian 
 24 oriental 
 25 romanian 
 26 pelog 
 27 iwato 
 28 hirajoshi 
 29 egyptian 
 30 pentatonic minor (pminor)

=head1 EXAMPLE

This will print every scale in every key, adjusting the enharmonic equivalents accordingly.

	foreach my $note qw (C C# D D# E F F# G G# A A# B) {
        foreach my $mode (1..30) {
            my @notes = get_scale_notes($note,$mode);
            push @notes, get_scale_notes($note,$mode,1); # descending
            print join(" ",@notes),"\n";
        }
    }


=head1 TODO
 
 Add further range of scales from http://www.cs.ruu.nl/pub/MIDI/DOC/scales.zip
 Improve enharmonic eqivalents.
 Microtones
 Generate ragas,gamelan etc.  - maybe needs an 'ethnic' subset of modules

=head1 AUTHOR

 Ben Daglish (bdaglish@surfnet-ds.co.uk)

 Thanks to Steve Hay for pointing out my 'minor' mix-up and many suggestions.
 Thanks also to Gene Boggs for the 'is_scale' suggestion / code.

=head1 BUGS 
 
 A few enharmonic problems still...

 All feedback most welcome.

=head1 COPYRIGHT

 Copyright (c) 2003, Ben Daglish. All Rights Reserved.
 This program is free software; you can redistribute
 it and/or modify it under the same terms as Perl itself.

 The full text of the license can be found in the
 LICENSE file included with this module.


=head1 SEE ALSO

PDL::Audio::Scale, perl(1).

=cut

my %modes = qw(ionian 1 major 1 hypolydian 1 dorian 2 hypomyxolydian 2 
	phrygian 3 hypoaeolian 3 lydian 4 hypolocrian 4 mixolydian 5 hypoionian 5
	aeolian 6 minor 6 m 6 hypodorian 6 locrian 7 hypophrygian 7 
	harmonicminor 8 hm 8 melodicminor 9 mm 9
	blues 10 pentatonic 11 pmaj 11 chromatic 12 diminished 13 wholetone 14
	augmented 15 hungarianminor 16 3semitone 17 4semitone 18 
	neapolitanminor 19 nmin 19 neapolitanmajor 20 nmaj 20
	todi 21 marva 22 persian 23 oriental 24 romanian 25 pelog 26
	iwato 27 hirajoshi 28 egyptian 29 pminor 30 pentatonicminor 30
);

my %abbrevs = abbrev(keys %modes);
while (my ($k,$v) = each %abbrevs) {
	$modes{$k} = $modes{$v};
}

my @scales=([0,2,4,5,7,9,11],	# Ionian(1)
			[0,2,3,5,7,9,10],	# Dorian (2)
			[0,1,3,5,7,8,10],	# Phrygian (3)
			[0,2,4,6,7,9,11],	# Lydian (4)
			[0,2,4,5,7,9,10],	# Mixolydian (5)
			[0,2,3,5,7,8,10],	# Aeolian (6)
			[0,1,3,5,6,8,10],	# Locrian (7)
			[0,2,3,5,7,8,11],	# Harmonic Minor (8)
			[0,2,3,5,7,9,11],	# Melodic Minor (9)
			[0,3,5,6,7,10],		# Blues (10)
			[0,2,4,7,9],		# Pentatonic (11)
			[0,1,2,3,4,5,6,7,8,9,10,11],# Chromatic (12)
			[0,2,3,5,6,8,9,11],	# Diminished (13)
			[0,2,4,6,8,10],		# Whole tone(14)
			[0,3,4,7,8,11],		# Augmented (15)
			[0,2,3,6,7,8,11],	# Hungarian minor (16)
			[0,3,6,9],			# 3 semitone (dimished arpeggio) (17)
			[0,4,8],			# 4 semitone (augmented arpeggio) (18)
			[0,1,3,5,7,8,11],	# Neapolitan minor  (19)
			[0,1,3,5,7,9,11],	# Neapolitan major (20)
			[0,1,3,6,7,8,11],	# Todi (Indian) (21)
			[0,1,4,6,7,9,11],	# Marva (Indian) (22)
			[0,1,4,5,6,8,11],	# Persian (23)
			[0,1,4,5,6,9,10],	# Oriental (24)
			[0,2,3,6,7,9,10],	# Romanian (25)
			[0,1,3,7,10],		# Pelog (Balinese) (26)
			[0,1,5,6,10],		# Iwato (Japanese) (27)
			[0,2,3,7,8],		# Hirajoshi (Japanese) (28)
			[0,2,5,7,10],		# Egyptian (29)
			[0,3,5,7,10],		# Pentatonic Minor (30)
);

sub get_scale_nums {
	my ($mode,$descending) = @_;
	$mode = get_mode($mode);
	my @dists = @{$scales[$mode-1]};
	if ($descending && $mode == 9) {
		$dists[5]-- ;$dists[6]--;
	}
	($descending) ? reverse @dists  : @dists;
}

sub get_scale_offsets {
	my @scale = get_scale_notes(@_);
	my %key_alts = qw(C 0 D 0 E 0 F 0 G 0 A 0 B 0);
	foreach (@scale) {
		$key_alts{$_}++ if s/#//;
		$key_alts{$_}-- if s/b//;
	}
	%key_alts;
}

sub get_mode {
	my $mode = shift() || 1;
	$mode =~ s/[^a-zA-Z0-9]//g;
	$mode = $modes{lc($mode)} unless $mode =~/^[0-9]+$/;
	($mode && ($mode <= @scales)) ? $mode : 1;
}

sub note_to_num {
	my $note = shift();
	my %note2num = ('A','0','A#','1','BB','1','B','2','C','3','C#','4','DB','4','D','5','D#','6','EB','6','E','7','F','8','F#','9','GB','9','G','10','G#','11','AB','11');
	return $note if ($note =~/^[0-9]+$/);
	(defined $note2num{uc($note)}) ? $note2num{uc($note)} : 0;
}

sub note_to_MIDI {
	my ($note,$octave) = @_;
	((note_to_num($note)+9) % 12) + (12 * ++$octave ); 
}

sub get_scale_MIDI {
	my ($note,$octave,$mode,$descending) = @_;
	my $basenum = note_to_MIDI($note,$octave);
	return map {$basenum + $_} get_scale_nums($mode,$descending);
}

sub get_scale_PDL {
	my ($note,$octave,$mode,$descending,$keypref) = @_;
	scale_to_PDL($octave,get_scale_notes($note,$mode,$descending,$keypref));
}

sub get_scale_notes {
	my ($keynote,$mode,$descending,$keypref) = @_;
	my @notes = ('A'..'G');
	my @nums = (2,1,2,2,1,2,2);

	$keynote =~ s/^[a-z]/\u$&/;
	$keypref='' unless defined $keypref;
	my $keynum = note_to_num(uc($keynote));
	$mode = get_mode($mode);
	my @dists = get_scale_nums($mode,$descending);
	@dists = reverse @dists if $descending;
	my @scale = map {($_+$keynum-$dists[0])%12} @dists;
	$keypref='b' if (!$keypref && $descending && $mode == 12); #prefer flat descending chromatic

	my %num2note = (0,'A',1,'A#',2,'B',3,'C',4,'C#',5,'D',6,'D#',7,'E',8,'F',9,'F#',10,'G',11,'G#');
	%num2note = (0,'A',1,'Bb',2,'B',3,'C',4,'Db',5,'D',6,'Eb',7,'E',8,'F',9,'Gb',10,'G',11,'Ab') if (($keypref eq 'b') || ($keynote =~ /.b/i));
	my @mscale = $keynote;
	if (@scale  > 7) {	# we're not bothered by niceties, so just convert
		@mscale = map {$num2note{$_}} @scale;
	}
	else {
		$keynote = $num2note{$keynote} if $keynote =~/^[0-9]+$/;
		my $kk = $keynote; $kk =~ s/b|\#//; $kk = ord($kk) - ord('A');
		foreach(0..$kk-1) {# rotate to keynote
			push @notes,shift(@notes);
			push @nums,shift(@nums);
		}
		push @notes,shift(@notes);
		shift(@dists);
		my $cu = shift(@nums);
		$cu++ if ($keynote =~ /b/);
		$cu-- if ($keynote =~ /#/);
		foreach (@dists) {
			my $m = $_ - $cu;
			my $ns = shift(@nums);
			push @nums,$ns;
			my $n = shift(@notes); 
			push @notes,$n;
			while (abs($m) > 2 || (@scale < 7 && abs($m) >= $ns)) {	# step up/down notes, 'reducing' flats/sharps
				$n = shift(@notes); push @notes,$n;
				if ($m > 0) {$m -= $ns;$cu += $ns }
				elsif ($m < 0){$m += $ns;$cu -= $ns}
				$ns = shift(@nums); push @nums,$ns;
			}
			$n .= '#' x $m if ($m > 0);
			$n .= 'b' x abs($m) if ($m < 0);
			push @mscale,$n;
			$cu += $ns;
		}
	}
	if ($descending) {
		@mscale = reverse @mscale;
		unshift @mscale,pop(@mscale);
	}
	@mscale;
}


sub is_scale {
	my $name = shift();
    $name =~ s/[^a-zA-Z0-9]//g;
    return exists $modes{lc $name} ? 1 : 0;
}

sub scale_to_PDL {
	my ($octave,@scale)=@_;
	my @result;
	my $descending;
	my $n1 = note_to_num($scale[0]);
	my $n2 = note_to_num($scale[1]);
	if ($n2 < $n1 && ($n1-$n2 < 5)) {
		$descending = 1;
		@scale = reverse @scale;
	}
	my $last = (note_to_num($scale[0]) + 9) % 12;
	foreach (@scale) {
		my $n = (note_to_num($_) + 9) % 12;
		$octave++ if ($last > $n); #switched over octave at 'c'
		s/\#/s/g;
		s/b/f/g;
		push @result,lc($_).$octave;
		$last = $n;
	}
	@result = reverse @result if $descending;
	@result;
}

1; 
__END__

