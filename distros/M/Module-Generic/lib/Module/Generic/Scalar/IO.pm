##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Scalar/IO.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/24
## Modified 2022/08/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Scalar::IO;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    # For import of constants
    use Module::Generic::File::IO;
    use parent qw( Module::Generic::File::IO );
    use vars qw( $DEBUG $VERSION $ERROR @EXPORT );
    use Devel::StackTrace;
    no warnings 'once';
    our @EXPORT = @Module::Generic::File::IO;
    our $ERROR = '';
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $class = ( ref( $this ) || $this );
    my $self;
    # try-catch
    local $@;
    eval
    {
        $self = $class->IO::File::new;
    };
    if( $@ )
    {
        return( $self->error( "Error trying to get a file handle: $@" ) );
    }
    *$self = {};
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->init( @_ ) );
    }
    my $new = $self->init( @_ );
    if( !defined( $new ) )
    {
        # If we are called on an object, we hand it the error so the caller can check it using the object:
        # my $new = $old->new || die( $old->error );
        if( $self->_is_object( $this ) && $this->can( 'pass_error' ) )
        {
            return( $this->pass_error( $self->error ) );
        }
        else
        {
            return( $self->pass_error );
        }
    };
    return( $new );
}

sub init
{
    my( $p, $f, $l ) = caller;
    my $self = shift( @_ );
    my $class = ( ref( $self ) || $self );
    my( $ref, $mode );
    if( @_ )
    {
        $ref = shift( @_ );
        return( $self->error( "No scalar reference was provided." ) ) if( !defined( $ref ) );
        return( $self->error( "I was expecting a scalar reference, but got a string of ", CORE::length( $ref ), " bytes instead." ) ) if( !ref( $ref ) );
        return( $self->error( "I was expecting a scalar reference, but got instead '", overload::StrVal( $ref ), "'." ) ) if( !$self->_is_scalar( $ref ) );
        $mode = ( scalar( @_ ) && ( ref( $_[0] ) ne 'HASH' || ( @_ > 2 && ( @_ % 2 ) ) ) ) ? shift( @_ ) : '+<';
        $mode =~ s/^(.*?)\:$// if( substr( $mode, -1, 1 ) eq ':' );
    }
    else
    {
        my $str = '';
        $ref = \$str;
        $mode = '+<';
    }
    *$self->{sr} = $ref;
    my $opts = $self->_get_args_as_hash( @_ );
    my $core = {};
    $core->{binmode} = CORE::delete( $opts->{binmode} ) if( exists( $opts->{binmode} ) );
    $core->{autoflush} = CORE::delete( $opts->{autoflush} ) if( exists( $opts->{autoflush} ) );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $this = *$self;
    # See PerlIO man page
    if( defined( $core->{binmode} ) && length( $core->{binmode} ) )
    {
        # No need to specify the scalar layer, because we add it ourself
        if( $core->{binmode} eq 'scalar' )
        {
            # no-op
        }
        elsif( 
            $core->{binmode} eq 'bytes' ||
            $core->{binmode} eq 'crlf' ||
            $core->{binmode} eq 'perlio' ||
            $core->{binmode} eq 'raw' ||
            $core->{binmode} eq 'stdio' ||
            $core->{binmode} eq 'unix' ||
            $core->{binmode} eq 'win32'
            )
        {
            $mode .= ':' . $core->{binmode};
        }
        # others are encapsulated with :encoding() pragma, including utf8
        else
        {
            $mode .= ':encoding(' . $core->{binmode} . ')';
        }
    }
    $self->open( $ref => $mode ) || return( $self->pass_error );
    $self->autoflush( $core->{autoflush} ) if( exists( $core->{autoflush} ) );
    return( $self );
}

sub bit { return( *{shift( @_ )}->{bit} ); }

# Could also do: !( $_[0] & O_ACCMODE )
sub can_read { return( ( ( $_[0]->bit & O_RDONLY ) == O_RDONLY ) || ( $_[0]->bit & O_RDWR ) ); }

sub can_write { return( shift->bit & ( O_APPEND | O_WRONLY | O_CREAT | O_RDWR ) ); }

sub clearerr { return( shift->clear_error ); }

sub fcntl
{
    my $self = shift( @_ );
    my( $func, $bit ) = @_;
    return( $self->error( "Function bit value is not an integer." ) ) if( !$self->_is_integer( $func ) );
    if( $func & F_GETFL )
    {
        return( *$self->{bit} );
    }
    elsif( $func & F_SETFL )
    {
        return( $self->error( "Bitwise value provided '$bit' is not an integer." ) ) if( !$self->_is_integer( $bit ) );
        *$self->{bit} = $bit;
    }
    else
    {
        return( $self->error( "Unknown fcntl function provided Please use either F_GETFL or F_SETFL" ) );
    }
}

# Need to wrap the getline() method here, because it will not sto even when eof() 
# has been reached and leading to the error: "Inappropriate ioctl for device"
# Thus here we wrap the getline() call and check for eof()
sub getline
{
    my $self = shift( @_ );
    return if( $self->eof );
    return( $self->SUPER::getline() );
}

sub is_append { return( shift->bit & O_APPEND ); }

sub is_create { return( shift->bit & O_CREAT ); }

sub is_readonly { return( shift->bit == O_RDONLY ); }

sub is_readwrite { return( shift->bit & O_RDWR ); }

sub is_writeonly { return( shift->bit & O_WRONLY ); }

sub length
{
    my $self = shift( @_ );
    return( CORE::length( ${ *$self->{sr} } ) );
}

sub line
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    return( $self->error( "No callback code was provided for line()" ) ) if( !defined( $code ) || ref( $code ) ne 'CODE' );
    my $opts = ref( $_[0] ) eq 'HASH' ? shift( @_ ) : { @_ };
    return if( !$self->can_read );
    $opts->{chomp} //= 0;
    $opts->{auto_next} //= 0;
    my $l;
    while( defined( $l = $self->getline ) )
    {
        chomp( $l ) if( $opts->{chomp} );
        local $_ = $l;
        my $rv = $code->( $l );
        if( !defined( $rv ) && !$opts->{auto_next} )
        {
            last;
        }
    }
    return( $self );
}

sub object { return( *{ $_[0] }->{sr} ) }

sub open
{
    my $self = shift( @_ );
    my $class = ( ref( $self ) || $self );
    return( $self->error( "open() is not a class function. You need to call it using a $class object." ) ) if( !ref( $self ) );
    my $ref = shift( @_ );
    return( $self->error( "No scalar reference was provided." ) ) if( !defined( $ref ) );
    return( $self->error( "I was expecting a scalar reference, but got a string of ", CORE::length( $ref ), " bytes instead." ) ) if( !ref( $ref ) );
    return( $self->error( "I was expecting a scalar reference, but got instead '", overload::StrVal( $ref ), "'." ) ) if( !$self->_is_scalar( $ref ) );
    my $mode = shift( @_ ) ||
        return( $self->error( "No mode was provided. Supported modes are: >, >>, +>, +>>, <, <+, r, r+, w, w+, a, a+" ) );
    my $equi =
    {
    'r'     => '<',
    'r+'    => '+<',
    'w'     => '>',
    'w+'    => '+>',
    'a'     => '>>',
    'a+'    => '+>>',
    };
    
    my $pl_mode = $mode;
    if( index( $mode, ':' ) != -1 )
    {
        my @parts = split( /:/, $mode );
        $mode = $parts[0];
        $parts[0] = $equi->{ $parts[0] } if( CORE::exists( $equi->{ $parts[0] } ) );
        # The order is important. :scalar needs to be the first IO layer
        splice( @parts, 1, 0, 'scalar' ) if( !scalar( grep( $_ eq 'scalar', @parts ) ) );
        # We only take the first part, i.e. the open mode and ignore the IO layer used for perl's open
        $pl_mode = join( ':', @parts );
    }
    else
    {
        $pl_mode = $equi->{ $pl_mode } if( CORE::exists( $equi->{ $pl_mode } ) );
        $pl_mode .= ':scalar';
    }
    no warnings 'uninitialized';
    local $@;
    my $rv = eval
    {
        open( $self, $pl_mode, $ref );
    };
    if( $@ )
    {
        return( $self->error( "Unable to open( $self, $pl_mode, ", overload::StrVal( $ref ), " ) scalar reference: $@" ) );
    }
    elsif( !$rv )
    {
        return( $self->error( "Unable to open( $self, $pl_mode, ", overload::StrVal( $ref ), " ) scalar reference: $!" ) );
    }

    my $bit;
    my $bitmap = 
    {
        '<'     => O_RDONLY,
        # Incorrect, but let's catch it anyway
        '<+'    => O_RDWR,
        '+<'    => O_RDWR,
        '>'     => ( O_CREAT | O_WRONLY ),
        '+>'    => ( O_CREAT | O_RDWR ),
        '>>'    => O_APPEND,
        '+>>'   => ( O_RDWR | O_APPEND ),
        'r'     => O_RDONLY,
        'r+'    => O_RDWR,
        'w'     => ( O_CREAT | O_WRONLY ),
        'w+'    => ( O_CREAT | O_RDWR ),
        'a'     => O_APPEND,
        'a+'    => ( O_RDWR | O_APPEND ),
    };
    
    # We set the bit for this glob, so fcntl works.
    if( $mode =~ /^(<|<\+|\+<|>|\+>|>>|\+>>|r|r\+|w|w\+|a|a\+)$/ )
    {
        die( "Unable to find mode '$1' in our bitmap!\n" ) if( !CORE::exists( $bitmap->{ $1 } ) );
        $bit = $bitmap->{ $1 };
        if( $bit & O_CREAT )
        {
            $$ref = '' unless( !defined( $$ref ) );
        }
    }
    else
    {
        return( $self->error( "Unsupported mode '$mode'" ) );
    }
    
    # If opened in read, even read/write mode, we position at the beginning of the string
    *$self->{sr}  = $ref;
    # We use the bits to check what the methods are allowed to do
    *$self->{bit} = $bit;
    return( $self );
}

sub setpos { return( shift->seek( $_[0], 0 ) ); }

sub size { return( shift->length ); }

sub sref { return( shift->object ); }

# Missing method in IO::Scalar and not working under perl native open with IO::Handle
# It throws 'Bad file descriptor'
sub truncate
{
    my $self = CORE::shift( @_ );
    return if( !$self->can_write );
    my $pos = $self->tell;
    return( CORE::length( CORE::substr( ${*$self->{sr}}, $pos, CORE::length( ${*$self->{sr}} ) - $pos, '' ) ) );
}

sub sysread { return( shift->read( @_ ) ); }

sub syswrite { return( shift->write( @_ ) ); }

sub write
{
    my $self = $_[0];
    my $n    = $_[2] // CORE::length( $_[1] );
    my $off  = $_[3] || 0;
    return( $self->error( "Wrong number of parameters. Usage: \$io->write( \$buffer, \$length, \$offset ); \$offset is optional." ) ) if( @_ < 2 || @_ > 4 ); 
    return if( !$self->can_write );

    if( @_ == 4 )
    {
        $n = ( CORE::length( $_[1] ) - $off ) if( ( $off + $n ) > CORE::length( $_[1] ) );
    }
    else
    {
        $n = CORE::length( $_[1] ) if( $n > CORE::length( $_[1] ) );
    }
    $self->print( substr( $_[1], $off, $n ) ) || return( $self->pass_error );
    return( $n );
}

sub DESTROY
{
    shift->close;
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self ) || $self;
    my %hash  = %{*$self};
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new = $class->new;
    foreach( CORE::keys( %$hash ) )
    {
        *$new->{ $_ } = CORE::delete( $hash->{ $_ } );
    }
    CORE::return( $new );
}

1;

__END__
