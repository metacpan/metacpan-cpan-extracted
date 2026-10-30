package Net::IDN::Punycode::PP;

use 5.008;

use strict;
use utf8;
use warnings;

use Carp;
use Exporter;

our $VERSION = "2.600";

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(encode_punycode decode_punycode);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

## no "use integer" - IV arithmetic wraps below PUNYCODE_MAXINT on 32-bit
## perls, whereas NV arithmetic is exact up to 2**53 everywhere

use constant BASE => 36;
use constant TMIN => 1;
use constant TMAX => 26;
use constant SKEW => 38;
use constant DAMP => 700;
use constant INITIAL_BIAS => 72;
use constant INITIAL_N => 128;

use constant UNICODE_MAX => 0x10FFFF;
use constant PUNYCODE_MAXINT => 0xFFFFFFFF;
use constant SURROGATE_MIN => 0xD800;
use constant SURROGATE_MAX => 0xDFFF;

my $Delimiter = chr 0x2D;
my $BasicRE   = "\x00-\x7f";
my $PunyRE    = "A-Za-z0-9";

sub _adapt {
    my($delta, $numpoints, $firsttime) = @_;
    $delta = int($firsttime ? $delta / DAMP : $delta / 2);
    $delta += int($delta / $numpoints);
    my $k = 0;
    while ($delta > int(((BASE - TMIN) * TMAX) / 2)) {
	$delta = int($delta / (BASE - TMIN));
	$k += BASE;
    }
    return $k + int(((BASE - TMIN + 1) * $delta) / ($delta + SKEW));
}

## die, not croak - Carp itself fails while it formats a malformed argument
sub _die {
    my $frame = 0;
    $frame++ while ((caller $frame)[0] || '') eq __PACKAGE__;
    my ($file, $line) = (caller $frame)[1, 2];
    die "$_[0] at $file line $line.\n";
}

sub _check_input {
    my ($input, $message) = @_;
    unless (defined $input) {
        warnings::warnif('uninitialized',
            'Use of uninitialized value in subroutine entry');
        return;
    }
    $input = "$input";    ## stringify an overloaded object once
    _die($message) unless utf8::valid($input);
    return $input;
}

sub decode_punycode {
    _die("Usage: Net::IDN::Punycode::decode_punycode(input)") unless @_ == 1;
    no warnings 'utf8';

    my $input = _check_input(shift,
        "non-base character in input for decode_punycode");
    return '' unless defined $input && length $input;

    my $n      = INITIAL_N;
    my $i      = 0;
    my $bias   = INITIAL_BIAS;
    my @output;

    if($input =~ s/(.*)$Delimiter//os) {
      my $base_chars = $1;
      croak("non-base character in input for decode_punycode")
        if $base_chars =~ m/[^$BasicRE]/os;
      push @output, split //, $base_chars;
    }
    my $code = $input;

    croak("non-base character in input for decode_punycode")
      if $code =~ m/[^$BasicRE]/os;
    croak('invalid digit in input for decode_punycode') if $code =~ m/[^$PunyRE]/os;

    utf8::downgrade($code);	## handling failure of downgrade is more expensive than
				## doing the above regexp w/ utf8 semantics

    while(length $code)
    {
	my $oldi = $i;
	my $w    = 1;
    LOOP:
	for (my $k = BASE; 1; $k += BASE) {
	    my $cp = substr($code, 0, 1, '');
	    croak("incomplete encoded code point in decode_punycode") if !length $cp;
	    my $digit = ord $cp;

	    ## NB: this depends on the PunyRE catching invalid digit characters
	    ## before they turn up here
	    ##
	    $digit = $digit < 0x40 ? $digit + (26-0x30) : ($digit & 0x1f) -1;

	    croak("input exceeds punycode limit")
	      if $digit > (PUNYCODE_MAXINT - $i) / $w;
	    $i += $digit * $w;
	    my $t =  $k - $bias;
	    $t = $t < TMIN ? TMIN : $t > TMAX ? TMAX : $t;

	    last LOOP if $digit < $t;
	    $w *= (BASE - $t);
	}
	my $len  = @output + 1;
	my $step = int($i / $len);
	$bias = _adapt($i - $oldi, $len, $oldi == 0);
	croak('invalid code point') if $step > UNICODE_MAX - $n;
	$n += $step;
	croak('invalid code point')
	  if $n >= SURROGATE_MIN && $n <= SURROGATE_MAX;
	$i = $i % $len;
	splice(@output, $i, 0, chr($n));
	$i++;
    }
    return join '', @output;
}

sub encode_punycode {
    _die("Usage: Net::IDN::Punycode::encode_punycode(input)") unless @_ == 1;
    no warnings 'utf8';

    my $input = _check_input(shift,
        "malformed UTF-8 in input for encode_punycode");
    return '' unless defined $input;
    my $input_length = length $input;

    ## my $output = join '', $input =~ m/([$BasicRE]+)/og; ## slower
    my $output = $input; $output =~ s/[^$BasicRE]+//ogs;

    my $h = my $bb = length $output;
    $output .= $Delimiter if $bb > 0;
    utf8::downgrade($output);	## no unnecessary use of utf8 semantics

    my @input = map ord, split //, $input;
    my @chars = sort { $a<=> $b } grep { $_ >= INITIAL_N } @input;
    croak("invalid code point") if grep {
        $_ > UNICODE_MAX || ($_ >= SURROGATE_MIN && $_ <= SURROGATE_MAX)
    } @chars;

    my $n = INITIAL_N;
    my $delta = 0;
    my $bias = INITIAL_BIAS;

    foreach my $m (@chars) {
 	next if $m < $n;
	croak("input exceeds punycode limit")
	  if $m - $n > (PUNYCODE_MAXINT - $delta) / ($h + 1);
	$delta += ($m - $n) * ($h + 1);
	$n = $m;
	for(my $i = 0; $i < $input_length; $i++)
	{
	    my $c = $input[$i];
	    $delta++ if $c < $n;
	    if ($c == $n) {
		croak("input exceeds punycode limit") if $delta > PUNYCODE_MAXINT;
		my $q = $delta;
	    LOOP:
		for (my $k = BASE; 1; $k += BASE) {
		    my $t = $k - $bias;
	            $t = $t < TMIN ? TMIN : $t > TMAX ? TMAX : $t;

		    last LOOP if $q < $t;

                    my $o = $t + (($q - $t) % (BASE - $t));
                    $output .= chr $o + ($o < 26 ? 0x61 : 0x30-26);

		    $q = int(($q - $t) / (BASE - $t));
		}
		croak("input exceeds punycode limit") if $q >= BASE;
                $output .= chr $q + ($q < 26 ? 0x61 : 0x30-26);

		$bias = _adapt($delta, $h + 1, $h == $bb);
		$delta = 0;
		$h++;
	    }
	}
	croak("input exceeds punycode limit") if $delta >= PUNYCODE_MAXINT;
	$delta++;
	$n++;
    }
    return $output;
}

1;
__END__

=head1 NAME

Net::IDN::Punycode::PP - pure-perl implementation of Net::IDN::Punycode

=head1 DESCRIPTION

See L<Net::IDN::Punycode>.

=head1 AUTHORS

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> (versions 0.01 to 0.02)

Claus FE<auml>rber E<lt>CFAERBER@cpan.orgE<gt> (from version 1.00)

Currently maintained by Robert Rothenberg <perl@rhizomnic.com> and Paul Johnson <paul@pjcj.net>.

=head1 LICENSE

Copyright 2002-2004 Tatsuhiko Miyagawa

Copyright 2007-2018 Claus FE<auml>rber

Parts copyright 2026 Robert Rothenberg <perl@rhizomnic.com> and Paul Johnson <paul@pjcj.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

S<RFC 3492> (L<http://www.ietf.org/rfc/rfc3492.txt>),
L<IETF::ACE>, L<Convert::RACE>

=cut
