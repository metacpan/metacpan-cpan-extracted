package Pcore::App::API::Auth;

use Pcore -class, -result;
use Pcore::App::API qw[:CONST];
use Pcore::App::API::Auth::Request;
use Pcore::Util::Scalar qw[blessed];

use overload    #
  q[bool] => sub {
    return $_[0]->{id} && $_[0]->{app}->{api}->{auth_cache}->{auth}->{ $_[0]->{id} };
  },
  fallback => undef;

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has id            => ( is => 'ro', isa => Maybe [Str] );
has private_token => ( is => 'ro', isa => Maybe [ArrayRef] );    # [ $token_type, $token_id, $token_hash ]

has is_user   => ( is => 'ro', isa => Bool );
has is_root   => ( is => 'ro', isa => Bool );
has user_id   => ( is => 'ro', isa => Maybe [Str] );
has user_name => ( is => 'ro', isa => Maybe [Str] );

has is_app          => ( is => 'ro', isa => Bool );
has app_id          => ( is => 'ro', isa => Maybe [Str] );
has app_instance_id => ( is => 'ro', isa => Maybe [Str] );

has permissions => ( is => 'ro', isa => Maybe [HashRef] );

sub TO_DATA ($self) {
    die q[Direct auth object serialization is impossible for security reasons];
}

sub api_can_call ( $self, $method_id, $cb ) {
    my $auth_cache = $self->{app}->{api}->{auth_cache};

    state $check_permissions = sub ( $auth, $method_id, $cb ) {

        # find method
        my $method_cfg = $auth->{app}->{api}->{map}->{method}->{$method_id};

        # method wasn't found
        if ( !$method_cfg ) {
            $cb->( result [ 404, qq[Method "$method_id" was not found] ] );
        }

        # method was found
        else {

            # user is root, method authentication is not required
            if ( $auth->{is_root} ) {
                $cb->( result 200 );
            }

            # method has no permissions, authorization is not required
            elsif ( !$method_cfg->{permissions} ) {
                $cb->( result 200 );
            }

            # auth has no permisisons, api call is forbidden
            elsif ( !$auth->{permissions} ) {
                $cb->( result [ 403, qq[Insufficient permissions for method "$method_id"] ] );
            }

            # compare permissions
            else {
                for my $role_name ( $method_cfg->{permissions}->@* ) {
                    if ( exists $auth->{permissions}->{$role_name} ) {
                        $cb->( result 200 );

                        return;
                    }
                }

                $cb->( result [ 403, qq[Insufficient permissions for method "$method_id"] ] );
            }
        }

        return;
    };

    # token is not authenticated
    if ( !$self->{private_token} ) {
        $check_permissions->( $self, $method_id, $cb );
    }

    # token is authenticated
    else {

        # get auth_id from cache
        my $auth_id = $auth_cache->{private_token}->{ $self->{private_token}->[2] };

        # token is authenticated
        if ( $auth_id && $auth_cache->{auth}->{$auth_id} ) {
            $check_permissions->( $self, $method_id, $cb );
        }

        # token was invalidated
        else {

            # re-authenticate token
            $self->{app}->{api}->authenticate_private(
                $self->{private_token},
                sub ($auth) {
                    $check_permissions->( $auth, $method_id, $cb );

                    return;
                }
            );
        }
    }

    return;
}

sub api_call ( $self, $method_id, @ ) {
    my ( $cb, $args );

    # parse $args and $cb
    if ( ref $_[-1] eq 'CODE' or ( blessed $_[-1] && $_[-1]->can('IS_CALLBACK') ) ) {
        $cb = $_[-1];

        $args = [ @_[ 2 .. $#_ - 1 ] ] if @_ > 3;
    }
    else {
        $args = [ @_[ 2 .. $#_ ] ] if @_ > 2;
    }

    return $self->api_call_arrayref( $method_id, $args, $cb );
}

sub api_call_arrayref ( $self, $method_id, $args, $cb = undef ) {
    $self->api_can_call(
        $method_id,
        sub ($can_call) {
            if ( !$can_call ) {
                $cb->($can_call) if $cb;
            }
            else {
                my $map = $self->{app}->{api}->{map};

                # get method
                my $method_cfg = $map->{method}->{$method_id};

                my $obj = $map->{obj}->{ $method_cfg->{class_name} };

                my $method_name = $method_cfg->{local_method_name};

                # create API request
                my $req = bless {
                    auth => $self,
                    _cb  => $cb,
                  },
                  'Pcore::App::API::Auth::Request';

                # call method
                eval { $obj->$method_name( $req, $args ? $args->@* : () ) };

                $@->sendlog if $@;
            }

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 157                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Auth

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
