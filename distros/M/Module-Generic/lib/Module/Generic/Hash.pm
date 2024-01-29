##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Hash.pm
## Version v1.4.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2023/12/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Hash;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $DEBUG $KEY_OBJECT );
    use Clone ();
    use Data::Dumper;
    use JSON;
    use Module::Generic::TieHash;
    use Regexp::Common;
    use Want;
    use overload (
        # '""'    => 'as_string',
        'eq'    => sub { _obj_eq(@_) },
        'ne'    => sub { !_obj_eq(@_) },
        '<'     => sub { _obj_comp( @_, '<') },
        '>'     => sub { _obj_comp( @_, '>') },
        '<='    => sub { _obj_comp( @_, '<=') },
        '>='    => sub { _obj_comp( @_, '>=') },
        '=='    => sub { _obj_comp( @_, '>=') },
        '!='    => sub { _obj_comp( @_, '>=') },
        'lt'    => sub { _obj_comp( @_, 'lt') },
        'gt'    => sub { _obj_comp( @_, 'gt') },
        'le'    => sub { _obj_comp( @_, 'le') },
        'ge'    => sub { _obj_comp( @_, 'ge') },
        'bool'  => sub{$_[0]},
        fallback => 1,
    );
    # Do we allow the use of object as hash keys?
    our $KEY_OBJECT = 0;
    our( $VERSION ) = 'v1.4.0';
};

use strict;
no warnings 'redefine';
require Module::Generic::Array;
require Module::Generic::Number;
require Module::Generic::Scalar;

sub new
{
    my $that = shift( @_ );
    my $class = ref( $that ) || $that;
    
    my %hash = ();
    # This enables access to the hash just like a real hash while still the user an call our object methods
    my $obj = tie( %hash, 'Module::Generic::TieHash', {
        # disable => ['Module::Generic'],
        debug => $DEBUG,
        enable => 0,
        # Should we allow objects to be used as key? Default to false
        key_object => $KEY_OBJECT,
    });
    my $self = bless( \%hash => $class );
    $obj->enable(1);

    if( scalar( @_ ) == 1 )
    {
        my $data = shift( @_ );
        return( $that->error( "I was expecting an hash, but instead got '", ( $data // 'undef' ), "'." ) ) if( Scalar::Util::reftype( $data // '' ) ne 'HASH' );
        my $tied = tied( %$data );
        return( $that->error( "Hash provided is already tied to ", ref( $tied ), " and our package $class cannot use it, or it would disrupt the tie." ) ) if( $tied );
        my @keys = CORE::keys( %$data );
        @hash{ @keys } = @$data{ @keys };
    }
    elsif( scalar( @_ ) > 1 &&
        !( @_ % 2 ) )
    {
        while( @_ )
        {
            $hash{ shift( @_ ) } = shift( @_ );
        }
    }
    elsif( scalar( @_ ) )
    {
        return( $self->error( "Odd number (", scalar( @_ ), ") of hash keys and values provided." ) );
    }

    $obj->enable(0);
    $self->SUPER::init( @_ );
    $obj->enable(1);
    return( $self );
}

# sub as_hash
# {
#     my $self = CORE::shift( @_ );
#     my $hash = {};
#     $self->_tie_object->enable(1);
#     my $keys = $self->keys;
#     @$hash{ @$keys } = @$self{ @$keys };
#     return( $hash );
# }

# We are already an hash, so no need to do anything.
# To convert to a regular hash as needed by JSON, the method TO_JSON can be used.
sub as_hash
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $opts = $self->_get_args_as_hash( @_ );
        if( $opts->{strict} )
        {
            my $ref = { %$self };
            return( $ref );
        }
    }
    return( $self );
}

sub as_json { return( shift->json(@_)->scalar ); }

sub as_string { return( shift->dump ); }

sub chomp
{
    my $self = CORE::shift( @_ );
    CORE::chomp( %$self );
    return( $self );
}

sub clone
{
    my $self = shift( @_ );
    $self->_tie_object->enable(0);
    my $data = $self->{data};
    my $clone = Clone::clone( $data );
    $self->_tie_object->enable(1);
    return( $self->new( $clone ) );
}

sub debug { return( shift->_internal( 'debug', '_set_get_number', @_ ) ); }

sub defined { CORE::defined( $_[0]->{ $_[1] } ); }

sub delete { return( CORE::delete( shift->{ shift( @_ ) } ) ); }

sub dump
{
    my $self = shift( @_ );
    return( $self->_dumper( $self ) );
}

sub each
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No subroutine callback as provided for each" ) );
    return( $self->error( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead." ) ) if( ref( $code ) ne 'CODE' );
    while( my( $k, $v ) = CORE::each( %$self ) )
    {
        CORE::defined( $code->( $k, $v ) ) || CORE::last;
    }
    return( $self );
}

sub exists { return( CORE::exists( shift->{ shift( @_ ) } ) ); }

sub for { return( shift->foreach( @_ ) ); }

sub foreach
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No subroutine callback as provided for each" ) );
    return( $self->error( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead." ) ) if( ref( $code ) ne 'CODE' );
    CORE::foreach my $k ( CORE::keys( %$self ) )
    {
        local $_ = $self->{ $k };
        CORE::defined( $code->( $k, $self->{ $k } ) ) || CORE::last;
    }
    return( $self );
}

sub get { return( $_[0]->{ $_[1] } ); }

sub has { return( shift->exists( @_ ) ); }

sub is_empty { return( scalar( CORE::keys( %{$_[0]} ) ) ? 0 : 1 ); }

sub json
{
    my $self = shift( @_ );
    my $opts = {};
    if( ref( $_[-1] ) eq 'HASH' )
    {
        $opts = pop( @_ );
    }
    elsif( @_ && !( @_ % 2 ) )
    {
        $opts = { @_ };
    }
    $self->_tie_object->enable(0);
    my $data = $self->{data};
    # $opts->{utf8} = 1 if( !CORE::exists( $opts->{utf8} ) );
    if( CORE::exists( $opts->{order} ) )
    {
        $opts->{canonical} = CORE::delete( $opts->{order} );
    }
    elsif( CORE::exists( $opts->{ordered} ) )
    {
        $opts->{canonical} = CORE::delete( $opts->{ordered} );
    }
    elsif( CORE::exists( $opts->{sort} ) )
    {
        $opts->{canonical} = CORE::delete( $opts->{sort} );
    }
    elsif( CORE::exists( $opts->{sorted} ) )
    {
        $opts->{canonical} = CORE::delete( $opts->{sorted} );
    }

    if( !CORE::exists( $opts->{canonical} ) && $opts->{pretty} )
    {
        $opts->{canonical} = 1;
    }
    if( !CORE::exists( $opts->{indent} ) && $opts->{pretty} )
    {
        $opts->{indent} = 1;
    }
    if( !CORE::exists( $opts->{relaxed} ) && $opts->{pretty} )
    {
        $opts->{relaxed} = 1;
    }
    my $j = JSON->new->allow_nonref;
    my @keys = qw(
        ascii latin1 utf8 pretty indent space_before space_after relaxed 
        canonical allow_nonref allow_unknown allow_blessed convert_blessed allow_tags 
        boolean_values filter_json_object filter_json_single_key_object max_depth max_size
    );
    foreach my $k ( @keys )
    {
        next unless( CORE::exists( $opts->{ $k } ) );
        my $code = $j->can( $k );
        if( defined( $code ) )
        {
            $code->( $j, $opts->{ $k } );
        }
    }
    my $json = $j->encode( $data );
    $self->_tie_object->enable(1);
    return( Module::Generic::Scalar->new( $json ) );
}

# Allow hash keys as object
sub key_object
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->_tie_object->key_object( shift( @_ ) );
    }
    return( $self->_tie_object->key_object );
}

# $h->keys->sort
sub keys
{
    my $self = shift( @_ );
    $self->_tie_object->enable(1);
    return( Module::Generic::Array->new( [ CORE::keys( %$self ) ] ) );
}

sub length { return( Module::Generic::Number->new( CORE::scalar( CORE::keys( %{$_[0]} ) ) ) ); }

sub map
{
    my $self = shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    return( CORE::map( $code->( $_, $self->{ $_ } ), CORE::keys( %$self ) ) );
}

sub map_array
{
    my $self = shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    return( Module::Generic::Array->new( [CORE::map( $code->( $_, $self->{ $_ } ), CORE::keys( %$self ) )] ) );
}

sub map_hash
{
    my $self = shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    return( $self->new( {CORE::map( $code->( $_, $self->{ $_ } ), CORE::keys( %$self ) )} ) );
}

sub merge
{
    my $self = shift( @_ );
    my $hash = {};
    $hash = shift( @_ );
    return( $self->error( "No valid hash provided." ) ) if( !$hash || ( Scalar::Util::reftype( $hash ) // '' ) ne 'HASH' );
    my $opts = {};
    $opts = pop( @_ ) if( @_ && ref( $_[-1] ) eq 'HASH' );
    $opts->{overwrite} = 1 unless( CORE::exists( $opts->{overwrite} ) );
    $self->_tie_object->enable(0);
    my $data = $self->{data};
    my $seen = {};
    my $copy;
    $copy = sub
    {
        my $this = shift( @_ );
        my $to = shift( @_ );
        my $p  = {};
        $p = shift( @_ ) if( @_ && ref( $_[-1] ) eq 'HASH' );
        CORE::foreach my $k ( CORE::keys( %$this ) )
        {
            next if( CORE::exists( $to->{ $k } ) && !$p->{overwrite} );
            if( ref( $this->{ $k } ) eq 'HASH' || 
                ( Scalar::Util::blessed( $this->{ $k } ) && $this->{ $k }->isa( 'Module::Generic::Hash' ) ) )
            {
                my $addr = Scalar::Util::refaddr( $this->{ $k } );
                if( CORE::exists( $seen->{ $addr } ) )
                {
                    $to->{ $k } = $seen->{ $addr };
                    next;
                }
                else
                {
                    $to->{ $k } = {} unless( CORE::defined( $to->{ $k } ) && ( Scalar::Util::reftype( $to->{ $k } ) // '' ) eq 'HASH' );
                    $copy->( $this->{ $k }, $to->{ $k } );
                }
                $seen->{ $addr } = $this->{ $k };
            }
            else
            {
                $to->{ $k } = $this->{ $k };
            }
        }
    };
    $copy->( $hash, $data, $opts );
    $self->_tie_object->enable(1);
    return( $self );
}

sub remove { return( shift->delete( @_ ) ); }

sub reset { %{$_[0]} = () };

sub set { $_[0]->{ $_[1] } = $_[2]; }

sub size { return( shift->length ); }

sub undef { %{$_[0]} = () };

sub values
{
    my $self = shift( @_ );
    my $code;
    $code = shift( @_ ) if( @_ && ref( $_[0] ) eq 'CODE' );
    my $opts = {};
    $opts = pop( @_ ) if( ( Scalar::Util::reftype( $_[-1] ) // '' ) eq 'HASH' );
    if( $code )
    {
        if( $opts->{sort} )
        {
            return( Module::Generic::Array->new( [ CORE::map( $code->( $_ ), CORE::sort( CORE::values( %$self ) ) ) ] ) );
        }
        else
        {
            return( Module::Generic::Array->new( [ CORE::map( $code->( $_ ), CORE::values( %$self ) ) ] ) );
        }
    }
    else
    {
        if( $opts->{sort} )
        {
            return( Module::Generic::Array->new( [ CORE::sort( CORE::values( %$self ) ) ] ) );
        }
        else
        {
            return( Module::Generic::Array->new( [ CORE::values( %$self ) ] ) );
        }
    }
}

sub _dumper
{
    my $self = shift( @_ );
    $self->_tie_object->enable(0);
    my $data = $self->{data};
    my $d = Data::Dumper->new( [ $data ] );
    $d->Indent(1);
    $d->Useqq(1);
    $d->Terse(1);
    $d->Sortkeys(1);
    # $d->Freezer( '' );
    $d->Bless( '' );
    # return( $d->Dump );
    my $str = $d->Dump;
    $self->_tie_object->enable(1);
    return( $str );
}

sub _internal
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $meth  = shift( @_ );
    $self->_tie_object->enable(0);
    my( @resA, $resB );
    if( wantarray )
    {
        @resA = $self->$meth( $field, @_ );
    }
    else
    {
        $resB = $self->$meth( $field, @_ );
    }
    $self->_tie_object->enable(1);
    return( wantarray ? @resA : $resB );
}

sub _obj_comp
{
    my( $self, $other, $swap, $op ) = @_;
    my( $lA, $lB );
    $lA = $self->length;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Hash' ) )
    {
        $lB = $other->length;
    }
    elsif( $other =~ /^$RE{num}{real}$/ )
    {
        $lB = $other;
    }
    else
    {
        return;
    }
    my $expr = $swap ? "$lB $op $lA" : "$lA $op $lB";
    return( eval( $expr ) );
}

sub _printer { return( shift->printer( @_ ) ); }

sub _obj_eq
{
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $strA = $self->_dumper( $self );
    my $strB;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Hash' ) )
    {
        $strB = $other->dump;
    }
    elsif( ( Scalar::Util::reftype( $other ) // '' ) eq 'HASH' )
    {
        $strB = $self->_dumper( $other )
    }
    else
    {
        return(0);
    }
    return( $strA eq $strB );
}

sub _tie_object
{
    my $self = shift( @_ );
    return( tied( %$self ) );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my $clone = $self->clone;
    $clone->_tie_object->enable(0);
    my %data = %{$clone->{data}};
    $clone->_tie_object->enable(1);
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%data] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%data );
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
        $new = $class->new( $hash );
    }
    CORE::return( $new );
}

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    my $ref  = { %$self };
    CORE::return( $ref );
}

1;

__END__
