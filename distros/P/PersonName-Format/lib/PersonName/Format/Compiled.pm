##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/Compiled.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/17
## Modified 2026/07/17
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package PersonName::Format::Compiled;
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
    use PersonName::Format::Name;
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $args = {%$args};
    my $formatter       = delete( $args->{formatter} );
    my $context         = delete( $args->{context} );
    my $name_script     = delete( $args->{name_script} );
    my $name_locale     = delete( $args->{name_locale} );
    my $preferred_order = delete( $args->{preferred_order} );
    unless( Scalar::Util::blessed( $formatter ) &&
            $formatter->isa( 'PersonName::Format' ) )
    {
        return( $self->error( "No formatter was provided." ) );
    }
    unless( ref( $context ) eq 'HASH' )
    {
        return( $self->error( "No compiled formatting context was provided." ) );
    }
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown Compiled option '", ( keys( %$args ) )[0], "'." ) );
    }
    $self->{formatter}       = $formatter;
    $self->{context}         = $context;
    $self->{name_script}     = $name_script;
    $self->{name_locale}     = $name_locale;
    $self->{preferred_order} = $preferred_order;
    return( $self );
}

sub format
{
    my $self = shift( @_ );
    my $name = $self->_name( @_ ) || return( $self->pass_error );
    return( $self->pass_error ) unless( $self->_validate_identity( $name ) );
    return( $self->{formatter}->_render_context( $self->{context}, $name, 0 ) );
}

sub format_to_parts
{
    my $self = shift( @_ );
    my $name = $self->_name( @_ ) || return( $self->pass_error );
    return( $self->pass_error ) unless( $self->_validate_identity( $name ) );
    return( $self->{formatter}->_render_context( $self->{context}, $name, 1 ) );
}

sub formatToParts
{
    return( shift->format_to_parts( @_ ) );
}

sub resolved_options
{
    my $self = shift( @_ );
    my $options = $self->{formatter}->resolved_options;
    $options->{nameScript} = $self->{name_script};
    $options->{nameLocale} = $self->{name_locale}
        if( defined( $self->{name_locale} ) );
    $options->{preferredOrder} = $self->{preferred_order}
        if( defined( $self->{preferred_order} ) );
    return( $options );
}

sub resolvedOptions
{
    return( shift->resolved_options( @_ ) );
}

sub _name
{
    my $self = shift( @_ );
    return( $self->{formatter}->_coerce_name( @_ ) || $self->pass_error( $self->{formatter}->error ) );
}

sub _validate_identity
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $script = $self->{formatter}->_detected_script( $name );
    unless( $self->{formatter}->_scripts_match( $script, $self->{name_script} ) )
    {
        return( $self->error( "The compiled formatter expects nameScript '$self->{name_script}', but the supplied name uses '$script'." ) );
    }

    if( defined( $self->{name_locale} ) &&
        length( "$self->{name_locale}" ) )
    {
        my $actual = $name->name_locale;
        if( !defined( $actual ) || lc( "$actual" ) ne lc( "$self->{name_locale}" ) )
        {
            return( $self->error( "The compiled formatter requires nameLocale '$self->{name_locale}'." ) );
        }
    }
    if( defined( $self->{preferred_order} ) )
    {
        my $actual = $name->preferred_order;
        if( !defined( $actual ) || $actual ne $self->{preferred_order} )
        {
            return( $self->error( "The compiled formatter requires preferredOrder '$self->{preferred_order}'." ) );
        }
    }
    return(1);
}

# NOTE: PersonName::Format::Compiled::IdentityName class
package PersonName::Format::Compiled::IdentityName;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use parent qw( PersonName::Format::Name );
    use Locale::Unicode;
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->SUPER::init || return( $self->pass_error );
    if( defined( $args->{name_locale} ) && length( "$args->{name_locale}" ) )
    {
        $self->{name_locale} = Locale::Unicode->new( $args->{name_locale} ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }
    if( defined( $args->{preferred_order} ) )
    {
        $self->{preferred_order} = $args->{preferred_order};
    }
    return( $self );
}

sub get_field_value
{
    return;
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::Compiled - Precompiled CLDR person name formatter

=head1 SYNOPSIS

    use PersonName::Format;

    my $formatter = PersonName::Format->new(
        locale => 'en-US',
    );

    my $compiled = $formatter->compile(
        nameLocale => 'ja-JP',
        nameScript => 'Jpan',
    );

    my $string = $compiled->format(
        {
        given   => '太郎',
        surname => '山田',
        }
    );

=head1 DESCRIPTION

This class represents a precompiled formatter created by L<PersonName::Format/compile>.

Compiling a formatter freezes all context-resolution steps that depend only on the formatter configuration and the name characteristics: the formatting locale, the name locale, the script, the preferred name order, the selected CLDR pattern group, the space replacement rules, and the field modifier resolver.

The final CLDR pattern is still selected for each individual name, since CLDR chooses the best pattern according to the fields actually present in that name.

Compiled formatters are intended for high-throughput applications that format many names sharing the same locale and script characteristics.

Objects of this class are created by L<PersonName::Format/compile> and should not normally be instantiated directly.

=head1 METHODS

=head2 format

    my $string = $compiled->format( $name );

Formats a name and returns the resulting string.

This method behaves identically to L<PersonName::Format/format>, but avoids repeating the context derivation performed during normal formatting.

=head2 format_to_parts

    my $parts = $compiled->format_to_parts( $name );

    my $parts = $compiled->format_to_parts( $name );

Formats a name and returns an array reference describing the generated parts.

The returned structure is identical to that returned by L<PersonName::Format/format_to_parts>.

=head2 formatToParts

This is an alias for L</format_to_parts>

The returned structure is identical to that returned by L<PersonName::Format/formatToParts>.

=for Pod::Coverage resolved_options

=head2 resolvedOptions

    my $options = $compiled->resolvedOptions;
    # or
    my $options = $compiled->resolved_options;

Returns a hash reference describing the effective formatting options frozen into this compiled formatter.

=head1 SEE ALSO

L<PersonName::Format>,
L<PersonName::Format::Name>,
L<https://www.unicode.org/reports/tr35/tr35-personNames.html>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
