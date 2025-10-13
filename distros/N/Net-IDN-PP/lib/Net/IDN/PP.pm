package Net::IDN::PP 0.01;
# ABSTRACT: A pure-Perl implementation of the Punycode algorithm for encoding internationalized domain names (IDNs)
use common::sense;


sub encode {
    my $name = pop;
    return join('.', map { encode_label($_) } split(/\./, $name));
}

sub decode {
    my $name = pop;
    return join('.', map { decode_label($_) } split(/\./, $name));
}

sub encode_label {
    my $label = lc(pop);

    # if ASCII-only: return as-is
    return $label if ($label =~ /^[\x00-\x7F]+$/);

    # extract code points
    my @cps = unpack("U*", $label);

    # Initialize @output with only the ASCII code points
    my @output = map { chr($_) } grep { $_ < 0x80 } @cps;

    my $basic_length = scalar(@output);
    my $output_str = join('', @output);
    $output_str .= '-' if ($basic_length > 0);

    # Punycode parameters
    my $n       = 128;
    my $delta   = 0;
    my $bias    = 72;
    my $h       = $basic_length;
    my $len     = scalar(@cps);

    while ($h < $len) {
        # Find the minimum code point >= n
        my $m = 0x10FFFF;

        for my $cp (@cps) {
            $m = $cp if $cp >= $n && $cp < $m;
        }

        my $inc = ($m - $n) * ($h + 1);
        $delta += $inc;
        $n = $m;

        for my $cp (@cps) {
            if ($cp < $n) {
                $delta++;

            } elsif ($cp == $n) {
                my $q = $delta;

                for (my $k = 36; ; $k += 36) {
                    my $t;

                    if ($k <= $bias) {
                        $t = 1;

                    } elsif ($k >= $bias + 26) {
                        $t = 26;

                    } else {
                        $t = $k - $bias;

                    }

                    last if ($q < $t);

                    my $code = $t + (($q - $t) % (36 - $t));
                    $output_str .= encode_digit($code);
                    $q = int(($q - $t) / (36 - $t));
                }

                $output_str .= encode_digit($q);
                $bias = adapt($delta, $h + 1, $h == $basic_length);
                $delta = 0;
                $h++;
            }
        }

        $delta++;
        $n++;
    }

    return q{xn--}.$output_str;
}

sub encode_digit {
    my $d = shift;
    return chr($d + 22 + 75 * ($d < 26));  # 0..25 = a..z, 26..35 = 0..9
}

sub decode_digit {
    my $ch = lc(shift);
    my $cp = ord($ch);

    # 'a'..'z' => 0..25
    return $cp - 97 if ($cp >= 97 && $cp <= 122);

    # '0'..'9' => 26..35

    return $cp - 22 if ($cp >= 48 && $cp <= 57);

    return 36; # invalid
}

sub adapt {
    my ($delta, $numpoints, $first_time) = @_;
    $delta = int($first_time ? $delta / 700 : $delta / 2);
    $delta += int($delta / $numpoints);

    my $k = 0;

    while ($delta > 455) {
        $delta = int($delta / 35);
        $k += 36;
    }

    return $k + int((36 * $delta) / ($delta + 38));
}

sub decode_label {
    my $label = shift;

    return $label unless ($label =~ /^xn--/i);

    my $input = lc(substr($label, 4));

    my @output;
    my $dash_pos = rindex($input, '-');
    if ($dash_pos != -1) {
        my $basic = substr($input, 0, $dash_pos);
        @output = map { ord($_) } split(//, $basic);
        $input = substr($input, $dash_pos + 1);
    }

    my $n    = 128;
    my $i    = 0;
    my $bias = 72;

    my $in_idx = 0;
    my $in_len = length($input);

    while ($in_idx < $in_len) {
        my $oldi = $i;
        my $w = 1;

        for (my $k = 36; ; $k += 36) {
            last if ($in_idx >= $in_len);

            my $c = substr($input, $in_idx++, 1);
            my $d = decode_digit($c);

            $i += $d * $w;

            my $t;
            if ($k <= $bias) {
                $t = 1;

            } elsif ($k >= $bias + 26) {
                $t = 26;

            } else {
                $t = $k - $bias;

            }

            last if ($d < $t);
            $w *= (36 - $t);
        }

        my $out_len_plus_1 = scalar(@output) + 1;

        $bias = adapt($i - $oldi, $out_len_plus_1, $oldi == 0);

        my $q = int($i / $out_len_plus_1);

        $n += $q;

        $i = $i % $out_len_plus_1;

        splice(@output, $i, 0, $n);

        $i++;
    }

    return join('', map { chr($_) } @output);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IDN::PP - A pure-Perl implementation of the Punycode algorithm for encoding internationalized domain names (IDNs)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Net::IDN::PP;

    say Net::IDN::PP->decode('xn--caf-dma.com'); # prints café.com

    say Net::IDN::PP->decode('café.com'); # prints xn--caf-dma.com

=head1 DESCRIPTION

Net::IDN::PP is a pure Perl IDN encoder/decoder. The C<decode()> method takes an
"A-label" and decodes it, and C<encode()> takes a "U-label" and encodes it.

Other modules exist which provide similar functionality, but they all rely on
external C libraries such as libidn/libidn2 or ICU.

=head2 IMPORTANT NOTE

This module only implements the Punycode algorithm from
L<RFC 3492|https://www.rfc-editor.org/rfc/rfc3492.html>; it does not implement
any of the "Nameprep" logic described in IDNA2003 or IDNA2008. This makes it
unsuitable for use in provisioning (domain registrar or registry) systems, but
it should work fine if you don't mind working on a "garbage in, garbage out"
basis.

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
