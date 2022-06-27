##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/TieHash.pm
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
package Module::Generic::TieHash;
BEGIN
{
    use strict;
    use warnings::register;
    use warnings;
    # use parent qw( Module::Generic );
    use Scalar::Util ();
    our $VERSION = 'v1.1.0';
};

use strict;
no warnings 'redefine';

sub TIEHASH
{
    my $self  = shift( @_ );
    my $opts  = {};
    $opts = shift( @_ ) if( @_ );
    if( Scalar::Util::reftype( $opts ) ne 'HASH' )
    {
        warn( "Parameters provided ($opts) is not an hash reference.\n" ) if( $self->_warnings_is_enabled );
        return;
    }
    my $disable = [];
    $disable = $opts->{disable} if( Scalar::Util::reftype( $opts->{disable} ) );
    my $list = {};
    @$list{ @$disable } = ( 1 ) x scalar( @$disable );
    my $hash =
    {
    ## The caller sets this to its class, so we can differentiate calls from inside and outside our caller's package
    disable => $list,
    debug => $opts->{debug},
    ## When disabled, the Tie::Hash system will return hash key values directly under $self instead of $self->{data}
    ## Disabled by default so the new() method can access its setup data directly under $self
    ## Then new() can call enable to active it
    enable => 0,
    ## Where to store the actual hash data
    data  => {},
    };
    my $class = ref( $self ) || $self;
    return( bless( $hash => $class ) );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $data = $self->{data};
    %$data = ();
}

sub DELETE
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        CORE::delete( $self->{ $key } );
    }
    else
    {
        CORE::delete( $data->{ $key } );
    }
}

sub EXISTS
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        CORE::exists( $self->{ $key } );
    }
    else
    {
        CORE::exists( $data->{ $key } );
    }
}

sub FETCH
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    ## print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key''\n" );
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        #print( STDERR "FETCH($caller)[owner calling, enable=$self->{enable}] <- '$key' <- '$self->{$key}'\n" );
        return( $self->{ $key } )
    }
    else
    {
        #print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key' <- '$data->{$key}'\n" );
        return( $data->{ $key } );
    }
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my @keys = ();
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        @keys = keys( %$self );
    }
    else
    {
        @keys = keys( %$data );
    }
    $self->{ITERATOR} = \@keys;
    return( shift( @keys ) );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $keys = ref( $self->{ITERATOR} ) ? $self->{ITERATOR} : [];
    return( shift( @$keys ) );
}

sub SCALAR
{
    my $self  = shift( @_ );
    my $data = $self->{data};
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        return( scalar( keys( %$self ) ) );
    }
    else
    {
        return( scalar( keys( %$data ) ) );
    }
}

sub STORE
{
    my $self  = shift( @_ );
    my $data = $self->{data};
    my( $key, $val ) = @_;
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        #print( STDERR "STORE($caller)[owner calling] <- '$key' -> '$val'\n" );
        $self->{ $key } = $val;
    }
    else
    {
        #print( STDERR "STORE($caller)[enable=$self->{enable}] <- '$key' -> '$val'\n" );
        $data->{ $key } = $val;
    }
}

# sub enable { return( shift->_set_get_boolean( 'enable', @_ ) ); }
sub enable
{
    my $self = shift( @_ );
    $self->{enable} = shift( @_ ) if( @_ );
    return( $self->{enable} );
}

sub _exclude
{
    my $self = shift( @_ );
    my $caller = shift( @_ );
    ## $self->message( 3, "Disable hash contains: ", sub{ $self->dump( $self->{disable} ) });
    return( CORE::exists( $self->{disable}->{ $caller } ) );
}

1;

__END__

=encoding utf-8

=head1 NAME

Module::Generic - Generic Tie Hash Mechanism for Object Oriented Hashes

=head1 SYNOPSIS

    my $tie = tie( %hash, 'Module::Generic::TieHash' );

=head1 VERSION

    v1.1.0

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
