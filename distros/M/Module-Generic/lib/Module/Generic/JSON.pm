##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/JSON.pm
## Version v0.2.2
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/03/24
## Modified 2025/04/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::JSON;
BEGIN
{
    use v5.12.0;
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( @EXPORT @EXPORT_OK $AUTOLOAD $DEBUG $VERSION );
    use JSON ();
    use Scalar::Util ();
    our @ISA         = qw( Module::Generic );
    our @EXPORT      = qw( from_json to_json encode_json decode_json );
    our @EXPORT_OK   = qw( new_json );
    our %EXPORT_TAGS = ();
    our $VERSION = 'v0.2.2';
};

use v5.12.0;
use strict;
use warnings;

sub import
{
    my $this = shift( @_ );
    $this->export_to_level( 1, undef, ( @_, @EXPORT ) );
}

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    my $opts = $self->_get_args_as_hash( @_ );
    # try-catch
    local $@;
    my $j = eval{ JSON->new };
    if( $@ )
    {
        return( $self->error( "Error instantiating a JSON object: $@" ) );
    }
    my $equi =
    {
        order   => 'canonical',
        ordered => 'canonical',
        sorted  => 'canonical',
        sort    => 'canonical',
    };

    # We remove it to prevent it from interfering with out checks
    my $debug = ( CORE::exists( $opts->{debug} ) ? CORE::delete( $opts->{debug} ) : undef );
    foreach my $opt ( keys( %$opts ) )
    {
        my $ref;
        $ref = $j->can( exists( $equi->{ $opt } ) ? $equi->{ $opt } : $opt ) || do
        {
            warn( "Unknown JSON option '${opt}'\n" ) if( $self->_warnings_is_enabled( 'Module::Generic' ) );
            next;
        };

        eval
        {
            $ref->( $j, $opts->{ $opt } );
        };
        if( $@ )
        {
            if( $@ =~ /perl[[:blank:]\h]+structure[[:blank:]\h]+exceeds[[:blank:]\h]+maximum[[:blank:]\h]+nesting[[:blank:]\h]+level/i )
            {
                my $max = $j->get_max_depth;
                return( $self->error( "Unable to set json option ${opt}: $@ (max_depth value is ${max})" ) );
            }
            else
            {
                return( $self->error( "Unable to set json option ${opt}: $@" ) );
            }
        }
        delete( $opts->{ $opt } );
    }
    $self->{_json} = $j;
    $opts->{debug} = $debug if( defined( $debug ) );
    # Pass the rest to our parent init for properties unique to our module.
    $self->SUPER::init( %$opts ) || return( $self->pass_error );
    return( $self );
}

sub decode_json($)
{
    my $json = __PACKAGE__->new;
    my $rv = eval
    {
        $json->utf8->decode( @_ );
    };
    if( $@ )
    {
        return( $json->error( $@ ) );
    }
    return( $rv );
}

sub encode_json($)
{
    my $json = __PACKAGE__->new;
    my $rv = eval
    {
        $json->utf8->encode( @_ );
    };
    if( $@ )
    {
        return( $json->error( $@ ) );
    }
    return( $rv );
}

sub to_json($@)
{
    if( ref($_[0]) eq __PACKAGE__ or
        ( @_ > 2 and $_[0] eq __PACKAGE__ ) )
    {
        return( __PACKAGE__->error( "to_json should not be called as a method." ) );
    }

    my $opts = {};
    if( @_ == 2 and ref($_[1]) eq 'HASH' )
    {
        $opts = $_[1];
    }
    my $json = __PACKAGE__->new( %$opts ) ||
        return( __PACKAGE__->pass_error );
    return( $json->encode( $_[0] ) );
}


sub from_json($@)
{
    if( ref( $_[0] ) eq __PACKAGE__ or $_[0] eq __PACKAGE__ )
    {
        return( __PACKAGE__->error( "from_json should not be called as a method." ) );
    }

    my $opts = {};
    if( @_ == 2 and ref($_[1]) eq 'HASH' )
    {
        $opts = $_[1];
    }
    my $json = __PACKAGE__->new( %$opts ) ||
        return( __PACKAGE__->pass_error );
    return( $json->decode( $_[0] ) );
}

sub new_json
{
    my $self = __PACKAGE__->new( @_ );
    $self->debug( $DEBUG );
    return( $self );
}

sub AUTOLOAD
{
    my $self;
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::JSON' ) );
    my @args = @_;
    my( $class, $meth, $code );
    $class = ref( $self ) || $self;
    $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }


    if( $self )
    {
        my $j = $self->{_json} || return( $self->error( "No JSON object could be found! This should not happen." ) );
        if( $code = $j->can( $meth ) )
        {
            local $@;
            my $wantlist = wantarray();
            my @rv = eval
            {
                local $SIG{__DIE__} = sub{};
                no warnings;
                ( $wantlist // '' ) ? ( $code->( $j, scalar( @args ) ? @args : () ) ) : scalar( $code->( $j, scalar( @args ) ? @args : () ) )
            };
            if( $@ )
            {
                return( $self->error( $@ ) );
            }
            if( Scalar::Util::blessed( $rv[0] ) && $rv[0]->isa( 'JSON' ) )
            {
                return( $self );
            }
            else
            {
                return( ( $wantlist // '' ) ? @rv : $rv[0] );
            }
        }
        else
        {
            return( $self->error( "Unknown JSON method '${meth}'" ) );
        }
    }
    elsif( $code = JSON->can( $meth ) )
    {
        local $@;
        my @rv = eval
        {
            local $SIG{__DIE__} = sub{};
            $code->( scalar( @args ) ? @args : () );
        };
        if( $@ )
        {
            return( __PACKAGE__->error( $@ ) );
        }
        return( wantarray() ? @rv : $rv[0] );
    }
    else
    {
        die( "Unknown class function '${meth}' in JSON" );
    }
}

sub DESTROY
{
    # DESTROY exists to avoid being caught by AUTOLOAD
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::JSON - A thin and reliable wrapper around JSON

=head1 SYNOPSIS

    use Module::Generic::JSON;
    my $j = Module::Generic::JSON->new(
        utf8         => 1,
        pretty       => 1,
        canonical    => 1,
        relaxed      => 1,
        allow_nonref => 1,
    ) || die( Module::Generic::JSON->error );
    $j->encode( $some_ref ) || die( $j->error );

Or

    my $j = Module::Generic::JSON->new;
    $j->utf8->pretty->canonical->relaxed->allow_nonref->encode( $some_ref ) ||
        die( $j->error );

Or, even simpler:

    use Module::Generic::JSON qw( new_json );
    my $j = new_json(
        utf8         => 1,
        pretty       => 1,
        canonical    => 1,
        relaxed      => 1,
        allow_nonref => 1,
    ) || die( Module::Generic::JSON->error );
    $j->encode( $some_ref ) || die( $j->error );

=head1 VERSION

    v0.2.2

=head1 DESCRIPTION

This is a thin and reliable wrapper around the otherwise excellent L<JSON> class. Its added value is:

=over 4

=item * Allow the setting of all the JSON properties upon object instantiation

As mentioned in the synopsis, you can do:

    my $j = Module::Generic::JSON->new(
        utf8         => 1,
        pretty       => 1,
        canonical    => 1,
        relaxed      => 1,
        allow_nonref => 1,
    ) || die( Module::Generic::JSON->error );

instead of:

    my $j = Module::Generic::JSON->new;
    $j = $j->utf8->pretty->canonical->relaxed->allow_nonref;

=item * No fatal exception that would kill your process inadvertently.

This is important in a web application where you do not want some module killing your process, but rather you want the exception to be handled gracefully.

Thus, instead of having to do:

    local $@;
    my $ref = eval{ $j->decode( $payload ) };
    if( $@ )
    {
        # Like returning a 500 or maybe 400 HTTP error
        bailout_gracefully( $@ );
    }

you can simply do:

    my $ref = $j->decode( $payload ) || bailout_gracefully( $j->error );

=item * Upon error, it returns an L<exception object|Module::Generic::Exception>

=item * All methods calls are passed through to L<JSON>, and any exception is caught, and handled properly for you.

=back

For L<class functions|/"CLASS FUNCTIONS"> too, you can execute them safely and catch error, if any, by calling C<< Module::Generic::JSON->error >>, so for example:

    decode_json( $some_data ) || die( Module::Generic::JSON->error );

=head1 CONSTRUCTOR

=head2 new

This takes an hash or hash reference of options and returns a new L<Module::Generic::JSON> object. The options must be supported by L<JSON>. On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $j = Module::Generic::JSON->new( utf8 => 1, pretty => 1 ) ||
        die( Module::Generic::JSON->error );

=head1 METHODS

See the documentation for the module L<JSON> for more information, but below are the known methods supported by L<JSON>

=head2 allow_blessed

=head2 allow_nonref

=head2 allow_tags

=head2 allow_unknown

=head2 ascii

=head2 backend

=head2 boolean

=head2 boolean_values

=head2 canonical

=head2 convert_blessed

=head2 decode

Decodes a JSON string and returns the resulting Perl data structure. On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $data = $j->decode( '{"a":1}' ) || die( $j->error );

=head2 decode_prefix

=head2 encode

Encodes a Perl data structure into a JSON string. On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $json_str = $j->encode( { a => 1 } ) || die( $j->error );

=head2 filter_json_object

=head2 filter_json_single_key_object

=head2 indent

=head2 is_pp

=head2 is_xs

=head2 latin1

=head2 max_depth

=head2 max_size

=head2 pretty

=head2 property

=head2 relaxed

=head2 space_after

=head2 space_before

=head2 utf8

=head1 CLASS FUNCTIONS

=head2 decode_json

Decodes a C<JSON> string and returns the resulting Perl data structure. On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $data = decode_json( '{"a":1}' ) || die( Module::Generic::JSON->error );

=head2 encode_json

Encodes a Perl data structure into a C<JSON> string. On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $json_str = encode_json( { a => 1 } ) || die( Module::Generic::JSON->error );

=head2 from_json

Decodes a C<JSON> string with optional configuration options. Takes a C<JSON> string and an optional hash reference of options (passed to L</new>). On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $data = from_json( '{"a":1}', { utf8 => 1 } ) || die( Module::Generic::JSON->error );

=head2 to_json

Encodes a Perl data structure with optional configuration options. Takes a Perl data structure and an optional hash reference of options (passed to L</new>). On error, sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context:

    my $json_str = to_json( { a => 1 }, { pretty => 1 } ) || die( Module::Generic::JSON->error );

=head1 SERIALISATION

L<Module::Generic::JSON> inherits serialisation methods from L<Module::Generic>. The following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze>, and C<STORABLE_thaw>. See L<Module::Generic> for details.

=head1 THREAD-SAFETY

L<Module::Generic::JSON> is thread-safe for all operations, as it operates on per-object state and avoids the thread-safety issues present in the underlying L<JSON> module.

Key considerations for thread-safety:

=over 4

=item * B<Shared Variables>

There are no shared variables that are modified at runtime in L<Module::Generic::JSON>. The global C<$DEBUG> variable (inherited from L<Module::Generic>) is typically set before threads are created, and it is the user's responsibility to ensure thread-safety if modified at runtime:

    use threads;
    local $Module::Generic::JSON::DEBUG = 0; # Set before threads
    my @threads = map
    {
        threads->create(sub
        {
            my $json = Module::Generic::JSON->new( utf8 => 1 );
            $json->encode( { a => 1 } ); # Thread-safe
        });
    } 1..5;
    $_->join for( @threads );

Note that the L<JSON> module uses a global C<$JSON> variable for functions like C<encode_json> and C<decode_json>, which can lead to thread-safety issues if modified at runtime. L<Module::Generic::JSON> avoids this by creating a new object instance for each call to L</decode_json> and L</encode_json>, ensuring thread isolation.

=item * B<Object State>

The underlying L<JSON> object is stored per-object, ensuring thread isolation:

    use threads;
    my @threads = map
    {
        threads->create(sub
        {
            my $json = Module::Generic::JSON->new( utf8 => 1 );
            $json->encode( { tid => threads->tid } ); # Thread-safe
        });
    } 1..5;
    $_->join for( @threads );

=item * B<Class Functions>

Class functions like L</decode_json> and L</encode_json> create a new object per call, ensuring thread isolation:

    use threads;
    my @threads = map
    {
        threads->create(sub
        {
            my $data = decode_json( '{"a":1}' ); # Thread-safe
        });
    } 1..5;
    $_->join for( @threads );

=item * B<External Libraries>

The underlying L<JSON> module (both L<JSON::XS> and L<JSON::PP>) is thread-safe for object methods, as it operates on per-object state. However, its class functions (e.g., C<encode_json>, C<decode_json>) are not thread-safe due to the use of a global C<$JSON> variable. L<Module::Generic::JSON> mitigates this by always creating a new instance for such calls.

=item * B<Serialisation>

Serialisation methods (L</FREEZE>, L</THAW>) operate on per-object state, making them thread-safe.

=back

For debugging in threaded environments (depending on your Operating System):

    ls -l /proc/$$/fd  # List open file descriptors

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<JSON>, L<Module::Generic::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
