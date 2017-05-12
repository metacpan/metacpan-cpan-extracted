package Pcore::API::DockerHub::Repository;

use Pcore -class;
use Pcore::API::DockerHub qw[:CONST];
use Pcore::API::DockerHub::Repository::WebHook;
use Pcore::API::DockerHub::Repository::Link;
use Pcore::API::DockerHub::Repository::Build;
use Pcore::API::DockerHub::Repository::Tag;
use Pcore::API::DockerHub::Repository::Build::Tag;
use Pcore::API::DockerHub::Repository::Collaborator;

with qw[Pcore::Util::Result::Status];

has api => ( is => 'ro', isa => InstanceOf ['Pcore::API::DockerHub'], required => 1 );

has name      => ( is => 'lazy', isa => Str, init_arg => undef );
has namespace => ( is => 'lazy', isa => Str, init_arg => undef );
has id        => ( is => 'lazy', isa => Str, init_arg => undef );

sub _build_name ($self) {
    return $self->{name};
}

sub _build_namespace ($self) {
    return $self->{namespace};
}

sub _build_id ($self) {
    return $self->namespace . q[/] . $self->name;
}

sub remove ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'delete',
        "/repositories/@{[$self->id]}/",
        1, undef,
        sub ($res) {
            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub set_desc ( $self, % ) {
    my %args = (
        cb        => undef,
        desc      => undef,
        desc_full => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'patch',
        "/repositories/@{[$self->id]}/",
        1,
        {   description      => $args{desc},
            description_full => $args{desc_full},
        },
        $args{cb}
    );
}

# COMMENTS
sub comments ( $self, % ) {
    my %args = (
        page      => 1,
        page_size => 100,
        cb        => undef,
        splice @_, 1,
    );

    return $self->api->request( 'get', "/repositories/@{[$self->id]}/comments/?page_size=$args{page_size}&page=$args{page}", 1, undef, $args{cb} );
}

# STAR
sub star_repo ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request( 'post', "/repositories/@{[$self->id]}/stars/", 1, {}, $args{cb} );
}

sub unstar_repo ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request( 'delete', "/repositories/@{[$self->id]}/stars/", 1, undef, $args{cb} );
}

# WEBHOOK
sub webhooks ( $self, % ) {
    my %args = (
        page      => 1,
        page_size => 100,
        cb        => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'get',
        "/repositories/@{[$self->id]}/webhooks/?page_size=$args{page_size}&page=$args{page}",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = {};

                for my $webhook ( $res->{data}->{results}->@* ) {
                    $webhook = bless $webhook, 'Pcore::API::DockerHub::Repository::WebHook';

                    $webhook->set_status( $res->status );

                    $webhook->{repo} = $self;

                    $result->{ $webhook->{name} } = $webhook;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub create_webhook ( $self, $webhook_name, $url, % ) {
    my %args = (
        cb => undef,
        splice @_, 3,
    );

    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->api->request(
        'post',
        "/repositories/@{[$self->id]}/webhooks/",
        1,
        { name => $webhook_name },
        sub ($res) {
            if ( !$res->is_success ) {
                $args{cb}->($res) if $args{cb};

                $blocking_cv->send($res) if $blocking_cv;
            }
            else {
                # create webhook object
                my $webhook = bless $res->{data}, 'Pcore::API::DockerHub::Repository::WebHook';

                $webhook->set_status( $res->status );

                $webhook->{repo} = $self;

                # create webhook hook
                $self->api->request(
                    'post',
                    "/repositories/@{[$self->id]}/webhooks/@{[$res->{data}->{id}]}/hooks/",
                    1,
                    { hook_url => $url },
                    sub ($hook_res) {

                        # roll back transaction if request is not successfull
                        if ( !$hook_res->is_success ) {
                            $webhook->remove(
                                cb => sub ($res) {
                                    $args{cb}->($hook_res) if $args{cb};

                                    $blocking_cv->send($hook_res) if $blocking_cv;

                                    return;
                                }
                            );
                        }
                        else {
                            push $webhook->{hooks}->@*, $hook_res->{data};

                            $args{cb}->($webhook) if $args{cb};

                            $blocking_cv->send($webhook) if $blocking_cv;
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub remove_empty_webhooks ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->webhooks(
        cb => sub ($res) {
            my $cv = AE::cv sub {
                $args{cb}->($res) if $args{cb};

                $blocking_cv->send($res) if $blocking_cv;

                return;
            };

            $cv->begin;

            if ( $res->{data}->%* ) {
                for my $webhook ( values $res->{data}->%* ) {
                    if ( !$webhook->{hooks}->@* ) {
                        $cv->begin;

                        $webhook->remove(
                            cb => sub ($res) {
                                $cv->end;

                                return;
                            }
                        );
                    }
                }
            }

            $cv->end;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# BUILD LINKS
sub links ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'get',
        "/repositories/@{[$self->id]}/links/",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = {};

                for my $link ( $res->{data}->{results}->@* ) {
                    $link = bless $link, 'Pcore::API::DockerHub::Repository::Link';

                    $link->set_status( $res->status );

                    $link->{repo} = $self;

                    $result->{ $link->id } = $link;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub create_link ( $self, $to_repo, % ) {
    my %args = (
        cb => undef,
        splice @_, 2,
    );

    $to_repo = "library/$to_repo" if $to_repo !~ m[/]sm;

    return $self->api->request(
        'post',
        "/repositories/@{[$self->id]}/links/",
        1,
        { to_repo => $to_repo },
        sub ($res) {
            if ( $res->is_success ) {
                my $link = bless $res->{data}, 'Pcore::API::DockerHub::Repository::Link';

                $link->set_status( $res->status, $res->reason );

                $link->{repo} = $self;

                $_[0] = $link;

                $res = $link;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# BUILD TRIGGER
sub build_trigger ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request( 'get', "/repositories/@{[$self->id]}/buildtrigger/", 1, undef, $args{cb} );
}

sub build_trigger_history ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request( 'get', "/repositories/@{[$self->id]}/buildtrigger/history", 1, undef, $args{cb} );
}

# BUILD
# NOTE build tag MUST be created before buid will be triggered
sub trigger_build ( $self, $source_name = 'latest', $source_type = $DOCKERHUB_SOURCE_TAG, % ) {
    my %args = (
        cb                  => undef,
        dockerfile_location => q[/],
        splice @_, 3,
    );

    return $self->api->request(
        'post',
        "/repositories/@{[$self->id]}/autobuild/trigger-build/",
        1,
        {   source_type         => $Pcore::API::DockerHub::DOCKERHUB_SOURCE_NAME->{$source_type},
            source_name         => $source_name,
            dockerfile_location => $args{dockerfile_location},
        },
        sub ($res) {
            if ( $res->is_success ) {
                if ( !$res->{data}->@* ) {
                    $res->set_status( 404, 'Invalid build source name' );
                }
                else {
                    my $result = [];

                    for my $build ( $res->{data}->@* ) {
                        $build = bless $build, 'Pcore::API::DockerHub::Repository::Build';

                        $build->set_status( $res->status );

                        $build->{repo} = $self;

                        push $result->@*, $build;
                    }

                    $res->{data} = $result;
                }
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub build_history ( $self, % ) {
    my %args = (
        page      => 1,
        page_size => 100,
        cb        => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'get',
        "/repositories/@{[$self->id]}/buildhistory/?page_size=$args{page_size}&page=$args{page}",
        1, undef,
        sub ($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = [];

                for my $build ( $res->{data}->{results}->@* ) {
                    $build = bless $build, 'Pcore::API::DockerHub::Repository::Build';

                    $build->{build_status} = $build->{status};

                    $build->set_status( $res->status );

                    $build->{repo} = $self;

                    push $result->@*, $build;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# only for automated builds
sub build_settings ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'get',
        "/repositories/@{[$self->id]}/autobuild/",
        1, undef,
        sub ($res) {
            if ( $res->is_success ) {
                my $build_tags = {};

                for my $build_tag ( $res->{data}->{build_tags}->@* ) {
                    my $tag = bless $build_tag, 'Pcore::API::DockerHub::Repository::Build::Tag';

                    $tag->{repo} = $self;

                    $tag->set_status( $res->status, $res->reason );

                    $build_tags->{ $tag->id } = $tag;
                }

                $res->{data}->{build_tags} = $build_tags;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# only for automated builds
sub create_build_tag ( $self, % ) {
    my %args = (
        cb                  => undef,
        name                => '{sourceref}',            # docker build tag name
        source_type         => $DOCKERHUB_SOURCE_TAG,    # Branch, Tag
        source_name         => '/.*/',                   # barnch / tag name in the source repository
        dockerfile_location => q[/],
        splice @_, 1,
    );

    return $self->api->request(
        'post',
        "/repositories/@{[$self->id]}/autobuild/tags/",
        1,
        {   name                => $args{name},
            source_type         => $Pcore::API::DockerHub::DOCKERHUB_SOURCE_NAME->{ $args{source_type} },
            source_name         => $args{source_name},
            dockerfile_location => $args{dockerfile_location},
        },
        sub ($res) {
            if ( $res->is_success ) {
                my $tag = bless $res->{data}, 'Pcore::API::DockerHub::Repository::Build::Tag';

                $tag->set_status( $res->status, $res->reason );

                $tag->{repo} = $self;

                $_[0] = $tag;

                $res = $tag;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# REPO TAGS
sub tags ( $self, % ) {
    my %args = (
        page      => 1,
        page_size => 100,
        cb        => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'get',
        "/repositories/@{[$self->id]}/tags/?page_size=$args{page_size}&page=$args{page}",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = {};

                for my $tag ( $res->{data}->{results}->@* ) {
                    $tag = bless $tag, 'Pcore::API::DockerHub::Repository::Tag';

                    $tag->set_status( $res->status );

                    $tag->{repo} = $self;

                    $result->{ $tag->{name} } = $tag;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# COLLABORATORS
# only for user repositories
sub collaborators ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request(
        'get',
        "/repositories/@{[$self->id]}/collaborators/",
        1, undef,
        sub($res) {
            if ( $res->is_success ) {
                $res->{count} = delete $res->{data}->{count};

                $res->{next} = delete $res->{data}->{next};

                $res->{previous} = delete $res->{data}->{previous};

                my $result = {};

                for my $collaborator ( $res->{data}->{results}->@* ) {
                    $collaborator = bless $collaborator, 'Pcore::API::DockerHub::Repository::Collaborator';

                    $collaborator->set_status( $res->status );

                    $collaborator->{repo} = $self;

                    $result->{ $collaborator->{user} } = $collaborator;
                }

                $res->{data} = $result;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

sub create_collaborator ( $self, $collaborator_name, % ) {
    my %args = (
        cb => undef,
        splice @_, 2,
    );

    return $self->api->request(
        'post',
        "/repositories/@{[$self->id]}/collaborators/",
        1,
        { user => $collaborator_name },
        sub ($res) {
            if ( $res->is_success ) {
                my $collaborator = bless $res->{data}, 'Pcore::API::DockerHub::Repository::Collaborator';

                $collaborator->( $res->status, $res->reason );

                $collaborator->{repo} = $self;

                $_[0] = $collaborator;

                $res = $collaborator;
            }

            $args{cb}->($res) if $args{cb};

            return;
        }
    );
}

# GROUPS
# only for organization repository
sub groups ( $self, % ) {
    my %args = (
        cb => undef,
        splice @_, 1,
    );

    return $self->api->request( 'get', "/repositories/@{[$self->id]}/groups/", 1, undef, $args{cb} );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 350                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::DockerHub::Repository

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
