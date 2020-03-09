package Pcore::API::Docker::Registry;

use Pcore -class, -const, -res;

has _token => ( init_arg => undef );

const our $BASE_URL => 'https://hub.docker.com/v2';

# https://docs.docker.com/registry/spec/api/

# https://docs.docker.com/registry/spec/auth/token/
sub _authenticate ($self) {
    my $res = P->http->get(
        "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$self->{repo_id}:delete,pull,push",
        headers => [    #
            Authorization => 'Basic ' . P->data->to_b64( "$self->{username}:$self->{token}", $EMPTY )
        ],
    );

    my $data = $res->{data} ? P->data->from_json( $res->{data} ) : undef;

    if ($res) {
        $self->{_token} = $data->{token};

        return res 200;
    }
    else {
        return res [ $res->{status}, $data->{message} // $data->{detail} ];
    }

    return;
}

# https://docs.docker.com/registry/spec/api/#tags
sub get_tags ( $self ) {
    my $res = P->http->get(
        "https://registry-1.docker.io/v2/$self->{repo_id}/tags/list",
        headers => [    #
            Authorization => "Bearer $self->{_token}",
        ],
    );

    my $data = $res->{data} ? P->data->from_json( $res->{data} ) : undef;

    if ($res) {
        return res 200, $data;
    }
    else {
        return res [ $res->{status}, $data->{errors}->[0]->{message} ];
    }
}

# https://docs.docker.com/registry/spec/api/#manifest
sub get_manifest ( $self, $tag ) {
    my $res = P->http->get(
        "https://registry-1.docker.io/v2/$self->{repo_id}/manifests/$tag",
        headers => [    #
            Authorization => "Bearer $self->{_token}",
            Accept        => 'application/vnd.docker.distribution.manifest.v2+json',
        ],
    );

    my $data = $res->{data} ? P->data->from_json( $res->{data} ) : undef;

    if ($res) {
        $data->{digest} = $res->{headers}->{'docker-content-digest'};

        return res 200, $data;
    }
    else {
        return res [ $res->{status}, $data->{errors}->[0]->{message} ];
    }
}

# NOTE disabled for dockerhub registry
# https://docs.docker.com/registry/spec/api/#deleting-an-image
sub delete_image ( $self, $digest ) {
    my $res = P->http->delete(
        "https://registry-1.docker.io/v2/$self->{repo_id}/manifests/$digest",
        headers => [    #
            Authorization => "Bearer $self->{_token}",
        ],
    );

    my $data = $res->{data} ? P->data->from_json( $res->{data} ) : undef;

    if ($res) {
        return res 200, $data;
    }
    else {
        return res [ $res->{status}, $data->{errors}->[0]->{message} ];
    }
}

# https://docs.docker.com/registry/spec/api/#catalog
# NOTE disabled for dockerhub registry
# TODO need to authenticate for scope "registry:catalog:*"
sub catalog ( $self ) {
    my $res = P->http->get(
        "https://registry-1.docker.io/v2/_catalog",
        headers => [    #
            Authorization => "Bearer $self->{_token}",
        ],
    );

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 12                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_authenticate' declared but not     |
## |      |                      | used                                                                                                           |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 100                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Docker::Registry

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
