##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Array.pm
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
package Module::Generic::Array;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use Module::Generic::Hash;
    use Module::Generic::Iterator;
    use Module::Generic::Null;
    use Module::Generic::Number;
    use Module::Generic::Scalar;
    use Scalar::Util ();
    use Want;
    use overload (
        # Turned out to be not such a good ide as it create unexpected results, especially when this is an array of overloaded objects
        # '""'  => 'as_string',
        '=='  => sub { _obj_eq(@_) },
        '!='  => sub { !_obj_eq(@_) },
        'eq'  => sub { _obj_eq(@_) },
        'ne'  => sub { !_obj_eq(@_) },
        '%{}' => 'as_hash',
        fallback => 1,
    );
    our( $VERSION ) = 'v1.0.0';
};

sub new
{
    my $this = CORE::shift( @_ );
    my $init = [];
    $init = CORE::shift( @_ ) if( @_ && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) );
    return( bless( $init => ( ref( $this ) || $this ) ) );
}

sub as_hash
{
    my $self = CORE::shift( @_ );
    my $opts = {};
    $opts = CORE::shift( @_ ) if( Scalar::Util::reftype( $opts ) eq 'HASH' );
    my $ref = {};
    my( @offsets ) = $self->keys;
    if( $opts->{start_from} )
    {
        my $start = CORE::int( $opts->{start_from} );
        for my $i ( 0..$#offsets )
        {
            $offsets[ $i ] += $start;
        }
    }
    @$ref{ @$self } = @offsets;
    return( Module::Generic::Hash->new( $ref ) );
}

sub as_string
{
    my $self = CORE::shift( @_ );
    my $sort = 0;
    $sort = CORE::shift( @_ ) if( @_ );
    return( $self->sort->as_string ) if( $sort );
    return( "@$self" );
}

sub clone { return( $_[0]->new( [ @{$_[0]} ] ) ); }

sub delete
{
    my $self = CORE::shift( @_ );
    my( $offset, $length ) = @_;
    if( defined( $offset ) )
    {
        if( $offset !~ /^\-?\d+$/ )
        {
            warn( "Non integer offset \"$offset\" provided to delete array element\n" ) if( $self->_warnings_is_enabled );
            return( $self );
        }
        if( CORE::defined( $length ) && $length !~ /^\-?\d+$/ )
        {
            warn( $self, "Non integer length \"$length\" provided to delete array element\n" ) if( $self->_warnings_is_enabled );
            return( $self );
        }
        my @removed = CORE::splice( @$self, $offset, CORE::defined( $length ) ? CORE::int( $length ) : 1 );
        if( Want::want( 'LIST' ) )
        {
            rreturn( @removed );
        }
        else
        {
            rreturn( $self->new( \@removed ) );
        }
        # Required to make the compiler happy, as per Want documentation
        return;
    }
    return( $self );
}

sub each
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ ) || do
    {
        warn( "No subroutine callback as provided for each\n" ) if( $self->_warnings_is_enabled );
        return;
    };
    if( ref( $code ) ne 'CODE' )
    {
        warn( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead.\n" ) if( $self->_warnings_is_enabled );
        return;
    }
    ## Index starts from 0
    while( my( $i, $v ) = CORE::each( @$self ) )
    {
        local $_ = $v;
        CORE::defined( $code->( $i, $v ) ) || CORE::last;
    }
    return( $self );
}

sub exists
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    return( $self->_number( CORE::scalar( CORE::grep( /^$this$/, @$self ) ) ) );
}

sub first
{
    my $self = CORE::shift( @_ );
    return( $self->[0] ) if( CORE::length( $self->[0] ) );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Module::Generic::Null->new );
    }
    return( $self->[0] );
}

sub for
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    CORE::for( my $i = 0; $i < scalar( @$self ); $i++ )
    {
        local $_ = $self->[ $i ];
        CORE::defined( $code->( $i, $self->[ $i ] ) ) || CORE::last;
    }
    return( $self );
}

sub foreach
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    CORE::foreach my $v ( @$self )
    {
        local $_ = $v;
        CORE::defined( $code->( $v ) ) || CORE::last;
    }
    return( $self );
}

sub get
{
    my $self = CORE::shift( @_ );
    my $offset = CORE::shift( @_ );
    return( $self->[ CORE::int( $offset ) ] );
}

sub grep
{
    my $self = CORE::shift( @_ );
    my $expr = CORE::shift( @_ );
    my $ref;
    if( ref( $expr ) eq 'CODE' )
    {
        $ref = [CORE::grep( $expr->( $_ ), @$self )];
    }
    else
    {
        $expr = ref( $expr ) eq 'Regexp'
            ? $expr
            : qr/\Q$expr\E/;
        $ref = [ CORE::grep( $_ =~ /$expr/, @$self ) ];
    }
    if( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub has { return( CORE::shift->exists( @_ ) ); }

sub index
{
    my $self = CORE::shift( @_ );
    my $pos  = CORE::shift( @_ );
    $pos = CORE::int( $pos );
    return( $self->[ $pos ] );
}

sub iterator { return( Module::Generic::Iterator->new( $self ) ); }

sub join
{
    my $self = CORE::shift( @_ );
    return( $self->_scalar( CORE::join( $_[0], @$self ) ) );
}

sub keys
{
    my $self = CORE::shift( @_ );
    return( $self->new( [ CORE::keys( @$self ) ] ) );
}

sub last
{
    my $self = CORE::shift( @_ );
    return( $self->[-1] ) if( CORE::length( $self->[-1] ) );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Module::Generic::Null->new );
    }
    return( $self->[-1] );
}

sub length { return( $_[0]->_number( scalar( @{$_[0]} ) ) ); }

sub list { return( @{$_[0]} ); }

sub map
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    my $ref = [ CORE::map( $code->( $_ ), @$self ) ];
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->new( $ref ) );
    }
    elsif( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub pop
{
    my $self = CORE::shift( @_ );
    return( CORE::pop( @$self ) );
}

sub pos
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    return if( !CORE::length( $this ) );
    my $is_ref = ref( $this );
    my $ref = $is_ref ? Scalar::Util::refaddr( $this ) : $this;
    foreach my $i ( 0 .. $#$self )
    {
        if( ( $is_ref && Scalar::Util::refaddr( $self->[$i] ) eq $ref ) ||
            ( !$is_ref && $self->[$i] eq $this ) )
        {
            return( $i );
        }
    }
    return;
}

sub push
{
    my $self = CORE::shift( @_ );
    CORE::push( @$self, @_ );
    return( $self );
}

sub push_arrayref
{
    my $self = CORE::shift( @_ );
    my $ref = CORE::shift( @_ );
    return( $self->error( "Data provided ($ref) is not an array reference." ) ) if( !UNIVERSAL::isa( $ref, 'ARRAY' ) );
    CORE::push( @$self, @$ref );
    return( $self );
}

sub reset
{
    my $self = CORE::shift( @_ );
    @$self = ();
    return( $self );
}

sub reverse
{
    my $self = CORE::shift( @_ );
    my $ref = [ CORE::reverse( @$self ) ];
    if( wantarray() )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub scalar { return( CORE::shift->length ); }

sub set
{
    my $self = CORE::shift( @_ );
    my $ref = ( scalar( @_ ) == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? CORE::shift( @_ ) : [ @_ ];
    @$self = @$ref;
    return( $self );
}

sub shift
{
    my $self = CORE::shift( @_ );
    return( CORE::shift( @$self ) );
}

sub size { return( $_[0]->_number( $#{$_[0]} ) ); }

sub sort
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    my $ref;
    if( ref( $code ) eq 'CODE' )
    {
        $ref = [sort 
        {
            $code->( $a, $b );
        } @$self];
    }
    else
    {
        $ref = [ CORE::sort( @$self ) ];
    }
    if( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub splice
{
    my $self = CORE::shift( @_ );
    my( $offset, $length, @list ) = @_;
    if( defined( $offset ) && $offset !~ /^\-?\d+$/ )
    {
        warn( "Offset provided for splice \"$offset\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        ## If a list was provided, the user is not looking to get an element removed, but add it, so we return out object
        return( $self ) if( scalar( @list ) );
        return;
    }
    if( defined( $length ) && $length !~ /^\-?\d+$/ )
    {
        warn( "Length provided for splice \"$length\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        return( $self ) if( scalar( @list ) );
        return;
    }
    ## Adding elements, so we return our object and allow chaining
    ## @_ = offset, length, replacement list
    if( scalar( @_ ) > 2 )
    {
        CORE::splice( @$self, $offset, $length, @list );
        return( $self );
    }
    elsif( !scalar( @_ ) )
    {
        CORE::splice( @$self );
        return( $self );
    }
    else
    {
        return( CORE::splice( @$self, $offset, $length ) ) if( CORE::defined( $offset ) && CORE::defined( $length ) );
        return( CORE::splice( @$self, $offset ) ) if( CORE::defined( $offset ) );
    }
}

sub undef
{
    my $self = CORE::shift( @_ );
    @$self = ();
    return( $self );
}

sub unshift
{
    my $self = CORE::shift( @_ );
    CORE::unshift( @$self, @_ );
    return( $self );
}

sub values
{
    my $self = CORE::shift( @_ );
    my $ref = [ CORE::values( @$self ) ];
    if( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub _number
{
    my $self = CORE::shift( @_ );
    my $num = CORE::shift( @_ );
    return if( !defined( $num ) );
    return( $num ) if( !CORE::length( $num ) );
    return( Module::Generic::Number->new( $num ) );
}

sub _obj_eq
{
    no overloading;
    my $self = CORE::shift( @_ );
    my $other = CORE::shift( @_ );
    ## Sorted
    my $strA = $self->as_string(1);
    my $strB;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Array' ) )
    {
        $strB = $other->as_string(1);
    }
    ## Compare error message
    elsif( Scalar::Util::reftype( $other ) eq 'ARRAY' )
    {
        $strB = $self->new( $other )->as_string(1);
    }
    else
    {
        return( 0 );
    }
    return( $strA eq $strB ) ;
}

sub _scalar
{
    my $self = CORE::shift( @_ );
    my $str  = CORE::shift( @_ );
    return if( !defined( $str ) );
    ## Whether empty or not, return an object
    return( Module::Generic::Scalar->new( $str ) );
}

sub _warnings_is_enabled { return( warnings::enabled( ref( $_[0] ) || $_[0] ) ); }

1;

__END__
