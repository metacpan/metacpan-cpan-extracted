package Pcore::App::Auth::Descriptor;

use Pcore -class, -res;
use Pcore::App::Auth qw[:TOKEN_TYPE :PRIVATE_TOKEN];
use Pcore::App::API::Request;
use Pcore::Util::Scalar qw[is_callback is_plain_coderef];

use overload    #
  q[bool] => sub {
    return $_[0]->{is_authenticated};
  },
  fallback => undef;

has app              => ( required => 1 );    # ConsumerOf ['Pcore::App']
has is_authenticated => ( required => 1 );    # Bool
has private_token => ();                      # Maybe [ArrayRef], [ $token_type, $token_id, $token_hash ]
has user_id       => ();                      # Maybe [Str]
has user_name     => ();                      # Maybe [Str]
has permissions   => ();                      # Maybe [HashRef]

*TO_JSON = *TO_CBOR = sub ($self) {
    return { $self->%{qw[is_authenticated user_id user_name permissions]} };
};

sub TO_DUMP ( $self, $dumper, @ ) {
    my %args = (
        path => undef,
        splice @_, 2,
    );

    my $tags;

    my $res;

    my %attrs = $self->%*;

    delete $attrs{app};

    $res .= $dumper->_dump( \%attrs, path => $args{path} );

    return $res, $tags;
}

sub api_can_call ( $self, $method_id ) {
    if ( $self->{is_authenticated} ) {
        my $auth = $self->{app}->{auth}->authenticate_private( $self->{private_token} );

        return $auth->_check_permissions($method_id);
    }
    else {
        return $self->_check_permissions($method_id);
    }
}

sub _check_permissions ( $self, $method_id ) {

    # find method
    my $method_cfg = $self->{app}->{api}->{method}->{$method_id};

    # method wasn't found
    if ( !$method_cfg ) {
        return res [ 404, qq[Method "$method_id" was not found] ];
    }

    # method was found
    else {

        # method has no permissions, authorization is not required
        return res 200 if !$method_cfg->{permissions};

        my $auth_permissions = $self->{permissions};

        # auth has no permisisons, api call is forbidden
        return res [ 403, qq[Insufficient permissions for method "$method_id"] ] if !$auth_permissions;

        # compare permissions
        for my $permission ( $method_cfg->{permissions}->@* ) {
            return res 200 if $auth_permissions->{$permission};
        }

        return res [ 403, qq[Insufficient permissions for method "$method_id"] ];
    }
}

sub api_call ( $self, $method_id, @ ) {
    my ( $cb, $args );

    # parse $args and $cb
    if ( is_callback $_[-1] ) {
        $cb = $_[-1];

        $args = [ @_[ 2 .. $#_ - 1 ] ] if @_ > 3;
    }
    else {
        $args = [ @_[ 2 .. $#_ ] ] if @_ > 2;
    }

    return $self->api_call_arrayref( $method_id, $args, $cb );
}

sub api_call_arrayref ( $self, $method_id, $args, $cb = undef ) {
    my $can_call = $self->api_can_call($method_id);

    if ( !$can_call ) {
        $cb->($can_call) if defined $cb;

        return $can_call;
    }
    else {
        my $api = $self->{app}->{api};

        # get method
        my $method_cfg = $api->{method}->{$method_id};

        my $obj = $api->{obj}->{ $method_cfg->{class_name} };

        my $method_name = $method_cfg->{local_method_name};

        if ( defined wantarray ) {
            my $cv = P->cv;

            # destroy req instance after call
            {
                # create API request
                my $req = bless {
                    auth => $self,
                    _cb  => $cv,
                  },
                  'Pcore::App::API::Request';

                # call method
                if ( !eval { $obj->$method_name( $req, $args ? $args->@* : () ); 1 } ) {
                    $@->sendlog if $@;
                }
            }

            my $res = $cv->recv;

            return $cb ? $cb->($res) : $res;
        }
        else {

            # create API request
            my $req = bless {
                auth => $self,
                _cb  => $cb,
              },
              'Pcore::App::API::Request';

            # call method
            if ( !eval { $obj->$method_name( $req, $args ? $args->@* : () ); 1 } ) {
                $@->sendlog if $@;
            }

            return;
        }
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Auth::Descriptor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
