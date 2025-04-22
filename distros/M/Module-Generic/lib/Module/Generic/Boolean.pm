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
    use Config;
    use constant HAS_THREADS => ( $Config{useithreads} && $INC{'threads.pm'} );
    if( HAS_THREADS )
    {
        require threads;
        require threads::shared;
        threads->import();
        threads::shared->import();
    }
    our( $VERSION ) = 'v1.2.1';
};

use v5.26.1;
use strict;
# require Module::Generic::Array;
# require Module::Generic::Number;
# require Module::Generic::Scalar;

sub new { return( $_[1] ? $true : $false ); }

# sub as_array { return( Module::Generic::Array->new( [ ${$_[0]} ] ) ); }
sub as_array
{
    state $loaded;
    if( HAS_THREADS && !$loaded )
    {
        lock( $loaded );
        require Module::Generic::Array;
        $loaded = 1;
    }
    elsif( !$loaded )
    {
        require Module::Generic::Array;
        $loaded = 1;
    }

    return( Module::Generic::Array->new( [ ${$_[0]} ] ) );
}

# sub as_number { return( Module::Generic::Number->new( ${$_[0]} ) ); }
sub as_number
{
    state $loaded;
    if( HAS_THREADS && !$loaded )
    {
        lock( $loaded );
        require Module::Generic::Number;
        $loaded = 1;
    }
    elsif( !$loaded )
    {
        require Module::Generic::Number;
        $loaded = 1;
    }

    return( Module::Generic::Number->new( ${$_[0]} ) );
}

# sub as_scalar { return( Module::Generic::Scalar->new( ${$_[0]} ) ); }
sub as_scalar
{
    state $loaded;
    if( HAS_THREADS && !$loaded )
    {
        lock( $loaded );
        require Module::Generic::Scalar;
        $loaded = 1;
    }
    elsif( !$loaded )
    {
        require Module::Generic::Scalar;
        $loaded = 1;
    }

    return( Module::Generic::Scalar->new( ${$_[0]} ) );
}

sub defined { return(1); }

sub true  () { $true  }
sub false () { $false }

sub is_bool  ($) {           UNIVERSAL::isa( $_[0], 'Module::Generic::Boolean' ) }
sub is_true  ($) {  $_[0] && UNIVERSAL::isa( $_[0], 'Module::Generic::Boolean' ) }
sub is_false ($) { !$_[0] && UNIVERSAL::isa( $_[0], 'Module::Generic::Boolean' ) }

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
