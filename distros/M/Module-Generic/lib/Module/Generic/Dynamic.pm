##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Dynamic.pm
## Version v1.2.4
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2023/11/18
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Dynamic;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use warnings::register;
    use vars qw( $AUTOLOAD $VERSION $DEBUG );
    use Config;
    use Module::Generic::Global ':const';
    use Scalar::Util ();
    our $DEBUG = 0;
    our $VERSION = 'v1.2.4';
};

use strict;
no warnings 'redefine';

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $self = bless( {} => $class );
    my $data = $self->{_data} = {};
    # A Module::Generic object standard parameter
    $self->{_data_repo} = '_data';
    my $hash = {};
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( scalar( @_ ) == 1 && ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'HASH' )
    {
        $hash = shift( @_ );
        $self->{debug} = $DEBUG if( $DEBUG && !CORE::exists( $hash->{debug} ) );
    }
    elsif( @_ )
    {
        CORE::warn( "Parameter provided is not an hash reference: '", join( "', '", @_ ), "'\n" ) if( $this->_warnings_is_enabled );
    }

    if( HAS_THREADS )
    {
        if( threads->tid != 0 )
        {
            warn( "Module::Generic::Dynamic is not thread-safe and should not be called from a thread." ) if( $this->_warnings_is_enabled );
        }
    }

    my $make_class = sub
    {
        my $k = shift( @_ );
        my $new_class = $k;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $new_class = "${class}\::${new_class}";
        ## Sanitise the key which will serve as a method name
        my $clean_field = $k;
        $clean_field =~ tr/-/_/;
        $clean_field =~ s/\_{2,}/_/g;
        $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
        $clean_field =~ s/^\d+//g;
        my $perl = <<EOT;
package $new_class;
BEGIN
{
    use strict;
    use Module::Generic;
    use parent -norequire, qw( Module::Generic::Dynamic );
};

1;

EOT
        local $@;
        my $rc = eval( $perl );
        die( "Unable to dynamically create module $new_class: $@" ) if( $@ );
        return( $new_class, $clean_field );
    };


    local $@;
    foreach my $k ( sort( keys( %$hash ) ) )
    {
        if( ref( $hash->{ $k } ) eq 'HASH' )
        {
            my( $new_class, $clean_field ) = $make_class->( $k );
            next unless( length( $clean_field ) );
            eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object( '$clean_field', '$new_class', \@_ ) ); }" );
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        # elsif( ref( $hash->{ $k } ) eq 'ARRAY' )
        elsif( $self->_is_array( $hash->{ $k } ) )
        {
            my( $new_class, $clean_field ) = $make_class->( $k );
            # We take a peek at what we have to determine how we will handle the data
            my $mode = lc( scalar( @{$hash->{ $k }} ) ? ref( $hash->{ $k }->[0] ) : '' );
            if( $mode eq 'hash' )
            {
                my $all = [];
                foreach my $this ( @{$hash->{ $k }} )
                {
                    my $o = $this->{_looping} ? $this->{_looping} : $new_class->new( $this );
                    $this->{_looping} = $o;
                    CORE::push( @$all, $o );
                }
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object_array_object( '$clean_field', '$new_class', \@_ ) ); }" );
            }
            else
            {
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_array_as_object( '$clean_field', \@_ ) ); }" );
            }
            die( $@ ) if( $@ );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        elsif( !ref( $hash->{ $k } ) )
        {
            my $clean_field = $k;
            $clean_field =~ tr/-/_/;
            $clean_field =~ s/\_{2,}/_/g;
            $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
            $clean_field =~ s/^\d+//g;
            # Possibly there is no acceptable characters to make a field out of it
            next unless( length( $clean_field ) );
            my $func_name = '_set_get_scalar_as_object';
            if( $clean_field =~ /(^|\b)date|datetime($|\b)/ )
            {
                $func_name = '_set_get_datetime';
            }
            elsif( $clean_field =~ /(^|\b)(uri|url)($|\b)/ || $hash->{ $k } =~ /^https?\:\/{2}/ )
            {
                $func_name = '_set_get_uri';
            }
            # my $pl = "sub ${class}::${clean_field} { return( shift->${func_name}( '$clean_field', \@_ ) ); }";
            my $pl = q[sub ${class}::${clean_field} { print( STDERR "Got here\n" ); }];
            eval( $pl );
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
        else
        {
            my $clean_field = $k;
            $clean_field =~ tr/-/_/;
            $clean_field =~ s/\_{2,}/_/g;
            $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
            $clean_field =~ s/^\d+//g;
            my $rv = $self->$clean_field( $hash->{ $k } );
            return( $self->pass_error ) if( !defined( $rv ) && $self->error );
        }
    }
    return( $self );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But CBOR and Storable want a list with the first element being the serialised element
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

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    my $ref  = { %$self };
    CORE::delete( $ref->{_data} );
    CORE::delete( $ref->{_data_repo} );
    CORE::return( $ref );
}

sub AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my @args = @_;
    my $class = ref( $self ) || $self;
    if( HAS_THREADS )
    {
        if( threads->tid != 0 )
        {
            CORE::warn( "Module::Generic::Dynamic::AUTOLOAD is not thread-safe and should not be called from a thread." ) if( warnings::enabled() );
            # return( $self->error( "Module::Generic::Dynamic::AUTOLOAD is not thread-safe and should not be called from a thread." ) );
        }
    }
    my $code;
    # print( STDERR __PACKAGE__, "::$method(): Called\n" );
    if( $code = $self->can( $method ) )
    {
        return( $code->( @args ) );
    }
    ## elsif( CORE::exists( $self->{ $method } ) )
    else
    {
        my $ref = lc( ref( $_[0] ) );
        # Default
        my $handler = ( $ref eq 'scalar' || !$ref ) ? '_set_get_scalar_as_object' : '_set_get_scalar';
        # if( @_ && ( $ref eq 'hash' || $ref eq 'array' ) )
        if( $ref eq 'hash' || $ref eq 'array' )
        {
            # print( STDERR __PACKAGE__, "::$method(): using handler $handler for type $ref\n" );
            $handler = "_set_get_${ref}_as_object";
        }
        elsif( $ref eq 'json::pp::boolean' || 
            $ref eq 'module::generic::boolean' ||
            ( $ref eq 'scalar' && ( $$ref == 1 || $$ref == 0 ) ) )
        {
            $handler = '_set_get_boolean';
        }
        elsif( $ref eq 'regexp' )
        {
            $handler = '_set_get_scalar';
        }
        elsif( !$ref && $method =~ /(?:created|updated|modified|(?<=[^a-zA-Z0-9])(date|datetime)(?!>[^a-zA-Z0-9]))/ )
        {
            $handler = '_set_get_datetime';
        }
        elsif( !$ref && ( $method =~ /(?<=[^a-zA-Z0-9])(uri|url)(?!>[^a-zA-Z0-9])/ || $_[0] =~ /^https?\:\/{2}/ ) )
        {
            $handler = '_set_get_uri';
        }
        elsif( !$ref && $_[0] =~ /^[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}$/ )
        {
            $handler = '_set_get_uuid';
        }
        local $@;
        eval( "sub ${class}::${method} { return( shift->$handler( '$method', \@_ ) ); }" );
        return( $self->error( "Failed to create method $method in $class: $@" ) ) if( $@ );
        # die( $@ ) if( $@ );
        return( $self->$method( @args ) );
    }
};

# Avoid being called by AUTOLOAD
sub DESTROY
{
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    my $self = CORE::shift( @_ );
    CORE::return if( !CORE::defined( $self ) );
};

1;

__END__
