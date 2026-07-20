#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/12.locale_derivation.t
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
    use_ok( 'PersonName::Format' ) || BAIL_OUT( 'Unable to load PersonName::Format' );
};

{
    # Hide it from CPAN
    package
        Local::DerivedData;

    sub new { return( bless( {}, shift ) ); }
    sub error { return; }

    sub likely_subtag
    {
        my $self = shift( @_ );
        my %args = @_;
        my $map =
        {
            und         => 'en-Latn-US',
            'und-Latn'  => 'en-Latn-US',
            'und-Hani'  => 'zh-Hani-CN',
            'und-Kana'  => 'ja-Kana-JP',
            'und-Hang'  => 'ko-Hang-KR',
            en          => 'en-Latn-US',
            de          => 'de-Latn-DE',
            'de-CH'     => 'de-Latn-CH',
            ja          => 'ja-Jpan-JP',
            'ja-JP'     => 'ja-Jpan-JP',
            zh          => 'zh-Hans-CN',
        };
        return unless( exists( $map->{ $args{locale} } ) );
        return({ locale => $args{locale}, target => $map->{ $args{locale} } });
    }

    sub make_inheritance_tree
    {
        my $self = shift( @_ );
        my $locale = "$_[0]";
        return( ['ja-JP', 'ja', 'und'] ) if( $locale =~ /^ja(?:-|$)/ );
        return( ['de-Latn-CH', 'de-CH', 'de', 'und'] ) if( $locale =~ /^de-Latn-CH$/ );
        return( ['de-Kana-CH', 'de-CH', 'de', 'und'] ) if( $locale =~ /^de-Kana-CH$/ );
        return( ['de-CH', 'de', 'und'] ) if( $locale =~ /^de(?:-|$)/ );
        return( ['zh-Hani', 'zh', 'und'] ) if( $locale =~ /^zh-Hani$/ );
        return( ['zh-Hani-CN', 'zh-Hani', 'zh', 'und'] ) if( $locale =~ /^zh-Hani-CN$/ );
        return( ['en-Latn-US', 'en-US', 'en', 'und'] ) if( $locale =~ /^en(?:-|$)/ );
        return( [$locale, 'und'] );
    }

    sub locales_info
    {
        my $self = shift( @_ );
        my %args = @_;
        return({ value => 'medium' })
            if( $args{property} eq 'person_name_default_length' );
        return({ value => 'formal' })
            if( $args{property} eq 'person_name_default_formality' );
        return;
    }

    sub person_name_order_locales
    {
        my $self = shift( @_ );
        my %args = @_;
        return(
        [
            { name_locale => 'und', name_order => 'givenFirst' },
            { name_locale => 'ja', name_order => 'surnameFirst' },
            { name_locale => 'zh', name_order => 'surnameFirst' },
        ]) if( $args{locale} eq 'ja' );
        return(
        [
            { name_locale => 'und', name_order => 'givenFirst' },
        ]) if( $args{locale} eq 'de' || $args{locale} eq 'en' );
        return( [] );
    }

    sub person_name_derive_order
    {
        my $self = shift( @_ );
        my %args = @_;
        my $fmt = "$args{formatting_locale}";
        my $name = "$args{name_locale}";
        return( 'surnameFirst' ) if( $fmt =~ /^ja/ && $name =~ /^(?:ja|zh)/ );
        return( 'givenFirst' );
    }

    sub person_name_formats
    {
        my $self = shift( @_ );
        my %args = @_;
        my $locale = $args{locale};

        if( $locale eq 'ja' )
        {
            return(
            [
                {
                    name_index     => 0,
                    name_order     => 'surnameFirst',
                    name_length    => 'medium',
                    name_usage     => 'referring',
                    name_formality => 'formal',
                    name_pattern   => '{surname} {given}',
                },
                {
                    name_index     => 1,
                    name_order     => 'givenFirst',
                    name_length    => 'medium',
                    name_usage     => 'referring',
                    name_formality => 'formal',
                    name_pattern   => '{given} {surname}',
                },
            ]);
        }
        if( $locale eq 'de' || $locale eq 'en' )
        {
            return(
            [
                {
                    name_index     => 0,
                    name_order     => 'givenFirst',
                    name_length    => 'medium',
                    name_usage     => 'referring',
                    name_formality => 'formal',
                    name_pattern   => '{given} {surname}',
                },
            ]);
        }
        return( [] );
    }

    sub person_name_initial_pattern
    {
        my $self = shift( @_ );
        my %args = @_;
        return({ pattern_value => '{0}.' })    if( $args{pattern_type} eq 'initial' );
        return({ pattern_value => '{0} {1}' }) if( $args{pattern_type} eq 'initialSequence' );
        return;
    }

    sub person_name_space_replacement
    {
        my $self = shift( @_ );
        my %args = @_;
        my( $fmt ) = "$args{formatting_locale}" =~ /^([a-z]{2,3})/;
        my( $name ) = "$args{name_locale}" =~ /^([a-z]{2,3})/;
        my %cjk = map{ $_ => 1 } qw( ja zh yue );
        if( $fmt eq 'ja' &&
            ( $fmt eq $name || ( $cjk{$fmt} && $cjk{$name} ) ) )
        {
            return( '' );
        }
        return( '・' ) if( $fmt eq 'ja' );
        return( ' ' );
    }
}

my $data = Local::DerivedData->new;

my $ja = PersonName::Format->new(
    'ja-JP',
    data => $data,
);

is(
    $ja->format(
        given   => '駿',
        surname => '宮崎',
    ),
    '宮崎駿',
    'Name script and locale are inferred for a Japanese name',
);

is(
    $ja->format(
        given      => 'Albert',
        surname    => 'Einstein',
        nameLocale => 'de-CH',
    ),
    'Albert Einstein',
    'Latin name switches from Japanese to German formatting data',
);

is(
    $ja->format(
        given      => 'アルベルト',
        surname    => 'アインシュタイン',
        nameLocale => 'de-CH',
    ),
    'アルベルト・アインシュタイン',
    'Katakana German name remains under Japanese formatting and uses foreign spacing',
);

my $context = $ja->_name_context(
    PersonName::Format::SimpleName->new(
        given   => '駿',
        surname => '宮崎',
    ),
);

is( $context->{name_script}, 'Hani', 'Detected Japanese name script is Hani' );
is( "$context->{name_locale}", 'zh-Hani', 'Missing name locale is inferred from und-Hani' );
is( "$context->{effective_formatting_locale}", 'ja-JP', 'Hani matches Jpan formatting script' );

done_testing();

__END__
