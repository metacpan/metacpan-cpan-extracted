##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/Generic.pm
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
package PersonName::Format::Generic;
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
    use vars qw( $VERSION );
    use Scalar::Util ();
    use PersonName::Format::Exception ();
    use PersonName::Format::NullObject ();
    use Wanted;
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

my $CLASS_ERROR = {};

sub new
{
    my $that  = shift( @_ );
    my $class = ( ref( $that ) || $that );
    my $self  = bless( {}, $class );
    $CLASS_ERROR->{ $class } = undef;
    my $result = $self->init( @_ );
    if( !defined( $result ) )
    {
        if( Scalar::Util::blessed( $that ) )
        {
            return( $that->pass_error( $self->error ) );
        }
        else
        {
            return( $self->pass_error );
        }
    }
    # Should be the same as $self, but not necessarily
    return( $result );
}

sub init
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->{debug} = delete( $args->{debug} ) ? 1 : 0;
    $self->{fatal} = delete( $args->{fatal} ) ? 1 : 0;
    return( $self );
}

sub debug { return( shift->_set_get_scalar( 'debug', @_ ) ); }

sub error
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;

    if( @_ )
    {
        my $message = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
        my $exception = PersonName::Format::Exception->new({
            skip_frames => 1,
            message     => $message,
        });
        $CLASS_ERROR->{ $class } = $exception;
        $self->{error} = $exception if( ref( $self ) );

        if( ref( $self ) && $self->fatal )
        {
            die( $exception );
        }
        else
        {
            if( warnings::enabled( 'PersonName::Format' ) )
            {
                warn( $message );
            }
            rreturn( PersonName::Format::NullObject->new ) if( want( 'OBJECT' ) );
            return;
        }
    }

    return( ref( $self ) ? $self->{error} : $CLASS_ERROR->{ $class } );
}

sub fatal { return( shift->_set_get_scalar( 'fatal', @_ ) ); }

sub pass_error
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $opts = {};
    my( $error, $exception_class, $code );

    if( @_ )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 &&
            ref( $_[0] ) eq 'HASH' )
        {
            $opts = shift( @_ );
        }
        else
        {
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $error = $_[0];
        }
    }

    if( !defined( $error ) &&
        exists( $opts->{error} ) &&
        defined( $opts->{error} ) &&
        length( "$opts->{error}" ) )
    {
        $error = $opts->{error};
    }
    if( exists( $opts->{class} ) &&
        defined( $opts->{class} ) &&
        length( $opts->{class} ) )
    {
        $exception_class = $opts->{class};
    }
    if( exists( $opts->{code} ) &&
        defined( $opts->{code} ) &&
        length( "$opts->{code}" ) )
    {
        $code = $opts->{code};
    }

    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $error ) && ( !scalar( @_ ) || defined( $exception_class ) ) )
    {
        $error = ref( $self ) ? $self->{error} : $CLASS_ERROR->{ $class };
        if( !defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef" ) if( warnings::enabled( 'PersonName::Format' ) );
        }
        else
        {
            $error = ( defined( $exception_class ) ? bless( $error => $exception_class ) : $error );
            $error->code( $code ) if( defined( $code ) );
        }
    }
    elsif( defined( $error ) && 
           Scalar::Util::blessed( $error ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $exception_class ) ) 
           ) )
    {
        my $err = defined( $exception_class ) ? bless( $error => $exception_class ) : $error;
        $err->code( $code ) if( defined( $code ) && $err->can( 'code' ) );
        $CLASS_ERROR->{ $class } = $err;
        $self->{error} = $err if( ref( $self ) );
        die( $err ) if( ref( $self ) && $self->fatal );
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }

    rreturn( PersonName::Format::NullObject->new ) if( want( 'OBJECT' ) );
    return;
}

sub _can
{
    my $self = shift( @_ );
    my $object = shift( @_ );
    my $methods = shift( @_ );
    return(0) if( !Scalar::Util::blessed( $object ) );
    $methods = [$methods] if( ref( $methods ) ne 'ARRAY' );
    foreach my $method ( @$methods )
    {
        return(0) if( !$object->can( $method ) );
    }
    return(1);
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    my $ref = {};
    if( scalar( @_ ) == 1 &&
        defined( $_[0] ) &&
        ( ref( $_[0] ) || '' ) eq 'HASH' )
    {
        $ref = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
    }
    else
    {
        warn( "Uneven number of parameters provided." ) if( warnings::enabled( 'PersonName::Format' ) );
    }
    return( $ref );
}

sub _set_get_scalar
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    if( @_ )
    {
        $self->{ $name } = shift( @_ );
    }
    return( $self->{ $name } );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::Generic - Internal base class for PersonName::Format objects

=head1 SYNOPSIS

    package My::Formatter;

    use parent qw( PersonName::Format::Generic );

=head1 DESCRIPTION

This class provides the common object infrastructure shared by the C<PersonName::Format> distribution.

It implements object construction, error handling, accessors, and a small set of utility methods used internally by the formatter.

It is intentionally lightweight and standalone, allowing the distribution to remain compatible with Perl v5.10.1 and later.

Applications normally do not need to interact with this class directly.

=head1 METHODS

=head2 new

    my $obj = Some::Class->new( %options );

Creates a new object.

=head2 init

    $obj->init( %options );

Object initialisation hook invoked by L</new>.

Subclasses may override this method.

=head2 error

    my $exception = $obj->error;

    $obj->error( "Something went wrong" );

Gets or sets the last exception associated with the object.

=head2 pass_error

    return $self->pass_error( $other );

Copies the error state from another object or exception and returns the appropriate failure value.

=head2 fatal

    my $bool = $obj->fatal;

Returns whether fatal exceptions are enabled.

=head2 debug

    my $bool = $obj->debug;

Returns whether debug mode is enabled.

=head1 INTERNAL METHODS

The following methods are intended for use by subclasses.

=head2 _can

=head2 _get_args_as_hash

=head2 _set_get_scalar

These methods are not considered part of the public API and may change in future releases.

=head1 SEE ALSO

L<PersonName::Format>, L<PersonName::Format::Exception>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
