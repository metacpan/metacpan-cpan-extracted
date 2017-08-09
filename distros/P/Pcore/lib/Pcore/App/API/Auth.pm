package Pcore::App::API::Auth;

use Pcore -class, -result;
use Pcore::App::API qw[:CONST];
use Pcore::App::API::Auth::Request;
use Pcore::Util::Scalar qw[is_blessed_ref is_plain_coderef];

use overload    #
  q[bool] => sub {
    return $_[0]->{is_authenticated};
  },
  fallback => undef;

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );
has is_authenticated => ( is => 'ro', isa => Bool, required => 1 );

has private_token => ( is => 'ro', isa => Maybe [ArrayRef] );    # [ $token_type, $token_id, $token_hash ]

has is_user   => ( is => 'ro', isa => Bool );
has is_root   => ( is => 'ro', isa => Bool );
has user_id   => ( is => 'ro', isa => Maybe [Str] );
has user_name => ( is => 'ro', isa => Maybe [Str] );

has is_app          => ( is => 'ro', isa => Bool );
has app_id          => ( is => 'ro', isa => Maybe [Str] );
has app_instance_id => ( is => 'ro', isa => Maybe [Str] );

has permissions => ( is => 'ro', isa => Maybe [HashRef] );
has depends_on  => ( is => 'ro', isa => Maybe [ArrayRef] );

sub TO_DATA ($self) {
    die q[Direct auth object serialization is impossible for security reasons];
}

sub api_can_call ( $self, $method_id, $cb ) {
    if ( $self->{is_authenticated} ) {
        $self->{app}->{api}->authenticate_private(
            $self->{private_token},
            sub ($auth) {
                $auth->_check_permissions( $method_id, $cb );

                return;
            }
        );
    }
    else {
        $self->_check_permissions( $method_id, $cb );
    }

    return;
}

sub _check_permissions ( $self, $method_id, $cb ) {

    # find method
    my $method_cfg = $self->{app}->{api}->{map}->{method}->{$method_id};

    # method wasn't found
    if ( !$method_cfg ) {
        $cb->( result [ 404, qq[Method "$method_id" was not found] ] );
    }

    # method was found
    else {

        # user is root, method authentication is not required
        if ( $self->{is_root} ) {
            $cb->( result 200 );
        }

        # method has no permissions, authorization is not required
        elsif ( !$method_cfg->{permissions} ) {
            $cb->( result 200 );
        }

        # auth has no permisisons, api call is forbidden
        elsif ( !$self->{permissions} ) {
            $cb->( result [ 403, qq[Insufficient permissions for method "$method_id"] ] );
        }

        # compare permissions
        else {
            for my $role_name ( $method_cfg->{permissions}->@* ) {
                if ( exists $self->{permissions}->{$role_name} ) {
                    $cb->( result 200 );

                    return;
                }
            }

            $cb->( result [ 403, qq[Insufficient permissions for method "$method_id"] ] );
        }
    }

    return;
}

sub api_call ( $self, $method_id, @ ) {
    my ( $cb, $args );

    # parse $args and $cb
    if ( is_plain_coderef $_[-1] || ( is_blessed_ref $_[-1] && $_[-1]->can('IS_CALLBACK') ) ) {
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
                if ( !eval { $obj->$method_name( $req, $args ? $args->@* : () ); 1 } ) {
                    $@->sendlog if $@;
                }
            }

            return;
        }
    );

    return;
}

1;
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
