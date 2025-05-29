##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Array.pm
## Version v2.2.3
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2025/05/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Array;
BEGIN
{
    use v5.26.1;
    use common::sense;
    use warnings;
    use warnings::register;
    use vars qw( $DEBUG $ERROR $TRUE $FALSE );
    use List::Util ();
    use Scalar::Util ();
    use Wanted;
    no warnings;
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
    use constant BREAK_LOOP => 'BREAK';

    use Module::Generic::Global ':const';

    $DEBUG = 0;
    our $VERSION = 'v2.2.3';
};

use v5.26.1;
use strict;
no warnings 'redefine';
require Module::Generic::Boolean;

{
    no strict 'refs';
    $TRUE  = ${"Module::Generic::Boolean::true"};
    $FALSE = ${"Module::Generic::Boolean::false"};
}

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

sub append { CORE::return( CORE::shift->push( @_ ) ); }

sub as_array { CORE::return( $_[0] ); }

sub as_hash
{
    my $self = CORE::shift( @_ );
    my $opts = {};
    $opts = CORE::shift( @_ ) if( ( Scalar::Util::reftype( $opts ) // '' ) eq 'HASH' );
    # my $ref = {};
    my $offsets = $self->keys;
    if( $opts->{start_from} )
    {
        my $start = CORE::int( $opts->{start_from} );
        for my $i ( 0..$#$offsets )
        {
            $offsets->[ $i ] += $start;
        }
    }

    $self->_load_class( 'Module::Generic::Hash' ) ||
        CORE::return( $self->pass_error );
    # Since our array might contain reference, we instantiate first our special hash object, and then we add into it our elements
    # Module::Generic::Hash, that uses Module::Generic::TieHash, knows how to handle keys as reference
    my $ref = Module::Generic::Hash->new;
    @$ref{ @$self } = @$offsets;
    CORE::return( $ref );
}

sub as_string
{
    my $self = CORE::shift( @_ );
    my $sort = 0;
    $sort = CORE::shift( @_ ) if( @_ );
    CORE::return( $self->sort->as_string ) if( $sort );
    CORE::return( "@$self" );
}

sub break
{
    my $self = CORE::shift( @_ );
    my $repo = Module::Generic::Global->new( 'return' => $self );
    my $val  = BREAK_LOOP;
    $repo->set( $val );
    CORE::return( $val );
}

sub callback
{
    my $self = CORE::shift( @_ );
    my( $what, $code ) = @_;
    if( !defined( $what ) )
    {
        warnings::warn( "No callback type was provided.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) );
        CORE::return;
    }
    elsif( $what ne 'add' && $what ne 'remove' )
    {
        warnings::warn( "Callback type provided ($what) is unsupported. Use 'add' or 'remove'.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) );
        CORE::return;
    }
    elsif( CORE::scalar( @_ ) == 1 )
    {
        warnings::warn( "No callback code was provided. Provide an anonymous subroutine, or reference to existing subroutine.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) );
        CORE::return;
    }
    elsif( defined( $code ) && ref( $code ) ne 'CODE' )
    {
        warnings::warn( "Callback provided is not a code reference. Provide an anonymous subroutine, or reference to existing subroutine." ) if( warnings::enabled( 'Module::Generic::Array' ) );
        CORE::return;
    }
    
    if( !defined( $code ) )
    {
        # undef is passed as an argument, so we remove the callback
        if( CORE::scalar( @_ ) >= 2 )
        {
            # The array is not tied, so there is nothing to remove.
            my $tie = tied( @$self );
            CORE::return(1) if( !$tie );
            my $rv = $tie->unset_callback( $what );
            untie( @$self ) if( !$tie->has_callback );
            CORE::return( $rv );
        }
        # Only 1 argument: get mode only
        else
        {
            my $tie = tied( @$self );
            CORE::return if( !$tie );
            CORE::return( $tie->get_callback( $what ) );
        }
    }
    # $code is defined, so we have something to set
    else
    {
        my $tie = tied( @$self );
        # Not tied yet
        if( !$tie )
        {
            $tie = tie( @$self => 'Module::Generic::Array::Tie',
            {
                data => $self,
                debug => $DEBUG,
                $what => $code,
            }) || CORE::return;
            CORE::return(1);
        }
        $tie->set_callback( $what => $code ) || CORE::return;
        CORE::return(1);
    }
}

sub chomp
{
    my $self = CORE::shift( @_ );
    CORE::chomp( @$self );
    CORE::return( $self );
}

sub clone { CORE::return( $_[0]->new( [ @{$_[0]} ] ) ); }

sub concat
{
    my $self = CORE::shift( @_ );
    my $new = $self->clone;
    for( my $i = 0; $i < CORE::scalar( @_ ); $i++ )
    {
        if( !defined( $_[$i] ) ||
            ( Scalar::Util::reftype( $_[$i] ) // '' ) ne 'ARRAY' )
        {
            next;
        }
        $new->push( @{$_[$i]} );
    }
    CORE::return( $new );
}

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
        if( Wanted::want( 'LIST' ) )
        {
            rreturn( @removed );
        }
        else
        {
            rreturn( $self->new( \@removed ) );
        }
        # Required to make the compiler happy, as per Wanted documentation
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
    # Index starts from 0
    while( my( $i, $v ) = CORE::each( @$self ) )
    {
        local $_ = $v;
        # CORE::defined( $code->( $i, $v ) ) || CORE::last;
        my $rv = $code->( $i, $v );
        CORE::last if( defined( $rv ) && CORE::length( $rv ) && ( $rv eq BREAK_LOOP || !$rv ) );
    }
    CORE::return( $self );
}

sub eighth { CORE::return( CORE::shift->get_null(7) ); }

sub empty { CORE::return( CORE::shift->reset( @_ ) ); }

sub error
{
    my $self = CORE::shift( @_ );
    my $addr = Scalar::Util::refaddr( $self ) || $self;
    my $class = ref( $self ) || $self;
    my $o;
    no strict 'refs';
    my $repo = Module::Generic::Global->new( 'errors' => $self );

    if( @_ )
    {
        my $args = {};
        # We got an object as first argument. It could be a child from our exception package or from another package
        # Either way, we use it as it is
        if( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) ) ||
            Scalar::Util::blessed( $_[0] ) )
        {
            $o = CORE::shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = CORE::shift( @_ );
        }
        else
        {
            $args->{message} = CORE::join( '', CORE::map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
        }

        $args->{class} //= '';
        my $ex_class = CORE::length( $args->{class} )
            ? $args->{class}
            : ( defined( ${"${class}\::EXCEPTION_CLASS"} ) && CORE::length( ${"${class}\::EXCEPTION_CLASS"} ) )
                ? ${"${class}\::EXCEPTION_CLASS"}
                : 'Module::Generic::Exception';
        unless( CORE::scalar( CORE::keys( %{"${ex_class}\::"} ) ) )
        {
            my $pl = "use $ex_class;";
            local $SIG{__DIE__} = sub{};
            local $@;
            eval( $pl );
            # We have to die, because we have an error within another error
            die( "${class}\::error() is unable to load exception class \"$ex_class\": $@" ) if( $@ );
        }

        $o = $ex_class->new( $args );
        $repo->set( $o );
        $ERROR = $o;

        # try-catch
        local $@;
        if( !$self->_is_class_loaded( 'Encode' ) && !eval( 'require Encode' ) )
        {
            warn( $o ) if( $self->_warnings_is_enabled );
        }
        else
        {
            my $enc_str = eval
            {
                no strict 'subs';
                Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK );
            };
            # Display warnings if warnings for this class is registered and enabled or if not registered
            warn( $@ ? $o : $enc_str ) if( $self->_warnings_is_enabled );
        }

        if( !$args->{no_return_null_object} && want( 'OBJECT' ) )
        {
            # try-catch
            local $@;
            if( !$self->_is_class_loaded( 'Module::Generic::Null' ) )
            {
                eval( 'require Module::Generic::Null' );
                die( "Unable to load module Module::Generic::Null" ) if( $@ );
            }
            my $null = Module::Generic::Null->new( $o, { debug => $DEBUG, has_error => 1 });
            rreturn( $null );
        }
        CORE::return;
    }

    $o = $repo->get;
    if( !$o && want( 'OBJECT' ) )
    {
        # try-catch
        local $@;
        if( !$self->_is_class_loaded( 'Module::Generic::Null' ) )
        {
            eval( 'require Module::Generic::Null' );
            die( "Unable to load module Module::Generic::Null" ) if( $@ );
        }
        my $null = Module::Generic::Null->new( $o, { debug => $DEBUG, wants => 'object' });
        rreturn( $null );
    }
    CORE::return( $o );
}

# Credits: <https://www.perlmonks.org/?node_id=871696>
sub even
{
    my $self = CORE::shift( @_ );
    my @new = @$self[ CORE::grep( !($_ % 2), 0..$#$self ) ];
    CORE::return( $self->new( \@new ) );
}

# Mostly the same as with remove() except for the end
sub except
{
    my $self = CORE::shift( @_ );
    my $ref;
    if( CORE::scalar( @_ ) == 1 && 
        Scalar::Util::blessed( $_[0] ) && 
        $_[0]->isa( 'Module::Generic::Array' ) )
    {
        $ref = CORE::shift( @_ );
    }
    elsif( CORE::scalar( @_ ) == 1 &&
           ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'ARRAY' )
    {
        $ref = $self->new( CORE::shift( @_ ) );
    }
    else
    {
        $ref = $self->new( [ @_ ] );
    }
    my $hash = $ref->as_hash;
    my @res = grep{ !CORE::exists( $hash->{ $_ } ) } @$self;
    CORE::return( $self->new( \@res ) );
}

sub exists
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    if( ref( $this ) && ref( $this ) ne 'Regexp' )
    {
        my $pos = $self->pos( $this );
        CORE::return( CORE::defined( $pos ) ? 1 : 0 );
    }
    else
    {
        CORE::return( $self->_number( CORE::scalar( CORE::grep( /^$this$/, @$self ) ) ) );
    }
}

sub fifth { CORE::return( CORE::shift->get_null(4) ); }

sub filter
{
    my $self = CORE::shift( @_ );
    my( $code, $this ) = @_;
    CORE::return if( ref( $code ) ne 'CODE' );
    my $n = -1;
    CORE::return( $self->map(sub
    {
        local $_ = CORE::shift( @_ );
        my $rv = $code->( ( defined( $this ) ? $this : () ), $_, ++$n, $self );
        CORE::return if( !$rv );
        CORE::return( $_ );
    }) );
}

sub first { CORE::return( CORE::shift->get_null(0) ); }

sub for
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    CORE::return if( ref( $code ) ne 'CODE' );
    $self->return_reset;
    CORE::for( my $i = 0; $i < CORE::scalar( @$self ); $i++ )
    {
        local $_ = $self->[ $i ];
        my $rv = $code->( $i, $self->[ $i ] );
        CORE::last if( CORE::defined( $rv ) && CORE::length( "$rv" ) && ( $rv eq BREAK_LOOP || !$rv ) );

        if( defined( my $ret = $self->return ) )
        {
            $rv = $ret;
            $self->return_reset;
        }

        # If it's a scalar ref, dereference it
        my $value = ref( $rv ) eq 'SCALAR' ? $$rv : $rv;

        CORE::last if( defined( $value ) && length( $value ) && ( $value eq BREAK_LOOP || !$value ) );

        if( ref( $rv ) eq 'SCALAR' && defined( $$rv ) && $$rv =~ /^[\-\+]?\d+$/ )
        {
            $i += int( $$rv );
        }
    }
    $self->return_reset;
    CORE::return( $self );
}

sub foreach
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    CORE::return if( ref( $code ) ne 'CODE' );
    # CORE::foreach my $v ( @$self )
    CORE::foreach( @$self )
    {
        # local $_;
        # local $_ = $v;
        # my $rv = $code->( $v );
        my $rv = $code->( $_ );
        CORE::last if( CORE::defined( $rv ) && CORE::length( "$rv" ) && ( $rv eq BREAK_LOOP || !$rv ) );

        if( defined( my $ret = $self->return ) )
        {
            $rv = $ret;
            $self->return_reset;
        }

        # If it's a scalar ref, dereference it
        my $value = ref( $rv ) eq 'SCALAR' ? $$rv : $rv;

        CORE::last if( defined( $value ) && length( $value ) && ( $value eq BREAK_LOOP || !$value ) );
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
    if( want( 'OBJECT' ) && ( !ref( $self->[ $offset ] ) || ( Scalar::Util::reftype( $self->[ $offset ] ) // '' ) eq 'SCALAR' ) )
    {
        $self->_load_class( 'Module::Generic::Scalar' ) ||
            die( "Unable to load module Module::Generic::Scalar" );
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
        if( want( 'OBJECT' ) && ( !ref( $self->[ $offset ] ) || ( Scalar::Util::reftype( $self->[ $offset ] ) // '' ) eq 'SCALAR' ) )
        {
            $self->_load_class( 'Module::Generic::Scalar' ) ||
                die( "Unable to load module Module::Generic::Scalar" );
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
        if( Wanted::want( 'OBJECT' ) )
        {
            $self->_load_class( 'Module::Generic::Null' ) ||
                die( "Unable to load module Module::Generic::Null" );
            rreturn( Module::Generic::Null->new( wants => 'object' ) );
        }
        CORE::return( $self->[ $offset ] );
    }
}

sub grep
{
    my $self = CORE::shift( @_ );
    my $expr = CORE::shift( @_ );
    my $invert = ( @_ ? CORE::shift( @_ ) : 0 );
    my $ref;
    my $i = -1;
    if( ref( $expr ) eq 'CODE' )
    {
        $ref = ( $invert ? [CORE::grep( !$expr->( $_, ++$i ), @$self )] : [CORE::grep( $expr->( $_, ++$i ), @$self )] );
    }
    else
    {
        $expr = ref( $expr ) eq 'Regexp'
            ? $expr
            : qr/\Q$expr\E/;
        $ref = ( $invert ? [ CORE::grep( $_ !~ /$expr/, @$self ) ] : [ CORE::grep( $_ =~ /$expr/, @$self ) ] );
    }
    if( Wanted::want( 'LIST' ) )
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
    if( want( 'OBJECT' ) && ( !ref( $self->[ $pos ] ) || ( Scalar::Util::reftype( $self->[ $pos ] ) // '' ) eq 'SCALAR' ) )
    {
        $self->_load_class( 'Module::Generic::Scalar' ) ||
            die( "Unable to load module Module::Generic::Scalar" );
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

sub is_empty { CORE::return( CORE::scalar( @{$_[0]} ) ? $FALSE : $TRUE ) }

# sub iterator { CORE::return( Module::Generic::Iterator->new( CORE::shift( @_ ) ) ); }
sub iterator
{
    my $self  = CORE::shift( @_ );
    $self->_load_class( 'Module::Generic::Iterator' ) ||
        die( "Unable to load module Module::Generic::Iterator" );
    CORE::return( Module::Generic::Iterator->new( $self ) );
}

sub join
{
    my $self = CORE::shift( @_ );
    CORE::return( $self->_scalar( CORE::join( CORE::shift( @_ ), @$self, @_ ) ) );
}

sub keys
{
    my $self = CORE::shift( @_ );
    CORE::return( $self->new( CORE::scalar( @$self ) ? [ CORE::keys( @$self ) ] : [] ) );
}

sub last { CORE::return( CORE::shift->get_null(-1) ); }

sub length { CORE::return( $_[0]->_number( CORE::scalar( @{$_[0]} ) ) ); }

sub list { CORE::return( @{$_[0]} ); }

sub map
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    CORE::return if( ref( $code ) ne 'CODE' );
    my $ref = [ CORE::map( $code->( $_ ), @$self ) ];
    if( Wanted::want( 'OBJECT' ) )
    {
        CORE::return( $self->new( $ref ) );
    }
    elsif( Wanted::want( 'LIST' ) )
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
    $self->_load_class( 'Module::Generic::Scalar' ) ||
        die( "Unable to load module Module::Generic::Scalar" );
    CORE::return( Module::Generic::Scalar->new( List::Util::max( @$self ) ) );
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
    $self->_load_class( 'Module::Generic::Scalar' ) ||
        die( "Unable to load module Module::Generic::Scalar" );
    CORE::return( Module::Generic::Scalar->new( List::Util::min( @$self ) ) );
}

sub ninth { CORE::return( CORE::shift->get_null(8) ); }

sub object { CORE::return( $_[0] ); }

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
    if( CORE::scalar( @_ ) >= 2 )
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
    if( Wanted::want( 'OBJECT' ) && ( !ref( $self->[-1] ) || ( Scalar::Util::reftype( $self->[-1] ) // '' ) eq 'SCALAR' ) )
    {
        $self->_load_class( 'Module::Generic::Scalar' ) ||
            die( "Unable to load module Module::Generic::Scalar" );
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

sub prepend { CORE::return( CORE::shift->unshift( @_ ) ); }

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

# Implementation of JavaScript reduce in perl.
# This is different from the one in List::Util that departs from its JavaScript counterpart.
# Ours is strictly compliant
# See <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce>
sub reduce
{
    my $self = CORE::shift( @_ );
    my $cb = CORE::shift( @_ ) ||
        CORE::return( $self->error( "No callback anonymous subroutine or reference to a subroutine was provided." ) );
    if( ref( $cb ) ne 'CODE' )
    {
        CORE::return( $self->error( "No callback anonymous subroutine or reference to a subroutine was provided." ) );
    }
    elsif( !CORE::scalar( @$self ) )
    {
        CORE::return( $self->error( "Array object is empty. Nothing to run reduce on." ) );
    }
    my $init;
    $init = CORE::shift( @_ ) if( @_ );
    my( $accumulator, $pos );
    if( CORE::defined( $init ) )
    {
        ( $accumulator, $pos ) = ( $init, 0 );
    }
    else
    {
        ( $accumulator, $pos ) = ( $self->[0], 1 );
    }
    for( my $i = $pos; $i < CORE::scalar( @$self ); $i++ )
    {
        # try-catch
        local $@;
        eval
        {
            local $_ = $self->[$i];
            $accumulator = $cb->( $accumulator, $self->[$i], $i );
        };
        if( $@ )
        {
            CORE::return( $self->error( "Error calling reduce callback: $@" ) );
        }
    }
    CORE::return( $accumulator );
}

sub remove
{
    my $self = CORE::shift( @_ );
    my $ref;
    if( CORE::scalar( @_ ) == 1 && 
        Scalar::Util::blessed( $_[0] ) && 
        $_[0]->isa( 'Module::Generic::Array' ) )
    {
        $ref = CORE::shift( @_ );
    }
    elsif( CORE::scalar( @_ ) == 1 &&
           ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'ARRAY' )
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

sub replace
{
    my $self = CORE::shift( @_ );
    my( $old, $new ) = @_;
    my $pos = $self->pos( $old );
    CORE::return if( !defined( $pos ) );
    $self->[ $pos ] = $new;
    CORE::return( $self );
}

sub reset
{
    my $self = CORE::shift( @_ );
    if( @_ )
    {
        warn( "Warning only: ", ref( $self ), "::reset() called with ", CORE::scalar( @_ ), " arguments, but I was not expecting any. Called from package \"", [caller]->[0], "\" at line ", [caller]->[2], " from subroutine ", [caller]->[3], "\n" );
    }
    @$self = ();
    CORE::return( $self );
}

sub return
{
    my $self = CORE::shift( @_ );
    my $repo = Module::Generic::Global->new( 'return' => $self );

    if( @_ )
    {
        my $this = CORE::shift( @_ );
        my $val  = \$this;
        $repo->set( $val );
        CORE::return( '' ) if( !CORE::defined( $$val ) );
    }

    CORE::return( $repo->get );
}

sub return_reset
{
    my $self = CORE::shift( @_ );
    my $repo = Module::Generic::Global->new( 'return' => $self );
    my $val  = $repo->get;
    $repo->remove;
    CORE::return( $val );
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
    my $ref = ( CORE::scalar( @_ ) == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? CORE::shift( @_ ) : [ @_ ];
    @$self = @$ref;
    CORE::return( $self );
}

sub seventh { CORE::return( CORE::shift->get_null(6) ); }

sub shift
{
    my $self = CORE::shift( @_ );
    if( Wanted::want( 'OBJECT' ) && ( !ref( $self->[0] ) || ( Scalar::Util::reftype( $self->[0] ) // '' ) eq 'SCALAR' ) )
    {
        $self->_load_class( 'Module::Generic::Scalar' ) ||
            die( "Unable to load module Module::Generic::Scalar" );
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
    if( Wanted::want( 'LIST' ) )
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
        CORE::return( $self ) if( CORE::scalar( @list ) );
        CORE::return;
    }
    if( defined( $length ) && int( $length ) !~ /^\-?\d+$/ )
    {
        warn( "Length provided for splice \"$length\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        CORE::return( $self ) if( CORE::scalar( @list ) );
        CORE::return;
    }
    # Adding elements, so we return our object and allow chaining
    # @_ = offset, length, replacement list
    if( CORE::scalar( @_ ) > 2 )
    {
        CORE::splice( @$self, int( $offset ), int( $length ), @list );
        CORE::return( $self );
    }
    elsif( !CORE::scalar( @_ ) )
    {
        CORE::splice( @$self );
        CORE::return( $self );
    }
    else
    {
        if( CORE::defined( $offset ) && CORE::defined( $length ) )
        {
            if( Wanted::want( 'OBJECT' ) )
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
            if( Wanted::want( 'OBJECT' ) )
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

sub unchomp
{
    my $self = CORE::shift( @_ );
    my $nl = CORE::scalar( @_ ) ? CORE::shift( @_ ) : $/;
    $_ .= $nl for( @$self );
    CORE::return( $self );
}

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
    if( Wanted::want( 'LIST' ) )
    {
        CORE::return( @$ref );
    }
    else
    {
        CORE::return( $self->new( $ref ) );
    }
}

sub _boolean
{
    my $self = CORE::shift( @_ );
}

sub _is_class_loaded
{
    my $self = CORE::shift( @_ );
    my $class = CORE::shift( @_ );
    ( my $pm = $class ) =~ s{::}{/}gs;
    $pm .= '.pm';
    CORE::return(1) if( CORE::exists( $INC{ $pm } ) );
    CORE::return(0);
}

sub _load_class
{
    my $self = CORE::shift( @_ );
    my $class = CORE::shift( @_ );
    die( "No class was provided to load." ) if( !$class );
    my $args = [@_];
    my $is_loaded = $self->_is_class_loaded( $class );
    if( $is_loaded )
    {
        if( CORE::scalar( @$args ) )
        {
            my $pl = "$class->import(" . ( CORE::scalar( @$args ) ? "'" . CORE::join( "', '", @$args ) . "'" : '' ) . ");";
            eval( $pl );
            CORE::return( $self->error( "Error importing class $class: $@" ) ) if( $@ );
        }
        CORE::return( $class );
    }

    local $@;
    local $SIG{__DIE__} = sub{};

    # Load the module with thread safety
    my $key  = HAS_THREADS ? CORE::join( ';', $class, threads->tid() ) : $class;
    my $repo = Module::Generic::Global->new( 'loaded_classes' => CORE::ref( $self ), key => $key );
    my $pl = "require $class;";
    eval( $pl );
    CORE::return( $self->error( "Unable to load package ${class}: $@\nCode executed was:\n${pl}" ) ) if( $@ );
    $pl = "$class->import(" . ( CORE::scalar( @$args ) ? "'" . CORE::join( "', '", @$args ) . "'" : '' ) . ");";
    eval( $pl );
    CORE::return( $self->error( "Error importing class $class: $@" ) ) if( $@ );
    $repo->set(1);
    CORE::return( $class );
}

sub _number
{
    my $self = CORE::shift( @_ );
    my $num = CORE::shift( @_ );
    CORE::return if( !defined( $num ) );
    CORE::return( $num ) if( !CORE::length( $num ) );
    $self->_load_class( 'Module::Generic::Number' ) ||
        die( "Unable to load module Module::Generic::Number" );
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
    # Compare error message
    elsif( ( Scalar::Util::reftype( $other ) // '' ) eq 'ARRAY' )
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
    $self->_load_class( 'Module::Generic::Scalar' ) ||
        die( "Unable to load module Module::Generic::Scalar" );
    CORE::return( Module::Generic::Scalar->new( $str ) );
}

sub _warnings_is_enabled { CORE::return( warnings::enabled( ref( $_[0] ) || $_[0] ) ); }

sub DESTROY
{
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    my $self = CORE::shift( @_ ) || CORE::return;
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );

    for my $namespace ( qw( errors return loaded_classes ) )
    {
        if( my $obj = Module::Generic::Global->new( $namespace => $self ) )
        {
            $obj->remove;
        }
    }
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my @array = @$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \@array] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \@array );
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
    $ref = ( CORE::scalar( @$ref ) && CORE::ref( $ref->[0] ) eq 'ARRAY' ) ? $ref->[0] : [];
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        @$self = @$ref;
        CORE::return( $self );
    }
    else
    {
        CORE::return( $class->new( $ref ) );
    }
}

sub TO_JSON { CORE::return( [ @{$_[0]} ] ); }

# NOTE: Module::Generic::Array::Tie class
{
    package
        Module::Generic::Array::Tie;
    BEGIN
    {
        use strict;
        use warnings;
        use Scalar::Util ();
    };

    our $dummy_callback = sub{1};
    
    sub TIEARRAY
    {
        my( $class, $opts ) = @_;
        $opts //= {};
        if( ( Scalar::Util::reftype( $opts ) // '' ) ne 'HASH' )
        {
            warn( "Options provided (", overload::StrVal( $opts ), ") is not an hash reference\n" );
            $opts = {};
        }
        $opts->{data} //= [];
        $opts->{debug} //= 0;
        if( CORE::length( $opts->{add} ) && ref( $opts->{add} ) ne 'CODE' )
        {
            warnings::warn( "Code provided for the array add callback is not a code reference.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $opts->{debug} );
            CORE::return;
        }
        if( CORE::length( $opts->{remove} ) && ref( $opts->{remove} ) ne 'CODE' )
        {
            warnings::warn( "Code provided for the array remove callback is not a code reference.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $opts->{debug} );
            CORE::return;
        }
        
        my $ref =
        {
        callback_add => $opts->{add},
        callback_remove => $opts->{remove},
        data => ( ( Scalar::Util::reftype( $opts->{data} ) // '' ) eq 'ARRAY' ? [@{$opts->{data}}] : [] ),
        debug => $opts->{debug},
        };
        print( STDERR ( ref( $class ) || $class ), "::TIEARRAY: Using ", CORE::scalar( @{$ref->{data}} ), " elements in array vs ", CORE::scalar( @{$opts->{data}} ), " received via opts->data.\n" ) if( $ref->{debug} );
        CORE::return( bless( $ref => ( ref( $class ) || $class ) ) );
    }
    
    sub CLEAR
    {
        my $self = shift( @_ );
        my $data = $self->{data};
        my $cb = $self->{callback_remove} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback remove found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            my $removed = [ @$data ];
            my $caller = $self->get_caller;
            my $def = { type => 'remove', start => 0, end => $#$data, removed => $removed, data => $removed, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        print( STDERR ref( $self ), "::CLEAR: removing all data from 0 to ", $#$data, " -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        CORE::return if( !defined( $rv ) );
        @{$self->{data}} = ();
    }
    
    sub DELETE
    {
        my( $self, $key ) = @_;
        my $data = $self->{data};
        CORE::return(0) if( $key > $#$data || $key < 0 );
        my $cb = $self->{callback_remove} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback remove found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            my $removed = [ @$data[ $key ] ];
            my $caller = $self->get_caller;
            my $def = { type => 'remove', start => $key, end => $key, removed => $removed, data => $removed, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        print( STDERR ref( $self ), "::DELETE: removing data from $key to ", ( $key + 1 ), " -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        CORE::return if( !defined( $rv ) );
        CORE::return( CORE::splice( @$data, $key, 1 ) );
    }
    
    sub EXISTS
    {
        my( $self, $key ) = @_;
        my $data = $self->{data};
        CORE::return(0) if( $key > $#$data || $key < 0 );
        CORE::return(1);
    }
    
    sub EXTEND
    {
        my( $self, $count ) = @_;
        # This is an optional method, so we set it as a noop
    }
    
    sub FETCH
    {
        my( $self, $index ) = @_;
        CORE::return( $self->{data}->[ $index ] );
    }
    
    sub FETCHSIZE
    {
        my $self = shift( @_ );
        my $data = $self->{data};
        CORE::return( $#$data + 1 );
    }
    
    sub POP
    {
        my $self = shift( @_ );
        my $data = $self->{data};
        my $cb = $self->{callback_remove} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback remove found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            my $removed = [ @$data[ $#$data ] ];
            my $caller = $self->get_caller;
            my $def = { type => 'remove', start => $#$data, end => $#$data, removed => $removed, data => $removed, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        print( STDERR ref( $self ), "::POP: removing data from ", $#$data, " to ", ( $#$data + 1 ), " -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        CORE::return if( !defined( $rv ) );
        CORE::return( CORE::splice( @$data, -1 ) );
    }
    
    sub PUSH
    {
        my( $self, @values ) = @_;
        my $data = $self->{data};
        my $cb = $self->{callback_add} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback add found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            my $added = \@values;
            my $caller = $self->get_caller;
            my $def = { type => 'add', start => ( $#$data + 1 ), added => $added, data => $added, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        print( STDERR ref( $self ), "::PUSH: adding ", CORE::scalar( @values ), " data at position ", ( $#$data + 1 ), " -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), ". Array contains ", CORE::scalar( @$data ), " elements.\n" ) if( $self->{debug} );
        CORE::return if( !defined( $rv ) );
        CORE::splice( @$data, ( $#$data + 1 ), 0, @values );
    }
    
    sub SHIFT
    {
        my $self = shift( @_ );
        my $data = $self->{data};
        my $cb = $self->{callback_remove} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback remove found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            my $removed = [ @$data[0] ];
            my $caller = $self->get_caller;
            my $def = { type => 'remove', start => 0, end => 0, removed => $removed, data => $removed, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        CORE::return if( !defined( $rv ) );
        CORE::return( CORE::splice( @$data, 0, 1 ) );
    }
    
    sub SPLICE
    {
        my( $self, $offset, $len, @values ) = @_;
        my $data = $self->{data};
        my $size = $#$data + 1;
        $offset //= 0;
        $offset += $size if( $offset < 0 );
        $len //= ( ( $#$data + 1 ) - $offset );
        print( STDERR ref( $self ), "::SPLICE: called with offset '$offset', length '$len' and ", CORE::scalar( @values ), "\n" ) if( $self->{debug} );
        my $rv;
        if( CORE::scalar( @values ) )
        {
            my $cb = $self->{callback_add} || $dummy_callback;
            if( !$cb )
            {
                warnings::warn( "No callback add found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
                $rv = 1;
            }
            else
            {
                my $added = \@values;
                my $caller = $self->get_caller;
                my $def = { type => 'add', start => $offset, added => $added, data => $added, 'caller' => $caller };
                local $_ = $def;
                $rv = $cb->( $def );
            }
            print( STDERR ref( $self ), "::SPLICE: adding ", CORE::scalar( @values ), " data at position $offset -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        }
        else
        {
            my $cb = $self->{callback_remove} || $dummy_callback;
            if( !$cb )
            {
                warnings::warn( "No callback remove found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
                $rv = 1;
            }
            else
            {
                my $removed = [ @$data[ $offset..( $offset + ( $len - 1 ) ) ] ];
                my $caller = $self->get_caller;
                my $def = { type => 'remove', start => $offset, end => ( $offset + ( $len - 1 ) ), removed => $removed, data => $removed, 'caller' => $caller };
                local $_ = $def;
                $rv = $cb->( $def );
            }
            print( STDERR ref( $self ), "::SPLICE: removing data from $offset to ", ( $offset + $len ), " -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        }
        CORE::return if( !defined( $rv ) );
        CORE::return( CORE::splice( @$data, $offset, $len, @values ) );
    }
    
    sub STORE
    {
        my( $self, $index, $value ) = @_;
        my $cb = $self->{callback_add} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback add found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            my $added = [ $value ];
            my $caller = $self->get_caller;
            my $def = { type => 'add', start => $index, added => $added, data => $added, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        print( STDERR ref( $self ), "::STORE: adding 1 data at position $index -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        CORE::return if( !defined( $rv ) );
        $self->{data}->[ $index ] = $value;
    }
    
    sub STORESIZE
    {
        my( $self, $count ) = @_;
        my $data = $self->{data};
        $#$data = ( $count - 1 );
#         if( $count > ( $#$data + 1 ) )
#         {
#             $#$data = ( $count - 1 );
#         }
#         else
#         {
#             CORE::splice( @$data, ( $count - 1 ) );
#         }
    }
    
    sub UNSHIFT
    {
        my( $self, @values ) = @_;
        my $data = $self->{data};
        my $cb = $self->{callback_add} || $dummy_callback;
        my $rv;
        if( !$cb )
        {
            warnings::warn( "No callback add found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Array' ) || $self->{debug} );
            $rv = 1;
        }
        else
        {
            print( STDERR ref( $self ), "::UNSHIFT: got here for values to add '", join( "', '", @values ), "' with callback '$cb'\n" ) if( $self->{debug} );
            my $added = \@values;
            my $caller = $self->get_caller;
            my $def = { type => 'add', start => 0, added => $added, data => $added, 'caller' => $caller };
            local $_ = $def;
            $rv = $cb->( $def );
        }
        print( STDERR ref( $self ), "::UNSHIFT: adding ", CORE::scalar( @values ), " data at position 0 -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        CORE::return if( !defined( $rv ) );
        CORE::return( CORE::splice( @$data, 0, 0, @values ) );
    }
    
    sub UNTIE
    {
        my( $self, $ref_count ) = @_;
        # noop
    }
    
    sub get_caller
    {
        my $self = shift( @_ );
        my $frame = 2;
        my $info = [caller( $frame )];
        print( STDERR ref( $self ), "::get_caller: At frame $frame, called from package ", $info->[0], " at line ", $info->[2], "\n" ) if( $self->{debug} );
        while( CORE::scalar( @$info ) && substr( $info->[0], 0, 22 ) eq 'Module::Generic::Array' )
        {
            $info = [caller( ++$frame )];
            print( STDERR ref( $self ), "::get_caller: At frame $frame, called from package ", $info->[0], " at line ", $info->[2], "\n" ) if( $self->{debug} );
        }
        CORE::return( $info );
    }
    
    sub has_callback
    {
        my $self = shift( @_ );
        CORE::return(1) if( ref( $self->{callback_add} ) eq 'CODE' || ref( $self->{callback_remove} ) eq 'CODE' );
        CORE::return(0);
    }
    
    sub set_callback
    {
        my( $self, $what, $code ) = @_;
        if( !defined( $what ) )
        {
            warn( "No callback type was provided. Use \"add\" or \"remove\".\n" );
            CORE::return;
        }
        elsif( $what ne 'add' && $what ne 'remove' )
        {
            warn( "Unknown callback type was provided: '$what'. Use \"add\" or \"remove\".\n" );
            CORE::return;
        }
        elsif( !defined( $code ) )
        {
            warn( "No callback anonymous subroutine or subroutine reference was provided.\n" );
            CORE::return;
        }
        elsif( ref( $code ) ne 'CODE' )
        {
            warn( "Callback provided (", overload::StrVal( $code ), ") is not a code reference.\n" );
            CORE::return;
        }
        $self->{ "callback_${what}" } = $code;
        CORE::return(1);
    }
    
    sub unset_callback
    {
        my( $self, $what ) = @_;
        if( !defined( $what ) )
        {
            warn( "No callback type was provided. Use \"add\" or \"remove\".\n" );
            CORE::return;
        }
        elsif( $what ne 'add' && $what ne 'remove' )
        {
            warn( "Unknown callback type was provided: '$what'. Use \"add\" or \"remove\".\n" );
            CORE::return;
        }
        $self->{ "callback_${what}" } = undef;
        CORE::return(1);
    }
}

1;

__END__
