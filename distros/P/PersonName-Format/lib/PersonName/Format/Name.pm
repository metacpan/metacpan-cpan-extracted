##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/Name.pm
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
package PersonName::Format::Name;
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
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

my $EXTERNAL_TO_INTERNAL =
{
    title               => 'title',
    given               => 'given',
    given2              => 'given2',
    surname             => 'surname',
    surname2            => 'surname2',
    generation          => 'generation',
    credentials         => 'credentials',
    'given-informal'    => 'given_informal',
    given_informal      => 'given_informal',
    givenInformal       => 'given_informal',
    'surname-prefix'    => 'surname_prefix',
    surname_prefix      => 'surname_prefix',
    surnamePrefix       => 'surname_prefix',
    'surname-core'      => 'surname_core',
    surname_core        => 'surname_core',
    surnameCore         => 'surname_core',
    name_locale         => 'name_locale',
    nameLocale          => 'name_locale',
    preferred_order     => 'preferred_order',
    preferredOrder      => 'preferred_order',
};

my $INTERNAL_TO_EXTERNAL =
{
    title           => 'title',
    given           => 'given',
    given2          => 'given2',
    surname         => 'surname',
    surname2        => 'surname2',
    generation      => 'generation',
    credentials     => 'credentials',
    given_informal  => 'given-informal',
    surname_prefix  => 'surname-prefix',
    surname_core    => 'surname-core',
    name_locale     => 'nameLocale',
    preferred_order => 'preferredOrder',
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub external_field_name
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    return if( !defined( $field ) );
    return( $INTERNAL_TO_EXTERNAL->{ $field } // $field );
}

sub get_field_value
{
    my $self = shift( @_ );
    return( $self->error( ref( $self ), " does not implement get_field_value()." ) );
}

sub implements_name_contract
{
    my $self   = shift( @_ );
    my $object = shift( @_ );
    return(0) unless( Scalar::Util::blessed( $object ) );
    return( $self->_can( $object, [qw( get_field_value name_locale preferred_order )] ) );
}

sub internal_field_name
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    return if( !defined( $field ) );
    return( $EXTERNAL_TO_INTERNAL->{ $field } // $field );
}

sub name_locale { return( shift->_set_get_scalar( 'name_locale', @_ ) ); }

sub preferred_order { return( shift->_set_get_scalar( 'preferred_order', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::Name - Base contract for person-name providers

=head1 SYNOPSIS

    package My::Name;
    use parent qw( PersonName::Format::Name );

    sub get_field_value
    {
        my( $self, $field, $modifiers ) = @_;
        ...
    }

=head1 DESCRIPTION

This class defines the internal contract used by L<PersonName::Format>.
Applications may subclass it or provide any object implementing C<get_field_value()>, C<name_locale()>, and C<preferred_order()>.

Internally, field names use underscore-separated Perl identifiers. CLDR field names using hyphens are converted only at the formatter boundary.

=head1 METHODS

=head2 external_field_name

Maps an internal Perl field name such as C<surname_core> to the corresponding CLDR-facing name C<surname-core>.

=head2 get_field_value

Must be implemented by a concrete name provider.

=head2 implements_name_contract

    PersonName::Format::Name->implements_name_contract( $object );
    $name->implements_name_contract( $object );

Returns true when the supplied object implements the required name contract: it must be a blessed reference that provides C<get_field_value()>, C<name_locale()>, and C<preferred_order()>. This method may be called as a class method or as an instance method; both forms are equivalent.

=head2 internal_field_name

Maps CLDR-facing and supported convenience aliases to their internal underscore-separated field name.

=head2 name_locale

Returns the locale associated with the name.

=head2 preferred_order

Returns C<givenFirst>, C<surnameFirst>, or an undefined value.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
