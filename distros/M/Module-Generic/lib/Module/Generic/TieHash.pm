##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/TieHash.pm
## Version v1.2.2
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2023/12/05
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
    use vars qw( $VERSION $PAUSED $MOD_PERL );
    use Scalar::Util ();
    # When true _exclude returns always false.
    # This is used by Module::Generic::_message, because Module::Generic is always part of
    # the exclusion list
    our $PAUSED = 0;
    our $VERSION = 'v1.2.2';
    if( exists( $ENV{MOD_PERL} )
        &&
        ( $MOD_PERL = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Log;
        require Apache2::Module;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
        require ModPerl::Util;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :log OK ) );
    }
};

use strict;
no warnings 'redefine';
my $mark = '__tiehash__';

sub TIEHASH
{
    my $this  = shift( @_ );
    my $opts  = {};
    $opts = shift( @_ ) if( @_ );
    if( ( Scalar::Util::reftype( $opts ) // '' ) ne 'HASH' )
    {
        warn( "Parameters provided ($opts) is not an hash reference.\n" ) if( warnings::enabled() );
        return;
    }
    my $disable = [];
    $disable = $opts->{disable} if( ( Scalar::Util::reftype( $opts->{disable} ) // '' ) eq 'ARRAY' );
    my $list = {};
    @$list{ @$disable } = (1) x scalar( @$disable );
    my $hash =
    {
        # The caller sets this to its class, so we can differentiate calls from inside and outside our caller's package
        disable => $list,
        debug => $opts->{debug},
        # When disabled, the Tie::Hash system will return hash key values directly under $self instead of $self->{data}
        # Disabled by default so the new() method can access its setup data directly under $self
        # Then new() can call enable to active it
        enable => 1,
        # Do we enable the use of object as hash key?
        key_object => $opts->{key_object} // 0,
        # Where to store the actual hash data
        data  => {},
        # object reference address -> value
        # This is used to store object as key
        object_repo => {},
    };
    my $self = bless( $hash => ( ref( $this ) || $this ) );
    return( $self );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $repo = $self->{object_repo};
    %$repo = ();
    %$data = ();
}

sub DELETE
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $repo = $self->{object_repo};
    my $key  = shift( @_ );
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        CORE::delete( $self->{ $key } );
    }
    else
    {
        if( ref( $key ) && $self->{key_object} )
        {
            CORE::delete( $repo->{ Scalar::Util::refaddr( $key ) } );
        }
        else
        {
            CORE::delete( $data->{ $key } );
        }
    }
}

sub EXISTS
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $repo = $self->{object_repo};
    my $key  = shift( @_ );
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        CORE::exists( $self->{ $key } );
    }
    else
    {
        if( ref( $key ) && $self->{key_object} )
        {
            CORE::exists( $repo->{ Scalar::Util::refaddr( $key ) } );
        }
        else
        {
            CORE::exists( $data->{ $key } );
        }
    }
}

sub FETCH
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $repo = $self->{object_repo};
    my $key  = shift( @_ );
    my $caller = caller;
    # require Devel::StackTrace;
    # my $trace = Devel::StackTrace->new;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        return( wantarray ? () : undef ) if( !CORE::exists( $self->{ $key } ) );
        return( $self->{ $key } )
    }
    else
    {
        if( ref( $key ) && $self->{key_object} )
        {
            return( $repo->{ Scalar::Util::refaddr( $key ) }->[1] );
        }
        else
        {
            return( wantarray ? () : undef ) if( !CORE::exists( $data->{ $key } ) );
            return( $data->{ $key } );
        }
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
    return( $self->NEXTKEY );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $repo = $self->{object_repo};
    my $keys = ref( $self->{ITERATOR} ) ? $self->{ITERATOR} : [];
    my $key = shift( @$keys );
    return if( !defined( $key ) );
    if( index( $key, $mark ) == 0 )
    {
        return( $repo->{ substr( $key, length( $mark ), -2 ) }->[0] );
    }
    return( $key );
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
    my $repo = $self->{object_repo};
    my( $key, $val ) = @_;
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    {
        # print( STDERR "STORE($caller)[owner calling] <- '$key' -> '$val'\n" );
        $self->{ $key } = $val;
    }
    else
    {
        # print( STDERR "STORE($caller)[non-owner calling] <- '$key' -> '$val' called from class ", [caller]->[0], " at line ", [caller]->[2], "\n" );
        # Ensure recursive tied hash
        if( ref( $val ) eq 'HASH' &&
            !tied( %$val ) )
        {
            my @items = %$val;
            my $this = tie( %$val, ref( $self ) );
            while( @items )
            {
                $this->STORE( splice( @items, 0, 2 ) );
            }
        }

        #print( STDERR "STORE($caller)[enable=$self->{enable}] <- '$key' -> '$val'\n" );
        if( ref( $key ) && $self->{key_object} )
        {
            my $addr = Scalar::Util::refaddr( $key );
            $repo->{ $addr } = [$key, $val];
            $data->{ "${mark}${addr}__" } = $val;
        }
        else
        {
            $data->{ $key } = $val;
        }
    }
}

sub enable
{
    my $self = shift( @_ );
    $self->{enable} = shift( @_ ) if( @_ );
    return( $self->{enable} );
}

sub key_object
{
    my $self = shift( @_ );
    $self->{key_object} = shift( @_ ) if( @_ );
    return( $self->{key_object} );
}

sub _exclude
{
    my $self = shift( @_ );
    my $caller = shift( @_ );
    return( !$PAUSED && CORE::exists( $self->{disable}->{ $caller } ) );
}

sub _message
{
    my $this = shift( @_ );
    my $self = ( ref( $this ) ? $this : {} );
    my $level = shift( @_ );
    return(1) if( $self->{debug} < $level );
    my( $pkg, $file, $line, @otherInfo ) = caller();
    my $sub = ( caller(1) )[3] // '';
    my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    my $txt = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @_ ) );
    my $prefix = '#';
    $txt    =~ s/\n$//gs;
    my $mesg = "${prefix} " . join( "\n${prefix} ", split( /\n/, $txt ) );
    if( $MOD_PERL )
    {
        require Apache2::ServerUtil;
        my $s = Apache2::ServerUtil->server;
        $s->log->debug( $mesg );
    }
    else
    {
        print( STDERR $mesg, "\n" );
    }
}

sub FREEZE
{
    my( $self, $serialiser ) = @_;
    # $serialiser is 'JSON' for example.
    return( $self->TO_JSON );
}

sub STORABLE_freeze
{
    my( $self, $is_cloning ) = @_;
    my $data = $self->{data};
    my $repo = $self->{object_repo};
    # Array reference of array reference, each containing the original key-object -> the corresponding value
    my $objects = [values( %$repo )];
    my $options = {};
    @$options{qw( disable debug enable )} = @$self{qw( disable debug enable )};
    return( 'module_generic_tiehash', $options, $objects, $data );
}

sub STORABLE_thaw
{
    my( $self, $is_cloning, $serialized, $options, $objects, $data ) = @_;
    my @keys = keys( %$options );
    @$self{ @keys } = @$options{ @keys };
    $self->{data} = $data;
    $self->{object_repo} = {};
    my $repo = $self->{object_repo};
    foreach my $ref ( @$objects )
    {
        $repo->{ Scalar::Util::refaddr( $ref->[0] ) } = $ref;
    }
    return( $self );
}

# Hmm, not sure this is meaningful unless we can find the original tied hash from the object
sub THAW
{
    my( $class, $serialiser, $ref ) = @_;
    my( $options, $objects, $data ) = @$ref{qw( options objects data )};
    my %hash;
    my $self = tie( %hash, $class, $options );
    foreach my $ref ( @$objects )
    {
        $hash{ $ref->[0] } = $ref->[1];
    }
    foreach my $k ( keys( %$ref ) )
    {
        $hash{ $k } = $ref->{ $k };
    }
    return( $self );
}

sub TO_JSON
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $repo = $self->{object_repo};
#     my( $pack, $file, $line ) = caller;
    # Array reference of array reference, each containing the original key-object -> the corresponding value
    my $objects = [values( %$repo )];
    my $options = {};
    @$options{qw( disable debug enable )} = @$self{qw( disable debug enable )};
    return({ options => $options, objects => $objects, data => $data });
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::TieHash - Generic Tie Hash Mechanism for Object Oriented Hashes

=head1 SYNOPSIS

    use DateTime;
    my $tie = tie( my %hash, 'Module::Generic::TieHash', { key_object => 1 } );
    my $now = DateTime->now;
    my $array = [];
    my $ref = {};
    my $scalar = \"Hello";
    my $code = sub{1};
    my $glob = \*main;

    $hash{ $now } = 'today';
    $hash{ $array } = 'an array';
    $hash{ $ref } = 'an hash';
    $hash{ $scalar } = 'a scalar reference';
    $hash{ $code } = 'anonymous subroutine';
    $hash{ $glob } = 'a filehandle';
    $hash{name} = 'John Doe';

=head1 DESCRIPTION

This module implements a tied hash mechanism that accepts as keys strings or references, if the option C<key_object> is enabled, recursively, meaning, even embedded hash references within the top hash reference are also tied to this class.

It also supports callback hooks for L<Storable>

The constructor C<TIEHASH> supports the following options provided as an hash reference:

=over 4

=item * C<debug>

The debug value as an integer.

=item * C<disable>

An array reference of module classes for which this package will give direct access to the tie object rather to the data stored.

To avoid conflict, the object properties and the tied hash properties are stored in different parts of the tied object.

By default, L<Module::Generic> is part of the exclusion list for which this tied object is disabled.

=item * C<key_object>

Boolean. If true, this allows for the storing of objects as hash keys. Normally, perl would stringify an object to use it as an hash key.

=back

Also, if you set the global variable C<$PAUSED>, then, the exclusion mechanism will be disabled, and during that time, any access to the tied hash will return data stored in it, rather than the object properties.

=head1 VERSION

    v1.2.2

=for Pod::Coverage key_object

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2024 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
