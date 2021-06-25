##----------------------------------------------------------------------------
## Module Generic - ~/lib//media/sf_src/perl/Module-Generic/lib/Module/Generic/Null.pm
## Version v1.0.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/05/20
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
    use Want;
    use overload ('""'     => sub{ '' },
                  'eq'     => sub { _obj_eq(@_) },
                  'ne'     => sub { !_obj_eq(@_) },
                  fallback => 1,
                 );
    use Scalar::Util ();
    use Want;
    our( $VERSION ) = 'v1.0.1';
};

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
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Null' ) )
    {
        return( $self eq $other );
    }
    ## Compare error message
    elsif( !ref( $other ) )
    {
        return( '' eq $other );
    }
    ## Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    # XXX Remove debugging
#     my $debug = $self->{debug} = 3;
#     print( STDERR __PACKAGE__, "::AUTOLOAD: self contains the following keys: '", join( "', '", keys( %$self ) ), "'\n" ) if( $debug );
#     my( $pack, $file, $line ) = caller;
#     my $sub = ( caller( 1 ) )[3];
    my $what = ( defined( $self->{wants} ) && length( $self->{wants} ) )
        ? $self->{wants}
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
#     print( STDERR __PACKAGE__, ": Method $method called in package $pack in file $file at line $line from subroutine $sub (AUTOLOAD = $AUTOLOAD) and expecting '$what'\n" ) if( $debug );
    ## If we are chained, return our null object, so the chain continues to work
    if( $what eq 'OBJECT' )
    {
        ## No, this is NOT a typo. rreturn() is a function of module Want
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
    ## Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
    return;
};

DESTROY {};

1;

__END__
