package Music::Chord::Namer;

use 5.008007;
use strict;
use warnings;
use subs qw/jws jwn/;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Music::Chord::Namer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	chordname
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


our %NOTES; 
our $NAME;
our $D;


sub chordname { # the sub that guesses the name of the chord

	# convert note names to numbers
	my %notevalues = ('C'=>0,'C#'=>1,'Db'=>1,'D'=>2,'D#'=>3,'Eb'=>3,'E'=>4,'F'=>5,
		'F#'=>6,'Gb'=>6,'G'=>7,'G#'=>8,'Ab'=>8,'A'=>9,'A#'=>10,'Bb'=>10,'B'=>11);
	# convert note numbers back to names
	my @value2note = ('C','C#','D','D#','E','F','F#','G','G#','A','A#','B');
	
	my @notes = ();	# store notes here...
	
	if(@_ > 1){	# if the notes are supplied as a list
		@notes = @_;	# ok
	}
	elsif($_[0]) { # or as a string
		@notes = split(/\s+/, $_[0]); # deal with it!
	}
	else {
		return; # no notes??
	}
	
	my @notenumbers = ();	# store the corresponding numbers here
	foreach my $note(@notes){
		die "Bad note \"$note\"!" unless defined $notevalues{$note};
		my $notenumber = $notevalues{$note};
		# make sure that it's a higher number than that of the note that preceeded it...
		if(defined $notenumbers[$#notenumbers]){
			while($notenumber < $notenumbers[$#notenumbers]){ $notenumber += 12; }
		}
		# add it to the list
		push  @notenumbers, $notenumber;
	}
	
	

# Naming

# We need to make some decisions about what to call it a chord...
# Lets assume we know no better and we're going to try every possible chord
# and see which name is the shortest!

# Lets go through every probable root note first... one of the two bass notes must
# be the 1, m3, 3, 5 or m7 of the chord.  No cheating!

# We can then work out the names of these 10 chords...

# 1) The bass note is 1
# 2) The bass note is m3
# 3) The bass note is 3
# 4) The bass note is 5
# 5) The bass note is m7
# 6) The bass note is separate, the next note is 1
# 7) The bass note is separate, the next note is m3
# 8) The bass note is separate, the next note is 3
# 9) The bass note is separate, the next note is 5
# 10) The bass note is separate, the next note is m7

# notes set to bass note being a certain chord member
	
	my @inversions = ();
	# name, notes, split, comment
	# the name depends on what we're saying the bass note is... it could be the root, minor or major 3rd
	# 5th or minor 7th.
	push @inversions,
		{name => $value2note[($notevalues{$notes[0]}) % 12], notes => [map { $_ - $notenumbers[0] } @notenumbers], split => '', comment => 'bass 1'},
		{name => $value2note[($notevalues{$notes[0]} - 3) % 12], notes => [map { $_ - $notenumbers[0] + 3 } @notenumbers], split => $notes[0], comment => 'bass m3'},
		{name => $value2note[($notevalues{$notes[0]} - 4) % 12], notes => [map { $_ - $notenumbers[0] + 4 } @notenumbers], split => $notes[0], comment => 'bass 3'},
		{name => $value2note[($notevalues{$notes[0]} + 5) % 12], notes => [map { $_ - $notenumbers[0] - 5 } @notenumbers], split => $notes[0], comment => 'bass 5'},
		{name => $value2note[($notevalues{$notes[0]} + 2) % 12], notes => [map { $_ - $notenumbers[0] - 2 } @notenumbers], split => $notes[0], comment => 'bass m7'};
	
	shift(@notenumbers);  # get rid of bass note, incase it's a split!
			# ... and do it all again!
	push @inversions,
		{name => $value2note[($notevalues{$notes[0]}) % 12], notes => [map { $_ - $notenumbers[0] } @notenumbers], split => $notes[0], comment => 'split 1'},
		{name => $value2note[($notevalues{$notes[0]} - 3) % 12], notes => [map { $_ - $notenumbers[0] + 3 } @notenumbers], split => $notes[0], comment => 'split m3'},
		{name => $value2note[($notevalues{$notes[0]} - 4) % 12], notes => [map { $_ - $notenumbers[0] + 4 } @notenumbers], split => $notes[0], comment => 'split 3'},
		{name => $value2note[($notevalues{$notes[0]} + 5) % 12], notes => [map { $_ - $notenumbers[0] - 5 } @notenumbers], split => $notes[0], comment => 'split 5'},
		{name => $value2note[($notevalues{$notes[0]} + 2) % 12], notes => [map { $_ - $notenumbers[0] - 2 } @notenumbers], split => $notes[0], comment => 'split m7'};
	
# ok, here's how it works:

# There are these notes:

#  0   1   2   3   4   5   6   7   8   9  10  11
#  1  b2   2  m3   3   4  b5   5  a5   6  m7   7

# 12  13  14  15  16  17  18  19  20  21  22  23
#  8  b9   9 m10  10  11 b12  12 b13  13 m14  14

	# these are the names of the notes we could have in the chord
	my @valuenames = qw(
		1  b2   2  m3   3   4  b5   5  a5   6  m7   7
		8  b9   9 m10  10  11 b12  12 b13  13 m14  14);

# Chord folding

# We'll fold our chord into this structure... whichever note is the root can get
# set as 0.  Any note below it can have 12 added to it until it's above 0.  Any
# note above 23 can have 12 taken from it until it is 23 or less.

	# fold each of our inversions of the chord!	
	foreach my $hash(@inversions){
		my $array = $hash->{notes}  ;
		for(my $i = 0; $i< @$array; $i++){
			while($array->[$i] > 23){ $array->[$i] -= 12; } # anything over 23, drop it an octave
			while($array->[$i] < 0){ $array->[$i] += 12; } # anything under 0, raise it an octave
		}
	}

	# we'll put the chord names in here:
	my @NAMES = (); 

	# now we need to turn them into hashes!!!   We'll do all the rest for each hash
	foreach my $hash(@inversions){
		# skip it if the name is the same as the split... this could happen in the "next" inversions... there's
		# no point to it because it will already have been covered by "bass 1"
		next if $hash->{'split'} && $notevalues{$hash->{'split'}} == $notevalues{$hash->{name}};
		# the notes...
		my $array = $hash->{notes}  ;	  	  
		%NOTES = ();    # global, setting it up before calling isset, etc
		$NAME = $hash->{name};   # global
		for(my $i = 0; $i< @$array; $i++){
			$NOTES{$array->[$i]} = 1;  # set up the existence of the notes in the hash
		}

# Duplicate notes

# If any note from 0-11 is set then the corresponding note from 12-23 can be
# un-set.

		foreach (0..11){		# remove notes from upper octave that are already in lower one!
			isset($_) and unset($_+12)
		}

# Shifting 1, 3, 5, 7

# If none of the 1sts, 3rds, 5ths or 7ths are set in the lower octave then any
# corresponding notes in the upper octave can be shifted down.

		isset(0) or (unset(12) and set(0));  # drop 12 to 0 if 0 doesn't exist
		isset(3) or isset(4) # drop either 16 or 15 to 3 or 4 unless 3 or 4 is already set (3rds)
			or (unset(4+12) and set(4))	or (unset(3+12) and set(3));
		isset(6) or isset(7) or isset(8) # the same for 5ths
			or (unset(7+12) and set(7))	or (unset(6+12) and set(6))	or (unset(8+12) and set(8));
		isset(10) or isset(11) # and 7ths
			or (unset(10+12) and set(10))	or (unset(11+12) and set(11));

# Now, lets look at what we have...

# Is there a root note (0)???  if not, then add "no-root" to the name
# Is there a third (3,4)???  if not, then add "no-3rd" to the name
# etc...

# (if the selection is true, the note concerned is removed so as not to be
#  evaluated more than once)


# Reasoning...

# unset returns true if it was able to unset, false otherwise...
				
		# special chords:
		$D = lower_octave_is(0,3,6,9) and unset(0,3,6,9) and app('o7');
		$D = $D || lower_octave_is(0,3,6,10) and unset(0,3,6,10) and app('Ø7');
		$D = $D || lower_octave_is(0,3,6) and unset(0,3,6) and app('o');
		# sort out our thirds
		$D or
			unset(4) or
			(unset(3) and app('m')) or
			(unset(5) and app(' sus')) or
			(unset(2) and app(' sus2')) or
			app('no-3rd');
		# sort out 13 11 9 7
		(unset(21,17,14,10) and app('13')) or
			(unset(21,17,14,11) and app('maj13')) or
			(unset(17,14,10) and app('11')) or
			(unset(17,14,11) and app('maj11')) or
			(unset(14,10) and app('9')) or
			(unset(14,11) and app('maj9')) or
			(unset(10) and app('7')) or
			(unset(11) and app('maj7')) or
			(unset(9,14) and app('6/9')) or
			(unset(9) and app('-6'));
		# sort out 5
		$D or
			unset(7) or
			(unset(6) and app(' b5')) or
			(unset(8) and app(' #5')) or
			app(' no5');
		# root
		$D or
			unset(0) or app(' no-root');
		# any additional notes
		foreach (0..23){
			unset($_) and app(' add'.$valuenames[$_]);
		}
		# split
		if($hash->{split}){ $NAME .= '/'.$hash->{split}; }
		push @NAMES, $NAME;
	}
	my @results =  sort {length($a) <=> length($b)} @NAMES;
	if(wantarray){
		return @results;
	}
	else {
		return $results[0];
	}
}




# some subs:
	
sub set {
	$NOTES{$_[0]} = 1;
	return 1;
}
sub isset {
	if($NOTES{$_[0]}){ return 1; }
	else {  return 0; }
}
sub unset {
	foreach (@_){
		if(! isset($_)){ return 0; }
	}
	foreach (@_){
		$NOTES{$_} = 0;
	}
	return 1;
}
sub app {
	$NAME .= $_[0];
	return 1;
}
sub lower_octave_is {
	my %notes = map { ($_ => 1) } @_; # sets up %notes = ($_[0]=>1,$_[1]=>1 ...)
	foreach my $i(0..11){
		if(($notes{$i} && ! $NOTES{$i}) || # if it's set in one but not the other
				($NOTES{$i} && ! $notes{$i})){  # or the other way around
			return 0;  # then the test returns false
		}
	}
	return 1;
}

sub jws {
	return join(' ',@_);
}
sub jwn {
	return join("\n",@_);
}

1;





=head1 NAME

Music::Chord::Namer - You give it notes, it names the chord.

=head1 SYNOPSIS

	use Music::ChordName qw/chordname/;

	print chordname(qw/C E G/); # prints C
	print chordname(q/C E G/); # same (yes, array or string!)
	print chordname(qw/C Eb G Bb D/); # prints Cm9
	print chordname(qw/G C Eb Bb D/); # prints Cm9/G

=head1 DESCRIPTION

Music::ChordName optionally exports one sub, chordname, which accepts some notes as either a string
or a list and returns the best chord name it can think of.

=head2 EXPORT

None by default.

=over 4

=item $bestnamescalar|@namesarray = chordname($notesstring|@notesarray)

chordname() accepts either a string of notes such as "C Eb G A#" or a list of notes such as
qw/Ab Bb F Bb D/.  In a scalar context it returns the best name it could think of to describe the 
chord made from the notes you gave it.  In an array context it returns all of the names it thought
of, sorted from best to worst (shortest to longest!)

=head1 EXAMPLES


	# to print a bunch of guitar chord names with at lest 4 notes each,
	# all below 5th fret...
	
	foreach my $s1(qw/- E F Gb G Ab/){
		foreach my $s2(qw/- A Bb B C Db/){
			foreach my $s3(qw/- D Eb E F Gb/){
				foreach my $s4(qw/- G Ab A Bb/){
					foreach my $s5(qw/- B C Db D Eb/){
						foreach my $s6(qw/- E F Gb G Ab/){
							my @notes = ();
							push @notes, $s1 unless $s1 eq '-';
							push @notes, $s2 unless $s2 eq '-';
							push @notes, $s3 unless $s3 eq '-';
							push @notes, $s4 unless $s4 eq '-';
							push @notes, $s5 unless $s5 eq '-';
							push @notes, $s6 unless $s6 eq '-';
							if(@notes >= 4){
								print scalar(chordname(@notes)),' = ',join(' ',@notes),"\n";
							}
						}
					}
				}
			}
		}
	}


=head1 SEE ALSO

L<Music::Image::Chord> could be combined nicely with this module.

=head1 AUTHOR

Jimi-Carlo Bukowski-Wills, jimi@webu.co.uk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jimi-Carlo Bukowski-Wills

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
