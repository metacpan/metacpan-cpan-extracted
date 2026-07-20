#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/lib/Local/PersonNameData.pm
##----------------------------------------------------------------------------
# Hide it from CPAN
package
    Local::PersonNameData;
use v5.10.1;
use strict;
use warnings;
use utf8;

sub new
{
    return( bless( {}, shift( @_ ) ) );
}

sub error { return; }

sub make_inheritance_tree
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    $locale = "$locale";
    return( ['en-US', 'en', 'und'] ) if( $locale eq 'en-US' );
    return( ['ja-JP', 'ja', 'und'] ) if( $locale eq 'ja-JP' );
    return( [$locale, 'und'] )       if( $locale ne 'und' );
    return( ['und'] );
}


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
        en          => 'en-Latn-US',
        'en-GB'     => 'en-Latn-GB',
        'en-US'     => 'en-Latn-US',
        fr          => 'fr-Latn-FR',
        'fr-FR'     => 'fr-Latn-FR',
        ja          => 'ja-Jpan-JP',
        'ja-JP'     => 'ja-Jpan-JP',
    };
    return unless( exists( $map->{ $args{locale} } ) );
    return({
        locale => $args{locale},
        target => $map->{ $args{locale} },
    });
}

sub person_name_order_locales
{
    my $self = shift( @_ );
    my %args = @_;
    return(
    [
        { name_locale => 'und', name_order => 'givenFirst' },
    ]) if( $args{locale} eq 'en' );
    return(
    [
        { name_locale => 'ja',  name_order => 'surnameFirst' },
        { name_locale => 'zh',  name_order => 'surnameFirst' },
        { name_locale => 'und', name_order => 'givenFirst' },
    ]) if( $args{locale} eq 'ja' );
    return( [] );
}

sub locales_info
{
    my $self = shift( @_ );
    my %args = @_;
    my $values =
    {
        'und:person_name_default_length'    => 'medium',
        'und:person_name_default_formality' => 'formal',
        'en:person_name_default_formality'  => 'informal',
    };
    my $key = "$args{locale}:$args{property}";
    return unless( exists( $values->{ $key } ) );
    return({
        locale   => $args{locale},
        property => $args{property},
        value    => $values->{ $key },
    });
}

sub person_name_derive_order
{
    my $self = shift( @_ );
    my %args = @_;
    if( "$args{name_locale}" =~ /^(?:ja|ko|zh|yue)/ )
    {
        return( 'surnameFirst' );
    }
    return( 'givenFirst' );
}

sub person_name_formats
{
    my $self = shift( @_ );
    my %args = @_;
    my $locale = $args{locale};

    if( $locale eq 'en' )
    {
        return(
        [
            {
                name_index     => 0,
                name_order     => 'givenFirst',
                name_length    => 'long',
                name_usage     => 'referring',
                name_formality => 'formal',
                alt            => undef,
                name_pattern   => '{title} {given} {given2} {surname}',
            },
            {
                name_index     => 1,
                name_order     => 'givenFirst',
                name_length    => 'short',
                name_usage     => 'referring',
                name_formality => 'formal',
                alt            => undef,
                name_pattern   => '{given-initial}{given2-initial} {surname}',
            },
            {
                name_index     => 2,
                name_order     => 'surnameFirst',
                name_length    => 'long',
                name_usage     => 'referring',
                name_formality => 'formal',
                alt            => undef,
                name_pattern   => '{surname} {given}',
            },
            {
                name_index     => 3,
                name_order     => undef,
                name_length    => 'medium',
                name_usage     => 'referring',
                name_formality => 'informal',
                alt            => undef,
                name_pattern   => '{given-informal} {surname}',
            },
        ]);
    }
    elsif( $locale eq 'ja' )
    {
        return(
        [
            {
                name_index     => 0,
                name_order     => 'surnameFirst',
                name_length    => 'long',
                name_usage     => 'referring',
                name_formality => 'formal',
                alt            => undef,
                name_pattern   => '{surname} {given}',
            },
            {
                name_index     => 1,
                name_order     => 'givenFirst',
                name_length    => 'long',
                name_usage     => 'referring',
                name_formality => 'formal',
                alt            => undef,
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
    return unless( $args{locale} eq 'und' );
    return(
    {
        pattern_type  => 'initial',
        pattern_value => '{0}.',
    }) if( $args{pattern_type} eq 'initial' );
    return(
    {
        pattern_type  => 'initialSequence',
        pattern_value => '{0} {1}',
    }) if( $args{pattern_type} eq 'initialSequence' );
    return;
}

sub person_name_space_replacement
{
    my $self = shift( @_ );
    my %args = @_;
    my( $fmt ) = "$args{formatting_locale}" =~ /^([^-]+)/;
    my( $name ) = "$args{name_locale}" =~ /^([^-]+)/;
    my %cjk = map{ $_ => 1 } qw( ja zh yue );
    if( ( $fmt eq $name ||
          ( $cjk{ $fmt } && $cjk{ $name } ) ) &&
            $fmt eq 'ja' )
    {
        return( '' );
    }
    return( '・' ) if( $fmt eq 'ja' );
    return( ' ' );
}

1;

__END__
