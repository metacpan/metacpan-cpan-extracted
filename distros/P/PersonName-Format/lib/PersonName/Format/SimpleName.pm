##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/SimpleName.pm
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
package PersonName::Format::SimpleName;
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
    use parent qw( PersonName::Format::Name );
    use vars qw( $VERSION );
    use Locale::Unicode;
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

my @NAME_FIELDS = qw(
    title
    given
    given2
    given_informal
    surname
    surname2
    surname_prefix
    surname_core
    generation
    credentials
);

my $NAME_FIELDS = {};
@$NAME_FIELDS{ @NAME_FIELDS } = (1) x scalar( @NAME_FIELDS );

sub init
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $args = {%$args};

    my $normalised = {};
    foreach my $key ( keys( %$args ) )
    {
        my $internal = $self->internal_field_name( $key );
        if( exists( $normalised->{ $internal } ) )
        {
            return( $self->error( "The field '${internal}' was provided more than once using aliases." ) );
        }
        $normalised->{ $internal } = $args->{ $key };
    }

    foreach my $key ( keys( %$normalised ) )
    {
        if( exists( $NAME_FIELDS->{ $key } ) ||
            $key eq 'name_locale' ||
            $key eq 'preferred_order' ||
            $key eq 'debug' ||
            $key eq 'fatal' )
        {
            next;
        }
        return( $self->error( "Unknown person-name field or option '${key}'." ) );
    }

    # $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init(
        debug => delete( $normalised->{debug} ),
        fatal => delete( $normalised->{fatal} ),
    ) || return( $self->pass_error );

    if( exists( $normalised->{name_locale} ) &&
        defined( $normalised->{name_locale} ) )
    {
        my $locale = Locale::Unicode->new( $normalised->{name_locale} ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
        $self->{name_locale} = $locale;
    }

    if( exists( $normalised->{preferred_order} ) &&
        defined( $normalised->{preferred_order} ) )
    {
        my $order = $normalised->{preferred_order};
        unless( $order eq 'givenFirst' ||
                $order eq 'surnameFirst' )
        {
            return( $self->error( "Invalid preferred order '${order}'. Expected 'givenFirst' or 'surnameFirst'." ) );
        }
        $self->{preferred_order} = $order;
    }

    foreach my $field ( @NAME_FIELDS )
    {
        next unless( exists( $normalised->{ $field } ) );
        my $value = $normalised->{ $field };
        if( defined( $value ) && ref( $value ) )
        {
            return( $self->error( "Value for person-name field '${field}' must be a scalar." ) );
        }
        $self->{ $field } = $value;
    }

    return( $self );
}

sub as_hash
{
    my $self = shift( @_ );
    my $hash = {};
    foreach my $field ( @NAME_FIELDS, qw( name_locale preferred_order ) )
    {
        next unless( exists( $self->{ $field } ) );
        my $value = $self->{ $field };
        if( $field eq 'name_locale' &&
            defined( $value ) )
        {
            $value = "$value";
        }
        $hash->{ $field } = $value;
    }
    return( $hash );
}

sub fields
{
    return( [@NAME_FIELDS] );
}

sub get_field_value
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $modifiers = shift( @_ );
    if( !defined( $field ) ||
        !length( $field ) )
    {
        return( $self->error( "No person-name field was provided." ) );
    }
    $modifiers = {} if( !defined( $modifiers ) );
    unless( ref( $modifiers ) eq 'HASH' )
    {
        return( $self->error( "Field modifiers must be provided as an hash reference." ) );
    }

    $field = $self->internal_field_name( $field );

    if( $field eq 'given' &&
        exists( $modifiers->{informal} ) )
    {
        delete( $modifiers->{informal} );
        if( exists( $self->{given_informal} ) &&
            defined( $self->{given_informal} ) )
        {
            return( $self->{given_informal} );
        }
        return( $self->{given} );
    }

    if( $field eq 'surname' &&
        exists( $modifiers->{prefix} ) )
    {
        delete( $modifiers->{prefix} );
        if( exists( $self->{surname_prefix} ) &&
            defined( $self->{surname_prefix} ) )
        {
            return( $self->{surname_prefix} );
        }
        elsif( exists( $self->{surname} ) )
        {
            return( '' );
        }
        return;
    }

    if( $field eq 'surname' &&
        exists( $modifiers->{core} ) )
    {
        delete( $modifiers->{core} );
        if( exists( $self->{surname_core} ) &&
            defined( $self->{surname_core} ) )
        {
            return( $self->{surname_core} );
        }
        return( $self->{surname} );
    }

    if( $field eq 'surname' )
    {
        if( exists( $self->{surname} ) &&
            defined( $self->{surname} ) )
        {
            return( $self->{surname} );
        }

        my $prefix = $self->{surname_prefix};
        my $core = $self->{surname_core};
        if( !defined( $prefix ) && !defined( $core ) )
        {
            return;
        }
        elsif( !defined( $prefix ) || !length( $prefix ) )
        {
            return( $core );
        }
        elsif( !defined( $core ) || !length( $core ) )
        {
            return( $prefix );
        }
        return( join( ' ', $prefix, $core ) );
    }

    if( exists( $NAME_FIELDS->{ $field } ) )
    {
        return( $self->{ $field } );
    }
    return;
}

sub has_field
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    return(0) if( !defined( $field ) );
    $field = $self->internal_field_name( $field );
    return(0) unless( exists( $NAME_FIELDS->{ $field } ) );
    return( exists( $self->{ $field } ) && defined( $self->{ $field } ) );
}

sub name_locale
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $value = shift( @_ );
        if( !defined( $value ) )
        {
            $self->{name_locale} = undef;
            return;
        }
        my $locale = Locale::Unicode->new( $value ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
        $self->{name_locale} = $locale;
    }
    return( $self->{name_locale} );
}

sub preferred_order
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $value = shift( @_ );
        if( defined( $value ) &&
            $value ne 'givenFirst' &&
            $value ne 'surnameFirst' )
        {
            return( $self->error( "Invalid preferred order '${value}'. Expected 'givenFirst' or 'surnameFirst'." ) );
        }
        $self->{preferred_order} = $value;
    }
    return( $self->{preferred_order} );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::SimpleName - Simple person-name value object

=head1 SYNOPSIS

    my $name = PersonName::Format::SimpleName->new(
        nameLocale       => 'en-GB',
        preferredOrder   => 'givenFirst',
        given            => 'John',
        given2           => 'Ronald Reuel',
        'given-informal' => 'Johnny',
        surname          => 'Tolkien',
    );

    my $modifiers = { informal => 1 };
    my $given = $name->get_field_value( 'given', $modifiers );

=head1 DESCRIPTION

This class is the standard in-memory implementation of the L<PersonName::Format::Name> contract.

It accepts a hash reference or a flat key/value list. Public input may use CLDR-facing hyphenated names, underscore-separated Perl names, or the documented camelCase convenience aliases. Internally all fields use underscore-separated names.

=head1 NAME FIELDS

    title
    given
    given2
    given_informal
    surname
    surname2
    surname_prefix
    surname_core
    generation
    credentials

=head1 METHODS

=head2 as_hash

Returns a plain hash reference using internal underscore-separated field names.

=head2 fields

Returns the supported internal name fields.

=head2 get_field_value

Returns a field value and consumes any modifiers that this name object resolves itself from the supplied mutable hash reference.

C<informal>, C<prefix>, and C<core> are handled by this class. Modifiers left in the hash are intended to be applied by the formatter.

=head2 has_field

Returns true when the requested field exists and is defined.

=head2 name_locale

Gets or sets the name locale as a L<Locale::Unicode> object.

=head2 preferred_order

Gets or sets C<givenFirst> or C<surnameFirst>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
