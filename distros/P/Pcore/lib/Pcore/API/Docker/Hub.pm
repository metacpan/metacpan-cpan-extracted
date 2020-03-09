package Pcore::API::Docker::Hub;

use Pcore -const, -class, -res, -export;

our $EXPORT = { DOCKERHUB_SOURCE_TYPE => [qw[$DOCKERHUB_SOURCE_TYPE_TAG $DOCKERHUB_SOURCE_TYPE_BRANCH]] };

has username => ( required => 1 );
has token    => ( required => 1 );

has _login_token   => ( init_arg => undef );
has _login_threads => ( init_arg => undef );
has _login_queue   => ( init_arg => undef );

const our $API_VER  => 'v2';
const our $BASE_URL => "https://hub.docker.com/$API_VER";

const our $DOCKERHUB_SOURCE_TYPE_TAG    => 'tag';
const our $DOCKERHUB_SOURCE_TYPE_BRANCH => 'branch';

const our $DOCKERHUB_SOURCE_TYPE_NAME => {
    $DOCKERHUB_SOURCE_TYPE_TAG    => 'Tag',
    $DOCKERHUB_SOURCE_TYPE_BRANCH => 'Branch',
};

const our $DEF_PAGE_SIZE => 250;

const our $BUILD_STATUS_TEXT => {
    -4 => 'cancelled',
    -2 => 'error',
    -1 => 'error',
    0  => 'queued',
    1  => 'queued',
    2  => 'building',
    3  => 'building',
    10 => 'success',
    11 => 'queued',
};

sub BUILDARGS ( $self, $args = undef ) {
    $args->{username} ||= $ENV->user_cfg->{DOCKER}->{registry}->{''}->{username};

    $args->{token} ||= $ENV->user_cfg->{DOCKER}->{registry}->{''}->{token};

    return $args;
}

sub _login ( $self ) {
    state $endpoint = '/users/login/';

    if ( $self->{_login_threads} ) {
        my $cv = P->cv;

        push $self->{_login_queue}->@*, $cv;

        return $cv->recv;
    }

    $self->{_login_threads} = 1;

    undef $self->{_login_token};

    my $res = $self->_req_no_auth(
        'POST',
        $endpoint,
        {   username => $self->{username},
            password => $self->{token},
        }
    );

    $self->{_login_threads} = 0;

    if ( !$res ) {
        $res = res [ $res->{status}, $res->{data}->{detail} ];
    }
    elsif ( $self->{_login_token} = $res->{data}->{token} ) {
        $res = res 200;
    }

    while ( my $cb = shift $self->{_login_queue}->@* ) {
        $cb->( res $res );
    }

    return $res;
}

sub _req ( $self, $method, $endpoint, $data = undef ) {
    if ( !$self->{_login_token} ) {
        my $res = $self->_login;

        # login ok
        return $res if !$res;
    }

    return $self->_req_no_auth( $method, $endpoint, $data );
}

sub _req_no_auth ( $self, $method, $endpoint, $data = undef ) {
    my $res = P->http->request(
        method  => $method,
        url     => $BASE_URL . $endpoint,
        headers => [
            'Content-Type' => 'application/json',
            $self->{_login_token} ? ( Authorization => 'JWT ' . $self->{_login_token} ) : (),
        ],
        data => $data ? P->data->to_json($data) : undef
    );

    return res [ $res->{status}, $res->{reason} ], $res->{data} && $res->{data}->$* ? P->data->from_json( $res->{data} ) : ();
}

# USER / NAMESPACE
sub get_user ( $self, $username ) {
    return $self->_req_no_auth( 'GET', "/users/$username/" );
}

sub get_user_registry_settings ( $self, $username ) {
    return $self->_req( 'GET', "/users/$username/registry-settings/" );
}

sub get_user_orgs ( $self ) {
    my $res = $self->_req( 'GET', "/user/orgs/?page_size=$DEF_PAGE_SIZE&page=1" );

    if ($res) {
        my $data;

        for my $org ( $res->{data}->{results}->@* ) {
            $data->{ $org->{orgname} } = $org;
        }

        $res->{data} = $data;
    }

    return $res;
}

# CREATE REPO / AUTOMATED BUILD
sub create_repo ( $self, $repo_id, %args ) {
    %args = (
        private   => 0,
        desc      => $EMPTY,
        full_desc => $EMPTY,
        %args
    );

    my ( $namespace, $name ) = split m[/]sm, $repo_id;

    return $self->_req(
        'POST',
        '/repositories/',
        {   namespace        => $namespace,
            name             => $name,
            is_private       => $args{private},
            description      => $args{desc},
            full_description => $args{full_desc},
        }
    );
}

# TODO not work
sub create_autobuild ( $self, $repo_id, $git_repo_id, $desc, %args ) {
    %args = (
        desc       => undef,
        private    => 0,
        active     => 1,
        build_tags => undef,
        %args,
    );

    my ( $namespace, $name ) = split m[/]sm, $repo_id;

    my $build_tags;

    # prepare build tags
    if ( !$args{build_tags} ) {
        $build_tags = [
            {   name                => '{sourceref}',                                                # docker build tag name
                source_type         => $DOCKERHUB_SOURCE_TYPE_NAME->{$DOCKERHUB_SOURCE_TYPE_TAG},    # Branch, Tag
                source_name         => '/.*/',                                                       # barnch / tag name in the source repository
                dockerfile_location => '/',
            },
        ];
    }
    else {
        for ( $args{build_tags}->@* ) {
            my %build_tags = $_->%*;

            $build_tags{source_type} = $DOCKERHUB_SOURCE_TYPE_NAME->{ lc $build_tags{source_type} };

            push $build_tags->@*, \%build_tags;
        }
    }

    return $self->_req(
        'POST',
        "/repositories/$repo_id/autobuild/",
        {   namespace           => $namespace,
            name                => $name,
            description         => $desc,
            is_private          => $args{private} ? \1 : \0,
            active              => $args{active} ? \1 : \0,
            dockerhub_repo_name => $repo_id,
            provider            => 'git',
            vcs_repo_name       => $git_repo_id,
            description         => $desc,
            build_tags          => $build_tags,
        }
    );
}

# REPO
sub get_all_repos ( $self, $namespace ) {
    my $res = $self->_req( 'GET', "/users/$namespace/repositories/" );

    if ($res) {
        my $data;

        for my $repo ( $res->{data}->@* ) {
            $repo->{id} = "$repo->{namespace}/$repo->{name}";

            $data->{ $repo->{id} } = $repo;
        }

        $res->{data} = $data;
    }

    return $res;
}

sub get_repo ( $self, $repo_id ) {
    my $res = $self->_req( 'GET', "/repositories/$repo_id/" );

    if ($res) {
        $res->{data}->{id} = $repo_id;
    }

    return $res;
}

sub remove_repo ( $self, $repo_id ) {
    return $self->_req( 'DELETE', "/repositories/$repo_id/" );
}

# REPO TAGS
# TODO gel all pages
sub get_tags ( $self, $repo_id ) {
    my $res = $self->_req( 'GET', "/repositories/$repo_id/tags/?page_size=$DEF_PAGE_SIZE&page=1" );

    if ($res) {
        my $data;

        for my $tag ( $res->{data}->{results}->@* ) {
            $data->{ $tag->{id} } = $tag;
        }

        $res->{data} = $data;
    }

    return $res;
}

sub delete_tag ( $self, $repo_id, $tag_name ) {
    return $self->_req( 'DELETE', "/repositories/$repo_id/tags/$tag_name/" );
}

# REPO WEBHOOKS
# TODO get all pages
sub get_webhooks ( $self, $repo_id ) {
    return $self->_req( 'GET', "/repositories/$repo_id/webhooks/?page_size=$DEF_PAGE_SIZE&page=1" );
}

sub create_webhook ( $self, $repo_id, $webhook_name, $webhook_url ) {
    return $self->_req(
        'POST',
        "/repositories/$repo_id/webhook_pipeline/",
        {   name                  => $webhook_name,
            expect_final_callback => \0,
            webhooks              => [ {
                name     => $webhook_name,
                hook_url => $webhook_url,
            } ],
        },
    );
}

sub delete_webhook ( $self, $repo_id, $webhook_name ) {
    return $self->_req( 'DELETE', "/repositories/$repo_id/webhook_pipeline/$webhook_name/" );
}

# AUTOBUILD LINKS
sub get_autobuild_links ( $self, $repo_id ) {
    my $res = $self->_req( 'GET', "/repositories/$repo_id/links/" );

    if ($res) {
        my $data;

        for my $link ( $res->{data}->{results}->@* ) {
            $data->{ $link->{id} } = $link;
        }

        $res->{data} = $data;
    }

    return $res;
}

sub create_autobuild_link ( $self, $repo_id, $target_repo_id ) {
    return $self->_req( 'POST', "/repositories/$repo_id/links/", { to_repo => $target_repo_id } );
}

sub delete_autobuild_link ( $self, $repo_id, $link_id ) {
    return $self->_req( 'DELETE', "/repositories/$repo_id/links/$link_id/" );
}

# BUILD
# TODO get all pages
sub get_build_history ( $self, $repo_id ) {
    my $res = $self->_req( 'GET', "/repositories/$repo_id/buildhistory/?page_size=$DEF_PAGE_SIZE&page=1" );

    if ($res) {
        my $data;

        for my $build ( $res->{data}->{results}->@* ) {
            $data->{ $build->{id} } = $build;

            $build->{status_text} = exists $BUILD_STATUS_TEXT->{ $build->{status} } ? $BUILD_STATUS_TEXT->{ $build->{status} } : $build->{status};
        }

        $res->{data} = $data;
    }

    return $res;
}

sub get_autobuild_settings ( $self, $repo_id ) {
    return $self->_req( 'GET', "/repositories/$repo_id/autobuild/" );
}

# AUTOBUILD TAGS
sub get_autobuild_tags ( $self, $repo_id ) {
    my $res = $self->_req( 'GET', "/repositories/$repo_id/autobuild/tags/" );

    if ($res) {
        my $data;

        for my $tag ( $res->{data}->{results}->@* ) {
            $data->{ $tag->{id} } = $tag;
        }

        $res->{data} = $data;
    }

    return $res;
}

sub create_autobuild_tag ( $self, $repo_id, $tag_name, $source_name, $source_type, $dockerfile_location ) {
    my ( $namespace, $name ) = split m[/]sm, $repo_id;

    return $self->_req(
        'POST',
        "/repositories/$repo_id/autobuild/tags/",
        {   name                => $tag_name,
            dockerfile_location => $dockerfile_location // '/',
            source_name         => $source_name,
            source_type         => $DOCKERHUB_SOURCE_TYPE_NAME->{ lc $source_type },
            isNew               => \1,
            repoName            => $name,
            namespace           => $namespace,
        }
    );
}

sub delete_autobuild_tag_by_id ( $self, $repo_id, $autobuild_tag_id ) {
    return $self->_req( 'DELETE', "/repositories/$repo_id/autobuild/tags/$autobuild_tag_id/" );
}

sub delete_autobuild_tag_by_name ( $self, $repo_id, $autobuild_tag_name ) {
    my $res = $self->get_autobuild_tags($repo_id);

    return $res if !$res;

    my $found_autobuild_tag;

    for my $autobuild_tag ( values $res->{data}->%* ) {
        if ( $autobuild_tag->{name} eq $autobuild_tag_name ) {
            $found_autobuild_tag = $autobuild_tag;

            last;
        }
    }

    if ( !$found_autobuild_tag ) {
        return res [ 404, 'Autobuild tag was not found' ];
    }
    else {
        return $self->delete_autobuild_tag_by_id( $repo_id, $found_autobuild_tag->{id} );
    }
}

sub trigger_autobuild ( $self, $repo_id, $source_name, $source_type ) {
    return $self->_req(
        'POST',
        "/repositories/$repo_id/autobuild/trigger-build/",
        {   source_name         => $source_name,
            source_type         => $DOCKERHUB_SOURCE_TYPE_NAME->{ lc $source_type },
            dockerfile_location => '/',
        }
    );
}

sub trigger_autobuild_by_tag_name ( $self, $repo_id, $autobuild_tag_name ) {
    my $res = $self->get_autobuild_tags($repo_id);

    return $res if !$res;

    my $found_autobuild_tag;

    for my $autobuild_tag ( values $res->{data}->%* ) {
        if ( $autobuild_tag->{name} eq $autobuild_tag_name ) {
            $found_autobuild_tag = $autobuild_tag;

            last;
        }
    }

    if ( !$found_autobuild_tag ) {
        return res [ 404, 'Autobuild tag was not found' ];
    }
    else {
        return $self->trigger_autobuild( $repo_id, $found_autobuild_tag->{source_name}, $found_autobuild_tag->{source_type} );
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 160, 271, 306, 355,  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |      | 372, 376, 399, 410   |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 40, 42               | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 138                  | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Docker::Hub

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
