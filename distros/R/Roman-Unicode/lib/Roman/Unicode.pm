use utf8;
use 5.014;

=encoding utf8

=head1 NAME

Roman::Unicode - Make roman numerals, using the Unicode characters for them

=head1 SYNOPSIS

	use Roman::Unicode qw( to_roman is_roman to_perl );

	my $perl_number  = to_perl( $roman ) if is_roman( $roman );
	my $roman_number = to_roman( $arabic );

=head1 DESCRIPTION

I made this module as a way to demonstrate various Unicode things without
mixing up natural language stuff. Surprisingly, roman numerals can do quite
a bit with that. You'll have to read the source to see it in action.

There are many fancy characters in this documentation, so you need a good
font that has the right glyphs. The Symbola font is a good one:
http://users.teilar.gr/~g1951d/

=head2 Functions

=over 4

=item is_roman( STRING )

Returns true if the string looks like a valid roman numeral. This
works with either the ASCII version or the ones using the characters
in the U+2160 to U+2188 range. You cannot mix the uppercase and lowercase
numerals.

=item to_perl( ROMAN )

If the argument is a valid roman numeral, C<to_perl> returns the Perl
number. Otherwise, it returns nothing.

=item to_roman( PERL_NUMBER )

If the argument is a valid Perl number, even if it is a string,
C<to_roman> returns the roman numeral representation. This uses the
characters in the U+2160 to U+2188 range.

If the number cannot be represented as roman numerals, this returns
nothing. Note that 0 doesn't have a roman numeral representation.

If you want the lowercase version, you can use C<lc> on the result.
However, some of the roman numerals don't have lowercase versions.

=item to_ascii( ROMAN )

If the argument is a valid roman numeral, it returns an ASCII
representation of it. Most of the numeral code points have compatible
decompositions, so the first step uses NFKD decomposition. For other
characters, it uses ASCII art representations:

	Roman       ASCII art
	------      ----------
	ↁ           |)
	ↂ          ((|))
	ↈ          (((|)))
	ↇ           |))

=back

=head2 Case mapping

As a demonstration of case mapping, I supply one function that uses
L<Unicode::Casing>. You can lexically override the case-mapping functions
as described in that module's documentation.

=over 4

=item to_roman_lower

A subroutine you can use with C<Unicode::Casing>. It's a bit more special
because it turns the higher magnitude characters into ASCII versions. That
means that the return value might not be a valid according to C<is_roman>. It
returns nothing if the input isn't a valid Roman numeral string.

You can also use this as a stand-alone function instead of C<lc>. That's the
smart way to do it, but then you don't get to play with C<Unicode::Casing>.

=back

=head2 User-defined properties

Perl lets you define your own properties, as documented in L<perlunicode>. This
module defines several.

=over 4

=item IsRoman

The C<IsRoman> property is a combination of C<IsUppercaseRoman> and
C<IsLowercaseRoman>.

=item IsUppercaseRoman

The C<IsUppercaseRoman> property matches these code points:

	Ⅰ       U+2160      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ᴏɴᴇ
	Ⅴ       U+2164      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ꜰɪᴠᴇ
	Ⅹ       U+2169      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ᴛᴇɴ
	Ⅼ       U+216C      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ꜰɪꜰᴛʏ
	Ⅽ       U+216D      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ᴏɴᴇ ʜᴜɴᴅʀᴇᴅ
	Ⅾ       U+216E      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ꜰɪᴠᴇ ʜᴜɴᴅʀᴇᴅ
	Ⅿ       U+216F      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ᴏɴᴇ ᴛʜᴏᴜsᴀɴᴅ
	ↁ       U+2181      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ꜰɪᴠᴇ ᴛʜᴏᴜsᴀɴᴅ
	ↂ      U+2182      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ᴛᴇɴ ᴛʜᴏᴜsᴀɴᴅ
	ↇ       U+2187      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ꜰɪꜰᴛʏ ᴛʜᴏᴜsᴀɴᴅ
	ↈ      U+2188      ʀᴏᴍᴀɴ ɴᴜᴍᴇʀᴀʟ ᴏɴᴇ ʜᴜɴᴅʀᴇᴅ ᴛʜᴏᴜsᴀɴᴅ

This excludes the other Roman numeral code points, such as Ⅻ (U+216B, ʀᴏᴍᴀɴ
ɴᴜᴍᴇʀᴀʟ ᴛᴡᴇʟᴠᴇ) since they are not designed to be part of larger strings of
Roman numerals.

=item IsLowercaseRoman

The C<IsLowercaseRoman> is the set of lowercase code points derived from the
set of code points in C<IsUppercaseRoman>. It checks each code point in
C<IsUppercaseRoman> and checks the Unicode Character Database (UCD) through
L<Unicode::UCD> to see if it has a lowercase mapping. If there is a lowercase
mapping, it makes it part of this property.

=back

=head1 LIMITATIONS

By using just the defined roman numerals characters in the Unicode Character
Set, you're limited to numbers less than 400,000 (although you could make
ↈↈↈↈ if you wanted, since that's not unheard of).

=head1 AUTHOR

brian d foy C<< <brian.d.foy@gmail.com> >>

This module started with the Roman module, credited to:

OZAWA Sakuro C<< <ozawa at aisoft.co.jp> >> 1995-1997

Alexandr Ciornii, C<< <alexchorny at gmail.com> >> 2007

=head1 COPYRIGHT

Copyright © 2011-2022, brian d foy <bdfoy@cpan.org>.

You can use this module under the terms of Artistic License 2.0.

=cut

package Roman::Unicode {
	use feature qw(unicode_strings);

	use strict;
	use warnings;
	use open IO => ':utf8';

	use Exporter 'import';
	our @EXPORT_OK = qw( is_roman to_perl to_roman to_ascii );
	our $VERSION = '1.034';

	use Unicode::UCD;
	use Unicode::Normalize qw(NFKD);

	# I'm specifically not using the characters for the other roman numerals
	# because those are meant to stand alone, as they might in a clock face
	our %valid_roman = map { $_, 1 } (
		# the capitals U+2160 to U+216F, U+2180 to U+2182, U+2187 to U+2188
		qw(Ⅰ Ⅴ Ⅹ Ⅼ Ⅽ Ⅾ Ⅿ ↁ ↂ ↇ ↈ ),
		# the lowercase U+2170 to U+217f
		qw(ⅰ ⅴ ⅹ ⅼ ⅽ ⅾ ⅿ),
		# the ASCII
		qw(I V X L C D M),
		qw(i v x l c d m),

		);

	our %roman2arabic = qw(
		Ⅰ 1 Ⅴ 5 Ⅹ 10
		Ⅼ 50 Ⅽ 100 Ⅾ 500 Ⅿ 1000 ↁ 5000 ↂ 10000 ↇ 50000 ↈ 100000

		ⅰ 1 ⅴ 5 ⅹ 10
		ⅼ 50 ⅽ 100 ⅾ 500 ⅿ 1000
		);

	sub _get_chars { my @chars = $_[0] =~ /(\X)/ug }

	sub _highest_value {  (sort { $a <=> $b } values %roman2arabic)[-1] }

	sub is_roman($) {
		$_[0] =~ / \A \p{IsUppercaseRoman}+ \z /x
			or
		$_[0] =~ / \A \p{IsLowercaseRoman}+ \z /x
		}

	sub to_perl($) { # Stolen from Roman.pm, mostly
		is_roman $_[0] or return;
		my($last_digit) = _highest_value();
		my($arabic);

		foreach my $char ( _get_chars( $_[0] ) ) {
			my $digit = $roman2arabic{$char};
			$arabic -= 2 * $last_digit if $last_digit < $digit;
			$arabic += ($last_digit = $digit);
			}

		$arabic;
		}

	BEGIN {

	my %roman_digits = qw(
		1 ⅠⅤ
		10 ⅩⅬ
		100 ⅭⅮ
		1000 Ⅿↁ
		10000 ↂↇ
		100000 ↈↈↈↈ
		);

	my @figure = reverse sort keys %roman_digits;
	$roman_digits{$_} = [split(//, $roman_digits{$_}, 2)] foreach @figure;

	sub to_roman($) { # stolen from Roman.pm, mostly
		my( $arg ) = @_;

		{
		no warnings 'numeric';
		0 < $arg and $arg < 4 * _highest_value()  or return;
		}

		my($x, $roman) = ( '', '' );
		foreach my $figure ( @figure ) {
			my( $digit, $i, $v ) = (int( $arg/$figure ), @{$roman_digits{$figure}});

			$roman .= do {
				   if( 1 <= $digit and $digit <= 3 ) { $i x $digit }
				elsif( $digit == 4 )                 { "$i$v" }
				elsif( $digit == 5 )                 { $v }
				elsif( 6 <= $digit and $digit <= 8 ) { $v . $i x ($digit - 5) }
				elsif( $digit == 9 )                 { "$i$x" }
				};

			$arg -= $digit * $figure;
			$x = $i;
			}

		$roman;
		}
	}

	sub to_ascii {
		my( $roman ) = @_;
		return unless is_roman( $roman );

		$roman = Unicode::Normalize::NFKD( $roman );

		$roman =~ s/ↁ/|))/g;
		$roman =~ s/ↂ/((|))/g;
		$roman =~ s/ↈ/(((|)))/g;
		$roman =~ s/ↇ/|)))/g;

		$roman;
		}

	sub IsRoman {
		IsUppercaseRoman() . IsLowercaseRoman()
		}

	sub IsUppercaseRoman {
		return <<"CODE_NUMBERS";
2160
2164
2169
216C 216F
2181 2182
2187 2188
CODE_NUMBERS
		}

	sub IsLowercaseRoman {
		state $string;
		return $string if defined $string;

		my @codes = ();

		my $uppers = IsUppercaseRoman();
		open my $string_fh, '<', \ $uppers;
		while( my $line = <$string_fh> ) {
			my @n = map { hex } map { m/(\p{HexDigit}+)/g } $line;
			if( @n == 1 ) { push @codes, $n[0] }
			if( @n == 2 ) { push @codes, $n[0] .. $n[1] };
			}

		my @lowers = map { hex } map {
			my $char_info = Unicode::UCD::charinfo( $_ );
			$char_info->{lower} ? $char_info->{lower} : ();
			} @codes;

		$string = join "\n", map {
			sprintf( '%04X', $_ )
			} @lowers;

		$string .= "\n";
		}

    # Use this with Unicode::Casing, or not
	sub to_roman_lower {
		return unless &is_roman;

		my $lower = CORE::lc( $_[0] );

		$lower =~ s/ↁ/|)/g;       # ↁ U+2181
		$lower =~ s/ↂ/((|))/g;   # ↂ U+2182
		$lower =~ s/ↇ/|))/g;      # ↇ U+2187
		$lower =~ s/ↈ/(((|)))/g; # ↈ U+2188

		return $lower;
		}
 }

1;
