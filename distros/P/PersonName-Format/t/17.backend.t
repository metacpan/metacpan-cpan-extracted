#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/17.backend.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use utf8;
    use Test::More;
    use PersonName::Format;
    use PersonName::Format::PP ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'PersonName::Format' )     || BAIL_OUT( 'Unable to load PersonName::Format' );
    use_ok( 'PersonName::Format::PP' ) || BAIL_OUT( 'Unable to load PersonName::Format::PP' );
};

my @cases =
(
    [ 'Latin',                  'Einstein',           'Albert',      'Latn' ],
    [ 'Cyrillic',               'Петров',             'Иван',        'Cyrl' ],
    [ 'Arabic',                 'رضایی',             'حسین',         'Arab' ],
    [ 'Devanagari',             'शर्मा',                'अमित',         'Deva' ],
    [ 'Han',                    '宮崎',               '駿',           'Hani' ],
    [ 'Katakana',               'アインシュタイン',     'アルベルト',    'Kana' ],
    [ 'Hiragana',               'やまだ',             'たろう',        'Hira' ],
    [ 'Hangul',                 '김',                '민준',          'Hang' ],
    [ 'Common first',           " -- Einstein",     'Albert',       'Latn' ],
    [ 'Inherited first',        "\x{0301}Einstein", 'Albert',       'Latn' ],
    [ 'Surname priority',       'Петров',           'Albert',       'Cyrl' ],
    [ 'Given fallback',         undef,              'Albert',       'Latn' ],
    [ 'No significant script',  '---',              '123',          'Zzzz' ],
);

foreach my $case ( @cases )
{
    my( $label, $surname, $given, $expected ) = @$case;
    my $pp = PersonName::Format::PP::_get_name_script(
        $surname,
        $given,
    );
    my $selected = PersonName::Format::_get_name_script(
        $surname,
        $given,
    );

    is( $pp, $expected, "${label}: pure-Perl backend" );
    is( $selected, $pp, "${label}: selected backend matches pure Perl" );
}

if( $PersonName::Format::IsPurePerl )
{
    pass( 'Pure-Perl backend selected because XS was unavailable or forced' );
}
else
{
    pass( 'XS backend loaded' );
}

done_testing();

__END__
