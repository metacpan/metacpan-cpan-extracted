##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Array.pm
## Version v1.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/08/31
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
    use List::Util ();
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
    our $RETURN = {};
    our( $VERSION ) = 'v1.1.0';
};

sub new
{
    my $this = CORE::shift( @_ );
    my $init = [];
    if( @_ )
    {
        if( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || 
            ref( $_[0] ) eq 'ARRAY' )
        {
            $init = CORE::shift( @_ );
        }
        else
        {
            $init = [@_];
        }
    }
    CORE::return( bless( $init => ( ref( $this ) || $this ) ) );
}

sub as_array { CORE::return( $_[0] ); }

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
    CORE::return( Module::Generic::Hash->new( $ref ) );
}

sub as_string
{
    my $self = CORE::shift( @_ );
    my $sort = 0;
    $sort = CORE::shift( @_ ) if( @_ );
    CORE::return( $self->sort->as_string ) if( $sort );
    CORE::return( "@$self" );
}

sub chomp
{
    my $self = CORE::shift( @_ );
    CORE::chomp( @$self );
    CORE::return( $self );
}

sub clone { CORE::return( $_[0]->new( [ @{$_[0]} ] ) ); }

sub contains { CORE::return( CORE::shift->exists( @_ ) ); }

sub delete
{
    my $self = CORE::shift( @_ );
    my( $offset, $length ) = @_;
    if( defined( $offset ) )
    {
        if( $offset !~ /^\-?\d+$/ )
        {
            warn( "Non integer offset \"$offset\" provided to delete array element\n" ) if( $self->_warnings_is_enabled );
            CORE::return( $self );
        }
        if( CORE::defined( $length ) && $length !~ /^\-?\d+$/ )
        {
            warn( $self, "Non integer length \"$length\" provided to delete array element\n" ) if( $self->_warnings_is_enabled );
            CORE::return( $self );
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
        CORE::return;
    }
    CORE::return( $self );
}

sub each
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ ) || do
    {
        warn( "No subroutine callback as provided for each\n" ) if( $self->_warnings_is_enabled );
        CORE::return;
    };
    if( ref( $code ) ne 'CODE' )
    {
        warn( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead.\n" ) if( $self->_warnings_is_enabled );
        CORE::return;
    }
    ## Index starts from 0
    while( my( $i, $v ) = CORE::each( @$self ) )
    {
        local $_ = $v;
        CORE::defined( $code->( $i, $v ) ) || CORE::last;
    }
    CORE::return( $self );
}

sub eighth { CORE::return( CORE::shift->get_null(7) ); }

sub empty { CORE::return( CORE::shift->reset( @_ ) ); }

# Credits: <https://www.perlmonks.org/?node_id=871696>
sub even
{
    my $self = CORE::shift( @_ );
    my @new = @$self[ CORE::grep( !($_ % 2), 0..$#$self ) ];
    CORE::return( $self->new( \@new ) );
}

sub exists
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    CORE::return( $self->_number( CORE::scalar( CORE::grep( /^$this$/, @$self ) ) ) );
}

sub fifth { CORE::return( CORE::shift->get_null(4) ); }

sub first { CORE::return( CORE::shift->get_null(0) ); }

sub for
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    CORE::return if( ref( $code ) ne 'CODE' );
    $self->return_reset;
    CORE::for( my $i = 0; $i < scalar( @$self ); $i++ )
    {
        local $_ = $self->[ $i ];
        # CORE::defined( $code->( $i, $self->[ $i ] ) ) || CORE::last;
        my $rv = $code->( $i, $self->[ $i ] );
        CORE::last if( !CORE::defined( $rv ) );
        if( defined( my $ret = $self->return ) )
        {
            $rv = $ret;
            $self->return_reset;
        }
        
        if( CORE::ref( $rv ) eq 'SCALAR' )
        {
            if( $$rv =~ /^[\-\+]?\d+$/ )
            {
                $i += int( $$rv );
            }
            elsif( !defined( $$rv ) )
            {
                CORE::last;
            }
        }
    }
    CORE::return( $self );
}

sub foreach
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    CORE::return if( ref( $code ) ne 'CODE' );
    my $i;
    CORE::foreach my $v ( @$self )
    {
        local $_ = $v;
        my $rv = $code->( $v );
        CORE::defined( $rv ) || CORE::last;
        if( CORE::defined( my $ret = $self->return ) )
        {
            $rv = $ret;
            $self->return_reset;
        }
        if( CORE::ref( $rv ) eq 'SCALAR' )
        {
            if( $$rv =~ /^[\-\+]?\d+$/ )
            {
                $i += int( $$rv );
            }
            elsif( !defined( $$rv ) )
            {
                CORE::last;
            }
        }
    }
    $self->return_reset;
    CORE::return( $self );
}

sub fourth { CORE::return( CORE::shift->get_null(3) ); }

sub get
{
    my $self = CORE::shift( @_ );
    my $offset = CORE::int( CORE::shift( @_ ) );
    # offset may be out of bound, which will lead Module::Generic::Scalar to hold an undefined value or the offset exists but contains an undef value which will lead to the same
    if( want( 'OBJECT' ) && ( !ref( $self->[ $offset ] ) || Scalar::Util::reftype( $self->[ $offset ] ) eq 'SCALAR' ) )
    {
        rreturn( Module::Generic::Scalar->new( $self->[ $offset ] ) );
    }
    # If the enclosed value is a regular ref like array or hash and user wants an object, this will trigger an error, but that is the user's fault. I think it would be bad design to prevent the error from happening and second guess what the user is trying to do.
    else
    {
        CORE::return( $self->[ $offset ] );
    }
}

sub get_null
{
    my $self = CORE::shift( @_ );
    my $offset = CORE::int( CORE::shift( @_ ) );
    if( CORE::defined( $self->[ $offset ] ) && CORE::length( $self->[ $offset ] ) )
    {
        if( want( 'OBJECT' ) && ( !ref( $self->[ $offset ] ) || Scalar::Util::reftype( $self->[ $offset ] ) eq 'SCALAR' ) )
        {
            rreturn( Module::Generic::Scalar->new( $self->[ $offset ] ) );
        }
        # If the enclosed value is a regular ref like array or hash and user wants an object, this will trigger an error, but that is the user's fault. I think it would be bad design to prevent the error from happening and second guess what the user is trying to do.
        else
        {
            CORE::return( $self->[ $offset ] );
        }
    }
    else
    {
        if( Want::want( 'OBJECT' ) )
        {
            rreturn( Module::Generic::Null->new( wants => 'object' ) );
        }
        CORE::return( $self->[ $offset ] );
    }
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
        CORE::return( @$ref );
    }
    else
    {
        CORE::return( $self->new( $ref ) );
    }
}

sub has { CORE::return( CORE::shift->exists( @_ ) ); }

# Same as get. Maybe I should alias it
sub index
{
    my $self = CORE::shift( @_ );
    my $pos  = CORE::int( CORE::shift( @_ ) );
    if( want( 'OBJECT' ) && ( !ref( $self->[ $pos ] ) || Scalar::Util::reftype( $self->[ $pos ] ) eq 'SCALAR' ) )
    {
        rreturn( Module::Generic::Scalar->new( $self->[ $pos ] ) );
    }
    else
    {
        CORE::return( $self->[ $pos ] );
    }
}

sub intersection
{
    my $self  = CORE::shift( @_ );
    my $other = $self->new( @_ );
    my $hash  = $self->as_hash;
    my $new   = $other->grep(sub{ CORE::exists( $hash->{ $_ } ) });
    CORE::return( $new );
}

sub iterator { CORE::return( Module::Generic::Iterator->new( $self ) ); }

sub join
{
    my $self = CORE::shift( @_ );
    CORE::return( $self->_scalar( CORE::join( shift( @_ ), @$self, @_ ) ) );
}

sub keys
{
    my $self = CORE::shift( @_ );
    CORE::return( $self->new( [ CORE::keys( @$self ) ] ) );
}

sub last { CORE::return( CORE::shift->get_null(-1) ); }

sub length { CORE::return( $_[0]->_number( scalar( @{$_[0]} ) ) ); }

sub list { CORE::return( @{$_[0]} ); }

sub map
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    CORE::return if( ref( $code ) ne 'CODE' );
    my $ref = [ CORE::map( $code->( $_ ), @$self ) ];
    if( Want::want( 'OBJECT' ) )
    {
        CORE::return( $self->new( $ref ) );
    }
    elsif( Want::want( 'LIST' ) )
    {
        CORE::return( @$ref );
    }
    else
    {
        CORE::return( $self->new( $ref ) );
    }
}

sub max
{
    my $self = CORE::shift( @_ );
    return( Module::Generic::Scalar->new( List::Util::max( @$self ) ) );
}

sub merge
{
    my $self = CORE::shift( @_ );
    # First check before modifying anything
    for( @_ )
    {
        CORE::return( $self->error( "Value provided (", overload::StrVal( $_ ), ") is not an Module::Generic::Array object." ) ) if( !Scalar::Util::blessed( $_ ) || !$_->isa( 'Module::Generic::Array' ) );
    }
    # Now, we modify
    for( @_ )
    {
        CORE::push( @$self, @$_ );
    }
    CORE::return( $self );
}

sub min
{
    my $self = CORE::shift( @_ );
    return( Module::Generic::Scalar->new( List::Util::min( @$self ) ) );
}

sub ninth { CORE::return( CORE::shift->get_null(8) ); }

sub object { return( $_[0] ); }

# Credits: <https://www.perlmonks.org/?node_id=871696>
sub odd
{
    my $self = CORE::shift( @_ );
    my @new = @$self[ CORE::grep( ($_ % 2), 0..$#$self ) ];
    CORE::return( $self->new( \@new ) );
}

sub offset
{
    my $self = CORE::shift( @_ );
    my( $pos, $len ) = @_;
    if( scalar( @_ ) >= 2 )
    {
        CORE::return(
            int( $len ) < 0 
                ? $self->new( [ @$self[ ( int( $pos ) + int( $len ) )..int( $pos ) ] ] )
                : $self->new( [ @$self[ int( $pos )..( int( $pos ) + ( int( $len ) - 1 ) ) ] ] )
        );
    }
    else
    {
        CORE::return( $self->new( [ @$self[ int( $pos )..$#$self ] ] ) );
    }
}

sub pack
{
    my $self = CORE::shift( @_ );
    CORE::return( $self->_scalar( CORE::pack( $_[0], @$self ) ) );
}

sub pop
{
    my $self = CORE::shift( @_ );
    if( Want::want( 'OBJECT' ) && ( !ref( $self->[-1] ) || Scalar::Util::reftype( $self->[-1] ) eq 'SCALAR' ) )
    {
        rreturn( Module::Generic::Scalar->new( CORE::pop( @$self ) ) );
    }
    else
    {
        CORE::return( CORE::pop( @$self ) );
    }
}

sub pos
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    CORE::return if( !CORE::length( $this ) );
    my $is_ref = ref( $this );
    my $ref = $is_ref ? Scalar::Util::refaddr( $this ) : $this;
    foreach my $i ( 0 .. $#$self )
    {
        if( ( $is_ref && Scalar::Util::refaddr( $self->[$i] ) eq $ref ) ||
            ( !$is_ref && $self->[$i] eq $this ) )
        {
            CORE::return( $i );
        }
    }
    CORE::return;
}

sub push
{
    my $self = CORE::shift( @_ );
    CORE::push( @$self, @_ );
    CORE::return( $self );
}

sub push_arrayref
{
    my $self = CORE::shift( @_ );
    my $ref = CORE::shift( @_ );
    CORE::return( $self->error( "Data provided ($ref) is not an array reference." ) ) if( !UNIVERSAL::isa( $ref, 'ARRAY' ) );
    CORE::push( @$self, @$ref );
    CORE::return( $self );
}

sub remove
{
    my $self = CORE::shift( @_ );
    my $ref;
    if( scalar( @_ ) == 1 && 
        Scalar::Util::blessed( $_[0] ) && 
        $_[0]->isa( 'Module::Generic::Array' ) )
    {
        $ref = CORE::shift( @_ );
    }
    elsif( scalar( @_ ) == 1 &&
           Scalar::Util::reftype( $_[0] ) eq 'ARRAY' )
    {
        $ref = $self->new( CORE::shift( @_ ) );
    }
    else
    {
        $ref = $self->new( [ @_ ] );
    }
    my $hash = $ref->as_hash;
    my @res = grep{ !CORE::exists( $hash->{ $_ } ) } @$self;
    @$self = @res;
    CORE::return( $self );
}

sub reset
{
    my $self = CORE::shift( @_ );
    @$self = ();
    CORE::return( $self );
}

sub return
{
    my $self = CORE::shift( @_ );
    my $id   = Scalar::Util::refaddr( $self );
    if( @_ )
    {
        $RETURN->{ $id } = \( CORE::shift( @_ ) );
        CORE::return( undef() ) if( !CORE::defined( ${$RETURN->{ $id }} ) );
    }
    CORE::return( $RETURN->{ $id } );
}

sub return_reset
{
    my $self = CORE::shift( @_ );
    my $id   = Scalar::Util::refaddr( $self );
    CORE::return( CORE::delete( $RETURN->{ $id } ) );
}

sub reverse
{
    my $self = CORE::shift( @_ );
    my $ref = [ CORE::reverse( @$self ) ];
    if( wantarray() )
    {
        CORE::return( @$ref );
    }
    else
    {
        CORE::return( $self->new( $ref ) );
    }
}

sub scalar { CORE::return( CORE::shift->length ); }

sub second { CORE::return( CORE::shift->get_null(1) ); }

sub set
{
    my $self = CORE::shift( @_ );
    my $ref = ( scalar( @_ ) == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? CORE::shift( @_ ) : [ @_ ];
    @$self = @$ref;
    CORE::return( $self );
}

sub seventh { CORE::return( CORE::shift->get_null(6) ); }

sub shift
{
    my $self = CORE::shift( @_ );
    if( Want::want( 'OBJECT' ) && ( !ref( $self->[0] ) || Scalar::Util::reftype( $self->[0] ) eq 'SCALAR' ) )
    {
        rreturn( Module::Generic::Scalar->new( CORE::shift( @$self ) ) );
    }
    else
    {
        CORE::return( CORE::shift( @$self ) );
    }
}

sub sixth { CORE::return( CORE::shift->get_null(5) ); }

sub size { CORE::return( $_[0]->_number( $#{$_[0]} ) ); }

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
        CORE::return( @$ref );
    }
    else
    {
        CORE::return( $self->new( $ref ) );
    }
}

sub splice
{
    my $self = CORE::shift( @_ );
    my( $offset, $length, @list ) = @_;
    if( defined( $offset ) && int( $offset ) !~ /^\-?\d+$/ )
    {
        warn( "Offset provided for splice \"$offset\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        ## If a list was provided, the user is not looking to get an element removed, but add it, so we return out object
        CORE::return( $self ) if( scalar( @list ) );
        CORE::return;
    }
    if( defined( $length ) && int( $length ) !~ /^\-?\d+$/ )
    {
        warn( "Length provided for splice \"$length\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        CORE::return( $self ) if( scalar( @list ) );
        CORE::return;
    }
    ## Adding elements, so we return our object and allow chaining
    ## @_ = offset, length, replacement list
    if( scalar( @_ ) > 2 )
    {
        CORE::splice( @$self, int( $offset ), int( $length ), @list );
        CORE::return( $self );
    }
    elsif( !scalar( @_ ) )
    {
        CORE::splice( @$self );
        CORE::return( $self );
    }
    else
    {
        if( CORE::defined( $offset ) && CORE::defined( $length ) )
        {
            if( Want::want( 'OBJECT' ) )
            {
                rreturn( $self->new( [CORE::splice( @$self, int( $offset ), int( $length ) )] ) );
            }
            else
            {
                CORE::return( CORE::splice( @$self, int( $offset ), int( $length ) ) );
            }
        }
        elsif( CORE::defined( $offset ) )
        {
            if( Want::want( 'OBJECT' ) )
            {
                rreturn( $self->new( [CORE::splice( @$self, int( $offset ) )] ) );
            }
            else
            {
                CORE::return( CORE::splice( @$self, int( $offset ) ) );
            }
        }
    }
}

# my $a = $ar->split( qr/[[:blank:]\h]+/, "I disapprove of what you say, but I will defend to the death your right to say it" );
sub split { CORE::return( CORE::shift->_scalar( CORE::splice( @_, 1, 1 ) )->split( @_ ) ); }

sub tenth { CORE::return( CORE::shift->get_null(9) ); }

sub third { CORE::return( CORE::shift->get_null(2) ); }

sub TO_JSON { CORE::return( [ @{$_[0]} ] ); }

sub undef
{
    my $self = CORE::shift( @_ );
    @$self = ();
    CORE::return( $self );
}

sub unique
{
    my $self = CORE::shift( @_ );
    my $self_update = 0;
    $self_update = CORE::shift( @_ ) if( @_ );
    my @new = List::Util::uniq( @$self );
    CORE::return( $self->new( \@new ) ) unless( $self_update );
    @$self = @new;
    CORE::return( $self );
}

sub unshift
{
    my $self = CORE::shift( @_ );
    CORE::unshift( @$self, @_ );
    CORE::return( $self );
}

sub values
{
    my $self = CORE::shift( @_ );
    my $ref = [ CORE::values( @$self ) ];
    if( Want::want( 'LIST' ) )
    {
        CORE::return( @$ref );
    }
    else
    {
        CORE::return( $self->new( $ref ) );
    }
}

sub _number
{
    my $self = CORE::shift( @_ );
    my $num = CORE::shift( @_ );
    CORE::return if( !defined( $num ) );
    CORE::return( $num ) if( !CORE::length( $num ) );
    CORE::return( Module::Generic::Number->new( $num ) );
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
        CORE::return( 0 );
    }
    CORE::return( $strA eq $strB ) ;
}

sub _scalar
{
    my $self = CORE::shift( @_ );
    my $str  = CORE::shift( @_ );
    CORE::return if( !defined( $str ) );
    # Whether empty or not, return an object
    CORE::return( Module::Generic::Scalar->new( $str ) );
}

sub _warnings_is_enabled { CORE::return( warnings::enabled( ref( $_[0] ) || $_[0] ) ); }

1;

__END__
