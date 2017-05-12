#===============================================================================
#
#         FILE:  Translit.pm
#
#  DESCRIPTION:  Cyrillic transliteration routines
#
#         NOTE:  This module ported from Wono framework "as is"
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.044
#      CREATED:  03.08.2008 15:04:22 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::Translit - transliteration routines

=head1 SYNOPSIS

	use NetSDS::Const;
	use NetSDS::Util::Translit;

	# Transliterate cyrillic string
	$trans_string = trans_cyr_lat($cyr_string);

	# Reverse transliteration to russian language
	$rus_string = trans_lat_cyr("Vsem privet", LANG_RU);

=head1 DESCRIPTION

C<NetSDS::Util::Translit> module contains routines for bidirectional
cyrillic text transliteration. Now it supports russian and ukrainian
languages processing.

=cut

package NetSDS::Util::Translit;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '1.044';

use NetSDS::Util::String;

our @EXPORT = qw(
  trans_cyr_lat
  trans_lat_cyr
);

use constant LANG_BE => 'be';
use constant LANG_EN => 'en';
use constant LANG_RU => 'ru';
use constant LANG_UK => 'uk';

use constant DEFAULT_LANG     => LANG_RU;

my %PREP = (
	LANG_RU() => {
		'а'   => 'a',
		'б'   => 'b',
		'в'   => 'v',
		'г'   => 'g',
		'д'   => 'd',
		'е'   => 'e',
		'ё'   => 'yo',
		'ж'   => 'zh',
		'з'   => 'z',
		'и'   => 'i',
		'й'   => 'j',
		'к'   => 'k',
		'л'   => 'l',
		'м'   => 'm',
		'н'   => 'n',
		'о'   => 'o',
		'п'   => 'p',
		'р'   => 'r',
		'с'   => 's',
		'т'   => 't',
		'у'   => 'u',
		'ф'   => 'f',
		'х'   => 'kh',
		'ц'   => 'tc',
		'ч'   => 'ch',
		'ш'   => 'sh',
		'щ'   => 'sch',
		'ъ'   => '"',
		'ы'   => 'y',
		'ые' => 'yje',
		'ыё' => 'yjo',
		'ыу' => 'yiu',
		'ыю' => 'yju',
		'ыя' => 'yja',
		'ь'   => "'",
		'ье' => 'jie',
		'ьё' => 'jio',
		'ью' => 'jiu',
		'ья' => 'jia',
		'э'   => 'ye',
		'ю'   => 'yu',
		'я'   => 'ya',
	},

	LANG_UK() => {
		"'"  => '"',
		'а' => 'a',
		'б' => 'b',
		'в' => 'v',
		'ґ' => 'g',
		'г' => 'h',
		'д' => 'd',
		'е' => 'e',
		'є' => 'ye',
		'ж' => 'zh',
		'з' => 'z',
		'і' => 'i',
		'и' => 'y',
		'ї' => 'yi',
		'й' => 'j',
		'к' => 'k',
		'л' => 'l',
		'м' => 'm',
		'н' => 'n',
		'о' => 'o',
		'п' => 'p',
		'р' => 'r',
		'с' => 's',
		'т' => 't',
		'у' => 'u',
		'ф' => 'f',
		'х' => 'kh',
		'ц' => 'tc',
		'ч' => 'ch',
		'ш' => 'sh',
		'щ' => 'sch',
		'ь' => "'",
		'ю' => 'yu',
		'я' => 'ya',
	},

	LANG_BE() => {
		"'"    => '"',
		'а'   => 'a',
		'б'   => 'b',
		'в'   => 'v',
		'ґ'   => 'g',
		'г'   => 'h',
		'д'   => 'd',
		'е'   => 'ye',
		'ё'   => 'yo',
		'ж'   => 'zh',
		'з'   => 'z',
		'і'   => 'i',
		'и'   => 'i',
		'ї'   => 'yi',
		'й'   => 'j',
		'к'   => 'k',
		'л'   => 'l',
		'м'   => 'm',
		'н'   => 'n',
		'о'   => 'o',
		'п'   => 'p',
		'р'   => 'r',
		'с'   => 's',
		'т'   => 't',
		'у'   => 'u',
		'ў'   => 'w',
		'ф'   => 'f',
		'х'   => 'kh',
		'ц'   => 'tc',
		'ч'   => 'ch',
		'ш'   => 'sh',
		'щ'   => 'sch',
		'ы'   => 'y',
		'ые' => 'yje',
		'ыё' => 'yjo',
		'ыу' => 'yiu',
		'ыю' => 'yju',
		'ыя' => 'yja',
		'ь'   => "'",
		'ье' => 'jie',
		'ьё' => 'jio',
		'ью' => 'jiu',
		'ья' => 'jia',
		'э'   => 'e',
		'ю'   => 'yu',
		'я'   => 'ya',
	},
);

my %TO_LAT = ();

my %TO_CYR = ();

#*********************************************************************************************
sub _prep_translit {
	my ($lang) = @_;

	return if ( $PREP{prepared}->{$lang} );

	my $rfw = {};
	my $rbw = {};
	while ( my ( $fw, $bw ) = each %{ $PREP{$lang} } ) {
		$fw = str_encode($fw);
		$bw = str_encode($bw);
		my $lf = length($fw);
		my $lb = length($bw);
		if ( ( $lf == 1 ) and ( $lb == 1 ) ) {
			$rfw->{0}->{ uc($fw) }      = uc($bw);
			$rfw->{0}->{ ucfirst($fw) } = ucfirst($bw);
			$rfw->{0}->{$fw}            = $bw;

			$rbw->{0}->{ uc($bw) }      = uc($fw);
			$rbw->{0}->{ ucfirst($bw) } = ucfirst($fw);
			$rbw->{0}->{$bw}            = $fw;
		} else {
			$rfw->{$lf}->{ uc($fw) }      = uc($bw);
			$rfw->{$lf}->{ ucfirst($fw) } = ucfirst($bw);
			$rfw->{$lf}->{$fw}            = $bw;

			$rbw->{$lb}->{ uc($bw) }      = uc($fw);
			$rbw->{$lb}->{ ucfirst($bw) } = ucfirst($fw);
			$rbw->{$lb}->{$bw}            = $fw;
		}
	} ## end while ( my ( $fw, $bw ) =...

	$TO_LAT{$lang} = [];
	foreach my $ord ( reverse sort { $a <=> $b } keys %{$rfw} ) {
		my $tra = $rfw->{$ord};
		my $fnd = join( '|', keys %{$tra} );
		push( @{ $TO_LAT{$lang} }, [ $fnd, $tra ] );
	}

	$TO_CYR{$lang} = [];
	foreach my $ord ( reverse sort { $a <=> $b } keys %{$rbw} ) {
		my $tra = $rbw->{$ord};
		my $fnd = join( '|', keys %{$tra} );
		push( @{ $TO_CYR{$lang} }, [ $fnd, $tra ] );
	}

	$PREP{prepared}->{$lang} = 1;
} ## end sub _prep_translit

#*********************************************************************************************

=head1 EXPORTS

=over

=item B<trans_cyr_lat($text[, $lang])> - transliterate string

Convert text from cyrillic to latin encoding.

Language may be set if not default one.

	$lat = trans_cyr_lat($string);

=cut

#-----------------------------------------------------------------------
sub trans_cyr_lat {
	my ( $text, $lang ) = @_;

	$lang ||= DEFAULT_LANG();

	_prep_translit($lang);

	$text = str_encode($text);

	foreach my $row ( @{ $TO_LAT{$lang} } ) {
		my ( $fnd, $has ) = @{$row};
		$text =~ s/($row->[0])/$row->[1]->{$1}/ge;
	}
	$text =~ s/[^\x{0}-\x{7f}]+/\?/g;

	return str_decode($text);
}

#*********************************************************************************************

=item B<trans_lat_cyr($text[, $lang])> - reverse transliteration

This function transliterate string from latin encoding to cyrillic one.

Target language may be set if not default one.

	$cyr = trans_lat_cyr("Sam baran", "ru");

=cut

#-----------------------------------------------------------------------
sub trans_lat_cyr {
	my ( $text, $lang ) = @_;

	$lang ||= DEFAULT_LANG();

	_prep_translit($lang);

	$text = str_encode($text);

	$text =~ s/[^\x{0}-\x{7f}]+/\?/g;
	foreach my $row ( @{ $TO_CYR{$lang} } ) {
		my ( $fnd, $has ) = @{$row};
		$text =~ s/($row->[0])/$row->[1]->{$1}/sg;
	}

	return str_decode($text);
}

1;
__END__

=back

=head1 EXAMPLES

None yet

=head1 BUGS

Unknown yet

=head1 TODO

Implement examples and tests.

=head1 SEE ALSO

L<Encode>, L<perlunicode>

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

=cut
