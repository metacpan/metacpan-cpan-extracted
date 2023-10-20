##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Iterator.pm
## Version v1.1.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2022/08/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Iterator;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use Module::Generic::Array;
    use Scalar::Util ();
    use Want;
    our( $VERSION ) = 'v1.1.1';
};

use strict;
no warnings 'redefine';

sub init
{
    my $self = CORE::shift( @_ );
    my $init = [];
    $init = CORE::shift( @_ ) if( @_ && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    my $elems = Module::Generic::Array->new;
    ## Wrap each element in an Iterator element to enable next, prev, etc
    foreach my $this ( @$init )
    {
        CORE::push( @$elems, Module::Generic::Iterator::Element->new( $this, { parent => $self, debug => $self->debug } ) );
    }
    $self->{elements} = $elems;
    $self->{pos} = 0;
    return( $self );
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

sub eof
{
    my $self = shift( @_ );
    my $pos;
    if( @_ )
    {
        $pos  = $self->_find_pos( @_ );
        return if( !CORE::defined( $pos ) );
    }
    else
    {
        $pos = $self->pos;
    }
    return( $pos >= ( $self->elements->length - 1 ) );
}

sub find
{
    my $self = shift( @_ );
    my $pos  = $self->_find_pos( @_ );
    return if( !CORE::defined( $pos ) );
    return( $self->elements->index( $pos ) );
}

sub first
{
    my $self = shift( @_ );
    $self->pos = 0;
    return( $self->elements->index( 0 ) );
}

sub has_next
{
    my $self = shift( @_ );
    my $pos  = $self->pos;
    return( $pos < ( $self->elements->length - 1 ) );
}

sub has_prev
{
    my $self = shift( @_ );
    my $pos  = $self->pos;
    return( $pos > 0 && $self->elements->length > 0 );
}

sub last
{
    my $self = shift( @_ );
    my $pos = $self->elements->length - 1;
    $self->pos = $pos;
    return( $self->elements->index( $pos ) );
}

sub length { return( shift->elements->length ); }

sub next
{
    my $self = shift( @_ );
    my $pos;
    if( @_ )
    {
        $pos = $self->_find_pos( @_ );
        return if( !CORE::defined( $pos ) );
        return if( $pos >= ( $self->elements->length - 1 ) );
        $pos++;
    }
    else
    {
        return if( $self->eof );
        $self->pos++;
        $pos = $self->pos;
    }
    return( $self->elements->index( $pos ) );
}

sub pos : lvalue
{
    my $self = shift( @_ );
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        my( $a ) = want( 'ASSIGN' );
        if( $a !~ /^\d+$/ )
        {
            CORE::warn( "Position provided \"$a\" is not an integer.\n" );
            lnoreturn;
        }
        $self->{pos} = $a;
        lnoreturn;
    }
    elsif( want( 'RVALUE' ) )
    {
        rreturn( $self->{pos} );
    }
    else
    {
        return( $self->{pos} );
    }
    return;
}

sub prev
{
    my $self = shift( @_ );
    my $pos;
    if( @_ )
    {
        $pos  = $self->_find_pos( @_ );
        return if( !CORE::defined( $pos ) );
        return if ( $pos <= 0 );
        $pos--;
    }
    else
    {
        $self->pos-- if( $self->pos > 0 );
        # Position of the given element is at the beginning of our array, there is nothing more
        $pos = $self->pos;
        return if( $pos <= 0 );
        # $self->pos--;
    }
    return( $self->elements->index( $pos ) );
}

sub reset
{
    my $self = shift( @_ );
    $self->pos = 0;
    return( $self );
}

sub _find_pos
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return if( !CORE::length( $this ) );
    my $is_ref = ref( $this );
    my $ref = $is_ref ? Scalar::Util::refaddr( $this ) : $this;
    my $elems = $self->elements;
    foreach my $i ( 0 .. $#$elems )
    {
        my $val = $elems->[$i]->value;
        if( ( $is_ref && Scalar::Util::refaddr( $elems->[$i] ) eq $ref ) ||
            ( !$is_ref && $val eq $this ) )
        {
            return( $i );
        }
    }
    return;
}

# NOTE: FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: THAW is inherited

# NOTE: package Module::Generic::Iterator::Element
package Module::Generic::Iterator::Element;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use Want;
    our( $VERSION ) = 'v0.1.0';
};

sub init
{
    my $self = CORE::shift( @_ );
    ## This could be anything
    my $value = CORE::shift( @_ );
    $self->{value}      = '';
    $self->{parent}     = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{value} = $value;
    return( $self );
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub has_next
{
    my $self = shift( @_ );
    my $pos = $self->pos;
    return( $pos < ( $self->parent->elements->length - 1 ) );
}

sub has_prev
{
    my $self = shift( @_ );
    my $pos  = $self->pos;
    return( $pos > 0 && $self->parent->elements->length > 0 );
}

sub next
{
    my $self = shift( @_ );
    my $next = $self->parent->next( $self );
    if( want( 'OBJECT' ) )
    {
        return( $next );
    }
    else
    {
        return( $next->value );
    }
}

sub parent { return( shift->_set_get_object( 'parent', 'Module::Generic::Iterator', @_ ) ); }

sub pos { return( $_[0]->parent->_find_pos( $_[0] ) ); }

sub prev
{
    my $self = shift( @_ );
    my $prev = $self->parent->prev( $self );
    if( want( 'OBJECT' ) )
    {
        return( $prev );
    }
    else
    {
        return( $prev->value );
    }
}

sub value { return( shift->{value} ); }

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
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
