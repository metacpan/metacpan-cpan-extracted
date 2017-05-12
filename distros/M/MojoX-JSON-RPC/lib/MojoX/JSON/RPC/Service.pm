package MojoX::JSON::RPC::Service;

use Mojo::Base -base;

{

    # Store rpc methods registered by register_rpc_method_names
    my $_rpcs = undef;

    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new(@_);

        # make shallow copy of class level rpcs
        if ( ref $_rpcs eq 'HASH' && exists $_rpcs->{$class} ) {
            $self->{_rpcs} = { %{ $_rpcs->{$class} } };
        }
        return $self;
    }

    sub register_rpc_method_names {
        my ( $class, @methods ) = @_;

    METHOD:
        foreach my $m (@methods) {
            my $name   = $class . '::' . $m;
            my $method = eval qq|*{*$name}{CODE}|;

            if ( ref $method ne 'CODE' ) {
                Carp::croak
                    qq{register_rpc_method_names: $name not a method.};
            }
            if ( exists $_rpcs->{$class}->{$m} ) {
                Carp::croak
                    qq{register_rpc_method_names: $name already registered.};
            }
            $_rpcs->{$class}->{$m} = { method => $method, with_svc_obj => 1 };
        }

        return $class;
    }
}

sub register {
    my ( $self, $name, $sub, $options ) = @_;

    if ( !defined $name || $name eq q{} ) {
        Carp::croak 'name?';
    }
    if ( ref $sub ne 'CODE' ) {
        Carp::croak qq{name[$name] code?};
    }
    if ( exists $self->{_rpcs}->{$name} ) {
        Carp::croak qq{$name already registered};
    }

    $options ||= {};
    if ( ref $options ne 'HASH' ) {
        Carp::croak 'options?';
    }

    my %obj = ( method => $sub );
OPTION:
    foreach my $opt ( 'with_mojo_tx', 'with_svc_obj', 'with_self' ) {
        if ( !exists $options->{$opt} ) {
            next OPTION;
        }
        $obj{$opt} = $options->{$opt};
    }

    $self->{_rpcs}->{$name} = \%obj;
    return $self;
}

1;

__END__

=head1 NAME

MojoX::JSON::RPC::Service - JSON RPC Service registration

=head1 SYNOPSIS

    use MojoX::JSON::RPC::Service;

    my $svc  = MojoX::JSON::RPC::Service->new;

    $svc->register(
        'sum',
        sub {
            my @params = @_;
            my $sum    = 0;
            $sum += $_ for @params;
            return $sum;
        }
    );

    $svc->register(
        'remote_address',
        sub {
            my $tx = shift;
            return $tx->remote_address;
        },
        {
             with_mojo_tx => 1
        }
    );


    ## Then in Mojolicious application
    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/jsonrpc'  => $svc,
        }
    );

This package can also be used as a base class to make it easy to create object-oriented
JSON-RPC applications:

    package MyService;

    use Mojo::Base 'MojoX::JSON::RPC::Service';

    sub sum {
        my ($self, @params) = @_;
        my $sum    = 0;
        $sum += $_ for @params;
        return $sum;
    }

    __PACKAGE__->register_rpc_method_names( 'sum' );

    ## Then in Mojolicious application
    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/jsonrpc'  => MyService->new,
        }
    );

=head1 DESCRIPTION

Register JSON-RPC service calls.

=head1 METHODS

L<MojoX::JSON::RPC::Service> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<register>

Register RPC methods.

    $svc->register(
        'sum',
        sub {
            my @params = @_;
            my $sum    = 0;
            $sum += $_ for @params;
            return $sum;
       }
    );

with_mojo_tx can be passed as options. In that case, L<Mojo::Transaction>
object will be pass as first argument of the subroutine.

    $svc->register(
        'remote_address',
        sub {
            my $tx = shift;
            return $tx->remote_address;
        },
        {
             with_mojo_tx => 1
        }
    );

=head2 C<register_rpc_method_names>

Class method. Register a list of methods as JSON-RPC calls.

    __PACKAGE__->register_rpc_method_names( 'sum', 'multiply' );

=head1 SEE ALSO

L<MojoX::JSON::RPC::Dispatcher>

=cut
