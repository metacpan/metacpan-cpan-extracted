##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Null.pm
## Version v1.0.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/03/20
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## Purpose of this package is to provide an object that will be invoked in chain without breaking and then return undef at the end
## Normally if a method in the chain returns undef, perl will then complain that the following method in the chain was called on an undefined value. This Null package alleviate this problem.
## This is an original idea from https://stackoverflow.com/users/2766176/brian-d-foy as document in this Stackoverflow thread here: https://stackoverflow.com/a/7068271/4814971
## And also by user "particle" in this perl monks discussion here: https://www.perlmonks.org/?node_id=265214
package Module::Generic::Null;
BEGIN
{
    use strict;
    use Want;
    use overload ('""'     => sub{ '' },
                  'eq'     => sub { _obj_eq(@_) },
                  'ne'     => sub { !_obj_eq(@_) },
                  fallback => 1,
                 );
    use Want;
    our( $VERSION ) = 'v1.0.0';
};

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $error_object = shift( @_ );
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
    # my $debug = $_[0]->{debug};
    # my( $pack, $file, $file ) = caller;
    # my $sub = ( caller( 1 ) )[3];
    # print( STDERR __PACKAGE__, ": Method $method called in package $pack in file $file at line $line from subroutine $sub (AUTOLOAD = $AUTOLOAD)\n" ) if( $debug );
    ## If we are chained, return our null object, so the chain continues to work
    if( want( 'OBJECT' ) )
    {
        ## No, this is NOT a typo. rreturn() is a function of module Want
        rreturn( $_[0] );
    }
    ## Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
    return;
};

DESTROY {};

1;

__END__
