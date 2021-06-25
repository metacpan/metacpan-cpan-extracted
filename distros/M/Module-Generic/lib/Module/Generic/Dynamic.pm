##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Dynamic.pm
## Version v1.0.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/04/18
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
    use Scalar::Util ();
    # use Class::ISA;
    our( $VERSION ) = 'v1.0.1';
};

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $self = bless( {} => $class );
    my $data = $self->{_data} = {};
    ## A Module::Generic object standard parameter
    $self->{_data_repo} = '_data';
    my $hash = {};
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( scalar( @_ ) == 1 && Scalar::Util::reftype( $_[0] ) eq 'HASH' )
    {
        $hash = shift( @_ );
    }
    elsif( @_ )
    {
        CORE::warn( "Parameter provided is not an hash reference: '", join( "', '", @_ ), "'\n" ) if( $this->_warnings_is_enabled );
    }
    ## $self->message( 3, "Data provided are: ", sub{ $self->dumper( $hash ) } );
    ## print( STDERR __PACKAGE__, "::new(): Got for hash: '", join( "', '", sort( keys( %$hash ) ) ), "'\n" );
    local $make_class = sub
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
        ## print( STDERR __PACKAGE__, "::new(): \$clean_field now is '$clean_field'\n" );
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
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
        my $rc = eval( $perl );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
        die( "Unable to dynamically create module $new_class: $@" ) if( $@ );
        return( $new_class, $clean_field );
    };
    
    foreach my $k ( sort( keys( %$hash ) ) )
    {
        if( ref( $hash->{ $k } ) eq 'HASH' )
        {
            my $clean_field = $k;
            $clean_field =~ tr/-/_/;
            $clean_field =~ s/\_{2,}/_/g;
            $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
            $clean_field =~ s/^\d+//g;
            next unless( length( $clean_field ) );
#             my( $new_class, $clean_field ) = $make_class->( $k );
            # print( STDERR __PACKAGE__, "::new(): Is hash looping? ", ( $hash->{ $k }->{_looping} ? 'yes' : 'no' ), " (", ref( $hash->{ $k }->{_looping} ), ")\n" );
#             my $o = $hash->{ $k }->{_looping} ? $hash->{ $k }->{_looping} : $new_class->new( $hash->{ $k } );
#             $data->{ $clean_field } = $o;
#             $hash->{ $k }->{_looping} = $o;
            eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object( $clean_field, '$new_class', \@_ ) ); }" );
            die( $@ ) if( $@ );
            $self->$clean_field( $hash->{ $k } );
        }
        elsif( ref( $hash->{ $k } ) eq 'ARRAY' )
        {
            my( $new_class, $clean_field ) = $make_class->( $k );
            # print( STDERR __PACKAGE__, "::new() found an array for key $k, creating objects for class $new_class\n" );
            ## We take a peek at what we have to determine how we will handle the data
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
                # $data->{ $clean_field } = $all;
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object_array_object( '$clean_field', '$new_class', \@_ ) ); }" );
            }
            else
            {
                # $data->{ $clean_field } = $hash->{ $k };
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_array_as_object( '$clean_field', \@_ ) ); }" );
            }
            die( $@ ) if( $@ );
            $self->$clean_field( $hash->{ $k } );
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
            eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_scalar_as_object( '$clean_field', \@_ ) ); }" );
            $self->$clean_field( $hash->{ $k } );
        }
        else
        {
            $self->$k( $hash->{ $k } );
        }
    }
    return( $self );
}

sub TO_JSON
{
    my $self = shift( @_ );
    my $ref  = { %$self };
    CORE::delete( $ref->{_data} );
    CORE::delete( $ref->{_data_repo} );
    return( $ref );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $code;
    # print( STDERR __PACKAGE__, "::$method(): Called\n" );
    if( $code = $self->can( $method ) )
    {
        return( $code->( @_ ) );
    }
    ## elsif( CORE::exists( $self->{ $method } ) )
    else
    {
        my $ref = lc( ref( $_[0] ) );
        my $handler = '_set_get_scalar_as_object';
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
        eval( "sub ${class}::${method} { return( shift->$handler( '$method', \@_ ) ); }" );
        die( $@ ) if( $@ );
        ## $self->message( 3, "Calling method '$method' with data: ", sub{ $self->printer( @_ ) } );
        return( $self->$method( @_ ) );
    }
};

1;

__END__
