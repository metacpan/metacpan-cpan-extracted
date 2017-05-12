package Term::TtyRec::Plus;
use warnings;
use strict;
use Carp qw/croak/;
use IO::Uncompress::Bunzip2 qw($Bunzip2Error);

our $VERSION = '0.09';

sub new {
    my $class = shift;

    my $self = {
        # options
        infile              => "-",
        filehandle          => undef,
        bzip2               => undef,
        time_threshold      => undef,
        frame_filter        => sub { @_ },

        # state
        frame               => 0,
        prev_timestamp      => undef,
        accum_diff          => 0,
        relative_time       => 0,

        # allow overriding of options *and* state
        @_,
    };

    $self->{initial_state} = {
        map { $_ => $self->{$_} }
        qw/frame prev_timestamp accum_diff relative_time/
    };

    bless $self, $class;

    if (defined($self->{filehandle})) {
        undef $self->{infile};
    }
    else {
        if (!defined($self->{infile}) || $self->{infile} eq '-') {
            $self->{filehandle} = *STDIN;
        }
        else {
            open($self->{filehandle}, '<', $self->{infile})
                or croak "Unable to open '$self->{infile}' for reading: $!";
        }
    }

    # If the caller tells us explicitly what to do, we honor that.
    # Otherwise use bzip2 if and only if the filename ends in .bz2.
    $self->{bzip2} = defined($self->{infile}) && $self->{infile} =~ /\.bz2$/
        unless defined $self->{bzip2};

    $self->{bzip2} = not not $self->{bzip2}; # force 0 or 1

    if ($self->{bzip2}) {
        my $bz2_handle = IO::Uncompress::Bunzip2->new(
            $self->{filehandle}
        ) or die "bunzip2 failed: $Bunzip2Error\n";
        $self->{filehandle} = $bz2_handle;
    }

    croak "Cannot have a negative time threshold"
        if defined($self->{time_threshold}) && $self->{time_threshold} < 0;

    return $self;
}

sub next_frame {
    my $self = shift;
    $self->{frame}++;

    my $hgot = read $self->{filehandle}, my $hdr, 12;

    # clean EOF
    return if $hgot == 0;

    croak "Expected 12-byte header, got $hgot in frame $self->{frame}"
        if $hgot != 12;

    my @hdr = unpack "VVV", $hdr;

    my $orig_timestamp = $hdr[0] + $hdr[1] / 1_000_000;
    my $diffed_timestamp = $orig_timestamp + $self->{accum_diff};
    my $timestamp = $diffed_timestamp;
    my $old_timestamp = $timestamp; # old = pre-filter
    my $prev_timestamp = $self->{prev_timestamp};

    # apply a threshold, if applicable
    if (defined($self->{time_threshold}) &&
        defined($prev_timestamp) &&
        $timestamp - $prev_timestamp > $self->{time_threshold})
    {
        $timestamp = $prev_timestamp + $self->{time_threshold};
        $self->{accum_diff} += $timestamp - $old_timestamp;
        $old_timestamp = $timestamp;
    }

    my $dgot = read $self->{filehandle}, my ($data), $hdr[2];

    croak "Expected $hdr[2]-byte frame, got $dgot in frame $self->{frame}"
        if $dgot != $hdr[2];

    $self->{frame_filter}(\$data, \$timestamp, \$self->{prev_timestamp});

    $self->{prev_timestamp} = $timestamp;

    my $diff = defined($prev_timestamp) ? $timestamp - $prev_timestamp : 0;

    $self->{relative_time} += $diff
        unless $self->{frame} == 1;

    $self->{accum_diff} += $timestamp - $old_timestamp;

    # rebuild header
    $hdr[0] = int($timestamp);
    $hdr[1] = int(1_000_000 * ($timestamp - $hdr[0]));
    $hdr[2] = length($data);

    my $newhdr =   pack "VVV", @hdr;

    # test if header is kosher
    my @newhdr = unpack "VVV", $newhdr;

    croak "Unable to create a new header, seconds portion of timestamp in frame $self->{frame}: want to write $hdr[0], can only write $newhdr[0]"
        if $hdr[0] != $newhdr[0];

    croak "Unable to create a new header, microseconds portion of timestamp in frame $self->{frame}: want to write $hdr[1], can only write $newhdr[1]"
        if $hdr[1] != $newhdr[1];

    croak "Unable to create a new header, frame length in frame $self->{frame}: want to write $hdr[2], can only write $newhdr[2]"
        if $hdr[2] != $newhdr[2];

    return {
        data             => $data,
        orig_timestamp   => $orig_timestamp,
        diffed_timestamp => $diffed_timestamp,
        timestamp        => $timestamp,
        prev_timestamp   => $prev_timestamp,
        diff             => $diff,
        orig_header      => $hdr,
        header           => $newhdr,
        frame            => $self->{frame},
        relative_time    => $self->{relative_time},
    };
}

sub grep {
    my $self = shift;
    my @conditions;

    foreach my $arg (@_) {
        if (ref($arg) eq 'CODE') {
            push @conditions, $arg;
        }
        elsif (ref($arg) eq 'Regexp') {
            push @conditions, sub { $_[0]{data} =~ $arg };
        }
        elsif (ref($arg) eq '') {
            push @conditions, sub { index($_[0]{data}, $arg) > -1 }
        }
        else {
            croak "Each of grep()'s arguments must be a subroutine, regular expression, or string; you passed a " . ref($arg);
        }
    }

    FRAME:
    while (my $frame_ref = $self->next_frame()) {
        CONDITION:
        foreach (@conditions) {
            next FRAME if not $_->($frame_ref);
        }
        return $frame_ref;
    }

    # no matching frames!
    return;
}

sub rewind {
    my $self = shift;

    while (my ($k, $v) = each %{$self->{initial_state}}) {
        $self->{$k} = $v;
    }

    seek $self->{filehandle}, 0, 0
        or croak "Unable to seek on filehandle";
}

sub infile {
    $_[0]->{infile};
}

sub filehandle {
    $_[0]->{filehandle};
}

sub bzip2 {
    $_[0]->{bzip2};
}

sub time_threshold {
    $_[0]->{time_threshold};
}

sub frame_filter {
    $_[0]->{frame_filter};
}

sub frame {
    $_[0]->{frame};
}

sub prev_timestamp {
    $_[0]->{prev_timestamp};
}

sub relative_time {
    $_[0]->{relative_time};
}

sub accum_diff {
    $_[0]->{accum_diff};
}

1;

__END__

=head1 NAME

Term::TtyRec::Plus - read a ttyrec

=head1 SYNOPSIS

C<Term::TtyRec::Plus> is a module that lets you read ttyrec files. The related module, L<Term::TtyRec|Term::TtyRec> is designed more for simple interactions. C<Term::TtyRec::Plus> gives you more information and, using a callback, lets you munge the data block and timestamp. It will do all the subtle work of making sure timing is kept consistent, and of rebuilding each frame header.

    use Term::TtyRec::Plus;
    # complete (but simple) ttyrec playback script

    foreach my $file (@ARGV) {
      my $ttyrec = Term::TtyRec::Plus->new(infile => $file, time_threshold => 10);
      while (my $frame_ref = $ttyrec->next_frame()) {
        select undef, undef, undef, $frame_ref->{diff};
        print $frame_ref->{data};
      }
    }

=head1 CONSTRUCTOR AND STARTUP

=head2 new()

Creates and returns a new C<Term::TtyRec::Plus> object.

    my $ttyrec = Term::TtyRec::Plus->new();

=head3 Parameters

Here are the parameters that C<< Term::TtyRec::Plus->new() >> recognizes.

=over 4

=item infile

The input filename. A value of C<"-">, which is the default, or C<undef>, means C<STDIN>.

=item filehandle

The input filehandle. By default this is C<undef>; if you have already opened the ttyrec then you can pass its filehandle to the constructor. If both filehandle and infile are defined, filehandle is used.

=item bzip2

Perform bzip2 decompression. By default this is C<undef>, which signals that bzip2 decompression should occur if and only if the filename is available and it ends in ".bz2". Otherwise, you can force or forbid decompression by setting bzip2 to a true or false value, respectively. After the call to new, this field will be set to either 1 if decompression is enabled or 0 if it is not.

=item time_threshold

The maximum difference between two frames, in seconds. If C<undef>, which is the default, there is no enforced maximum. The second most common value would be C<10>, which some ttyrec utilities (such as timettyrec) use.

=item frame_filter

A callback, run for each frame before returning the frame to the user of C<Term::TtyRec::Plus>. This callback receives three arguments: the frame text, the timestamp, and the timestamp of the previous frame. All three arguments are passed as scalar references. The previous frame's timestamp is C<undef> for the first frame. The return value is not currently looked at. If you modify the timestamp, the module will make sure that change is noted and respected in further frame timestamps. Modifications to the previous frame's timestamp are currently ignored.

    sub halve_frame_time_and_stumblify {
        my ($data_ref, $time_ref, $prev_ref) = @_;
        $$time_ref = $$prev_ref + ($$time_ref - $$prev_ref) / 2
            if defined $$prev_ref;
        $$data_ref =~ s/Eidolos/Stumbly/g;
    }

=back

=head3 State

In addition to passing arguments, you can modify C<Term::TtyRec::Plus>'s initial state, if you want to. This could be useful if you are chaining multiple ttyrecs together; you could pass a different initial frame. Support for such chaining might be added in a future version.

=over 4

=item frame

The initial frame number. Default C<0>.

=item prev_timestamp

The previous frame's timestamp. Default C<undef>.

=item accum_diff

The accumulated difference of all frames seen so far; see the section on C<diffed_timestamp> in C<next_frame()>'s return value. Default C<0>.

=item relative_time

The time passed since the first frame. Default C<0>.

=back

=head1 METHODS

=head2 next_frame()

C<next_frame()> reads and processes the next frame in the ttyrec. It accepts no arguments. On EOF, it will return C<undef>. On malformed ttyrec input, it will die. If it cannot reconstruct the header of a frame (which might happen if the callback sets the timestamp to -1, for example), it will die. Otherwise, a hash reference is returned with the following fields set.

=over 4

=item data

The frame data, filtered through the callback. The original data block is not made available.

=item orig_timestamp

The frame timestamp, straight out of the file.

=item diffed_timestamp

The frame timestamp, with the accumulated difference of all of the previous frames applied to it. This is so consistent results are given. For example, if your callback adds three seconds to frame 5's timestamp, then frame 6's diffed timestamp will take into account those three seconds, so frame 6 happens three seconds later as well. So the net effect is frame 5 is extended by three seconds, and no other frames' relatives times are affected.

=item timestamp

The diffed timestamp, filtered through the callback.

=item prev_timestamp

The previous frame's timestamp (after diffing and filtering; the originals are not made available).

=item diff

The difference between the current frame's timestamp and the previous frame's timestamp. Yes, it is equivalent to C<timestamp - prev_timestamp>, but it is provided for convenience. On the first frame it will be C<0> (not C<undef>).

=item orig_header

The 12-byte frame header, straight from the file.

=item header

The 12-byte frame header, reconstructed from C<data> and C<timestamp> (so, after filtering, etc.).

=item frame

The frame number, using 1-based indexing.

=item relative_time

The time between the first frame's timestamp and the current frame's timestamp.

=back

=head2 grep()

Returns the next frame that meets the specified criteria. C<grep()> accepts arguments that are subroutines, regex, or strings; anything else is a fatal error. If you pass multiple arguments to C<grep()>, each one must be true. The subroutines receive the frame reference that is returned by C<next_frame()>. You can modify the frame, but do so cautiously.

  my $next_jump_frame_ref = $t->grep("Where do you want to jump?", sub { $_[0]{data} !~ /Message History/});

=head2 rewind()

Rewinds the ttyrec to the first frame and resets state variables to their initial values. Note that if C<filehandle> is not seekable (such as STDIN on some systems, or if bzip2 decompression is used), C<rewind()> will die.

=head2 infile()

Returns the infile passed to the constructor. If a filehandle was passed, this will be C<undef>.

=head2 filehandle()

Returns the filehandle passed to the constructor, or if C<infile> was used, a handle to C<infile>.

=head2 bzip2()

Returns 1 if bzip2 decompression has taken place, 0 if it has not.

=head2 time_threshold()

Returns the time threshold passed to the constructor. By default it is C<undef>.

=head2 frame_filter()

Returns the frame filter callback passed to the constructor. By default it is C<sub { @_ }>.

=head2 frame()

Returns the frame number of the most recently returned frame.

=head2 prev_timestamp()

Returns the timestamp of the most recently returned frame.

=head2 relative_time()

Returns the time so far since the first frame.

=head2 accum_diff()

Returns the total time difference between timestamps and filtered timestamps. C<accum_diff> is added to each frame's timestamp before they are passed to the C<frame_filter> callback.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 CAVEATS

=over 4

=item *

Ttyrecs are frame-based. If you are trying to modify a string that is broken across multiple frames, it will not work. Say you have a ttyrec that prints "foo" in frame one and "bar" in frame two, both with the same timestamp. In a ttyrec player, it might look like these are one frame (with data "foobar"), but it's not. There is no easy, complete way to add arbitrary substitutions; you would have to write (or reuse) a terminal emulator.

=item *

If you modify the data block, weird things could happen. This is especially true of escape-code-littered ttyrecs (such as those of NetHack). For best results, pretend the data block is an executable file; changes are OK as long as you do not change the length of the file. It really depends on the ttyrec though.

=item *

If you modify the timestamp of a frame so that it is not in sequence with other frames, the behavior is undefined (it is up to the client program). C<Term::TtyRec::Plus> will not reorder the frames for you.

=item *

bzip2 support is transparent, mostly. Unfortunately L<IO::Uncompress::Bunzip2|IO::Uncompress::Bunzip2> is rather slow. I took a lengthy (~4 hours), bzipped ttyrec and ran a simple script on it, depending on the built-in bzip2 decompression. This took nearly four minutes. Using bunzip2 then the same script took about four seconds. So when you can, do explicit bzip2 decompression. Or better yet, help out the guys working on IO::Uncompress::Bunzip2. :)

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Shawn M Moore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

