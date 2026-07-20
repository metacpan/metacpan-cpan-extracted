##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/FieldModifier.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/16
## Modified 2026/07/16
## All rights reserved
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package PersonName::Format::FieldModifier;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'PersonName::Format' );
    use parent qw( PersonName::Format::Generic );
    use vars qw( $VERSION );
    use Locale::Unicode;
    use PersonName::Format::PP ();
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    if( !defined( $locale ) || !length( "$locale" ) )
    {
        return( $self->error( "No modifier locale was provided." ) );
    }
    my $args = $self->_get_args_as_hash( @_ );
    # $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init(
        debug => delete( $args->{debug} ),
        fatal => delete( $args->{fatal} ),
    ) || return( $self->pass_error );
    my $locale_object = Locale::Unicode->new( $locale ) ||
        return( $self->pass_error( Locale::Unicode->error ) );
    $self->{locale} = $locale_object;

    my $data = delete( $args->{data} );
    my $initial_pattern = delete( $args->{initial_pattern} );
    my $initial_sequence_pattern = delete( $args->{initial_sequence_pattern} );

    if( defined( $data ) )
    {
        unless( Scalar::Util::blessed( $data ) &&
                $self->_can( $data, [qw( make_inheritance_tree person_name_initial_pattern )] ) )
        {
            return( $self->error( "The data option must provide the Locale::Unicode::Data initial-pattern contract." ) );
        }
    }
    elsif( !defined( $initial_pattern ) ||
           !defined( $initial_sequence_pattern ) )
    {
        local $@;
        eval{ require Locale::Unicode::Data; };
        return( $self->error( "Unable to load Locale::Unicode::Data: ", ( $@ || 'unknown error' ) ) ) if( $@ );
        $data = Locale::Unicode::Data->new ||
            return( $self->pass_error( Locale::Unicode::Data->error ) );
    }
    $self->{data} = $data;
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown FieldModifier option '", ( keys( %$args ) )[0], "'." ) );
    }

    if( !defined( $initial_pattern ) ||
        !defined( $initial_sequence_pattern ) )
    {
        my $patterns = $self->_load_initial_patterns ||
            return( $self->pass_error );
        if( !defined( $initial_pattern ) )
        {
            $initial_pattern = $patterns->{initial};
        }
        if( !defined( $initial_sequence_pattern ) )
        {
            $initial_sequence_pattern = $patterns->{initialSequence};
        }
    }

    unless( $self->_valid_initial_pattern( $initial_pattern ) )
    {
        return( $self->error( "The initial pattern must contain exactly one '{0}' placeholder." ) );
    }
    unless( $self->_valid_initial_sequence_pattern( $initial_sequence_pattern ) )
    {
        return( $self->error( "The initial sequence pattern must contain exactly one '{0}' and one '{1}' placeholder." ) );
    }
    $self->{initial_pattern} = "$initial_pattern";
    $self->{initial_sequence_pattern} = "$initial_sequence_pattern";
    return( $self );
}

sub data
{
    return( shift->{data} );
}

sub initial_pattern
{
    return( shift->_set_get_scalar( 'initial_pattern', @_ ) );
}

sub initial_sequence_pattern
{
    return( shift->_set_get_scalar( 'initial_sequence_pattern', @_ ) );
}

sub locale
{
    return( shift->{locale} );
}

sub resolve
{
    my $self     = shift( @_ );
    my $modifier = shift( @_ );
    my $value    = shift( @_ );
    my $field    = shift( @_ );
    my $token    = shift( @_ );
    my $name     = shift( @_ );
    if( !defined( $modifier ) || !length( $modifier ) )
    {
        return( $self->error( "No field modifier was provided to resolve()." ) );
    }
    return if( !defined( $value ) );

    if( $modifier eq 'allCaps' )
    {
        return( uc( $value ) );
    }
    elsif( $modifier eq 'initialCap' )
    {
        return( $self->_initial_cap( $value ) );
    }
    elsif( $modifier eq 'initial' )
    {
        my $retain = 0;
        if( ref( $token ) eq 'HASH' &&
            ref( $token->{modifiers} ) eq 'ARRAY' )
        {
            $retain = scalar( grep{ $_ eq 'retain' } @{$token->{modifiers}} ) ? 1 : 0;
        }
        return( $self->_initial( $value, $retain ) );
    }
    elsif( $modifier eq 'monogram' )
    {
        return( $self->_first_grapheme( $value ) );
    }
    elsif( $modifier eq 'retain' ||
           $modifier eq 'genitive' ||
           $modifier eq 'vocative' )
    {
        return( $value );
    }
    return( $self->error( "Unsupported person-name field modifier '${modifier}'." ) );
}

sub resolver
{
    my $self = shift( @_ );
    return( sub
    {
        return( $self->resolve( @_ ) );
    });
}

sub _first_grapheme
{
    my $self  = shift( @_ );
    my $value = shift( @_ );
    if( defined( &PersonName::Format::_first_grapheme ) )
    {
        return( PersonName::Format::_first_grapheme( $value ) );
    }
    return( PersonName::Format::PP::_first_grapheme( $value ) );
}

sub _format_pattern
{
    my $self    = shift( @_ );
    my $pattern = shift( @_ );
    my $values  = shift( @_ );
    my $result  = "$pattern";
    $result =~ s/\{([01])\}/$values->[$1]/ge;
    return( $result );
}

sub _initial
{
    my $self   = shift( @_ );
    my $value  = shift( @_ );
    my $retain = shift( @_ );
    return( '' ) if( !defined( $value ) || !length( $value ) );
    my $initials   = [];
    my $separators = [];
    my $separator  = '';
    my $in_word    = 0;

    while( $value =~ /(\X)/gs )
    {
        my $grapheme = $1;
        if( $grapheme =~ /\p{L}/ )
        {
            if( !$in_word )
            {
                push( @$separators, $separator ) if( @$initials );
                push( @$initials, $grapheme );
                $separator = '';
            }
            $in_word = 1;
        }
        else
        {
            $in_word = 0;
            $separator .= $grapheme;
        }
    }
    return( '' ) unless( @$initials );

    my $result = $self->_format_pattern(
        $self->{initial_pattern},
        [$initials->[0]],
    );
    for( my $i = 1; $i < scalar( @$initials ); $i++ )
    {
        my $current = $self->_format_pattern(
            $self->{initial_pattern},
            [$initials->[$i]],
        );
        if( $retain )
        {
            my $between = $separators->[$i - 1] // '';
            $between =~ s/\s+/ /gs;
            $result .= $between . $current;
        }
        else
        {
            $result = $self->_format_pattern(
                $self->{initial_sequence_pattern},
                [$result, $current],
            );
        }
    }
    return( $result );
}

sub _initial_cap
{
    my $self  = shift( @_ );
    my $value = shift( @_ );
    return( '' ) if( !defined( $value ) || !length( $value ) );
    my $first = $self->_first_grapheme( $value );
    return( $value ) unless( length( $first ) );
    return( uc( $first ) . substr( $value, length( $first ) ) );
}

sub _load_initial_patterns
{
    my $self = shift( @_ );
    my $tree = $self->{data}->make_inheritance_tree( $self->{locale} ) ||
        return( $self->pass_error( $self->{data}->error ) );
    my $patterns = {};

    foreach my $locale ( @$tree )
    {
        foreach my $type ( qw( initial initialSequence ) )
        {
            next if( exists( $patterns->{ $type } ) );
            my $ref = $self->{data}->person_name_initial_pattern(
                locale       => $locale,
                pattern_type => $type,
            );
            if( !defined( $ref ) )
            {
                if( $self->{data}->error )
                {
                    return( $self->pass_error( $self->{data}->error ) );
                }
                next;
            }
            if( exists( $ref->{pattern_value} ) &&
                defined( $ref->{pattern_value} ) )
            {
                $patterns->{ $type } = $ref->{pattern_value};
            }
        }
        if( exists( $patterns->{initial} ) &&
            exists( $patterns->{initialSequence} ) )
        {
            last;
        }
    }

    unless( exists( $patterns->{initial} ) &&
            exists( $patterns->{initialSequence} ) )
    {
        return( $self->error( "Unable to find both initial and initialSequence patterns for locale '", $self->{locale}, "'." ) );
    }
    return( $patterns );
}

sub _valid_initial_pattern
{
    my $self = shift( @_ );
    my $pattern = shift( @_ );
    return(0) if( !defined( $pattern ) || ref( $pattern ) );
    my @zero  = "$pattern" =~ /\{0\}/g;
    my @other = "$pattern" =~ /\{(?!0\})[^}]*\}/g;
    return( scalar( @zero ) == 1 && !@other );
}

sub _valid_initial_sequence_pattern
{
    my $self = shift( @_ );
    my $pattern = shift( @_ );
    return(0) if( !defined( $pattern ) || ref( $pattern ) );
    my @zero = "$pattern" =~ /\{0\}/g;
    my @one = "$pattern" =~ /\{1\}/g;
    my @other = "$pattern" =~ /\{(?![01]\})[^}]*\}/g;
    return( scalar( @zero ) == 1 &&
            scalar( @one ) == 1 &&
            !@other );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::FieldModifier - Default CLDR person-name field modifiers

=head1 SYNOPSIS

    my $modifier = PersonName::Format::FieldModifier->new(
        'en-GB',
        data => $cldr,
    );

    my $result = $pattern->format(
        $name,
        modifier_resolver => $modifier,
    );

=head1 DESCRIPTION

This class provides the default implementation of the CLDR C<allCaps>, C<initialCap>, C<initial>, C<monogram>, and C<retain> modifiers. C<genitive> and C<vocative> are no-op fallbacks when the name object has not consumed them.

The locale-specific C<initial> and C<initialSequence> patterns are loaded from L<Locale::Unicode::Data> through the locale inheritance tree. Explicit patterns may be supplied for isolated tests or specialised callers.

The implementation is pure Perl and compatible with Perl v5.10.1. Grapheme selection uses Perl's C<\X>. Locale-sensitive word breaking and casing may be replaced later by optional XS primitives without changing this API.

=head1 METHODS

=head2 data

Returns the L<Locale::Unicode::Data> provider.

=head2 initial_pattern

Returns the pattern used to decorate one initial.

=head2 initial_sequence_pattern

Returns the pattern used to join a sequence of formatted initials.

=head2 locale

Returns the L<Locale::Unicode> locale object.

=head2 resolve

Applies one supported modifier. Its arguments match the resolver callback contract used by L<PersonName::Format::Pattern>.

=head2 resolver

Returns a callback suitable for C<modifier_resolver>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
