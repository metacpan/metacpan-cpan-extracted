##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Tie.pm
## Version v1.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2025/04/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Tie;
BEGIN
{
    use Tie::Hash;
    use strict;
    use warnings;
    our @ISA = qw( Tie::Hash );
    our $VERSION = 'v1.2.0';
};

use strict;

sub TIEHASH
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[0];
    my %arg  = ( @_ );
    my $auth = [ $pkg, __PACKAGE__ ];
    if( $arg{ 'pkg' } )
    {
        my $ok = delete( $arg{ 'pkg' } );
        push( @$auth, ref( $ok ) eq 'ARRAY' ? @$ok : $ok );
    }
    my $priv = { 'pkg' => $auth };
    my $data = { '__priv__' => $priv };
    my @keys = keys( %arg );
    @$priv{ @keys } = @arg{ @keys };
    return( bless( $data, ref( $self ) || $self ) );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $pkg = ( caller() )[0];
    my $data = $self->{ '__priv__' };
    return() if( $data->{ 'readonly' } && $pkg ne __PACKAGE__ );
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    my $key  = $self->FIRSTKEY( @_ );
    my @keys = ();
    while( defined( $key ) )
    {
        push( @keys, $key );
        $key = $self->NEXTKEY( @_, $key );
    }
    foreach $key ( @keys )
    {
        $self->DELETE( @_, $key );
    }
}

sub DELETE
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[0];
    $pkg     = ( caller(1) )[0] if( $pkg eq 'Module::Generic' );
    my $data = $self->{ '__priv__' };
    return if( $_[0] eq '__priv__' && $pkg ne __PACKAGE__ );
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return() if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    return( delete( $self->{ shift( @_ ) } ) );
}

sub EXISTS
{
    my $self = shift( @_ );
    my $pkg = ref( $self );
    return(0) if( $_[0] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[0];
        return(0) if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    return( exists( $self->{ shift( @_ ) } ) );
}

sub FETCH
{
    my $self = shift( @_ );
    my $pkg = ref( $self );
    # This is a hidden entry, we return nothing
    return() if( $_[0] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    # If we have to protect our object, we hide its inner content if our caller is not our creator
    # if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[0];
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    return( $self->{ shift( @_ ) } );
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    # my $a    = scalar( keys( %$hash ) );
    # return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller(0) )[0];
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    my( @keys ) = grep( !/^__priv__$/, keys( %$self ) );
    $self->{ '__priv__' }->{ 'ITERATOR' } = \@keys;
    return( shift( @keys ) );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    ## return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller(0) )[0];
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    my $keys = $self->{ '__priv__' }->{ 'ITERATOR' };
    return( shift( @$keys ) );
}

sub STORE
{
    my $self = shift( @_ );
    return() if( $_[0] eq '__priv__' );
    my $data = $self->{ '__priv__' };
    if( !( $data->{ 'perms' } & 2 ) )
    {
        my $pkg  = ( caller() )[0];
        $pkg     = ( caller(1) )[0] if( $pkg eq 'Module::Generic' );
        return if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    $self->{ $_[0] } = $_[1];
}

1;

__END__
