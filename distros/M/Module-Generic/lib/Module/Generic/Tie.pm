##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Tie.pm
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
package Module::Generic::Tie;
BEGIN
{
    use Tie::Hash;
    our( @ISA ) = qw( Tie::Hash );
    our( $VERSION ) = 'v1.0.0';
};

sub TIEHASH
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[ 0 ];
    ## print( STDERR __PACKAGE__ . "::TIEHASH() called with following arguments: '", join( ', ', @_ ), "'.\n" );
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
    my $pkg = ( caller() )[ 0 ];
    ## print( $err __PACKAGE__ . "::CLEAR() called by package '$pkg'.\n" );
    my $data = $self->{ '__priv__' };
    return() if( $data->{ 'readonly' } && $pkg ne __PACKAGE__ );
    ## if( $data->{ 'readonly' } || $data->{ 'protect' } )
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
    my $pkg  = ( caller() )[ 0 ];
    $pkg     = ( caller( 1 ) )[ 0 ] if( $pkg eq 'Module::Generic' );
    ## print( STDERR __PACKAGE__ . "::DELETE() package '$pkg' tries to delete '$_[ 0 ]'\n" );
    my $data = $self->{ '__priv__' };
    return if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    ## if( $data->{ 'readonly' } || $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return() if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    return( delete( $self->{ shift( @_ ) } ) );
}

sub EXISTS
{
    my $self = shift( @_ );
    ## print( STDERR __PACKAGE__ . "::EXISTS() called from package '", ( caller() )[ 0 ], "'.\n" );
    return( 0 ) if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[ 0 ];
        return( 0 ) if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    ## print( STDERR __PACKAGE__ . "::EXISTS() returns: '", exists( $self->{ $_[ 0 ] } ), "'.\n" );
    return( exists( $self->{ shift( @_ ) } ) );
}

sub FETCH
{
    ## return( shift->{ shift( @_ ) } );
    ## print( STDERR __PACKAGE__ . "::FETCH() called with arguments: '", join( ', ', @_ ), "'.\n" );
    my $self = shift( @_ );
    ## This is a hidden entry, we return nothing
    return() if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    ## If we have to protect our object, we hide its inner content if our caller is not our creator
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::FETCH() package '$pkg' wants to fetch the value of '$_[ 0 ]'\n" );
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    return( $self->{ shift( @_ ) } );
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    ## my $a    = scalar( keys( %$hash ) );
    ## return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller( 0 ) )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::FIRSTKEY() called by package '$pkg'\n" );
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY(): gathering object's keys.\n" );
    my( @keys ) = grep( !/^__priv__$/, keys( %$self ) );
    $self->{ '__priv__' }->{ 'ITERATOR' } = \@keys;
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY(): keys are: '", join( ', ', @keys ), "'.\n" );
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY() returns '$keys[ 0 ]'.\n" );
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
        my $pkg = ( caller( 0 ) )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::NEXTKEY() called by package '$pkg'\n" );
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    my $keys = $self->{ '__priv__' }->{ 'ITERATOR' };
    ## print( STDERR __PACKAGE__ . "::NEXTKEY() returns '$_[ 0 ]'.\n" );
    return( shift( @$keys ) );
}

sub STORE
{
    my $self = shift( @_ );
    return() if( $_[ 0 ] eq '__priv__' );
    my $data = $self->{ '__priv__' };
    #if( $data->{ 'readonly' } || 
    #    $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        my $pkg  = ( caller() )[ 0 ];
        $pkg     = ( caller( 1 ) )[ 0 ] if( $pkg eq 'Module::Generic' );
        ## print( STDERR __PACKAGE__ . "::STORE() package '$pkg' is trying to STORE the value '$_[ 1 ]' to key '$_[ 0 ]'\n" );
        return if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    ## print( STDERR __PACKAGE__ . "::STORE() ", ( caller() )[ 0 ], " is storing value '$_[ 1 ]' for key '$_[ 0 ]'.\n" );
    ## $self->{ shift( @_ ) } = shift( @_ );
    $self->{ $_[ 0 ] } = $_[ 1 ];
    ## print( STDERR __PACKAGE__ . "::STORE(): object '$self' now contains: '", join( ', ', map{ "$_, $self->{ $_ }" } keys( %$self ) ), "'.\n" );
}

1;

__END__
