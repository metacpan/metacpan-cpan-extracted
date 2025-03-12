##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Exception.pm
## Version v1.3.1
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2024/02/24
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
        bool    => sub{1},
        fallback => 1,
    );
    $CALLER_LEVEL = 0;
    $CALLER_INTERNAL->{'Module::Generic'}++;
    $CALLER_INTERNAL->{'Module::Generic::Exception'}++;
    our $VERSION = 'v1.3.1';
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
    $self->{cause} = undef unless( length( $self->{cause} ) );
    $self->{code} = '' unless( length( $self->{code} ) );
    $self->{file} = '' unless( length( $self->{file} ) );
    $self->{lang} = '' unless( length( $self->{lang} ) );
    $self->{line} = '' unless( length( $self->{line} ) );
    $self->{message} = '' unless( length( $self->{message} ) );
    $self->{package} = '' unless( length( $self->{package} ) );
    $self->{retry_after} = '' unless( length( $self->{retry_after} ) );
    $self->{subroutine} = '' unless( length( $self->{subroutine} ) );
    $self->{type} = '' unless( length( $self->{type} ) );
    my $args = {};
    if( @_ )
    {
        if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
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
    $self->debug( $args->{debug} ) if( exists( $args->{debug} ) );
    
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
        $self->message( $o->message );
        $self->code( $o->code );
        $self->type( $o->type );
        $self->retry_after( $o->retry_after );
    }
    else
    {
        # print( STDERR __PACKAGE__, "::init() Got here with args: ", Module::Generic->dump( $args ), "\n" );
        $self->message( $args->{message} || '' );
        $self->code( $args->{code} ) if( exists( $args->{code} ) );
        $self->type( $args->{type} ) if( exists( $args->{type} ) );
        $self->retry_after( $args->{retry_after} ) if( exists( $args->{retry_after} ) );
        # I do not want to alter the original hash reference, which may adversely affect the calling code if they depend on its content for further execution for example.
        my $copy = {};
        %$copy = %$args;
        CORE::delete( @$copy{ qw( message code type retry_after skip_frames file line subroutine ) } );
        # print( STDERR __PACKAGE__, "::init() Following non-standard keys to set up: '", join( "', '", sort( keys( %$copy ) ) ), "'\n" );
        # Do we have some non-standard parameters?
        foreach my $p ( keys( %$copy ) )
        {
            my $p2 = $p;
            $p2 =~ tr/-/_/;
            $p2 =~ s/[^a-zA-Z0-9\_]+//g;
            $p2 =~ s/^\d+//g;
            # We do not want to trigger an error by calling non-existing subroutines
            if( my $subref = $self->can( $p2 ) )
            {
                $subref->( $self => $copy->{ $p } );
            }
        }
    }
    $self->file( $frame->filename );
    $self->line( $frame->line );
    ## The caller sub routine ( caller( n ) )[3] returns the sub called by our caller instead of the sub that called our caller, so we go one frame back to get it
    $self->subroutine( $frame2->subroutine ) if( $frame2 );
    $self->package( $frame->package );
    $self->trace( $trace );
    return( $self );
}

# This is important as stringification is called by die, so as per the manual page, we need to end with new line
# And will add the stack trace
sub as_string
{
    no overloading;
    my $self = shift( @_ );
    return( $self->{_cache} ) if( $self->{_cache} && !CORE::length( $self->{_reset} ) );
    my $str = $self->message;
    if( $self->_can_overload( $str => '""' ) )
    {
        use overloading;
        $str = "$str";
    }
    $str =~ s/\r?\n$//g;
    $str .= sprintf( " within package %s at line %d in file %s\n%s", $self->package, $self->line, $self->file, $self->trace->as_string );
    $self->{_cache} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

sub caught 
{
    my( $class, $e ) = @_;
    return if( ref( $class ) );
    return unless( Scalar::Util::blessed( $e ) && $e->isa( $class ) );
    return( $e );
}

sub cause { return( shift->reset(@_)->_set_get_hash_as_mix_object( 'cause', @_ ) ); }

sub code { return( shift->reset(@_)->_set_get_scalar( 'code', @_ ) ); }

sub file { return( shift->reset(@_)->_set_get_scalar( 'file', @_ ) ); }

sub lang { return( shift->reset(@_)->_set_get_scalar( 'lang', @_ ) ); }

sub line { return( shift->reset(@_)->_set_get_scalar( 'line', @_ ) ); }

sub locale { return( shift->reset(@_)->_set_get_scalar( 'lang', @_ ) ); }

sub message { return( shift->reset(@_)->_set_get_scalar( {
    field => 'message',
    callbacks => 
    {
        set => sub
        {
            my( $self, $val ) = @_;
            if( defined( $val ) && !$self->lang )
            {
                if( $self->_can( $val => 'locale' ) )
                {
                    $self->lang( $val->locale );
                }
                elsif( $self->_can( $val => 'lang' ) )
                {
                    $self->lang( $val->lang );
                }
            }
            return( $val );
        },
    },
}, @_ ) ); }

sub package { return( shift->reset(@_)->_set_get_scalar( 'package', @_ ) ); }

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

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

sub rethrow 
{
    my $self = shift( @_ );
    return if( !Scalar::Util::blessed( $self ) );
    die( $self );
}

sub retry_after { return( shift->reset(@_)->_set_get_scalar( 'retry_after', @_ ) ); }

sub subroutine { return( shift->reset(@_)->_set_get_scalar( 'subroutine', @_ ) ); }

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

# Devel::StackTrace has a stringification overloaded so users can use the object to get more information or simply use it as a string to get the stack trace equivalent of doing $trace->as_string
sub trace { return( shift->reset(@_)->_set_get_object( 'trace', 'Devel::StackTrace', @_ ) ); }

sub type { return( shift->reset(@_)->_set_get_scalar( 'type', @_ ) ); }

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
            return(1);
        }
        else
        {
            return(0);
        }
    }
    # Compare error message
    elsif( !ref( $other ) )
    {
        my $me = $self->message;
        return( $me eq $other );
    }
    # Otherwise some reference data to which we cannot compare
    return(0) ;
}

# NOTE: AUTOLOAD
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

sub UNIVERSAL::exception
{
    my $class = shift( @_ );
    my $me = __PACKAGE__;
    my $opts = $me->_get_args_as_hash( @_ );
    $opts->{extends} //= $me;
    my $rv = $class->create_class( %$opts ) || die( Module::Generic->error );
    return( $rv );
}

1;
# NOTE: POD
__END__
=encoding utf8

=head1 NAME

Module::Generic::Exception - Generic Module Exception Class

=head1 SYNOPSIS

    my $ex = Module::Generic::Exception->new({
        code => 404,
        type => $error_type,
        file => '/home/joe/some/lib/My/Module.pm',
        lang => 'en_GB',
        # or alternatively
        # locale => 'en_GB',
        line => 120,
        message => 'Invalid property provided',
        package => 'My::Module',
        subroutine => 'customer_info',
        # Some optional discretionary metadata hash reference
        cause =>
            {
            object => $some_object,
            payload => $raw_data,
            },
    });

or, providing a list of string that will be concatenated:

    my $ex = Module::Generic::Exception->new( "Some error", "has occurred:", $details );

or, re-using an exception object:

    my $ex = Module::Generic::Exception->new( $other_exception_object );

    print( "Error stack trace: ", $ex->stack_trace, "\n" );
    # or
    $object->customer_orders || die( "Error in file ", $object->error->file, " at line ", $object->error->line, "\n" );
    # or simply:
    $object->customer_orders || die( "Error: ", $object->error, "\n" );
    $ex->cause->payload;

=head1 VERSION

    v1.3.1

=head1 DESCRIPTION

This is a simple and straightforward exception class you can use or inherit from. The error object can be stringified or compared.

When stringified, it provides the error message along with precise information about where the error occurred and a stack trace.

L<Module::Generic::Exception> objects are created by L<Module::Generic/"error"> method.

=head1 METHODS

=head2 new

It takes either an L<Module::Generic::Exception> object or an hash reference of properties, or a list of arguments that will be concatanated to form the error message. The list of arguments can contain code reference such as reference to sub routines, who will be called and their returned value added to the error message string. For example :

    my $ex = Module::Generic::Exception->new( "Invalid property. Value recieved are: ", sub{ Dumper( $hash ) } );

    # or

    my $ex = Module::Generic::Exception->new( $other_exception_object_for_reuse );
    # This will the object property

    # or

    my #ex = Module::Generic::Exception->new({
        message => "Invalid property.",
        code => 404,
        type => 'customer',
    })

Possible properties that can be specified are :

=over 4

=item * C<cause>

An optional and arbitrary hash reference of metadata that serve to provide more context on the error.

=item * C<code>

An error code

=item * C<file>

The location where the error occurred. This is populated using the L<Devel::StackTrace/"filename">

=item * C<lang>

An iso 639 language code that represents the language the error message is in.

You can use C<locale> alternatively. See the L</lang> method below for more information.

=item * C<line>

The line number in the file where the error occurred. This is populated using the L<Devel::StackTrace/"line">

=item * C<locale>

An iso 639 language code that represents the language the error message is in.

You can use C<lang> alternatively. See the L</lang> method below for more information.

=item * C<message>

The error message. It can be provided as a list of arguments that will be concatenated, or as the I<message> property in an hash reference, or copied from another exception object passed as the sole argument.

=item * C<object>

When this is set, such as when another L<Module::Generic::Exception> object is provided as unique argument, then the properties I<message>, I<code>, I<type>, I<retry_after> are copied from it in the new exception object.

=item * C<package>

The package name where the error occurred. This is populated using the L<Devel::StackTrace/"package">

=item * C<retry_after>

An optional value to indicate in seconds how long to wait to retry.

=item * C<skip_frames>

This is used as a parameter to L<Devel::StackTrace> upon instantiation to instruct how many it should skip to start creating the stack trace.

=item * C<subroutine>

The name of the sub routine from which this was called. This is populated using the L<Devel::StackTrace/"subroutine">

=item * C<type>

An optional error type

=back

It returns the exception object.

=head2 as_string

This returns a string representation of the Exception such as :

    Invalid property within package My::Module at line 120 in file /home/john/lib/My/Module.pm
        # then some strack trace here

=head2 caught

    use Nice::Try;
    try
    {
        # An error made with Module::Generic::Exception
        die( $object->error );
    }
    catch( $e )
    {
        # If this error is one of ours
        if( Module::Generic::Exception->caught( $e ) )
        {
            # Do something about it
        }
    }

But L<Nice::Try> let's you do this:

    try
    {
        die( $object->error );
    }
    catch( Module::Generic::Exception $e )
    {
        # Do something about it
    }

=head2 cause

    my $ex = Module::Generic::Exception->new({
        code => 401,
        message => 'Not authorised',
        cause => {
            id => 1234,
        },
    });
    say $ex->cause->id; # 1234

Sets or gets an hash reference of metadata that serve to provide more context on the error.

This returns an L<hash object|Module::Generic::Hash>.

=head2 code

Set or get the error code. It returns the current value.

=head2 file

Set or get the file path where the error originated. It returns the current value.

=head2 lang

Set or get the language iso 639 code representing the language the error message is in.

If the error message is a string object that has a C<locale> or C<lang> object, it will be used to set this C<lang> value.

This is the case if you use the module L<Text::PO::Gettext> to implement GNU PO localisation framework. For example:

    use Text::PO::Gettext;
    my $po = Text::PO::Gettext->new || die( Text::PO::Gettext->error, "\n" );
    my $po = Text::PO::Gettext->new({
        category => 'LC_MESSAGES',
        debug    => 3,
        domain   => "com.example.api",
        locale   => 'ja-JP',
        path     => "/home/joe/locale",
        use_json => 1,
    }) || die( Text::PO::Gettext->error, "\n" );

    my $message = $po->gettext( "Something wrong happened." );

Then, C<$message> would be a C<Text::PO::String>

See L<Text::PO::Gettext/gettext> for more information.

=head2 line

Set or get the line where the error originated. It returns the current value.

=head2 locale

This is an alias for L</lang>

=head2 message

Set or get the error message. It returns the current value.

It takes a string, or a list of strings which will be concatenated.

For example :

    $ex->messsage( "I found some error:", $some_data );

=head2 package

Set or get the class/package name where the error originated. It returns the current value.

=head2 PROPAGATE

This method is called by perl when you call L<perlfunc/die> with no parameters and C<$@> is set to a L<Module::Generic::Exception> object.

This returns a new exception object that perl will use to replace the value in C<$@>

=head2 reset

The stringification of the exception is cached. This method C<reset>, resets that cache so the exception can be stringified again.

=head2 rethrow

This rethrow (i.e. L<perlfunc/"die">) the original error. It must be called with the exception object or else it will return undef.

This is ok :

    $ex->rethrow;

But this is not :

    Module::Generic::Exception->rethrow;

=head2 retry_after

Set or get the number of seconds to way before to retry whatever cause the error. It returns the current value.

=head2 subroutine

Set or get the subroutine where the error originated. It returns the current value.

=head2 throw

Provided with a message string, this will create a new L<Module::Generic::Exception> object and call L<perlfunc/"die"> with it.

=head2 TO_JSON

Special method called by L<JSON> to transform this object into a string suitable to be added in a json data.

=head2 trace

Set or get the L<Devel::StackTrace> object used to provide a full stack trace of the error. It returns the current value.

=head2 type

Set or get the error type. It returns the current value.

=head1 CLASS FUNCTIONS

=head2 exception

    exception My::Exception;
    # or
    exception Other::Exception extends => 'My::Exception';
    die My::Exception->new( "Something bad has happened" );
    say Other::Exception->error( "Another bad thing has happened" );

This class function takes a package name, and creates an exception class based on that package.

The following options are also available:

=over 4

=item * C<extends>

This takes a package name as value and will serve as the parent class

=back

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2024 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
