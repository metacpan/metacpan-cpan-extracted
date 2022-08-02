##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Null.pm
## Version v1.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2022/02/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## Purpose of this package is to provide an object that will be invoked in chain without breaking and then return undef at the end
## Normally if a method in the chain returns undef, perl will then complain that the following method in the chain was called on an undefined value. This Null package alleviate this problem.
## This is an original idea from https://stackoverflow.com/users/2766176/brian-d-foy as documented in this Stackoverflow thread here: https://stackoverflow.com/a/7068271/4814971
## And also by user "particle" in this perl monks discussion here: https://www.perlmonks.org/?node_id=265214
package Module::Generic::Null;
BEGIN
{
    use strict;
    use warnings;
    use overload ('""'     => sub{ '' },
                  'eq'     => sub { _obj_eq(@_) },
                  'ne'     => sub { !_obj_eq(@_) },
                  fallback => 1,
                 );
    use Scalar::Util ();
    use Want;
    our( $VERSION ) = 'v1.1.0';
};

use strict;
no warnings 'redefine';

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $error_object;
    $error_object = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) );
    my $hash = ( @_ == 1 && ref( $_[0] ) ? shift( @_ ) : { @_ } );
    $hash->{has_error} = $error_object;
    return( bless( $hash => $class ) );
}

sub _obj_eq 
{
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Null' ) )
    {
        return( $self eq $other );
    }
    # Compare error message
    elsif( !ref( $other ) )
    {
        return( '' eq $other );
    }
    # Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    my $what = ( defined( $self->{wants} ) && length( $self->{wants} ) )
        ? uc( $self->{wants} )
        : Want::want( 'LIST' )
            ? 'LIST'
            : Want::want( 'HASH' )
                ? 'HASH'
                : Want::want( 'ARRAY' )
                    ? 'ARRAY'
                    : Want::want( 'OBJECT' )
                        ? 'OBJECT'
                        : Want::want( 'CODE' )
                            ? 'CODE'
                            : Want::want( 'REFSCALAR' )
                                ? 'REFSCALAR'
                                : Want::want( 'BOOLEAN' )
                                    ? 'BOOLEAN'
                                    : Want::want( 'GLOB' )
                                        ? 'GLOB'
                                        : Want::want( 'SCALAR' )
                                            ? 'SCALAR'
                                            : Want::want( 'VOID' )
                                                ? 'VOID'
                                                : '';
    # If we are chained, return our null object, so the chain continues to work
    if( $what eq 'OBJECT' )
    {
        # No, this is NOT a typo. rreturn() is a function of module Want
        rreturn( $_[0] );
    }
    elsif( $what eq 'CODE' )
    {
        rreturn( sub{ return; } );
    }
    elsif( $what eq 'ARRAY' )
    {
        rreturn( [] );
    }
    elsif( $what eq 'HASH' )
    {
        rreturn( {} );
    }
    elsif( $what eq 'REFSCALAR' )
    {
        rreturn( \undef );
    }
    # Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
    return;
};

DESTROY {};

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' || $serialiser eq 'CBOR' );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

1;

__END__
