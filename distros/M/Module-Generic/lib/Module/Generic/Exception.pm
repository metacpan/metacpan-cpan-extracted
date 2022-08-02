##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Exception.pm
## Version v1.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2022/07/18
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $CALLER_LEVEL $CALLER_INTERNAL );
    use Scalar::Util;
    use Devel::StackTrace;
    use overload (
        '""'    => 'as_string',
        '=='    => sub{ _obj_eq(@_) },
        '!='    => sub{ !_obj_eq(@_) },
        bool    => sub{ $_[0] },
        fallback => 1,
    );
    $CALLER_LEVEL = 0;
    $CALLER_INTERNAL->{'Module::Generic'}++;
    $CALLER_INTERNAL->{'Module::Generic::Exception'}++;
    our $VERSION = 'v1.2.0';
};

BEGIN
{
    Module::Generic->_implement_freeze_thaw( qw( Devel::StackTrace Devel::StackTrace::Frame ) );
};

use strict;
no warnings 'redefine';

sub init
{
    my $self = shift( @_ );
    $self->{code} = '' unless( length( $self->{code} ) );
    $self->{type} = '' unless( length( $self->{type} ) );
    $self->{file} = '' unless( length( $self->{file} ) );
    $self->{line} = '' unless( length( $self->{line} ) );
    $self->{message} = '' unless( length( $self->{message} ) );
    $self->{package} = '' unless( length( $self->{package} ) );
    $self->{retry_after} = '' unless( length( $self->{retry_after} ) );
    $self->{subroutine} = '' unless( length( $self->{subroutine} ) );
    my $args = {};
    if( @_ )
    {
        if( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) ) ||
            Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
        {
            $args->{object} = shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = shift( @_ );
        }
        else
        {
            $args->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
        }
    }
    # $self->SUPER::init( @_ );
    
    unless( length( $args->{skip_frames} ) )
    {
        # NOTE: Taken from Carp to find the right point in the stack to start from
        no strict 'refs';
        my $caller_func;
        $caller_func = \&{"CORE::GLOBAL::caller"} if( defined( &{"CORE::GLOBAL::caller"} ) );
        my $call_pack = $caller_func ? $caller_func->() : caller();
        ## Check if this is an internal package or a package inheriting from us
        local $CALLER_LEVEL = ( $CALLER_INTERNAL->{ $call_pack } || bless( {} => $call_pack )->isa( 'Module::Generic::Exception' ) ) 
            ? $CALLER_LEVEL 
            : $CALLER_LEVEL + 1;
        my $error_start_frame = sub 
        {
            my $i;
            my $lvl = $CALLER_LEVEL;
            {
                ++$i;
                my @caller = $caller_func ? $caller_func->( $i ) : caller( $i );
                my $pkg = $caller[0];
                unless( defined( $pkg ) ) 
                {
                    if( defined( $caller[2] ) ) 
                    {
                        # this can happen when the stash has been deleted
                        # in that case, just assume that it's a reasonable place to
                        # stop (the file and line data will still be intact in any
                        # case) - the only issue is that we can't detect if the
                        # deleted package was internal (so don't do that then)
                        # -doy
                        redo unless( 0 > --$lvl );
                        last;
                    }
                    else 
                    {
                        return( 2 );
                    }
                }
                redo if( $CALLER_INTERNAL->{ $pkg } );
                redo unless( 0 > --$lvl );
            }
            return( $i - 1 );
        };
        
        $args->{skip_frames} = $error_start_frame->();
    }
    
    my $skip_frame = $args->{skip_frames} || 0;
    # Skip one frame to exclude us
    $skip_frame++;
    
    my $trace = Devel::StackTrace->new( skip_frames => $skip_frame, indent => 1 );
    my $frame = $trace->next_frame;
    my $frame2 = $trace->next_frame;
    $trace->reset_pointer;
    if( ref( $args->{object} ) && Scalar::Util::blessed( $args->{object} ) && $args->{object}->isa( 'Module::Generic::Exception' ) )
    {
        my $o = $args->{object};
        $self->{message} = $o->message;
        $self->{code} = $o->code;
        $self->{type} = $o->type;
        $self->{retry_after} = $o->retry_after;
    }
    else
    {
        # print( STDERR __PACKAGE__, "::init() Got here with args: ", Data::Dumper::Concise::Dumper( $args ), "\n" );
        $self->{message} = $args->{message} || '';
        $self->{code} = $args->{code} if( exists( $args->{code} ) );
        $self->{type} = $args->{type} if( exists( $args->{type} ) );
        $self->{retry_after} = $args->{retry_after} if( exists( $args->{retry_after} ) );
        # I do not want to alter the original hash reference, which may adversely affect the calling code if they depend on its content for further execution for example.
        my $copy = {};
        %$copy = %$args;
        CORE::delete( @$copy{ qw( message code type retry_after skip_frames ) } );
        # print( STDERR __PACKAGE__, "::init() Following non-standard keys to set up: '", join( "', '", sort( keys( %$copy ) ) ), "'\n" );
        # Do we have some non-standard parameters?
        foreach my $p ( keys( %$copy ) )
        {
            my $p2 = $p;
            $p2 =~ tr/-/_/;
            $p2 =~ s/[^a-zA-Z0-9\_]+//g;
            $p2 =~ s/^\d+//g;
            $self->$p2( $copy->{ $p } );
        }
    }
    $self->{file} = $frame->filename;
    $self->{line} = $frame->line;
    ## The caller sub routine ( caller( n ) )[3] returns the sub called by our caller instead of the sub that called our caller, so we go one frame back to get it
    $self->{subroutine} = $frame2->subroutine if( $frame2 );
    $self->{package} = $frame->package;
    $self->{trace} = $trace;
    return( $self );
}

# This is important as stringification is called by die, so as per the manual page, we need to end with new line
# And will add the stack trace
sub as_string
{
    no overloading;
    my $self = shift( @_ );
    return( $self->{_cache} ) if( $self->{_cache} );
    my $str = $self->message;
    $str =~ s/\r?\n$//g;
    $str .= sprintf( " within package %s at line %d in file %s\n%s", $self->package, $self->line, $self->file, $self->trace->as_string );
    $self->{_cache} = $str;
    return( $str );
}

sub caught 
{
    my( $class, $e ) = @_;
    return if( ref( $class ) );
    return unless( Scalar::Util::blessed( $e ) && $e->isa( $class ) );
    return( $e );
}

sub code { return( shift->_set_get_scalar( 'code', @_ ) ); }

sub file { return( shift->_set_get_scalar( 'file', @_ ) ); }

sub line { return( shift->_set_get_scalar( 'line', @_ ) ); }

sub message { return( shift->_set_get_scalar( 'message', @_ ) ); }

sub package { return( shift->_set_get_scalar( 'package', @_ ) ); }

# From perlfunc docmentation on "die":
# "If LIST was empty or made an empty string, and $@ contains an
# object reference that has a "PROPAGATE" method, that method will
# be called with additional file and line number parameters. The
# return value replaces the value in $@; i.e., as if "$@ = eval {
# $@->PROPAGATE(__FILE__, __LINE__) };" were called."
sub PROPAGATE
{
    my( $self, $file, $line ) = @_;
    if( defined( $file ) && defined( $line ) )
    {
        my $clone = $self->clone;
        $clone->file( $file );
        $clone->line( $line );
        return( $clone );
    }
    return( $self );
}

sub rethrow 
{
    my $self = shift( @_ );
    return if( !Scalar::Util::blessed( $self ) );
    die( $self );
}

sub retry_after { return( shift->_set_get_scalar( 'retry_after', @_ ) ); }

sub subroutine { return( shift->_set_get_scalar( 'subroutine', @_ ) ); }

sub throw
{
    my $self = shift( @_ );
    my $e;
    if( @_ )
    {
        my $msg  = shift( @_ );
        $e = $self->new({
            skip_frames => 1,
            message => $msg,
        });
    }
    else
    {
        $e = $self;
    }
    die( $e );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' || $serialiser eq 'CBOR' );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

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

sub TO_JSON { return( shift->as_string ); }

# Devel::StackTrace has a stringification overloaded so users can use the object to get more information or simply use it as a string to get the stack trace equivalent of doing $trace->as_string
sub trace { return( shift->_set_get_object( 'trace', 'Devel::StackTrace', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub _obj_eq
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Exception' ) )
    {
        if( $self->message eq $other->message &&
            $self->file eq $other->file &&
            $self->line == $other->line )
        {
            return( 1 );
        }
        else
        {
            return( 0 );
        }
    }
    # Compare error message
    elsif( !ref( $other ) )
    {
        my $me = $self->message;
        return( $me eq $other );
    }
    # Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $code;
    if( $code = $self->can( $method ) )
    {
        return( $code->( @_ ) );
    }
    else
    {
        eval( "sub ${class}::${method} { return( shift->_set_get_scalar( '$method', \@_ ) ); }" );
        die( $@ ) if( $@ );
        return( $self->$method( @_ ) );
    }
};

1;

__END__
