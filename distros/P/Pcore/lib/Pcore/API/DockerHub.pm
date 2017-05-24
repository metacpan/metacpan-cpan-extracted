package Pcore::API::DockerHub;

use Pcore -const, -class, -result, -export => { CONST => [qw[$DOCKERHUB_PROVIDER_BITBUCKET $DOCKERHUB_PROVIDER_GITHUB $DOCKERHUB_SOURCE_TAG $DOCKERHUB_SOURCE_BRANCH]] };
require Pcore::API::DockerHub::Repository;

# https://github.com/RyanTheAllmighty/Docker-Hub-API

has api_username => ( is => 'ro', isa => Str, required => 1 );
has api_password => ( is => 'ro', isa => Str, required => 1 );
has namespace => ( is => 'lazy', isa => Str );

has login_token => ( is => 'ro', isa => Str, init_arg => undef );

const our $API_VERSION => 2;
const our $URL         => "https://hub.docker.com/v$API_VERSION";

const our $DOCKERHUB_PROVIDER_BITBUCKET => 1;
const our $DOCKERHUB_PROVIDER_GITHUB    => 2;

const our $DOCKERHUB_SOURCE_TAG    => 1;
const our $DOCKERHUB_SOURCE_BRANCH => 2;

const our $DOCKERHUB_PROVIDER_NAME => {
    $DOCKERHUB_PROVIDER_BITBUCKET => 'bitbucket',
    $DOCKERHUB_PROVIDER_GITHUB    => 'github',
};

const our $DOCKERHUB_SOURCE_NAME => {
    $DOCKERHUB_SOURCE_TAG    => 'Tag',
    $DOCKERHUB_SOURCE_BRANCH => 'Branch',
};

sub BUILDARGS ( $self, $args = undef ) {
    $args->{api_username} ||= $ENV->user_cfg->{DOCKERHUB}->{username} if $ENV->user_cfg->{DOCKERHUB}->{username};

    $args->{api_password} ||= $ENV->user_cfg->{DOCKERHUB}->{password} if $ENV->user_cfg->{DOCKERHUB}->{password};

    $args->{namespace} ||= $ENV->user_cfg->{DOCKERHUB}->{namespace} if $ENV->user_cfg->{DOCKERHUB}->{namespace};

    return $args;
}

sub _build_namespace ($self) {
    return $self->api_username;
}

sub login ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->request(
        'post',
        '/users/login/',
        undef,
        { username => $self->api_username, password => $self->api_password },
        sub ($res) {
            if ( $res->{data}->{detail} ) {
                $res->{reason} = delete $res->{data}->{detail};
            }

            if ( $res->is_success && $res->{data}->{token} ) {
                $self->{login_token} = delete $res->{data}->{token};
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub get_user ( $self, % ) {
    my %args = (
        username => $self->api_username,
        cb       => undef,
        splice @_, 1,
    );

    return $self->request( 'get', "/users/$args{username}/", undef, undef, $args{cb} );
}

sub get_registry_settings ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->request( 'get', "/users/@{[$self->api_username]}/registry-settings/", 1, undef, $args{cb} );
}

# GET REPOS
sub get_all_repos ( $self, % ) {
    my %args = (
        namespace => $self->namespace,
        cb        => undef,
        splice @_, 1,
    );

    return $self->request(
        'get',
        "/users/$args{namespace}/repositories/",
        1, undef,
        sub ($res) {
            if ( $res->is_success ) {
                my $result = {};

                for my $repo ( $res->{data}->@* ) {
                    $repo = bless $repo, 'Pcore::API::DockerHub::Repository';

                    $repo->set_status( $res->status );

                    $repo->{api} = $self;

                    $result->{ $repo->id } = $repo;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub get_repos ( $self, % ) {
    my %args = (
        page      => 1,
        page_size => 100,
        namespace => $self->namespace,
        cb        => undef,
        splice @_, 1,
    );

    return $self->request(
        'get',
        "/repositories/$args{namespace}/?page_size=$args{page_size}&page=$args{page}",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = {};

                for my $repo ( $res->{data}->{results}->@* ) {
                    $repo = bless $repo, 'Pcore::API::DockerHub::Repository';

                    $repo->set_status( $res->status );

                    $repo->{api} = $self;

                    $result->{ $repo->id } = $repo;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub get_starred_repos ( $self, % ) {
    my %args = (
        page      => 1,
        page_size => 100,
        namespace => $self->namespace,
        cb        => undef,
        splice @_, 1,
    );

    return $self->request(
        'get',
        "/users/$args{namespace}/repositories/starred/?page_size=$args{page_size}&page=$args{page}",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = {};

                for my $repo ( $res->{data}->{results}->@* ) {
                    $repo = bless $repo, 'Pcore::API::DockerHub::Repository';

                    $repo->set_status( $res->status );

                    $repo->{api} = $self;

                    $result->{ $repo->id } = $repo;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub get_repo ( $self, $repo_name, % ) {
    my %args = (
        namespace => $self->namespace,
        cb        => undef,
        splice @_, 2,
    );

    return $self->request(
        'get',
        "/repositories/$args{namespace}/$repo_name/",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                my $repo = bless $res->{data}, 'Pcore::API::DockerHub::Repository';

                $repo->set_status( $res->status, $res->reason );

                $repo->{api} = $self;

                $_[0] = $repo;

                $res = $repo;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# CREATE REPO / AUTOMATED BUILD
sub create_repo ( $self, $repo_name, % ) {
    my %args = (
        namespace => $self->namespace,
        private   => 0,
        desc      => q[],
        full_desc => q[],
        cb        => undef,
        splice @_, 2,
    );

    return $self->request(
        'post',
        '/repositories/',
        1,
        {   name             => $repo_name,
            namespace        => $args{namespace},
            is_private       => $args{private},
            description      => $args{desc},
            full_description => $args{full_desc},
        },
        sub ($res) {
            if ( $res->is_success ) {
                my $repo = bless $res->{data}, 'Pcore::API::DockerHub::Repository';

                $repo->set_status( $res->status, $res->reason );

                $repo->{api} = $self;

                $_[0] = $repo;

                $res = $repo;
            }
            else {
                if ( $res->{data}->{__all__} ) {
                    $res->{reason} = $res->{data}->{__all__}->[0] if $res->{data}->{__all__}->[0];
                }
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub create_automated_build ( $self, $repo_name, $provider, $vcs_repo_name, $desc, % ) {
    my %args = (
        namespace  => $self->namespace,
        private    => 0,
        active     => 1,
        build_tags => undef,
        cb         => undef,
        splice( @_, 5 ),
    );

    my $build_tags;

    # prepare build tags
    if ( !$args{build_tags} ) {
        $build_tags = [
            {   name                => '{sourceref}',                                      # docker build tag name
                source_type         => $DOCKERHUB_SOURCE_NAME->{$DOCKERHUB_SOURCE_TAG},    # Branch, Tag
                source_name         => '/.*/',                                             # barnch / tag name in the source repository
                dockerfile_location => q[/],
            },
        ];
    }
    else {
        for ( $args{build_tags}->@* ) {
            my %build_tags = $_->%*;

            $build_tags{source_type} = $DOCKERHUB_SOURCE_NAME->{ $build_tags{source_type} };

            push $build_tags->@*, \%build_tags;
        }
    }

    return $self->request(
        'post',
        "/repositories/$args{namespace}/$repo_name/autobuild/",
        1,
        {   name                => $repo_name,
            namespace           => $args{namespace},
            is_private          => $args{private},
            active              => $args{active} ? $TRUE : $FALSE,
            dockerhub_repo_name => "$args{namespace}/$repo_name",
            provider            => $DOCKERHUB_PROVIDER_NAME->{$provider},
            vcs_repo_name       => $vcs_repo_name,
            description         => $desc,
            build_tags          => $build_tags,
        },
        sub ($res) {
            if ( $res->is_success ) {
                my $repo = bless $res->{data}, 'Pcore::API::DockerHub::Repository';

                $repo->set_status( $res->status, $res->reason );

                $repo->{api} = $self;

                $_[0] = $repo;

                $res = $repo;
            }
            else {
                if ( $res->{data}->{detail} ) {
                    $res->{reason} = $res->{data}->{detail};
                }
                elsif ( $res->{data}->{__all__} ) {
                    $res->{reason} = $res->{data}->{__all__}->[0] if $res->{data}->{__all__}->[0];
                }
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# PRIVATE METHODS
sub request ( $self, $type, $path, $auth, $data, $cb ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my $request = sub {
        P->http->$type(
            $URL . $path,
            headers => {
                CONTENT_TYPE => 'application/json',
                $auth ? ( AUTHORIZATION => 'JWT ' . $self->{login_token} ) : (),
            },
            body => $data ? P->data->to_json($data) : undef,
            on_finish => sub ($res) {
                my $api_res = result [ $res->status, $res->reason ], $res->body && $res->body->$* ? P->data->from_json( $res->body ) : ();

                $cb->($api_res) if $cb;

                $blocking_cv->send($api_res) if $blocking_cv;

                return;
            }
        );
    };

    if ( !$auth ) {
        $request->();
    }
    elsif ( $self->{login_token} ) {
        $request->();
    }
    else {
        $self->login(
            cb => sub ($res) {
                if ( $res->is_success ) {
                    $request->();
                }
                else {
                    $cb->($res) if $cb;

                    $blocking_cv->send($res) if $blocking_cv;
                }

                return;
            }
        );
    }

    return $blocking_cv ? $blocking_cv->recv : ();
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 292, 367             | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::DockerHub

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
