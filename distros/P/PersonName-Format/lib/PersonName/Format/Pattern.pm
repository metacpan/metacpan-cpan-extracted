##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/Pattern.pm
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
package PersonName::Format::Pattern;
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
    use PersonName::Format::FieldModifier;
    use PersonName::Format::Name;
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

my $FIELDS = {};
@$FIELDS{ qw(
    title
    given
    given2
    surname
    surname2
    generation
    credentials
) } = (1) x 7;

my $MODIFIERS = {};
@$MODIFIERS{ qw(
    informal
    prefix
    core
    initial
    monogram
    allCaps
    initialCap
    retain
    genitive
    vocative
) } = (1) x 10;

sub init
{
    my $self    = shift( @_ );
    my $pattern = shift( @_ );
    if( !defined( $pattern ) )
    {
        return( $self->error( "No person-name pattern was provided." ) );
    }
    if( ref( $pattern ) )
    {
        return( $self->error( "A person-name pattern must be a scalar value." ) );
    }
    my $args = $self->_get_args_as_hash( @_ );
    # $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init(
        debug => delete( $args->{debug} ),
        fatal => delete( $args->{fatal} ),
    ) || return( $self->pass_error );
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown Pattern option '", ( keys( %$args ) )[0], "'." ) );
    }
    $self->{pattern} = "$pattern";
    $self->{tokens} = $self->_parse( "$pattern" ) ||
        return( $self->pass_error );
    return( $self );
}

sub format
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    unless( Scalar::Util::blessed( $name ) &&
            PersonName::Format::Name->implements_name_contract( $name ) )
    {
        return( $self->error( "No name object was provided to format()." ) );
    }
    my $resolver = delete( $args->{modifier_resolver} );
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown format option '", ( keys( %$args ) )[0], "'." ) );
    }
    $name = $self->_prepare_name( $name );

    my $result                   = '';
    my $seen_leading_field       = 0;
    my $seen_empty_leading_field = 0;
    my $seen_empty_field         = 0;
    my $text_before              = '';
    my $text_after               = '';

    foreach my $token ( @{$self->{tokens}} )
    {
        if( $token->{type} eq 'literal' )
        {
            if( $seen_empty_leading_field )
            {
                next;
            }
            elsif( $seen_empty_field )
            {
                $text_after .= $token->{value};
            }
            else
            {
                $text_before .= $token->{value};
            }
            next;
        }

        my $field_text = $self->_field_value( $name, $token, $resolver );
        return( $self->pass_error ) if( !defined( $field_text ) && $self->error );
        if( !defined( $field_text ) ||
            !length( $field_text ) )
        {
            if( !$seen_leading_field )
            {
                $seen_empty_leading_field = 1;
                $text_before = '';
            }
            else
            {
                $seen_empty_field = 1;
                $text_after = '';
            }
        }
        else
        {
            $seen_leading_field = 1;
            $seen_empty_leading_field = 0;
            if( $seen_empty_field )
            {
                $result .= $self->_coalesce( $text_before, $text_after );
                $text_before = '';
                $text_after  = '';
                $result .= $field_text;
                $seen_empty_field = 0;
            }
            else
            {
                $result .= $text_before;
                $text_before = '';
                $result .= $field_text;
            }
        }
    }
    $result .= $text_before unless( $seen_empty_field );
    return( $result );
}

sub format_to_parts
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    unless( Scalar::Util::blessed( $name ) &&
            PersonName::Format::Name->implements_name_contract( $name ) )
    {
        return( $self->error( "No name object was provided to format_to_parts()." ) );
    }
    my $resolver = delete( $args->{modifier_resolver} );
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown format_to_parts option '", ( keys( %$args ) )[0], "'." ) );
    }
    $name = $self->_prepare_name( $name );

    my $parts = [];
    my $seen_leading_field       = 0;
    my $seen_empty_leading_field = 0;
    my $seen_empty_field         = 0;
    my $text_before              = '';
    my $text_after               = '';

    foreach my $token ( @{$self->{tokens}} )
    {
        if( $token->{type} eq 'literal' )
        {
            if( $seen_empty_leading_field )
            {
                next;
            }
            elsif( $seen_empty_field )
            {
                $text_after .= $token->{value};
            }
            else
            {
                $text_before .= $token->{value};
            }
            next;
        }

        my $field_text = $self->_field_value( $name, $token, $resolver );
        return( $self->pass_error ) if( !defined( $field_text ) && $self->error );

        if( !defined( $field_text ) ||
            !length( $field_text ) )
        {
            if( !$seen_leading_field )
            {
                $seen_empty_leading_field = 1;
                $text_before              = '';
            }
            else
            {
                $seen_empty_field = 1;
                $text_after       = '';
            }
            next;
        }

        $seen_leading_field      = 1;
        $seen_empty_leading_field = 0;

        if( $seen_empty_field )
        {
            my $literal = $self->_coalesce( $text_before, $text_after );
            $self->_append_part( $parts, 'literal', $literal );
            $text_before      = '';
            $text_after       = '';
            $seen_empty_field = 0;
        }
        else
        {
            $self->_append_part( $parts, 'literal', $text_before );
            $text_before = '';
        }

        $self->_append_part(
            $parts,
            $token->{source},
            $field_text,
            $token,
        );
    }

    unless( $seen_empty_field )
    {
        $self->_append_part( $parts, 'literal', $text_before );
    }
    return( $parts );
}

sub formatToParts
{
    return( shift->format_to_parts( @_ ) );
}

sub num_empty_fields
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $resolver = delete( $args->{modifier_resolver} );
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown num_empty_fields option '", ( keys( %$args ) )[0], "'." ) );
    }
    unless( Scalar::Util::blessed( $name ) &&
            PersonName::Format::Name->implements_name_contract( $name ) )
    {
        return( $self->error( "No valid name object was provided." ) );
    }
    $name = $self->_prepare_name( $name );
    my $count = 0;
    foreach my $token ( @{$self->{tokens}} )
    {
        next unless( $token->{type} eq 'field' );
        my $value = $self->_field_value( $name, $token, $resolver );
        return( $self->pass_error ) if( !defined( $value ) && $self->error );
        $count++ if( !defined( $value ) || !length( $value ) );
    }
    return( $count );
}

sub num_populated_fields
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    my $resolver = delete( $args->{modifier_resolver} );
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown num_populated_fields option '", ( keys( %$args ) )[0], "'." ) );
    }
    unless( Scalar::Util::blessed( $name ) &&
            PersonName::Format::Name->implements_name_contract( $name ) )
    {
        return( $self->error( "No valid name object was provided." ) );
    }
    $name = $self->_prepare_name( $name );
    my $count = 0;
    foreach my $token ( @{$self->{tokens}} )
    {
        next unless( $token->{type} eq 'field' );
        my $value = $self->_field_value( $name, $token, $resolver );
        return( $self->pass_error ) if( !defined( $value ) && $self->error );
        $count++ if( defined( $value ) && length( $value ) );
    }
    return( $count );
}

sub pattern
{
    return( shift->_set_get_scalar( 'pattern', @_ ) );
}

sub select_best
{
    my $self = shift( @_ );
    my $patterns = shift( @_ );
    my $name = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    unless( ref( $patterns ) eq 'ARRAY' && @$patterns )
    {
        return( $self->error( "Patterns must be provided as an array reference." ) );
    }
    my $best;
    my $best_populated = -1;
    my $best_empty;

    foreach my $pattern ( @$patterns )
    {
        $pattern = __PACKAGE__->new( $pattern ) unless( Scalar::Util::blessed( $pattern ) );
        return( $self->pass_error( __PACKAGE__->error ) ) unless( defined( $pattern ) );
        unless( $pattern->isa( __PACKAGE__ ) )
        {
            return( $self->error( "Pattern list contains an unsupported object." ) );
        }
        my $populated = $pattern->num_populated_fields( $name, %$args );
        return( $self->pass_error( $pattern->error ) ) unless( defined( $populated ) );
        my $empty = $pattern->num_empty_fields( $name, %$args );
        return( $self->pass_error( $pattern->error ) ) unless( defined( $empty ) );

        if( !defined( $best ) ||
            $populated > $best_populated ||
            ( $populated == $best_populated && $empty < $best_empty ) ||
            ( $populated == $best_populated && $empty == $best_empty &&
              $pattern->pattern lt $best->pattern ) )
        {
            $best = $pattern;
            $best_populated = $populated;
            $best_empty = $empty;
        }
    }
    return( $best );
}

sub tokens
{
    my $self = shift( @_ );
    my $copy = [];
    foreach my $token ( @{$self->{tokens}} )
    {
        my $item = {%$token};
        if( exists( $token->{modifiers} ) )
        {
            $item->{modifiers} = [@{$token->{modifiers}}];
        }
        push( @$copy, $item );
    }
    return( $copy );
}

sub _append_part
{
    my $self  = shift( @_ );
    my $parts = shift( @_ );
    my $type  = shift( @_ );
    my $value = shift( @_ );
    my $token = shift( @_ );
    return if( !defined( $value ) || !length( $value ) );

    if( $type eq 'literal' &&
        @$parts &&
        $parts->[-1]->{type} eq 'literal' )
    {
        $parts->[-1]->{value} .= $value;
        return( $parts->[-1] );
    }

    my $part =
    {
        type  => $type,
        value => $value,
    };

    if( defined( $token ) )
    {
        $part->{field} = $token->{field};
        if( @{$token->{modifiers}} )
        {
            $part->{modifiers} = [@{$token->{modifiers}}];
        }
    }

    push( @$parts, $part );
    return( $part );
}

sub _coalesce
{
    my $self   = shift( @_ );
    my $before = shift( @_ ) // '';
    my $after  = shift( @_ ) // '';

    # Remove punctuation immediately preceding the omitted field, stopping at the
    # closest whitespace character or the preceding populated field.
    $before =~ s/\S+$//;

    # Remove punctuation immediately following the omitted field, stopping at the
    # closest whitespace character or the following populated field.
    $after =~ s/^\S+//;

    # If the surviving text after the omitted field already occurs at the end of the
    # surviving text before it, keep only the former text. This is the common case for
    # two identical separating spaces.
    if( length( $after ) <= length( $before ) &&
        substr( $before, length( $before ) - length( $after ) ) eq $after )
    {
        $after = '';
    }
    elsif( $before =~ /\s\z/ && $after =~ /^\s/ )
    {
        # Otherwise coalesce the two adjacent whitespace characters to one.
        substr( $after, 0, 1, '' );
    }

    return( $before . $after );
}

sub _field_value
{
    my $self      = shift( @_ );
    my $name      = shift( @_ );
    my $token     = shift( @_ );
    my $resolver  = shift( @_ );
    my $modifiers = $self->_modifier_hash( $token->{modifiers} );
    my $value = $name->get_field_value( $token->{field}, $modifiers );
    return if( !defined( $value ) );

    foreach my $modifier ( @{$token->{modifiers}} )
    {
        next unless( exists( $modifiers->{ $modifier } ) );
        if( ref( $resolver ) eq 'CODE' )
        {
            $value = $resolver->(
                $modifier,
                $value,
                $token->{field},
                $token,
                $name,
            );
        }
        elsif( Scalar::Util::blessed( $resolver ) &&
               $resolver->can( 'resolve' ) )
        {
            $value = $resolver->resolve(
                $modifier,
                $value,
                $token->{field},
                $token,
                $name,
            );
        }
        else
        {
            return( $self->error( "No modifier resolver was provided for modifier '${modifier}' in field '", $token->{source}, "'." ) );
        }
        return if( !defined( $value ) );
        delete( $modifiers->{ $modifier } );
    }
    return( $value );
}

sub _has_non_initial_given
{
    my $self = shift( @_ );
    foreach my $token ( @{$self->{tokens}} )
    {
        unless( $token->{type} eq 'field' &&
                $token->{field} eq 'given' )
        {
            next;
        }
        my $mods = {};
        @$mods{ @{$token->{modifiers}} } = (1) x scalar( @{$token->{modifiers}} );
        unless( exists( $mods->{initial} ) )
        {
            return(1);
        }
    }
    return(0);
}

sub _modifier_hash
{
    my $self      = shift( @_ );
    my $modifiers = shift( @_ );
    my $hash = {};
    @$hash{ @$modifiers } = (1) x scalar( @$modifiers );
    return( $hash );
}

sub _parse
{
    my $self = shift( @_ );
    my $pattern = shift( @_ );
    my $tokens = [];
    my $buffer = '';
    my $in_field = 0;
    my $escaped = 0;

    foreach my $char ( split( //, $pattern ) )
    {
        if( $escaped )
        {
            $buffer .= $char;
            $escaped = 0;
            next;
        }
        if( $char eq '\\' )
        {
            $escaped = 1;
            next;
        }
        if( $char eq '{' )
        {
            if( $in_field )
            {
                return( $self->error( "Nested braces are not allowed in person-name patterns." ) );
            }
            if( length( $buffer ) )
            {
                push( @$tokens, { type => 'literal', value => $buffer } );
            }
            $buffer = '';
            $in_field = 1;
            next;
        }
        if( $char eq '}' )
        {
            unless( $in_field )
            {
                return( $self->error( "Unmatched closing brace in person-name pattern." ) );
            }
            unless( length( $buffer ) )
            {
                return( $self->error( "No field name was provided inside braces." ) );
            }
            my $token = $self->_parse_field( $buffer ) ||
                return( $self->pass_error );
            push( @$tokens, $token );
            $buffer = '';
            $in_field = 0;
            next;
        }
        $buffer .= $char;
    }

    if( $escaped )
    {
        return( $self->error( "A trailing escape character is not allowed in a person-name pattern." ) );
    }
    elsif( $in_field )
    {
        return( $self->error( "Unmatched opening brace in person-name pattern." ) );
    }

    if( length( $buffer ) )
    {
        push( @$tokens, { type => 'literal', value => $buffer } );
    }

    unless( scalar( grep{ $_->{type} eq 'field' } @$tokens ) )
    {
        return( $self->error( "A person-name pattern must contain at least one field." ) );
    }
    return( $tokens );
}

sub _parse_field
{
    my $self = shift( @_ );
    my $definition = shift( @_ );
    my @parts = split( /-/, $definition, -1 );
    my $field = shift( @parts );
    unless( exists( $FIELDS->{ $field } ) )
    {
        return( $self->error( "Unknown person-name field '${field}'." ) );
    }
    my $seen = {};
    foreach my $modifier ( @parts )
    {
        if( !length( $modifier ) )
        {
            return( $self->error( "An empty modifier was found in field '${definition}'." ) );
        }
        elsif( !exists( $MODIFIERS->{ $modifier } ) )
        {
            return( $self->error( "Unknown person-name modifier '${modifier}' in field '${definition}'." ) );
        }
        elsif( $seen->{ $modifier }++ )
        {
            return( $self->error( "Modifier '${modifier}' occurs more than once in field '${definition}'." ) );
        }
    }
    foreach my $pair (
        [qw( allCaps initialCap )],
        [qw( initial monogram )],
        [qw( prefix core )],
    )
    {
        if( exists( $seen->{ $pair->[0] } ) &&
            exists( $seen->{ $pair->[1] } ) )
        {
            return( $self->error( "Modifiers '$pair->[0]' and '$pair->[1]' are mutually exclusive in field '${definition}'." ) );
        }
    }
    if( exists( $seen->{retain} ) &&
        !exists( $seen->{initial} ) )
    {
        return( $self->error( "Modifier 'retain' requires modifier 'initial' in field '${definition}'." ) );
    }
    return(
    {
        type       => 'field',
        field      => $field,
        modifiers  => [@parts],
        source     => $definition,
    });
}

sub _prepare_name
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $surname = $name->get_field_value( 'surname', {} );
    return( $name ) if( defined( $surname ) );
    return( $name ) if( $self->_has_non_initial_given );
    return( PersonName::Format::Pattern::GivenToSurname->new( $name ) );
}

# NOTE: PersonName::Format::Pattern::GivenToSurname class
package PersonName::Format::Pattern::GivenToSurname;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use parent qw( PersonName::Format::Name );
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( $self->error( "No underlying name object was provided." ) )
        unless( Scalar::Util::blessed( $name ) );
    $self->{name} = $name;
    return( $self );
}

sub get_field_value
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $modifiers = shift( @_ );
    return( $self->{name}->get_field_value( 'given', $modifiers ) )
        if( $field eq 'surname' );
    return if( $field eq 'given' );
    return( $self->{name}->get_field_value( $field, $modifiers ) );
}

sub name_locale
{
    return( shift->{name}->name_locale( @_ ) );
}

sub preferred_order
{
    return( shift->{name}->preferred_order( @_ ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::Pattern - Parsed CLDR person-name pattern

=head1 SYNOPSIS

    my $pattern = PersonName::Format::Pattern->new(
        '{title} {given} {given2} {surname}, {credentials}'
    );

    my $result = $pattern->format( $name );

=head1 DESCRIPTION

This class parses and validates one CLDR C<namePattern>. It retains a structured sequence of literal and field tokens, counts populated and empty fields, chooses the best pattern from a group, and renders missing fields structurally.

Unresolved field modifiers are delegated to a C<modifier_resolver> callback.
Modifiers consumed by the name object are not passed to that callback.

=head1 METHODS

=head2 format

    $pattern->format(
        $name,
        modifier_resolver => sub
        {
            my( $modifier, $value, $field, $token, $name ) = @_;
            ...
            return( $value );
        },
    );

=head2 num_empty_fields

Returns the number of field tokens whose resolved value is undefined or empty.

=head2 num_populated_fields

Returns the number of field tokens whose resolved value is defined and nonempty.

=head2 pattern

Returns the original pattern text.

=head2 select_best

Selects the pattern with the greatest number of populated fields, then the fewest empty fields, then the alphabetically least pattern text.

=head2 tokens

Returns a detached copy of the parsed token sequence.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
