package Net::OpenSoundControl;

use 5.006;
use strict;
use warnings;

our @ISA = qw();

our $VERSION            = '0.05';
our $NTP_ADJUSTMENT     = 2208988800;
our $IMMEDIATE_FRACTION = '0' x 31 . '1';

use Config;

# initialize functions

BEGIN {

    # Note: the little endian functions also work on a big endian
    # platform, but they are less efficient.

    if ($Config{byteorder} eq '1234') {
        *toFloat   = *_toFloat_littleEndian;
        *fromFloat = *_fromFloat_littleEndian;
    } elsif ($Config{byteorder} eq '12345678') {
        *toFloat   = *_toFloat_64bit;
        *fromFloat = *_fromFloat_64bit;
    } else {
        *toFloat   = *_toFloat_bigEndian;
        *fromFloat = *_fromFloat_bigEndian;
    }
}

=head1 NAME

Net::OpenSoundControl - OpenSound Control client and server implementation

=head1 SYNOPSIS

See L<Net::OpenSoundControl::Client> and L<Net::OpenSoundControl::Server> for the synopsis.

=head1 DESCRIPTION

    OpenSound Control ("OSC") is a protocol for communication among computers,
    sound synthesizers, and other multimedia devices that is optimized for
    modern networking technology. 

    http://www.cnmat.berkeley.edu/OpenSoundControl

This suite of modules provides an implementation of the protocol in Perl,
according to version 1.0 (March 26, 2002) of the specification. 

To actually create an OSC client or server, take a look at L<Net::OpenSoundControl::Client> and  L<Net::OpenSoundControl::Server>. This module only provides several helper functions. Normally, there shouldn't be a need for you to use this module directly.

Please also see the F<examples/> directory in this distribution, especially if
you are not very familiar with references.

=head1 DATA FORMAT

OSC data is represented in a form closely related to the original binary format.

=head2 MESSAGES

A message is an array reference containing an OSC address followed by zero or more pairs of type identifiers and data. Examples:

    ['/Fader', f, 0.2]

    ['/Synth/XY', i, 10, i, 200]

=head2 BUNDLES

A bundle is an array reference that contains the bundle identifier
C<#bundle> and a timestamp, followed by zero or more
messages. Examples:

    ['#bundle', time() + 0.1, ['/Pitch', 'f', rand(1)]

    ['#bundle', time() + 2, ['/Slider', 'f', $s],
                            ['/Synth/XY', 'i', $x, 'i', $y]

Note that the time should be expressed in seconds since 1st January
1970, which is what time() returns on UNIX systems.  You can pass it
a floating point time, the Time::HiRes module will help you find the
current time with sub-second accuracy.

A timestamp with the value "0" carries the special meaning of "execute immediately". Example:

    ['#bundle', 0, ['/Pitch', 'f', rand(1)]

=head1 FUNCTIONS

=over

=item protocol()

Returns information about the version of the OSC protocol implemented. Currently C<OSC/1.0>. 

=cut

sub protocol {
    return "OSC/1.0";
}

=item types()

Returns information about the data types implemented. Currently C<bfis> (blobs, floats, ints and strings).

=cut

sub types {
    return "bfis";
}

our $_match_OSCString = <<EOT;
(?:[^\0]{4})*       # zero or more blocks of four non-ASCII-NULs
(?:
[^\0]{3}\0    |      # block padded with ASCII-NULs
[^\0]{2}\0{2} |
[^\0]{1}\0{3} |
\0{4}
)
EOT

=item decode($data)

Decodes binary OSC message or bundle data into a Perl data structure

=cut

sub decode {
    local $_;
    my ($data) = @_;

    return undef unless $data;

    if ($data =~ /^\#bundle/) {
        return _decode_bundle($data);
    } else {
        return _decode_message($data);
    }
}

# format: ['#bundle', timestamp, [element1...], [element2...], ...]
sub _decode_bundle {
    my ($data) = @_;

    my $msg = [];

    # Get OSC target address
    $data =~ /^($_match_OSCString)(.*)/x || return undef;
    $data = $2;    # discard '#bundle'
    push @$msg, '#bundle';

    my ($secs, $frac) = unpack('NB32', $data);
    substr($data, 0, 8) = '';
    if ($secs eq 0 && $frac == $IMMEDIATE_FRACTION) {

        # 'immediately'
        push @$msg, 0;
    } else {
        push @$msg, $secs - $NTP_ADJUSTMENT + _bin2frac($frac);
    }

    while (length($data) > 0) {
        my $len = unpack('N', $data);
        substr($data, 0, 4) = '';
        push @$msg, decode(substr($data, 0, $len));
        substr($data, 0, $len) = '';
    }

    return $msg;
}

# format: [addr, type, data, type, data, ...]
sub _decode_message {
    local $_;
    my ($data) = @_;

    my $msg = [];

    # Get OSC target address
    $data =~ /^($_match_OSCString)(.*)/x || return undef;
    $data = $2;

    (my $addr = $1) =~ s/\0//g;
    push @$msg, $addr;

    # Get type string
    $data =~ /^($_match_OSCString)(.*)/x || return undef;
    $data = $2;
    (my $types = $1) =~ s/(^,|\0)//g;

    foreach (split //, $types) {

        # push type identifier
        push @$msg, $_;

      SWITCH: for ($_) {
            /i/ && do {
                push @$msg, unpack('N', $data);

                # remove this integer from remaining data
                substr($data, 0, 4) = '';
                last SWITCH;
            };
            /f/ && do {
                push @$msg, fromFloat($data);

                #                push @$msg, unpack('f', $data);
                # remove this float from remaining data
                substr($data, 0, 4) = '';
                last SWITCH;
            };
            /s/ && do {
                $data =~ /^($_match_OSCString)(.*)/x || return undef;
                $data = $2;
                (my $s = $1) =~ s/\0//g;
                push @$msg, $s;
                last SWITCH;
            };
            /b/ && do {
                my $len = unpack('N', $data);
                substr($data, 0, 4) = '';

                push @$msg, substr($data, 0, $len);

                # blob is zero-padded
                substr($data, 0, $len + (4 - $len % 4)) = '';

                last SWITCH;
            };

            return undef;
        }
    }

    return $msg;
}

=item encode($data)

Encodes OSC messages or bundles into their binary representation

=cut

sub encode {
    local $_;
    my ($data) = @_;
    my $idx = 0;

    return undef unless $data && ref($data);

    my $msg;

    if ($data->[0] eq '#bundle') {
        my $msg = toString($data->[$idx++]);

        $msg .= toTimetag($data->[$idx++]);

        while ($idx <= $#$data) {
            my $e = encode($data->[$idx++]);
            $msg .= toInt(length($e)) . $e;
        }

        return $msg;
    }

    $msg = toString($data->[$idx++]);
    my ($types, $payload) = ('', '');

    # '<' because we need _two_ elements (type tag, data)
    while ($idx < $#$data) {
        my ($t, $d) = ($data->[$idx++], $data->[$idx++]);
        $t eq 'i' && do { $types .= 'i'; $payload .= toInt($d) };
        $t eq 'f' && do { $types .= 'f'; $payload .= toFloat($d) };
        $t eq 's' && do { $types .= 's'; $payload .= toString($d) };
        $t eq 'b' && do { $types .= 'b'; $payload .= toBlob($d) };
    }

    return $msg . toString(",$types") . $payload;
}

=item toInt($n)

Returns the binary representation of an integer in OSC format

=cut

sub toInt {
    return pack('N', $_[0]);
}

=item fromFloat($n)

Converts the binary representation of a floating point value in OSC format
into a Perl value. (There are no other "from..." functions since the code
for that is directly embedded into the decode functons for speed, but this
one is separate since it depends on the endianness of the system it's
running on).

=cut

sub _fromFloat_bigEndian {
    return unpack('f', $_[0]);
}

sub _fromFloat_littleEndian {
    return unpack('f', pack('N', unpack('l', $_[0])));

    #    return unpack('f', reverse $_[0]);
}

sub _fromFloat_64bit {
    my $t =
      substr($_[0], 3, 1) . substr($_[0], 2, 1) . substr($_[0], 1, 1) .
      substr($_[0], 0, 1);
    return unpack('f', $t);
}

=item toFloat($n)

Returns the binary representation of a floating point value in OSC format

=cut

sub _toFloat_bigEndian {
    return pack("f", $_[0]);
}

sub _toFloat_littleEndian {

    #    return reverse pack('f', $_[0]);
    return pack('N', unpack('l', pack('f', $_[0])));
}

sub _toFloat_64bit {
    my $t = pack("f", $_[0]);
    return
      substr($t, 3, 1) . substr($t, 2, 1) . substr($t, 1, 1) . substr($t, 0, 1);
}

=item toString($str)

Returns the binary representation of a string in OSC format

=cut

sub toString {
    my ($str) = @_;

    return undef unless defined $str;

    # use bytes for UNICODE compatibility
    return $str . "\0" x (4 - length($str) % 4);
}

=item toBlob($d)

Returns the binary representation of a BLOB value in OSC format

=cut

sub toBlob {
    my ($d) = @_;

    return undef unless defined $d;

    return toInt(length($d)) . toString($d);
}

=item toTimetag($d)

Returns the binary representation of a TIMETAG value in OSC format.

=cut

sub toTimetag {
    my $timetag = shift;

    if ($timetag == 0) {

        # 'immediately'
        return (pack("NB32", 0, $IMMEDIATE_FRACTION));
    } else {
        my $secs = int($timetag);
        my $frac = $timetag - $secs;

        return (pack("NB32", $secs + $NTP_ADJUSTMENT, _frac2bin($frac)));
    }
}

# NTP conversion code, see e.g. Net::NTP
sub _frac2bin {
    my $bin  = '';
    my $frac = shift;
    while (length($bin) < 32) {
        $bin = $bin . int($frac * 2);
        $frac = ($frac * 2) - (int($frac * 2));
    }
    return $bin;
}

sub _bin2frac {
    my @bin = split '', shift;
    my $frac = 0;
    while (@bin) {
        $frac = ($frac + pop @bin) / 2;
    }
    return $frac;
}

1;

=back


=head1 BUGS

Doesn't work with Unicode data. Remember to C<use bytes> if you use
Unicode Strings.

=head1 SEE ALSO

Hacking Perl in Nightclubs at L<http://www.perl.com/pub/a/2004/08/31/livecode.html>

The OpenSoundControl website at L<http://www.cnmat.berkeley.edu/OpenSoundControl/>

L<Net::OpenSoundControl::Client>

L<Net::OpenSoundControl::Server>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

Timestamp code lifted from Net::NTP.

Test against specification by Alex (yaxu.org).

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Christian Renz E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

