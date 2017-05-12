#============================================================= -*-Perl-*-
#
# Template::Plugin::Translit::RU
#
# DESCRIPTION
#   Filter converting cyrillic text into transliterated one.
#
# AUTHOR
#   Igor Lobanov <igor.lobanov@gmail.com>
#
# COPYRIGHT
#   Copyright (C) 2004 Igor Lobanov.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::Translit::RU;
use strict;
use vars qw( $VERSION );
use Template::Plugin;
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision: 0.05 $ =~ /(\d+)\.(\d+)/);

my $DEFAULT_CHARSET = 'koi';

# (en|de)code table
my $tab = {
	koi	=> {
		# {1} => {1}
		single	=> [
			'ÁÂ×ÇÄÅÚÉÊËÌÍÎÏÐÒÓÔÕÆØÙßáâ÷çäåúéêëìíîïðòóôõæøùÿ',
			"abvgdezijklmnoprstuf'y\"ABVGDEZIJKLMNOPRSTUF'Y\""
		],
		# +	=> {2,}
		plural	=> [
			# 0: re with plural-transliterated letters and special cases
			'(ÕÛÞ|Ø[Å£ÀÑ]|Ù[Å£ÀÑÕ]|£|Ö|È|Ã|Þ|Û|Ý|Ü|À|Ñ|õûþ|ø[å³àñ]|ù[å³àñõ]|³|ö|è|ã|þ|û|ý|ü|à|ñ)',
			# 1: table for these letters and cases [0]
			{
				'£'	=> 'yo',
				'³'	=> 'Yo',
				'Ö'	=> 'zh',
				'ö'	=> 'Zh',
				'È'	=> 'kh',
				'è'	=> 'Kh',
				'Ã'	=> 'tc',
				'ã'	=> 'Tc',
				'Þ'	=> 'ch',
				'þ'	=> 'Ch',
				'Û'	=> 'sh',
				'û'	=> 'Sh',
				'Ý'	=> 'shch',
				'ý'	=> 'Shch',
				'Ù'	=> 'y',
				'ù'	=> 'Y',
				'Ü'	=> 'ye',
				'ü'	=> 'Ye',
				'À'	=> 'yu',
				'à'	=> 'Yu',
				'Ñ'	=> 'ya',
				'ñ'	=> 'Ya',
				# {2} => {3} - could not be at the begining of the word
				'ØÅ'	=> 'jie',
				'øå'	=> 'JIE',
				'Ø£'	=> 'jio',
				'ø³'	=> 'JIO',
				'ØÀ'	=> 'jiu',
				'øà'	=> 'JIU',
				'ØÑ'	=> 'jia',
				'øñ'	=> 'JIA',
				'ÙÅ'	=> 'yje',
				'ùå'	=> 'YJE',
				'Ù£'	=> 'yjo',
				'ù³'	=> 'YJO',
				'ÙÀ'	=> 'yju',
				'ùà'	=> 'YJU',
				'ÙÑ'	=> 'yja',
				'ùñ'	=> 'YJA',
				'ÙÕ'	=> 'yiu',
				'ùõ'	=> 'YIU',
				# {3} => {3,5} - could not be at the begining of the word
				'ÕÛÞ'	=> 'uisch',
				'õûþ'	=> 'UISCH',
			},
			# 3: re with special transliterated escapes
			'(uisch|UISCH|shch|Shch|SHCH|tch|TCH|Tch|ji[eoua]|JI[EOUA]|yj[eoua]|yiu|YIU|YJ[EOUA]|yo|zh|kh|tc|ch|sh|ye|yu|ya|Y[Oo]|Z[Hh]|K[Hh]|T[Cc]|C[Hh]|S[Hh]|Y[Ee]|Y[Uu]|Y[Aa])',
			# 4: table for special transliterated escapes [3]
			{
				'shch'	=> 'Ý',
				'SHCH'	=> 'ý',
				'Shch'	=> 'ý',
				'tch'	=> 'ÔÞ',
				'TCH'	=> 'ôþ',
				'Tch'	=> 'ôÞ',
				'jie'	=> 'ØÅ',
				'jio'	=> 'Ø£',
				'jiu'	=> 'ØÀ',
				'jia'	=> 'ØÑ',
				'JIE'	=> 'øå',
				'JIO'	=> 'ø³',
				'JIU'	=> 'øà',
				'JIA'	=> 'øñ',
				'yje'	=> 'ÙÅ',
				'yjo'	=> 'Ù£',
				'yju'	=> 'ÙÀ',
				'yja'	=> 'ÙÑ',
				'yiu'	=> 'ÙÕ',
				'YJE'	=> 'ùå',
				'YJO'	=> 'ù³',
				'YJU'	=> 'ùà',
				'YJA'	=> 'ùñ',
				'YIU'	=> 'ùõ',
				'yo'	=> '£',
				'zh'	=> 'Ö',
				'kh'	=> 'È',
				'tc'	=> 'Ã',
				'ch'	=> 'Þ',
				'sh'	=> 'Û',
				'ye'	=> 'Ü',
				'yu'	=> 'À',
				'ya'	=> 'Ñ',
				'YO'	=> '³',
				'Yo'	=> '³',
				'ZH'	=> 'ö',
				'Zh'	=> 'ö',
				'KH'	=> 'è',
				'Kh'	=> 'è',
				'TC'	=> 'ã',
				'Tc'	=> 'ã',
				'CH'	=> 'þ',
				'Ch'	=> 'þ',
				'SH'	=> 'û',
				'Sh'	=> 'û',
				'YE'	=> 'ü',
				'Ye'	=> 'ü',
				'YU'	=> 'à',
				'Yu'	=> 'à',
				'YA'	=> 'ñ',
				'Ya'	=> 'ñ',
				'uisch'	=> 'ÕÛÞ',
				'UISCH'	=> 'õûþ',
			}
		]
	},
	win	=> {
		# {1} => {1}
		single	=> [
			'àáâãäåçèéêëìíîïðñòóôüûúÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÜÛÚ',
			"abvgdezijklmnoprstuf'y\"ABVGDEZIJKLMNOPRSTUF'Y\""
		],
		# +	=> {2,}
		plural	=> [
			# 0: re with plural-transliterated letters and special cases
			'(óø÷|ü[å¸þÿ]|û[å¸þÿó]|¸|æ|õ|ö|÷|ø|ù|ý|þ|ÿ|ÓØ×|Ü[Å¨Þß]|Û[Å¨ÞßÓ]|¨|Æ|Õ|Ö|×|Ø|Ù|Ý|Þ|ß)',
			# 1: table for these letters and cases [0]
			{
				'¸'	=> 'yo',
				'¨'	=> 'Yo',
				'æ'	=> 'zh',
				'Æ'	=> 'Zh',
				'õ'	=> 'kh',
				'Õ'	=> 'Kh',
				'ö'	=> 'tc',
				'Ö'	=> 'Tc',
				'÷'	=> 'ch',
				'×'	=> 'Ch',
				'ø'	=> 'sh',
				'Ø'	=> 'Sh',
				'ù'	=> 'shch',
				'Ù'	=> 'Shch',
				'û'	=> 'y',
				'Û'	=> 'Y',
				'ý'	=> 'ye',
				'Ý'	=> 'Ye',
				'þ'	=> 'yu',
				'Þ'	=> 'Yu',
				'ÿ'	=> 'ya',
				'ß'	=> 'Ya',
				# {2} => {3} - could not be at the begining of the word
				'üå'	=> 'jie',
				'ÜÅ'	=> 'JIE',
				'ü¸'	=> 'jio',
				'Ü¨'	=> 'JIO',
				'üþ'	=> 'jiu',
				'ÜÞ'	=> 'JIU',
				'üÿ'	=> 'jia',
				'Üß'	=> 'JIA',
				'ûå'	=> 'yje',
				'ÛÅ'	=> 'YJE',
				'û¸'	=> 'yjo',
				'Û¨'	=> 'YJO',
				'ûþ'	=> 'yju',
				'ÛÞ'	=> 'YJU',
				'ûÿ'	=> 'yja',
				'Ûß'	=> 'YJA',
				'ûó'	=> 'yiu',
				'ÛÓ'	=> 'YIU',
				# {3} => {3,5} - could not be at the begining of the word
				'óø÷'	=> 'uisch',
				'ÓØ×'	=> 'UISCH',
			},
			# 3: re with special transliterated escapes
			'(uisch|UISCH|shch|Shch|SHCH|tch|TCH|Tch|ji[eoua]|JI[EOUA]|yj[eoua]|yiu|YIU|YJ[EOUA]|yo|zh|kh|tc|ch|sh|ye|yu|ya|Y[Oo]|Z[Hh]|K[Hh]|T[Cc]|C[Hh]|S[Hh]|Y[Ee]|Y[Uu]|Y[Aa])',
			# 4: table for special transliterated escapes [3]
			{
				'shch'	=> 'ù',
				'SHCH'	=> 'Ù',
				'Shch'	=> 'Ù',
				'tch'	=> 'ò÷',
				'TCH'	=> 'Ò×',
				'Tch'	=> 'Ò÷',
				'jie'	=> 'üå',
				'jio'	=> 'ü¸',
				'jiu'	=> 'üþ',
				'jia'	=> 'üÿ',
				'JIE'	=> 'ÜÅ',
				'JIO'	=> 'Ü¨',
				'JIU'	=> 'ÜÞ',
				'JIA'	=> 'Üß',
				'yje'	=> 'ûå',
				'yjo'	=> 'û¸',
				'yju'	=> 'ûþ',
				'yja'	=> 'ûÿ',
				'yiu'	=> 'ûó',
				'YJE'	=> 'ÛÅ',
				'YJO'	=> 'Û¨',
				'YJU'	=> 'ÛÞ',
				'YJA'	=> 'Ûß',
				'YIU'	=> 'ÛÓ',
				'yo'	=> '¸',
				'zh'	=> 'æ',
				'kh'	=> 'õ',
				'tc'	=> 'ö',
				'ch'	=> '÷',
				'sh'	=> 'ø',
				'ye'	=> 'ý',
				'yu'	=> 'þ',
				'ya'	=> 'ÿ',
				'YO'	=> '¨',
				'Yo'	=> '¨',
				'ZH'	=> 'Æ',
				'Zh'	=> 'Æ',
				'KH'	=> 'Õ',
				'Kh'	=> 'Õ',
				'TC'	=> 'Ö',
				'Tc'	=> 'Ö',
				'CH'	=> '×',
				'Ch'	=> '×',
				'SH'	=> 'Ø',
				'Sh'	=> 'Ø',
				'YE'	=> 'Ý',
				'Ye'	=> 'Ý',
				'YU'	=> 'Þ',
				'Yu'	=> 'Þ',
				'YA'	=> 'ß',
				'Ya'	=> 'ß',
				'uisch'	=> 'óø÷',
				'UISCH'	=> 'ÓØ×',
			}
		]
	}
};

# define aliases
$tab->{'windows-1251'} = $tab->{'cp1251'} = $tab->{'win'};
$tab->{'koi8-r'} = $tab->{'koi8r'} = $tab->{'koi8'} = $tab->{'koi'};

sub new {
	my ( $class, $context, @params ) = @_;

	# init future object
	my $self = {
		_CONTEXT	=> $context,
		_PARAMS		=> { map { $_ => 1 } @params },
	};

	# check translit flag and define translit filter factory
	if ( $self->{_PARAMS}->{translit} ) {
		$context->define_filter( 'translit', [ \&translit_filter_factory, 1 ] );
	}

	# check detranslit flag and define detranslit filter factory
	if ( $self->{_PARAMS}->{detranslit} ) {
		$context->define_filter( 'detranslit', [ \&detranslit_filter_factory, 1 ] );
	}

	bless $self, $class;
}

sub translit_filter_factory {
    my ( $context, $charset ) = @_;
    return sub {
		my $text = shift;
		Template::Plugin::Translit::RU->translit( $text, $charset );
    }
}

sub detranslit_filter_factory {
    my ( $context, $charset ) = @_;
    return sub {
		my $text = shift;
		Template::Plugin::Translit::RU->detranslit( $text, $charset );
    }
}

sub translit {
	my ( $self, $text, $charset ) = @_;
	$charset ||= $DEFAULT_CHARSET;
	# replace plurals (most slow place)
	$text =~ s/$tab->{$charset}->{plural}->[0]/$tab->{$charset}->{plural}->[1]->{$1}/sg;
	# replace singles
	eval "\$text =~ tr/$tab->{$charset}->{single}->[0]/$tab->{$charset}->{single}->[1]/";
	return $text;
}

sub detranslit {
	my ( $self, $text, $charset ) = @_;
	$charset ||= $DEFAULT_CHARSET;
	# replace plurals (most slow place)
	$text =~ s/$tab->{$charset}->{plural}->[2]/$tab->{$charset}->{plural}->[3]->{$1}/sge;
	# replace singles
	eval "\$text =~ tr/$tab->{$charset}->{single}->[1]/$tab->{$charset}->{single}->[0]/";
	return $text;
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Translit::RU - Filter converting cyrillic
text into transliterated one and back.

=head1 SYNOPSIS

Use as filters.

 [% USE Translit::RU 'translit' 'detranslit' %]
 [% FILTER translit( 'koi' ) %]
 ...
 This text would stay unchanged because it is not cyrillic.
 ...
 [% END %]

Use as object. First argument - text for conversion. Second
optional argument - charset ('koi' is default).

 [% USE plTranslit = Translit::RU %]
 [% plTranslit.translit( 'without cyrillic text is useless' ) %]
 [% plTranslit.detranslit( 'kirilitca', 'win' ) %]

=head1 DESCRIPTION

Template::Plugin::Translit::RU is Template Toolkit filter
which allows to convert cyrillic text into transliterated
latin text. Currently two most popular charsets are
supported - B<koi8-r> and B<windows-1251>. Also back
conversion supported.

=head1 SUPPORTED CHARSETS

Currently Template::Plugin::Translit::RU supports 2 main
cyrillic charsets B<koi8-r> and B<windows-1251>.

Charset arguments could take such values:

=over

=item * 'koi', 'koi8-r', 'koi8r', 'koi8' - for B<koi8-r>
charset.

=item * 'win', 'windows-1251', 'cp1251' - for
B<windows-1251> charset.

=back

=head1 KNOWN PROBLEMS

In some cases there is no exact correspondence between
source cyrillic word and result of
B<cyrillic>->B<translit>->B<cyrillic> conversion
(B<CTC>-conversion). Although one of the aims of this module
is to find such correspondence, this is difficult without
making transliterated text bad understandable. Currently 1
main problem is known:

=over

=item * Case loss while conversion of hard and soft signs
(UPPER source after B<CTC> become lower). This could take
place if you make B<CTC>-conversion with UPPER case words.
Fortunately there are no words which starts with signs.

=back

=head1 SEE ALSO

L<Template|Template>

=head1 AUTHOR

Igor Lobanov, E<lt>liol@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Igor Lobanov. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
