##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Boolean.pm
## Version v1.2.1
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2025/04/20
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Boolean;
BEGIN
{
    use v5.26.1;
    use common::sense;
    use vars qw( $true $false );
    use overload
        "0+"     => sub{ ${$_[0]} },
        "++"     => sub{ $_[0] = ${$_[0]} + 1 },
        "--"     => sub{ $_[0] = ${$_[0]} - 1 },
        fallback => 1;
    $true  = do{ bless( \( my $dummy = 1 ) => 'Module::Generic::Boolean' ) };
    $false = do{ bless( \( my $dummy = 0 ) => 'Module::Generic::Boolean' ) };
    our( $VERSION ) = 'v1.2.1';
};

use v5.26.1;
use strict;

sub new { return( $_[1] ? $true : $false ); }

# sub as_array { return( Module::Generic::Array->new( [ ${$_[0]} ] ) ); }
sub as_array
{
    my $self = shift( @_ );
    unless( $self->_is_class_loaded( 'Module::Generic::Array' ) )
    {
        # try-catch
        local $@;
        eval( 'Module::Generic::Array' );
        if( $@ )
        {
            die( "Unable to load Module::Generic::Array" );
        }
    }
    return( Module::Generic::Array->new( [ $$self ] ) );
}

# sub as_number { return( Module::Generic::Number->new( ${$_[0]} ) ); }
sub as_number
{
    my $self = shift( @_ );
    unless( $self->_is_class_loaded( 'Module::Generic::Number' ) )
    {
        # try-catch
        local $@;
        eval( 'Module::Generic::Number' );
        if( $@ )
        {
            die( "Unable to load Module::Generic::Number" );
        }
    }
    return( Module::Generic::Number->new( $$self ) );
}

# sub as_scalar { return( Module::Generic::Scalar->new( ${$_[0]} ) ); }
sub as_scalar
{
    my $self = shift( @_ );
    unless( $self->_is_class_loaded( 'Module::Generic::Scalar' ) )
    {
        # try-catch
        local $@;
        eval( 'Module::Generic::Scalar' );
        if( $@ )
        {
            die( "Unable to load Module::Generic::Scalar" );
        }
    }
    return( Module::Generic::Scalar->new( $$self ) );
}

sub defined { return(1); }

sub true  () { $true  }
sub false () { $false }

sub is_bool  ($) {           UNIVERSAL::isa( $_[0], 'Module::Generic::Boolean' ) }
sub is_true  ($) {  $_[0] && UNIVERSAL::isa( $_[0], 'Module::Generic::Boolean' ) }
sub is_false ($) { !$_[0] && UNIVERSAL::isa( $_[0], 'Module::Generic::Boolean' ) }

sub _is_class_loaded
{
    my $self = CORE::shift( @_ );
    my $class = CORE::shift( @_ );
    ( my $pm = $class ) =~ s{::}{/}gs;
    $pm .= '.pm';
    return(1) if( CORE::exists( $INC{ $pm } ) );
    return(0);
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, $$self] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $$self );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my( $class, $str );
    if( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' )
    {
        ( $class, $str ) = @{$args[0]};
    }
    else
    {
        $class = CORE::ref( $self ) || $self;
        $str = CORE::shift( @args );
    }
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        $$self = $str;
        CORE::return( $self );
    }
    else
    {
        CORE::return( $class->new( $str ) );
    }
}

sub TO_JSON
{
    # JSON does not check that the value is a proper true or false. It stupidly assumes this is a string
    # The only way to make it understand is to return a scalar ref of 1 or 0
    # return( $_[0] ? 'true' : 'false' );
    return( $_[0] ? \1 : \0 );
}

1;

__END__
