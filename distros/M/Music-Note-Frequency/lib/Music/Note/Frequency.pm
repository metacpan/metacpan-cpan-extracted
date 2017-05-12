package Music::Note::Frequency;

use 5.006;
use strict;
use warnings;

our @ISA=("Music::Note");
use Music::Note;

sub new {
	my ($class,@args)=@_;

	our $self={};
	our $base=440;
	
	if (ref($args[0]) =~/HASH/) {
		if (defined($args[0]->{base}) && $args[0]->{base} =~ /^\d+$/) {
			$base=$args[0]->{base};
			delete $args[0]->{base};
		}
		
		$self=Music::Note->new($args[0]);
	} elsif (scalar(@args) > 0) {
		#my $type='ISO';
		#my $step='C'; my $alter=0;my $octave=4;
		$base=pop @args;
		if ($base !~ /^\d*\.?\d*$/ ||  $base !~ /\d/ || $base < 0) {
			push @args, $base;
			$base=440;
		};
		$self=Music::Note->new(@args);
	} else {
		$self=Music::Note->new();
	}

	$self->{base}=$base;

	bless $self,$class;
	return $self;
}
	

=head1 NAME

Music::Note::Frequency - returns the note's frequency in Hertz (Hz).

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    use Music::Note::Frequency;

	# create a new note object at C4 with base frequency A4=440 Hz.
	my $note = Music::Note::Frequency->new();

	# all of these create a new object with note = C4 and base 
        #   frequency A4=431 Hz (default is 440):
        my $note = Music::Note::Frequency->new(431); 
        my $note = Music::Note::Frequency->new("C4",431); 
        my $note = Music::Note::Frequency->new("C4","ISO",431); 
        my $note = Music::Note::Frequency->new({   step=>'C',
                                                   alter=>0,
                                                   octave=>4,
                                                   base=>431});
        my $note = Music::Note::Frequency->new({base=>431});
	

        # get the frequency of a note
        my $note = Music::Note::Frequency->new("C4");
        print $note->frequency(); # prints 261.625565300599
        # change the note's base frequency
	my $base=$note->base(431); # sets new base to 431 Hz
	print $note->frequency(); # prints 256.274133283086


=head1 DESCRIPTION

This module extends Music::Note to provide a method to return the frequency in Hertz (Hz) of the object's note from an equal-tempered tuning.  The formula for calculating frequency values was taken from L<https://en.wikipedia.org/wiki/Piano_key_frequencies> and modified to support MIDI pitch values instead of piano key numbers and alternative base frequencies:

        f(n) = 2**((n - 69)/12) * base

        

=head1 METHODS

=head2 new()

=head2 new(NOTE)

=head2 new(NOTE,TYPE)

=head2 new(NOTE,TYPE,BASE)

=head2 new(NOTE,BASE)

=head2 new(BASE)

=head2 new(\%args)

Creates and returns a Music::Note::Frequency object with the values specified in the arguments or defaults of note value = C4 and frequency base (value of A4) = 440 Hz.  Otherwise takes the same arguments as described in the perldoc for Music::Note, with the addition of BASE as an optional (last) numeric argument or as a key/value pair in the passed argument hashref.  Example:

        my $note = Music::Note::Frequency->new({step=>'C',octave=>4,base=>415});

=head2 frequency()

Returns the frequency in Hertz (Hz) of the note from an equal-tempered tuning.  Calculates the frequency from the above formula.  Supports all note types that are supported by Music::Note.


=cut

sub frequency {
        my $self = shift;
        my $n=$self->to_midinum();
	
	my $f=$self->{base} * 2**(($n-69)/12);

        return $f;
};

=head2 base()

=head2 base(FREQ)

Sets or gets the base frequency, i.e. the value of A4 (the A above middle C).  This defaults to 440 when you create the note object without specifying a base frequency.  If called without any parameters, it simply returns the currently set base frequency (from which all other frequencies are calculated).  If called with a numeric parameter, then it sets the base frequency to that value and returns the same.  If FREQ is not numeric, then it doesn't set anything - it just returns the current base frequency.

=cut

sub base {
	my $self = shift;
	my $base = shift || undef;

	if (defined($base) && $base =~ /^\d*\.?\d*$/ &&  $base =~ /\d/ && $base >= 0) {
		$self->{base}=$base;
	}  
	return $self->{base};
}


=head1 ACKNOWLEDGEMENTS

Special thanks to Ben Daglish, the author of Music::Note L<http://search.cpan.org/dist/Music-Note/>, both for his original module and his suggestion to allow setting the base frequency, and Wikipedia for source material: L<https://en.wikipedia.org/wiki/Piano_key_frequencies>.


=head1 AUTHOR

Mike Kroh, C<< <kroh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-music-note-frequency at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Note-Frequency>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

Future releases should contain methods to: return frequency in radians/second, return normalized frequencies (given the sampling rate), return frequencies for alternate tunings.  Should create methods for different tunings instead of including equal-tempered formula in "frequency()".  None of these are a priority at the time of this release.  


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Music::Note::Frequency


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Music-Note-Frequency>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Music-Note-Frequency>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Music-Note-Frequency>

=item * Search CPAN

L<http://search.cpan.org/dist/Music-Note-Frequency/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Mike Kroh.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Music::Note::Frequency
