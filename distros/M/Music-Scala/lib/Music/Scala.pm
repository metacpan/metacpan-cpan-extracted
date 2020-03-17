# -*- Perl -*-
#
# Scala scale (musical tuning and temperament) support for Perl, based
# on specification at: http://www.huygens-fokker.org/scala/
#
# Ratio to cent and cent to ratio equations lifted from "Musimathics,
# volume 1", pp. 45-46. MIDI conversion probably from wikipedia.

package Music::Scala;

use 5.010000;
use strict;
use warnings;

use Carp qw/croak/;
use File::Basename qw/basename/;
use Moo;
use namespace::clean;
use Scalar::Util qw/looks_like_number reftype/;

our $VERSION = '1.06';

##############################################################################
#
# ATTRIBUTES
#
# NOTE that much of the Moo setup (getters/setters, how "notes" handled,
# etc) is to preserve compatibility with how the code worked pre-Moo.
# Additional hilarity stemmed from (the mistake of?) offering multiple
# methods to get/set the same data in different guises (notes (as cents
# or ratios), (notes as) cents, (notes as) ratios).

has binmode => (
    is        => 'rw',
    predicate => 1,               # has_binmode
    reader    => 'get_binmode',
    writer    => 'set_binmode',
);

has concertfreq => (
    is      => 'rw',
    default => sub { 440 },
    isa     => sub {
        die 'frequency must be a positive number (Hz)'
          if !defined $_[0]
          or !looks_like_number $_[0]
          or $_[0] <= 0;
    },
    reader => 'get_concertfreq',
    writer => 'set_concertfreq',
);

has concertpitch => (
    is      => 'rw',
    default => sub { 69 },
    isa     => sub {
        die 'pitch must be a positive number'
          if !defined $_[0]
          or !looks_like_number $_[0]
          or $_[0] <= 0;
    },
    reader => 'get_concertpitch',
    writer => 'set_concertpitch',
);

has description => (
    is      => 'rw',
    default => sub { '' },
    isa     => sub {
        die 'description must be string value'
          if !defined $_[0]
          or defined reftype $_[0];
    },
    reader => 'get_description',
    writer => 'set_description',
);

# Sanity on scala scale file reads; other prudent limits with untrusted
# input would be to check the file size, and perhaps to bail if the note
# count is some absurd value.
has MAX_LINES => (
    is      => 'rw',
    default => sub { 3000 },
);

has notes => (
    is        => 'rw',
    clearer   => 1,
    predicate => 1,      # has_notes
);

##############################################################################
#
# METHODS

sub BUILD {
    my ($self, $param) = @_;

    if (exists $param->{file} and exists $param->{fh}) {
        die "new accepts only one of the 'file' or 'fh' arguments\n";
    }

    if (exists $param->{file}) {
        $self->read_scala(file => $param->{file});
    } elsif (exists $param->{fh}) {
        $self->read_scala(fh => $param->{fh});
    }
}

# Absolute interval list to relative (1 2 3 -> 1 1 1)
sub abs2rel {
    my $self = shift;
    return if !@_;
    my @result = $_[0];
    if (@_ > 1) {
        for my $i (1 .. $#_) {
            push @result, $_[$i] - $_[ $i - 1 ];
        }
    }
    return @result;
}

sub cents2ratio {
    my ($self, $cents, $precision) = @_;
    croak 'cents must be a number' if !looks_like_number $cents;
    if (defined $precision) {
        croak 'precision must be a positive integer'
          if !looks_like_number $precision or $precision < 0;
        $precision = int $precision;
    } else {
        $precision = 2;
    }

    return sprintf "%.*f", $precision, 10**($cents / 3986.31371386484);
}

# MIDI calculation, for easy comparison to scala results
sub freq2pitch {
    my ($self, $freq) = @_;
    croak 'frequency must be a positive number'
      if !looks_like_number $freq
      or $freq <= 0;

    # no precision, as assume pitch numbers are integers
    return sprintf '%.0f',
      $self->get_concertpitch +
      12 * (log($freq / $self->get_concertfreq) / 0.693147180559945);
}

sub get_cents {
    my ($self) = @_;
    croak 'no scala loaded' if !$self->has_notes;
    return $self->notes2cents(@{ $self->notes });
}

sub get_notes {
    my ($self) = @_;
    croak 'no scala loaded' if !$self->has_notes;
    return @{ $self->notes };
}

sub get_ratios {
    my ($self) = @_;
    croak 'no scala loaded' if !$self->has_notes;
    return $self->notes2ratios(@{ $self->notes });
}

sub interval2freq {
    my $self = shift;
    croak 'no scala loaded' if !$self->has_notes;

    my @ratios = $self->notes2ratios(@{ $self->notes });

    my @freqs;
    for my $i (ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_) {
        if ($i == 0) {    # special case for unison (ratio 1/1)
            push @freqs, $self->get_concertfreq;
        } else {
            my $is_dsc = $i < 0 ? 1 : 0;

            # for non-"octave" portion, if any
            my $offset = $i % @ratios;

            # "Octave" portion, if any - how many times the interval
            # passes through the complete scale
            my $octave_freq  = 0;
            my $octave_count = abs int $i / @ratios;

            # if non-octave on a negative interval, go one octave past
            # the target, then use the regular ascending logic to
            # backtrack to the proper frequency
            $octave_count++ if $is_dsc and $offset != 0;

            if ($octave_count > 0) {
                my $octaves_ratio = $ratios[-1]**$octave_count;
                $octaves_ratio = 1 / $octaves_ratio if $is_dsc;
                $octave_freq   = $self->get_concertfreq * $octaves_ratio;
            }

            my $remainder_freq = 0;
            if ($offset != 0) {
                $remainder_freq =
                  ($octave_freq || $self->get_concertfreq) * $ratios[ $offset - 1 ];

                # zero as remainder is based from $octave_freq, if
                # relevant, so already includes such
                $octave_freq = 0;
            }

            push @freqs, $octave_freq + $remainder_freq;
        }
    }

    return @freqs;
}

sub is_octavish {
    my $self = shift;
    croak 'no scala loaded' if !$self->has_notes;

    my @ratios = $self->notes2ratios(@{ $self->notes });

    # not octave bounded (double the frequency, e.g. 440 to 880)
    return 0 if $ratios[-1] != 2;

    my $min;
    for my $r (@ratios) {
        # don't know how to handle negative ratios
        return 0 if $r < 0;

        # multiple scales within the same definition file (probably for
        # instruments that have two different scales in the same
        # frequency domain) - but don't know how to handle these
        return 0 if defined $min and $r <= $min;

        $min = $r;
    }

    return 1;
}

sub notes2cents {
    my $self = shift;

    my @cents;
    for my $n (ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_) {
        if ($n =~ m{([0-9]+)/([1-9][0-9]*)}) {
            push @cents, 1200 * ((log($1 / $2) / 2.30258509299405) / 0.301029995663981);
        } else {
            push @cents, $n;
        }
    }

    return @cents;
}

sub notes2ratios {
    my $self = shift;

    my @ratios;
    for my $n (ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_) {
        if ($n =~ m{([0-9]+)/([1-9][0-9]*)}) {
            push @ratios, $1 / $2;    # ratio, as marked with /
        } else {
            push @ratios, 10**($n / 3986.31371386484);
        }
    }

    return @ratios;
}

# MIDI for comparison, the other way
sub pitch2freq {
    my ($self, $pitch) = @_;
    croak "pitch must be MIDI number"
      if !looks_like_number $pitch
      or $pitch < 0;

    return $self->get_concertfreq * (2**(($pitch - $self->get_concertpitch) / 12));
}

sub ratio2cents {
    my ($self, $ratio, $precision) = @_;
    croak 'ratio must be a number' if !looks_like_number $ratio;
    if (defined $precision) {
        croak 'precision must be a positive integer'
          if !looks_like_number $precision or $precision < 0;
        $precision = int $precision;
    } else {
        $precision = 2;
    }

    return sprintf "%.*f", $precision,
      1200 * ((log($ratio) / 2.30258509299405) / 0.301029995663981);
}

sub read_scala {
    my $self = shift;
    my %param;
    if (@_ == 1) {
        $param{file} = $_[0];
    } else {
        %param = @_;
    }

    my $fh;
    if (exists $param{file}) {
        open($fh, '<', $param{file}) or croak 'open failed: ' . $!;
    } elsif (exists $param{fh}) {
        $fh = $param{fh};
    } else {
        croak 'must specify file or fh parameter to read_scala';
    }
    if (exists $param{binmode}) {
        binmode $fh, $param{binmode} or croak 'binmode failed: ' . $!;
    } elsif ($self->has_binmode) {
        binmode $fh, $self->get_binmode or croak 'binmode failed: ' . $!;
    }

    my (@scala, $line_count);
    while (!eof($fh)) {
        my $line = readline $fh;
        croak 'readline failed: ' . $! unless defined $line;
        croak 'input exceeds MAX_LINES' if ++$line_count >= $self->MAX_LINES;
        next if $line =~ m/^[!]/;    # skip comments

        chomp $line;
        push @scala, $line;

        last if @scala == 2;
    }
    # but as might hit the MAX_LINES or eof() instead check again...
    if (@scala != 2) {
        croak 'missing description or note count lines';
    }

    $self->set_description(shift @scala);
    my $NOTECOUNT;
    if ($scala[-1] =~ m/^\s*([0-9]+)/) {
        $NOTECOUNT = $1;
    } else {
        croak 'could not parse note count';
    }

    my @notes;
    my $cur_note = 1;
    while (!eof($fh)) {
        my $line = readline $fh;
        croak 'readline failed: ' . $! unless defined $line;
        croak 'input exceeds MAX_LINES' if ++$line_count >= $self->MAX_LINES;
        next if $line =~ m/^[!]/;    # skip comments

        # All the scales.zip *.scl files as of 2013-02-19 have digits on
        # both sides of the dot (so there are no ".42" cent values, but
        # the "these are all valid pitch lines" does include a "408." as
        # allowed). Some scale files have negative cents, though that is
        # illegal for ratios. All the ratios are plain numbers (no
        # period), or if they have a slash, it is followed by another
        # number (so no "42/" cases). Checked via various greps on the
        # file contents.
        if ($line =~ m/^\s* ( -?[0-9]+\. [0-9]* ) /x) {
            push @notes, $1;    # cents
        } elsif ($line =~ m{^\s* -[0-9] }x) {
            # specification says these "should give a read error"
            croak 'invalid negative ratio in note list';
        } elsif ($line =~ m{^\s* ( [1-9][0-9]* (?:/[0-9]+)? ) }x) {
            my $ratio = $1;
            $ratio .= '/1' if $ratio !~ m{/};    # implicit qualify of ratios
            push @notes, $ratio;
        } else {
            # Nothing in the spec about non-matching lines, so blow up.
            # However, there are six files in scales.zip that have
            # trailing blank lines, though these blank lines occur only
            # after an appropriate number of note entries. So must exit
            # loop before reading those invalid? lines. (Did mail the
            # author about these, so probably has been rectified.)
            croak 'invalid note specification on line ' . $.;
        }

        last if $cur_note++ >= $NOTECOUNT;
    }
    if (@notes != $NOTECOUNT) {
        croak 'expected ' . $NOTECOUNT . ' notes but got ' . scalar(@notes) . " notes";
    }

    # edge case: remove any 1/1 (zero cents) at head of the list, as
    # this implementation treats that as implicit
    shift @notes if sprintf("%.0f", $self->notes2cents($notes[0])) == 0;

    $self->notes(\@notes);

    return $self;
}

# Relative interval list to absolute (1 1 1 -> 1 2 3)
sub rel2abs {
    my $self = shift;
    return if !@_;
    my @result = $_[0];
    if (@_ > 1) {
        for my $i (1 .. $#_) {
            push @result, $result[-1] + $_[$i];
        }
    }
    return @result;
}

# Given list of frequencies, assume first is root frequency, then
# convert the remainder of the frequencies to cents against that first
# frequency.
sub set_by_frequency {
    my $self  = shift;
    my $freqs = ref $_[0] eq 'ARRAY' ? $_[0] : \@_;
    croak 'need both root and other frequencies' if @$freqs < 2;
    croak 'root frequency must not be zero'      if $freqs->[0] == 0;

    my @notes;
    for my $i (1 .. $#{$freqs}) {
        push @notes,
          1200 *
          ((log($freqs->[$i] / $freqs->[0]) / 2.30258509299405) / 0.301029995663981);
    }

    # edge case: remove any 1/1 (zero cents) at head of the list, as
    # this implementation treats that as implicit
    shift @notes if sprintf("%.0f", $self->notes2cents($notes[0])) == 0;

    $self->notes(\@notes);

    return $self;
}

sub set_notes {
    my $self = shift;
    my @notes;
    for my $n (ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_) {
        if ($n =~ m{^ -?[0-9]+\. (?:[0-9]+)? $}x) {
            push @notes, $n;
        } elsif ($n =~ m{^ [1-9][0-9]* (?:/[0-9]+)? $}x) {
            my $ratio = $n;
            $ratio .= '/1' if $ratio !~ m{/};    # implicit qualify of ratios
            push @notes, $ratio;
        } else {
            croak 'notes must be integer ratios or real numbers';
        }
    }

    # edge case: remove any 1/1 (zero cents) at head of the list, as
    # this implementation treats that as implicit
    shift @notes if sprintf("%.0f", $self->notes2cents($notes[0])) == 0;

    $self->notes(\@notes);
    return $self;
}

sub write_scala {
    my $self = shift;
    croak 'no scala loaded' if !$self->has_notes;

    my %param;
    if (@_ == 1) {
        $param{file} = $_[0];
    } else {
        %param = @_;
    }

    my $fh;
    if (exists $param{file}) {
        open($fh, '>', $param{file}) or croak 'open failed: ' . $!;
    } elsif (exists $param{fh}) {
        $fh = $param{fh};
    } else {
        croak 'must specify file or fh parameter to write_scala';
    }
    if (exists $param{binmode}) {
        binmode $fh, $param{binmode} or croak 'binmode failed: ' . $!;
    } elsif ($self->has_binmode) {
        binmode $fh, $self->get_binmode or croak 'binmode failed: ' . $!;
    }

    my $filename = basename($param{file})
      if exists $param{file};
    my $note_count = @{ $self->notes } || 0;

    say $fh defined $filename
      ? "! $filename"
      : '!';
    say $fh '!';
    say $fh $self->get_description;
    say $fh ' ', $note_count;
    say $fh '!';    # conventional comment between note count and notes

    for my $note (@{ $self->notes }) {
        say $fh ' ', $note;
    }

    return $self;
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Music::Scala - Scala scale support for Perl

=head1 SYNOPSIS

  use Music::Scala ();
  my $scala = Music::Scala->new;

  $scala->set_binmode(':encoding(iso-8859-1):crlf');
  $scala->read_scala('groenewald_bach.scl');

  $scala->get_description;   # "Jurgen Gronewald, si..."
  $scala->get_notes;         # (256/243, 189.25008, ...)
  $scala->get_cents;
  $scala->get_ratios;

  # which interval is what frequency given the loaded scala data
  # and the given concert frequency (A440 if not changed)
  $scala->set_concertfreq(422.5);
  $scala->interval2freq(0, 1); # (422.5, 445.1)

  $scala->set_description('Heavenly Chimes');
  # by ratio; these are strings that get parsed internally
  $scala->set_notes(qw{ 32/29 1/2 16/29 });
  $scala->write_scala('chimes.scl');

  # or by cents -- mark well the quoting on 1200; Perl will map
  # things like a bare 1200.000 to '1200' which then becomes the
  # ratio 1200/1 which is wrong.
  $scala->set_notes(250.9, 483.3, 715.6, 951.1, '1200.0');

  # utility MIDI equal temperament algorithms
  $scala->pitch2freq(69);
  $scala->freq2pitch(440);

This list is incomplete. See also the C<eg/> and C<t/> directories of
the distribution of this module for example code.

=head1 DESCRIPTION

Scala scale support for Perl: reading, writing, setting, and interval to
frequency conversion methods are provided. The L</"SEE ALSO"> section
links to the developer pages for the original specification, along with
an archive of scala files that define various tunings and temperaments.

=head2 SEVERAL WORDS REGARDING FLOATING POINT NUMBERS

Frequencies derived from scala scale calculations will likely need to be
rounded due to floating point number representation limitations:

  # octave, plus default concert pitch of 440, so expect 880
  my $scala = Music::Scala->new->set_notes('1200.000');

  $scala->interval2freq(1);   # 879.999999999999        (maybe)

  sprintf "%.*f", 0, $scala->interval2freq(1);   # 880  (for sure)

For more information, see:

L<http://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html> "What
Every Computer Scientist Should Know About Floating-Point Arithmetic".
David Goldberg, Computing Surveys, March 1991.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</"ATTRIBUTES"> as well as
optionally one of the B<file> => I<filename> or B<fh> => I<filehandle>
arguments to read a scala scale file from.

  $scala = Music::Scala->new(
    binmode => ':encoding(iso-8859-1):crlf',
    file    => 'foo.scl',
  );

=head1 ATTRIBUTES

Moo attributes via C<has> statements. These may throw exceptions if bad
data is passed (negative frequencies or the like). The sporadic use of
B<get_*> and B<set_*> accessors is due to compatibility with older
versions of this module. These may also be specified to B<new>:

  # equivalent ways to do the same thing
  $scala = Music::Scala->new( concertfreq => 443 );
  $scala->set_concertfreq(443);

=over 4

=item B<binmode>

Holds the default C<binmode> layer used in the B<read_scala> and
B<write_scala> methods (unless a custom I<binmode> argument is passed to
those calls). The scala scale files from C<www.huygens-fokker.org> tend
to be in the ISO 8859-1 encoding, mostly for the description and other
such metadata fields. Note that Perl on Windows systems tends to turn on
C<:crlf>. For scala scale files, it probably should be specified,
regardless of the operating system. Therefore, a reasonable default to
set might be:

  $scala->set_binmode(':encoding(iso-8859-1):crlf');

Though this module does nothing by default for encoding.

=item B<concertfreq>

The concert frequency. C<440> (Hz) is the default. Use
B<get_concertfreq> or B<set_concertfreq> to obtain or change it.

=item B<concertpitch>

Holds the MIDI pitch number that the I<concertfreq> maps to.
C<69> by default (as that is the MIDI number of A440).

=item B<description>

Holds the description of the scala data. This will be the empty string
if no description was read or set prior.

=item B<MAX_LINES>

Gets or sets the maximum lines to allow in an input scala scale file,
C<3000> by default.

=item B<notes>

Gets or sets the notes from the scala scale data loaded, if any. Mostly
for internal use; the B<get_cents>, B<get_notes>, or B<get_ratios>
methods are likely better means to access this information, and the
B<read_scala>, B<set_by_frequency>, or B<set_notes> methods better ways
to set it.

=back

=head1 METHODS

Methods will throw exceptions under various conditions, mostly related
to bad input or scala scale data not being loaded.

=over 4

=item B<abs2rel> I<interval-list>

Takes a list of intervals assumed to be absolute (which is the format
the scala scale files are in) and returns the relative delta between
those intervals as a list.

=item B<cents2ratio> I<cents>, [ I<precision> ]

Converts a value in cents (e.g. C<1200>) to a ratio (e.g. C<2>). An
optional precision for C<sprintf> can be supplied; the default precision
is C<2>. There are C<1200> cents in an octave (a doubling of the
frequency).

=item B<freq2pitch> I<frequency>

Converts the passed frequency (Hz) to the corresponding MIDI pitch
number using the MIDI algorithm, as influenced by the B<concertfreq>
attribute. Unrelated to scala, but handy for comparison with results
from B<interval2freq>.

This method *is not* influenced by the scala scale data, and always uses
equal temperament. See also B<pitch2freq>.

=item B<get_binmode>

Returns the current value of the B<binmode> attribute.

=item B<get_cents>

Returns, as a list, the "notes" of the scala scale data, except
converted to cents ("notes" may either be ratios or values in
cents; this method ensures that they are all represented in cents).
Throws an exception if the notes have not been set by some previous
method call (one of the B<read_scala>, B<set_by_frequency>, or
B<set_notes> methods).

=item B<get_concertfreq>

Returns the current concert frequency (440 Hz by default).

=item B<get_concertpitch>

Returns the current concert pitch (69 by default, MIDI number).

=item B<get_description>

Returns the description of the scala scale data, if any.

=item B<get_notes>

Returns, as a list, the "notes" of the scala, but throws an exception if
this field has not been set by some previous method. The notes are
either real numbers (representing values in cents, or 1/1200 of an
octave (these may be rarely be negative)) or otherwise integer ratios
(e.g. C<3/2> or C<2> (these may not be negative)).

  $scala->read_scala(file => $some_file);
  my @notes = $scala->get_notes;
  if (@notes == 12) { ...

The implicit C<1/1> for unison is not contained in the list of
notes; the first element is for the 2nd degree of the scale (e.g.
the minor second of a 12-tone scale). Other implementations may
differ in this regard.

=item B<get_ratios>

Returns, as a list, the "notes" of the scala, except converted to ratios
("notes" may either be ratios or values in cents; this method ensures
that these values are returned as ratios). Throws an exception if the
notes have not been set by some previous method call.

=item B<interval2freq> I<intervals ...>

Converts a list of passed interval numbers (as a list or a single array
reference) to frequencies (in Hz) that are returned as a list. Interval
numbers are integers, C<0> for unison (the B<concertfreq>), C<1> for the
first interval (which would be a "minor 2nd" for a 12-note scale, but
something different for scales of different composition), and so on up
to the "octave." Negative intervals take the frequency in the other
direction, e.g. C<-1> for what in a 12-note system would be a minor 2nd
downwards. Intervals past the "octave" consist of however many "octaves"
are present in the scale, plus whatever remainder lies inside that
"octave," if any. "octave" uses scare quotes due to 13% of the scala
archive consisting of non-octave bounded scales; that is, scales that do
not repeat themselves when the frequency is doubled (see the
B<is_octavish> method for a test for that condition).

Conversions are based on the I<concertfreq> setting, which is 440Hz by
default. Use B<set_concertfreq> method to adjust this. An example that
derives the frequencies of C4 through B4 using the equal temperament
tuning file from the scala scale file archive:

  $scala->read_scala('equal.scl');
  $scala->set_concertfreq(261.63);
  my @freqs = map { sprintf '%.2f', $_ } 
    $scala->interval2freq(qw/0 1 2 3 4 5 6 7 8 9 10 11/);

Some scala files note what this value should be in the comments or
description, or it may vary based on the needs of the software or
instruments involved.

There is no error checking for nonsense conditions: an interval of a
15th makes no sense for a xylophone with only 10 keys in total. Audit
the contents of the scala scale file to learn what its limits are or
screen for appropriate scales depending on the application.

=item B<is_octavish>

Returns true if the scala scale has an ultimate ratio of 2:1, as well as
no negative or repeated ratios; false otherwise. Throws an exception if
no scala scale is loaded.

=item B<notes2cents> I<notes ...>

Given a list of notes, returns a list of corresponding cents. Used
internally by the B<get_cents> method.

=item B<notes2ratios> I<notes ...>

Given a list of notes, returns a list of corresponding ratios. Used
internally by the B<get_ratios> and B<interval2freq> methods.

=item B<pitch2freq> I<MIDI_pitch_number>

Converts the given MIDI pitch number to a frequency using the MIDI
conversion algorithm, as influenced by the I<concertfreq> setting.

This method *is not* influenced by the scala scale data, and always uses
equal temperament. See also B<freq2pitch>.

=item B<ratio2cents> I<ratio>, [ I<precision> ]

Converts a ratio (e.g. C<2>) to a value in cents (e.g. C<1200>). An
optional precision for C<sprintf> can be supplied; the default
precision is C<2>.

=item B<read_scala> I<filename>

Parses a scala file. Will throw some kind of exception if anything at
all is wrong with the input. Use the appropriate C<get_*> methods to
obtain the scala data thus parsed. Comments in the input file are
ignored, so anything subsequently written using B<write_scala> will lack
those. All ratios are made implicit by this method; that is, a C<2>
would be qualified as C<2/1>.

As an alternative, accepts also I<file> or I<fh> hash keys, along with
I<binmode> as in the B<new> method:

  $scala->read_scala('somefile');
  $scala->read_scala( file => 'file.scl', binmode => ':crlf' );
  $scala->read_scala( fh   => $input_fh );

=item B<rel2abs> I<interval-list>

Takes a list of relative intervals and returns a list of absolute
intervals. Scala scale files use absolute intervals.

=item B<set_binmode> I<layer>

Sets the current value of the B<bindmode> attribute.

=item B<set_by_frequency> I<root_frequency>, I<frequencies...>

Given a root frequency as the first argument, performs the equivalent of
B<set_notes> except that it creates the intervals on the fly based on
the I<root_frequency> supplied. Handy if you have a list of frequencies,
and need those converted to cents or ratios.

=item B<set_concertfreq> I<frequency>

Set the concert frequency.

=item B<set_concertpitch> I<midi-number>

Set the concert pitch.

=item B<set_description> I<string>

Set the description of the scala scale data.

=item B<set_notes> I<array_or_array_ref>

Sets the notes. Can either be an array, or an array reference,
ideally containing values in ratios or cents as per the Scala scale
file specification, as an exception will be thrown if these ideals
are not met.

NOTE cents with no value past the decimal must be quoted in code, as
otherwise Perl converts the value to C<1200> which the code then
turns into the integer ratio C<1200/1> instead of what should be
C<2/1>. B<read_scala> does not suffer this problem, as it is looking
for the literal dot, and that is a different code path than what
happens for ratios.

  $scala->set_notes(250.9, 483.3, 715.6, 951.1, '1200.0');

=item B<write_scala> I<filename>

Writes a scala file. Will throw some kind of exception if anything at
all is wrong, such as not having scala data loaded in the object. Like
B<read_scala> alternatively accepts I<file> or I<fh> hash keys, along
with a I<binmode> option to set the output encoding.

  $scala->write_scala('out.scl');
  $scala->write_scala( file => 'out.scl', binmode => ':crlf' );
  $scala->write_scala( fh => $output_fh );

Data will likely not be written until the I<fh> passed is closed. If
this seems surprising, see L<http://perl.plover.com/FAQs/Buffering.html>
to learn why it is not.

=back

=head1 EXAMPLES

Check the C<eg/> and C<t/> directories of the distribution of this
module for example code.

=head1 BUGS

=head2 Reporting Bugs

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

L<http://github.com/thrig/Music-Scala>

=head2 Known Issues

Negative cents are likely not handled well, or at all. The specification
frowns on negative ratios, but does allow for negative cents, so
converting such negative cents to ratios (which do not support negative
values) might yield unexpected or wrong results. Only 0.36% of the scala
scale archive file scales contain negative cents.

=head1 SEE ALSO

L<http://www.huygens-fokker.org/scala/> by Manuel Op de Coul, and in
particular the scala archive L<http://www.huygens-fokker.org/docs/scales.zip>
which contains many different scales to play around with.

Scales, tunings, and temperament would be good music theory topics to
read up on, e.g. chapters in "Musicmathics, volume 1" by Gareth Loy,
among other in-depth treatments stemming from the no few centuries of
development behind music theory.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
