package Music::Lyrics::LRC;

# Force me to write this properly
use strict;
use warnings;
use utf8;

# Target reasonably old Perl
use 5.006;

# Include required modules
use Carp;
use English '-no_match_vars';

# Declare package version
our $VERSION = '0.11';

# Patterns to match elements of the LRC file; these are somewhat tolerant
our %RE = (

    # A blank line
    blank => qr{
        \A      # Start of string
        \s*     # Any whitespace
        \z      # End of string
    }msx,

    # A meta tag line
    tag => qr{
        \A          # Start of string
        \s*         # Any whitespace
        \[          # Opening left bracket
            ([^:\r\n]+)  # Tag name, capture
            :            # Colon
            (.*)         # Tag value, capture
        \]          # Closing right bracket
        \s*         # Any whitespace
        \z          # End of string
    }msx,

    # A lyric line
    lyric => qr{
        \A            # Start of string
        \s*           # Any whitespace
        \[            # Opening left bracket
            (\d+)         # Minutes, capture
            :             # Colon
            (             # Seconds group, capture
                \d{1,2}       # Whole seconds
                (?:           # Group for fractional seconds
                    [.]           # Period
                    \d+           # At least one digit
                )?            # End optional fractional seconds group
            )             # End seconds group
        \]            # Closing right bracket
        [\t ]*        # Any tabs or spaces
        (             # Lyric line group, capture
            (?:.*\S)?     # Anything ending with non-whitespace
        )             # End lyric line group
        \s*           # Any whitespace
        \z            # End of string
    }msx,
);

# Parser functions to consume and process captures from the above patterns
my %parsers = (

    # A meta tag line
    tag => sub {
        my ( $self, $tag, $value ) = @_;
        $self->set_tag( $tag, $value );
    },

    # A lyric line
    lyric => sub {
        my ( $self, $min, $sec, $text ) = @_;

        # Calculate the number of milliseconds
        my $msec = $self->_min_sec_to_msec( $min, $sec );

        # Push a lyric hashref onto our list
        $self->add_lyric( $msec, $text );
    },
);

# Oldschool constructor
sub new {
    my ( $class, %opts ) = @_;

    # Declare a hash to build the object around
    my %self;

    # Start with empty tags and lyrics
    $self{tags}   = {};
    $self{lyrics} = [];

    # Read in the "verbose" flag if defined, default to zero
    $self{verbose} =
      exists $opts{verbose}
      ? !!$opts{verbose}
      : 0;

    # Perlician, bless thyself
    return bless \%self, $class;
}

# Read-only accessor for lyrics, sorted by time
sub lyrics {
    my $self = shift;
    my @lyrics = sort { $a->{time} <=> $b->{time} } @{ $self->{lyrics} };
    return \@lyrics;
}

# Read-only accessor for tags
sub tags {
    my $self = shift;
    my %tags = %{ $self->{tags} };
    return \%tags;
}

# Add a new lyric to the object
sub add_lyric {
    my ( $self, $time, $text ) = @_;

    # Check parameters
    int $time >= 0
      or croak 'Bad lyric time';
    $text !~ m/ [\r\n] /msx
      or croak 'Bad lyric line';

    # Push the lyric onto our list
    return push @{ $self->{lyrics} },
      {
        time => $time,
        text => $text,
      };
}

# Set the value of a tag
sub set_tag {
    my ( $self, $name, $value ) = @_;

    # Check parameters
    $name !~ m/ [:\r\n] /msx
      or croak 'Bad tag name';

    # Tag content cannot have vertical whitespace
    $value !~ m/ [\r\n] /msx
      or croak 'Bad tag value';

    # Set the tag's value on our hash
    return ( $self->{tags}{$name} = $value );
}

# Unset a tag
sub unset_tag {
    my ( $self, $name ) = @_;

    # Check parameters
    $name !~ m/ [:\r\n] /msx
      or croak 'Bad tag name';
    exists $self->{tags}{$name}
      or carp 'Tag not set';

    # Delete the tag's value
    return defined delete $self->{tags}{$name};
}

# Parse an LRC file from a given filehandle
sub load {
    my ( $self, $fh ) = @_;

    # Panic if this doesn't look like a filehandle
    ref $fh eq 'GLOB'
      or croak 'Not a filehandle';

    # Iterate through lines
  LINE: while ( my $line = <$fh> ) {

        # Iterate through line types until one matches
      TYPE: for my $type (qw(lyric tag blank)) {
            my @vals = $line =~ $RE{$type}
              or next TYPE;
            exists $parsers{$type}
              or next LINE;
            $parsers{$type}->( $self, @vals );
            next LINE;
        }

        # No line format match, warn if verbose
        warn "Unknown format for line $NR\n" if $self->{verbose};
    }

    # Check we got to the end of the file
    eof $fh or die "Failed file read: $ERRNO\n";

    # All done, return the number of lyrics we have now
    return scalar @{ $self->lyrics };
}

# Write an LRC file to a given filehandle
sub save {
    my ( $self, $fh ) = @_;

    # Panic if this doesn't look like a filehandle
    ref $fh eq 'GLOB'
      or croak 'Not a filehandle';

    # Start counting lines written
    my $lines = 0;

    # Iterate through tags
    for my $name ( sort keys %{ $self->{tags} } ) {
        my $value = $self->{tags}{$name};
        $lines += printf {$fh} "[%s:%s]\n", $name, $value
          or die "Failed tag write: $ERRNO\n";
    }

    # Iterate through lyrics (sorted by time)
    for my $lyric ( @{ $self->lyrics } ) {

        # Convert milliseconds to timestamp hash
        my $msec = $lyric->{time};
        my ( $min, $sec ) = $self->_msec_to_min_sec($msec);

        # Write the line to the file, counting the lines
        $lines += printf {$fh} "[%02u:%05.2f]%s\n", $min, $sec, $lyric->{text}
          or die "Failed lyric write: $ERRNO\n";
    }

    # Return the number of lines written
    return $lines;
}

# Named constants for the conversion functions
# This stands for "millisecond factors"
my %MSF = (
    sec => 1_000,
    min => 60_000,
);

# Convert a minutes-seconds pair to milliseconds
sub _min_sec_to_msec {
    my ( $self, $min, $sec ) = @_;
    my $msec = 0;
    $msec += int $min * $MSF{min};
    $msec += $sec * $MSF{sec};
    return $msec;
}

# Convert milliseconds to a minutes-seconds pair
sub _msec_to_min_sec {
    my ( $self, $msec ) = @_;
    my $min = int $msec / $MSF{min};
    my $sec = ( int $msec ) % $MSF{min} / $MSF{sec};
    return ( $min, $sec );
}

1;

__END__

=pod

=for stopwords
LRC tradename licensable MERCHANTABILITY arrayref hashrefs hashref filehandle
writeable whitespace

=head1 NAME

Music::Lyrics::LRC - Manipulate LRC karaoke timed lyrics files

=head1 VERSION

Version 0.11

=head1 DESCRIPTION

Read, write, and do simple manipulations of the LRC lyrics files used for some
karaoke devices.

For details on the LRC file format, please see Wikipedia:

L<https://en.wikipedia.org/wiki/LRC_(file_format)>

=head1 SYNOPSIS

    use Music::Lyrics::LRC;
    ...
    my $lrc = Music::Lyrics::LRC->new();
    open my $rfh, '<', 'mylyrics.lrc';
    $lrc->load($rfh);
    ...
    my $lyrics = $lrc->lyrics();  # arrayref of hashrefs: time (msec), text
    my $tags = $lrc->tags();  # hashref, name => value
    ...
    $lrc->add_lyric(5500, q(Now I'm singin' at exactly 5.5 seconds...));
    $lrc->set_tag('author', 'Justin A. Perlhacker');
    $lrc->unset_tag('author');
    ...
    open my $wfh, '>', 'savelyrics.lrc';
    $lrc->save($wfh);

=head1 SUBROUTINES/METHODS

=head2 C<new(%opts)>

Constructor method. Accepts a hash with one attribute C<verbose>. This
specifies whether the module will C<warn> explicitly when it cannot parse an
input line from a file. It defaults to 0.

    my $lrc = MRC::Lyrics::LRC->new();
    ...
    my $lrc_verbose = MRC::Lyrics::LRC->new(verbose => 1);
    ...

=head2 C<lyrics()>

Retrieve an arrayref of hashrefs representing lyric lines, sorted by time
ascending. Each one has C<time> and C<text> keys. The time is in milliseconds.

    [
        {
            time => 5500,
            text => 'Now I\'m singin\' at exactly 5.5 seconds...',
        },
        {
            time => 6001,
            text => 'And now a moment after the sixth...',
        },
    ...
    ]

=head2 C<tags()>

Retrieve a hashref of tag names to tag values for this lyrics file.

    {
        ar => 'Justin A. Perlhacker',
        ti => 'Perl timekeeping blues',
        ...
    }

=head2 C<add_lyric($time, $text)>

Add a lyric at the given non-negative time in milliseconds and with the given
text. The text must not include newlines or carriage returns.

=head2 C<set_tag($name, $value)>

Set a tag with the given name and value. The name must be at least one
character and cannot have colons. Neither the name nor the value can include
newlines or carriage returns.

=head2 C<unset_tag($name)>

Clear a tag with the given name. Raises a warning if the tag has not been set.

=head2 C<load($fh)>

Load lyrics from the given readable filehandle.

=head2 C<save($fh)>

Save lyrics to the given writeable filehandle.

=head1 DIAGNOSTICS

=over 4

=item C<Bad lyric time>

A lyric could not be added with the given time. It may have been negative.

=item C<Bad lyric line>

The line you tried to add had illegal characters in it, probably a carriage
return or a newline.

=item C<Bad tag name>

The tag you tried to set had an illegal name. It needs to be at least one
character, and can't include colons or whitespace.

=item C<Bad tag value>

You tried to set a tag to an illegal value. The value probably had a carriage
return or a newline in it.

=item C<Tag not set>

You tried to clear a tag that had not already been set.

=item C<Unknown format for line %s>

The parser ran across a line in the LRC file that it could not understand. It
tolerates blank lines, tags, and lyric lines, and doesn't know anything else.

=item C<Failed file read: %s>

The file read failed with the given system error.

=item C<Not a filehandle>

You passed C<load()> or C<save()> something that wasn't a filehandle.

=item C<Failed tag write: %s>

An attempt to write a tag to the output filehandle in C<save()> failed with the
given system error.

=item C<Failed lyric write: %s>

An attempt to write a lyric timestamp and line to the output filehandle in
C<save()> failed with the given system error.

=back

=head1 CONFIGURATION AND ENVIRONMENT

You'll need to make sure that you're passing in a filehandle with the
appropriate I/O layers you want, especially encoding.

=head1 DEPENDENCIES

=over 4

=item *

Perl 5.6 or newer

=item *

L<Carp|Carp>

=item *

L<English|English>

=back

=head1 INCOMPATIBILITIES

This module does not support any "extended" or "enhanced" LRC format; in
particular, at the time of writing it can't handle per-word times syntax. This
may change in future revisions.

=head1 BUGS AND LIMITATIONS

The format accepted here is very liberal, and needs to be tested with lots of
different LRC files from the wild.

Fractional seconds of any length can be parsed, and preserved in the
millisecond count return by C<lyrics()>, but any resolution beyond 2 decimal
places is lost on C<save()>.

=head1 AUTHOR

Tom Ryder C<< <tom@sanctum.geek.nz> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Tom Ryder

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License. By using, modifying or distributing the
Package, you accept this license. Do not use, modify, or distribute the
Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by
someone other than you, you are nevertheless required to ensure that your
Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent
license to make, have made, use, offer to sell, sell, import and otherwise
transfer the Package with respect to any patent claims licensable by the
Copyright Holder that are necessarily infringed by the Package. If you
institute patent litigation (including a cross-claim or counterclaim) against
any party alleging that the Package constitutes direct or contributory patent
infringement, then this Artistic License to you shall terminate on the date
that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW.
UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY
OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

=cut
