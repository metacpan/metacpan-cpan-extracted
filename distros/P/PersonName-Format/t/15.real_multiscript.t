#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/15.real_multiscript.t
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
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

BEGIN
{
    use_ok( 'PersonName::Format' )             || BAIL_OUT( 'Unable to load PersonName::Format' );
    use_ok( 'PersonName::Format::SimpleName' ) || BAIL_OUT( 'Unable to load PersonName::Format::SimpleName' );
};

my @cases =
(
    {
        label       => 'Russian Cyrillic',
        formatter   => 'ru-RU',
        name_locale => 'ru-RU',
        given       => 'Иван',
        surname     => 'Петров',
        script      => 'Cyrl',
        language    => 'ru',
        result      => 'Иван Петров',
    },
    {
        label       => 'Arabic',
        formatter   => 'ar-EG',
        name_locale => 'ar-EG',
        given       => 'محمد',
        surname     => 'علي',
        script      => 'Arab',
        language    => 'ar',
        result      => 'محمد علي',
    },
    {
        label       => 'Persian in Arabic script',
        formatter   => 'fa-IR',
        name_locale => 'fa-IR',
        given       => 'حسین',
        surname     => 'رضایی',
        script      => 'Arab',
        language    => 'fa',
        result      => 'حسین رضایی',
    },
    {
        label       => 'Hindi Devanagari',
        formatter   => 'hi-IN',
        name_locale => 'hi-IN',
        given       => 'अमित',
        surname     => 'शर्मा',
        script      => 'Deva',
        language    => 'hi',
        result      => 'अ॰ शर्मा',
    },
    {
        label       => 'Chinese Han',
        formatter   => 'zh-CN',
        name_locale => 'zh-CN',
        given       => '小明',
        surname     => '王',
        script      => 'Hani',
        language    => 'zh',
        result      => '王小明',
    },
    {
        label       => 'Japanese Han',
        formatter   => 'ja-JP',
        name_locale => 'ja-JP',
        given       => '駿',
        surname     => '宮崎',
        script      => 'Hani',
        language    => 'ja',
        result      => '宮崎駿',
    },
    {
        label       => 'Korean Hangul',
        formatter   => 'ko-KR',
        name_locale => 'ko-KR',
        given       => '민준',
        surname     => '김',
        script      => 'Hang',
        language    => 'ko',
        result      => '김민준',
    },
);

foreach my $case ( @cases )
{
    subtest $case->{label} => sub
    {
        my $formatter = PersonName::Format->new(
            $case->{formatter},
            length    => 'medium',
            usage     => 'referring',
            formality => 'formal',
        );
        isa_ok( $formatter, 'PersonName::Format' );

        my $name = PersonName::Format::SimpleName->new(
            given       => $case->{given},
            surname     => $case->{surname},
            name_locale => $case->{name_locale},
        );
        isa_ok( $name, 'PersonName::Format::SimpleName' );

        my $context = $formatter->_name_context( $name );
        ok( defined( $context ), 'Derived the complete formatting context' ) ||
            diag( $formatter->error );
        is( $context->{name_script}, $case->{script}, 'Detected expected script' );
        is( $context->{name_base_language}, $case->{language}, 'Preserved expected name language' );
        is( $formatter->format( $name ), $case->{result}, 'Produced expected CLDR result' );
    };
}

done_testing();

__END__
