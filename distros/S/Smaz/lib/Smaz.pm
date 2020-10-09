package Smaz;

use 5.006;
use strict;
use warnings;
use utf8;
our $VERSION = '0.02';
use open ":std", ":encoding(UTF-8)";
use base 'Import::Export';

our %EX = (
	'smaz_compress' => [qw/all/],
	'smaz_decompress' => [qw/all/],
);

our (%CODEBOOK, %REVERSE_CODEBOOK);
BEGIN {
	%CODEBOOK = (
		" "=> 0,
		"the"=> 1,
		"e"=> 2,
		"t"=> 3,
		"a"=> 4,
		"of"=> 5,
		"o"=> 6,
		"and"=> 7,
		"i"=> 8,
		"n"=> 9,
		"s"=> 10,
		"e "=> 11,
		"r"=> 12,
		" th"=> 13,
		" t"=> 14,
		"in"=> 15,
		"he"=> 16,
		"th"=> 17,
		"h"=> 18,
		"he "=> 19,
		"to"=> 20,
		"\r\n"=> 21,
		"l"=> 22,
		"s "=> 23,
		"d"=> 24,
		" a"=> 25,
		"an"=> 26,
		"er"=> 27,
		"c"=> 28,
		" o"=> 29,
		"d "=> 30,
		"on"=> 31,
		" of"=> 32,
		"re"=> 33,
		"of "=> 34,
		"t "=> 35,
		", "=> 36,
		"is"=> 37,
		"u"=> 38,
		"at"=> 39,
		"   "=> 40,
		"n "=> 41,
		"or"=> 42,
		"which"=> 43,
		"f"=> 44,
		"m"=> 45,
		"as"=> 46,
		"it"=> 47,
		"that"=> 48,
		"\n"=> 49,
		"was"=> 50,
		"en"=> 51,
		"  "=> 52,
		" w"=> 53,
		"es"=> 54,
		" an"=> 55,
		" i"=> 56,
		"\r"=> 57,
		"f "=> 58,
		"g"=> 59,
		"p"=> 60,
		"nd"=> 61,
		" s"=> 62,
		"nd "=> 63,
		"ed "=> 64,
		"w"=> 65,
		"ed"=> 66,
		"http=>//"=> 67,
		"for"=> 68,
		"te"=> 69,
		"ing"=> 70,
		"y "=> 71,
		"The"=> 72,
		" c"=> 73,
		"ti"=> 74,
		"r "=> 75,
		"his"=> 76,
		"st"=> 77,
		" in"=> 78,
		"ar"=> 79,
		"nt"=> 80,
		","=> 81,
		" to"=> 82,
		"y"=> 83,
		"ng"=> 84,
		" h"=> 85,
		"with"=> 86,
		"le"=> 87,
		"al"=> 88,
		"to "=> 89,
		"b"=> 90,
		"ou"=> 91,
		"be"=> 92,
		"were"=> 93,
		" b"=> 94,
		"se"=> 95,
		"o "=> 96,
		"ent"=> 97,
		"ha"=> 98,
		"ng "=> 99,
		"their"=> 100,
		"\""=> 101,
		"hi"=> 102,
		"from"=> 103,
		" f"=> 104,
		"in "=> 105,
		"de"=> 106,
		"ion"=> 107,
		"me"=> 108,
		"v"=> 109,
		"."=> 110,
		"ve"=> 111,
		"all"=> 112,
		"re "=> 113,
		"ri"=> 114,
		"ro"=> 115,
		"is "=> 116,
		"co"=> 117,
		"f t"=> 118,
		"are"=> 119,
		"ea"=> 120,
		". "=> 121,
		"her"=> 122,
		" m"=> 123,
		"er "=> 124,
		" p"=> 125,
		"es "=> 126,
		"by"=> 127,
		"they"=> 128,
		"di"=> 129,
		"ra"=> 130,
		"ic"=> 131,
		"not"=> 132,
		"s,"=> 133,
		"d t"=> 134,
		"at "=> 135,
		"ce"=> 136,
		"la"=> 137,
		"h "=> 138,
		"ne"=> 139,
		"as "=> 140,
		"tio"=> 141,
		"on "=> 142,
		"n t"=> 143,
		"io"=> 144,
		"we"=> 145,
		" a "=> 146,
		"om"=> 147,
		", a"=> 148,
		"s o"=> 149,
		"ur"=> 150,
		"li"=> 151,
		"ll"=> 152,
		"ch"=> 153,
		"had"=> 154,
		"this"=> 155,
		"e t"=> 156,
		"g "=> 157,
		"e\r\n"=> 158,
		" wh"=> 159,
		"ere"=> 160,
		" co"=> 161,
		"e o"=> 162,
		"a "=> 163,
		"us"=> 164,
		" d"=> 165,
		"ss"=> 166,
		"\n\r\n"=> 167,
		"\r\n\r"=> 168,
		"=\""=> 169,
		" be"=> 170,
		" e"=> 171,
		"s a"=> 172,
		"ma"=> 173,
		"one"=> 174,
		"t t"=> 175,
		"or "=> 176,
		"but"=> 177,
		"el"=> 178,
		"so"=> 179,
		"l "=> 180,
		"e s"=> 181,
		"s,"=> 182,
		"no"=> 183,
		"ter"=> 184,
		" wa"=> 185,
		"iv"=> 186,
		"ho"=> 187,
		"e a"=> 188,
		" r"=> 189,
		"hat"=> 190,
		"s t"=> 191,
		"ns"=> 192,
		"ch "=> 193,
		"wh"=> 194,
		"tr"=> 195,
		"ut"=> 196,
		"/"=> 197,
		"have"=> 198,
		"ly "=> 199,
		"ta"=> 200,
		" ha"=> 201,
		" on"=> 202,
		"tha"=> 203,
		"-"=> 204,
		" l"=> 205,
		"ati"=> 206,
		"en "=> 207,
		"pe"=> 208,
		" re"=> 209,
		"there"=> 210,
		"ass"=> 211,
		"si"=> 212,
		" fo"=> 213,
		"wa"=> 214,
		"ec"=> 215,
		"our"=> 216,
		"who"=> 217,
		"its"=> 218,
		"z"=> 219,
		"fo"=> 220,
		"rs"=> 221,
		">"=> 222,
		"ot"=> 223,
		"un"=> 224,
		"<"=> 225,
		"im"=> 226,
		"th "=> 227,
		"nc"=> 228,
		"ate"=> 229,
		"><"=> 230,
		"ver"=> 231,
		"ad"=> 232,
		" we"=> 233,
		"ly"=> 234,
		"ee"=> 235,
		" n"=> 236,
		"id"=> 237,
		" cl"=> 238,
		"ac"=> 239,
		"il"=> 240,
		"</"=> 241,
		"rt"=> 242,
		" wi"=> 243,
		"div"=> 244,
		"e, "=> 245,
		" it"=> 246,
		"whi"=> 247,
		" ma"=> 248,
		"ge"=> 249,
		"x"=> 250,
		"e c"=> 251,
		"men"=> 252,
		".com"=> 253
	);
	%REVERSE_CODEBOOK = map { $CODEBOOK{$_} => $_ } keys %CODEBOOK;
}

sub flush_verbatim {
	my $verbatim = shift;
	return (((length($verbatim) > 1)
		? ( chr(255), chr(length($verbatim) - 1) )
		: chr(254)), split '', $verbatim);
}

sub smaz_compress {
	my ($input, $verbatim, $input_index, @output) = (shift, '', 0);
	while ($input_index < length $input) {
		my ($encoded, $j, $i) = (0, (length($input) - $input_index) < 7 ? (length($input) - $input_index) : 7);
		for ($j = ($i = $j); $j <= 0 ? $i < 0 : $i > 0; $j = ($j <= 0) ? ($i += 1) : ($i -= 1)) {
			my $code = $CODEBOOK{substr($input, $input_index, $j)};
			if (defined $code) {
				if ($verbatim) {
					push @output, flush_verbatim($verbatim);
					$verbatim = '';
				}
				push @output, chr($code);
				$encoded = $input_index += $j;
				last;
			}
		}
		if (!$encoded) {
			$verbatim .= substr $input, $input_index++, 1;
			if (length($verbatim) == 256) {
				push @output, flush_verbatim($verbatim);
				$verbatim = '';
			}
		}
	}
	push @output, flush_verbatim($verbatim) if ($verbatim);
	return join('', @output);
}

sub smaz_decompress {
	my ($str_input, $output, $i, $ii) = (shift, '', 0);
	my @input = map { ord($_) } split "", $str_input;
	while ($i < scalar @input) {
		if ($input[$i] == 254) {
			die 'Malformed SMAZ' if ($i + 1 > scalar @input);
			$output .= substr($str_input, $i + 1, 1);
			$i += 2;
		} elsif ($input[$i] == 255) {
			die 'Malformed SMAZ' if ($i + $input[$i + 1] + 2 >= scalar @input);
			my $ref = $input[$i + 1] + 1;
			for (my $j = ($ii = 0); $ii < $ref; $j = (0 <= $ref) && ($ii += 1)) {
				$output .= substr($str_input, $i + 2 + $j, 1);
			}
			$i += 3 + $input[$i + 1];
		} else {
			$output .= $REVERSE_CODEBOOK{$input[$i++]};
		}
	}
	return $output;
}

__END__

1;

=head1 NAME

Smaz - compression for very small strings!

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Smaz qw/all/;

	my $comp = smaz_compress($str);
	my $decomp = smaz_decompress($str);

=head1 DESCRIPTION

Smaz is a simple compression library suitable for compressing very short
strings. General purpose compression libraries will build the state needed
for compressing data dynamically, in order to be able to compress every kind
of data. This is a very good idea, but not for a specific problem: compressing
small strings will not work.

Smaz instead is not good for compressing general purpose data, but can compress
text by 40-50% in the average case (works better with English), and is able to
perform a bit of compression for HTML and urls as well. The important point is
that Smaz is able to compress even strings of two or three bytes!

For example the string "the" is compressed into a single byte.

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 smaz_compress

Compress a string. Expects a Str.

	smaz_compress($string);

=cut

=head2 smaz_decompress

Decompress a Smaz string. Expects a Str.

	smaz_decompress($string);

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-smaz at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Smaz>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Smaz


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Smaz>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Smaz>

=item * Search CPAN

L<https://metacpan.org/release/Smaz>

=back

=head1 ACKNOWLEDGEMENTS

Smaz was written by Salvatore Sanfilippo and is released under the BSD license. Check the COPYING file for more information.

See http://github.com/antirez/smaz for information on smaz and the algorithm itself.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Smaz
