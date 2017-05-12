package Music::Note;
use strict;

BEGIN {
	use vars qw ($VERSION);
	$VERSION     = 0.01;
}

=head1 NAME

 Note - representation of a single musical note, and various manipulation routines

=head1 SYNOPSIS

    use Music::Note;

	my $note = Music::Note->new("C#4","ISO");  # 'simple' style - notename/type
	$note->transpose->(-16);     # to A2
	$note->alter(1);             # to A#2
	$note->en_eq('flat');        # to Bb2
	print $note->format("kern"); # BB-
	$note = Music::Note->new({step=>'C',octave=>'4',alter=>1});
	print $note->octave();       # 4
	print $note->step();         # C


=head1 DESCRIPTION

 An OO encapsulation of a single musical note. Includes methods for transposition, enharmonic equivalence, and creation/output in a range of formats.

=head1 METHODS

=head2 new($notename,$type)

Creates a new Note object. See below for a list of types. $type defaults to "ISO" if omitted. $notename defaults to "C4".

=head2 new({%params})

Creates a new Note object. Parameters are MusicXML compliant - viz. "step" (A-G), 'octave' (+/- integer) and 'alter' (+/- integer).
The 'octave' parameter is based upon standard usage, where C4=Middle C and the number changes between B and C. The 'alter' parameter indicates
accidentals, where '1' is sharp, '-1' is flat, '2' is double-sharp and so on.

=head2 format($type)

Returns the note object formatted in one of the styles named below.

=head2 transpose($amount)

Transposes the note by $amount semitones (+/-), keeping accidental types where possible (eg. - Ab + 2 = Bb, not A#).
Returns the note object.

=head2 en_eq($type)

Changes the Note into an enharmonic equivalent (C#->Db, for instance).
$type can be either 'sharp' (or 's'/'#') or 'flat'('f'/'b').
Double accidentals are naturalised - so 'Bbb' will become 'A' if sharpened, and 'Fx' becomes 'G' if flattened.
Returns the note object.

=head1 STYLES

 ISO      (C3, D#4, Ab5)
 isobase  (C, Ds, Af  (as ISO, but no octave number) )
 midi     (C3, Ds4, Af5)
 midinum  (0-127)
 kern     (CC, d+, aa-)
 MusicXML (<pitch><step>D</step><octave>4</octave><alter>1</alter></pitch>)
 pdl      (c3, ds4, af5)

 'xml' can be used as a synonym for 'MusicXML'.


=head1 TODO
 more types - abc, solfa (do,re,mi,fa,so,la,ti), Indian (sa,re,ga,ma,pa,da,ni)
 length manipulation

=head1 AUTHOR

 Ben Daglish (bdaglish@cpan.org)

=head1 BUGS 
 
 None known
 All feedback most welcome.

=head1 COPYRIGHT

 Copyright (c) 2003, Ben Daglish. All Rights Reserved.
 This program is free software; you can redistribute
 it and/or modify it under the same terms as Perl itself.

 The full text of the license can be found in the
 LICENSE file included with this module.

=head1 SEE ALSO

 perl(1).

=cut

my %midinotes = qw(0 C 1 CS 2 D 3 DS 4 E 5 F 6 FS 7 G 8 GS 9 A 10 AS 11 B);
my %stepnums = qw(C 0 D 2 E 4 F 5 G 7 A 9 B 11);
my @numsteps = qw(C C D D E F F G G A A B C C D D E F F G G A A B C C D D E F F G G A A B);

sub new  {
	my ($class) = shift();
	my %self = ('step'=>'C','alter'=>0,'octave'=>4);
	my ($note) = shift();
	if (ref($note) =~ /HASH/) {
		%self = (%self,%$note);
	}
	else {
		my $type = lc(shift() || "iso");
		if ($type eq 'iso' || $type eq 'isobase' || $type eq 'midi' || $type eq 'pdl') {
			$note =~ /([A-Ga-g])([bn\#xfs]\b?)?([+-]?\d+)?/;
			$self{step} = uc($1) if $1;
			$self{octave} = $3 if defined $3;
			my $alt = $2 || ''; 
			$alt =~ s/f(?:lat)?/b/g;
			$alt =~ s/s(?:harp)?/\#/g;
			$self{alter} = -2 if $alt eq 'bb';
			$self{alter} = -1 if $alt eq 'b';
			$self{alter} = 1 if $alt eq '#';
			$self{alter} = 2 if ($alt eq 'x' || $alt eq '##');
		}
		elsif ($type eq 'musicxml' || $type eq 'xml') {
			if ($note =~ /<step>(.*?)<\/step>/){$self{step} = $1 if $1;}
			if ($note =~ /<octave>(.*?)<\/octave>/){$self{octave} = $1 if $1;}
			if ($note =~ /<alter>(.*?)<\/alter>/){$self{alter} = $1 if $1;}
		}
		elsif ($type eq 'midinum') {
			($self{step},$self{octave},$self{alter}) = from_midinum($note);
		}
		elsif ($type eq 'kern') {
			$note =~ /([a-gA-G]+)([\#-]*)/;
			my ($step,$alt) = ($1,$2);
			$self{alter} = length($alt) * (($alt =~/-/) ? -1 : 1);
			$self{step} = uc(substr($step,0,1));
			my $l = length($step) - 1;
			if ($step eq uc($step)) {$l = -(++$l)}
			$self{octave} = 4 + $l;
		}
	}
	bless \%self,$class;
}

sub step {
	my $self = shift();
	$self->{step} = shift() if (@_ && $_[0] =~ /^[A-G]$/);
	$self->{step};
}
sub octave {
	my $self = shift();
	$self->{octave} = shift() if (@_ && $_[0] =~ /[+-]?\d+/);
	$self->{octave};
}
sub alter {
	my $self = shift();
	$self->{alter} = shift() if (@_ && $_[0] =~ /[+-]?\d+/);
	$self->{alter};
}

sub format {
	my ($self,$format) = @_;
	$format = lc($format) || "iso";
	my %isofs =  (-3,'bbb',-2,'bb',-1,'b',0,'',1,'#',2,'x',3,'x#');
	my %midifs = (-3,'fff',-2,'ff',-1,'f',0,'',1,'s',2,'ss',3,'sss');
	my %kernfs = (-3,'---',-2,'--',-1,'-',0,'',1,'#',2,'##',3,'###');
	if ($format eq 'iso') {
		return $self->{step}.$isofs{$self->{alter}}.$self->{octave};
	}
	if ($format eq 'isobase') {
		return $self->{step}.$isofs{$self->{alter}};
	}
	elsif ($format eq 'midi') {
		return $self->{step}.$midifs{$self->{alter}}.$self->{octave};
	}
	elsif ($format eq 'pdl') {
		return lc($self->{step}).$midifs{$self->{alter}}.$self->{octave};
	}
	elsif ($format eq 'midinum') {
		return $self->to_midinum;
	}
	elsif ($format eq 'kern') {
		my $s = $self->{step};
		my $o = $self->{octave} - 4;
		if ($o >= 0) {$s = lc($s);}
		else {$o = -(++$o);}
		$s.($s x $o).$kernfs{$self->{alter}};
	}
	elsif ($format eq 'xml' || $format eq 'musicxml') {
		return "<pitch><step>$self->{step}</step><octave>$self->{octave}</octave><alter>$self->{alter}</alter></pitch>";
	}
	else {warn ("Incorrect format ($format) passed to Music::Note->format");}
}
sub transpose {
	my ($self,$amount) = @_;
	my $num = $self->to_midinum;
	my $alt = $self->{alter};
	$num += int($amount);
	($self->{step},$self->{octave},$self->{alter}) = from_midinum($num);
	if ($alt < 0 && $self->{alter}) {
		$self->en_eq('f');
	}
	$self;
}

sub en_eq {
	my ($self,$type) = @_;
	my $stepnum = $stepnums{$self->{step}} + 12;
	if ($type =~ /^[s\#]/) {
		$self->{alter} += 2;
		$stepnum -= 2;
		$self->{step} = $numsteps[$stepnum];
		$self->{octave}-- if ($stepnum < 12);
	}
	elsif ($type =~ /^[fb]/) {
		$self->{alter} -= 2;
		$stepnum += 2;
		$self->{step} = $numsteps[$stepnum];
		$self->{octave}++ if ($stepnum > 24);
	}
	else {warn ("Incorrect type ($type) passed to Music::Note->en_hq");}
}

sub to_midinum {
	my $self = shift();
	return (12 * ($self->{octave}+1)) + $stepnums{$self->{step}} + $self->{alter};
}
sub from_midinum {
	my $num = shift();
	my $step = $midinotes{$num % 12};
	my $octave =  int($num / 12) - 1;
	my $alter = 0;
	if ($step =~ s/S$//) {$alter = 1;}
	($step,$octave,$alter);
}


1;

