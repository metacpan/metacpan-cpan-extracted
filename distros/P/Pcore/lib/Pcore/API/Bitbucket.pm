package Pcore::API::Bitbucket;

use Pcore -class, -result;
use Pcore::API::Bitbucket::Issue;
use Pcore::API::SCM qw[:CONST];

has username  => ( is => 'ro', isa => Str, required => 1 );
has password  => ( is => 'ro', isa => Str, required => 1 );
has repo_name => ( is => 'ro', isa => Str, required => 1 );

has namespace => ( is => 'lazy', isa => Str );
has scm_type => ( is => 'ro', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ], default => $SCM_TYPE_HG );

has id   => ( is => 'lazy', isa => Str, init_arg => undef );
has auth => ( is => 'lazy', isa => Str, init_arg => undef );

has clone_uri_https            => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_https_hggit      => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_ssh              => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_ssh_hggit        => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_https       => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_https_hggit => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_ssh         => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_ssh_hggit   => ( is => 'lazy', isa => Str, init_arg => undef );

has cpan_meta => ( is => 'lazy', isa => HashRef, init_arg => undef );

sub BUILDARGS ( $self, $args = undef ) {
    $args->{username} ||= $ENV->user_cfg->{BITBUCKET}->{username} if $ENV->user_cfg->{BITBUCKET}->{username};

    $args->{password} ||= $ENV->user_cfg->{BITBUCKET}->{password} if $ENV->user_cfg->{BITBUCKET}->{password};

    $args->{namespace} ||= $ENV->user_cfg->{BITBUCKET}->{namespace} if $ENV->user_cfg->{BITBUCKET}->{namespace};

    return $args;
}

sub _build_namespace ($self) {
    return $self->username;
}

sub _build_id ($self) {
    return $self->namespace . q[/] . $self->repo_name;
}

sub _build_auth ($self) {
    return 'Basic ' . P->data->to_b64( $self->username . q[:] . $self->password, q[] );
}

# CLONE URL BUILDERS
sub _build_clone_uri_https ($self) {
    my $url = "https://bitbucket.org/@{[$self->id]}";

    $url .= '.git' if $self->scm_type == $SCM_TYPE_GIT;

    return $url;
}

sub _build_clone_uri_https_hggit ($self) {
    if ( $self->scm_type == $SCM_TYPE_HG ) {
        return $self->clone_uri_https;
    }
    else {
        return 'git+' . $self->clone_uri_https;
    }
}

sub _build_clone_uri_ssh ($self) {
    if ( $self->scm_type == $SCM_TYPE_HG ) {
        return "ssh://hg\@bitbucket.org/@{[$self->id]}";
    }
    else {
        return "ssh://git\@bitbucket.org/@{[$self->id]}.git";
    }
}

sub _build_clone_uri_ssh_hggit ($self) {
    if ( $self->scm_type == $SCM_TYPE_HG ) {
        return $self->clone_uri_ssh;
    }
    else {
        return 'git+' . $self->clone_uri_ssh;
    }
}

sub _build_clone_uri_wiki_https ($self) {
    return $self->clone_uri_https . '/wiki';
}

sub _build_clone_uri_wiki_https_hggit ($self) {
    if ( $self->scm_type == $SCM_TYPE_HG ) {
        return $self->clone_uri_wiki_https;
    }
    else {
        return 'git+' . $self->clone_uri_wiki_https;
    }
}

sub _build_clone_uri_wiki_ssh ($self) {
    return $self->clone_uri_ssh . '/wiki';
}

sub _build_clone_uri_wiki_ssh_hggit ($self) {
    if ( $self->scm_type == $SCM_TYPE_HG ) {
        return $self->clone_uri_wiki_ssh;
    }
    else {
        return 'git+' . $self->clone_uri_wiki_ssh;
    }
}

# CPAN META
sub _build_cpan_meta ($self) {
    return {
        homepage   => "https://bitbucket.org/@{[$self->id]}/overview",
        bugtracker => {                                                  #
            web => "https://bitbucket.org/@{[$self->id]}/issues?status=new&status=open",
        },
        repository => {
            type => $self->scm_type == $SCM_TYPE_HG ? 'hg' : 'git',
            url  => $self->clone_uri_https,
            web  => "https://bitbucket.org/@{[$self->id]}/overview",
        },
    };
}

# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D#post
sub create_repo ( $self, @ ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my $cb;

    my $args = {
        scm_type    => $self->scm_type,
        is_private  => 0,
        description => undef,
        fork_police => 'allow_forks',     # allow_forks, no_public_forks, no_forks
        language    => 'perl',
        has_issues  => 1,
        has_wiki    => 1,
    };

    if ( ref $_[-1] eq 'CODE' ) {
        $cb = $_[-1];

        if ( @_ > 2 ) {
            my %args = @_[ 1 .. $#_ - 1 ];

            $args->@{ keys %args } = values %args;
        }
    }
    elsif ( @_ > 1 ) {
        my %args = @_[ 1 .. $#_ ];

        $args->@{ keys %args } = values %args;
    }

    given ( delete $args->{scm_type} ) {
        when ($SCM_TYPE_HG)  { $args->{scm} = 'hg' }
        when ($SCM_TYPE_GIT) { $args->{scm} = 'git' }
        default              { die 'Invalid SCM type' }
    }

    P->http->post(    #
        "https://api.bitbucket.org/2.0/repositories/@{[$self->id]}",
        headers => {
            AUTHORIZATION => $self->auth,
            CONTENT_TYPE  => 'application/json',
        },
        body      => P->data->to_json($args),
        on_finish => sub ($res) {
            my $done = sub ($res) {
                $cb->($res) if $cb;

                $blocking_cv->send($res) if $blocking_cv;

                return;
            };

            if ( !$res ) {
                my $data = eval { P->data->from_json( $res->body ) };

                $done->( result [ $res->status, $data->{error}->{message} || $res->reason ] );
            }
            else {
                my $data = eval { P->data->from_json( $res->body ) };

                if ($@) {
                    $done->( result [ 500, 'Error decoding respnse' ] );
                }
                else {
                    $done->( result 201, $data );
                }
            }

            return;
        },
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# VERSIONS
# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/versions
sub get_versions ( $self, $cb ) {
    my $versions;

    state $get = sub ( $url, $cb ) {
        P->http->get(
            $url,
            headers => {    #
                AUTHORIZATION => $self->auth,
            },
            on_finish => sub ($res) {
                if ( !$res ) {
                    $cb->( result [ $res->status, $res->reason ] );
                }
                else {
                    my $data = eval { P->data->from_json( $res->body->$* ) };

                    if ($@) {
                        $cb->( result [ 500, 'Error decoding content' ] );
                    }
                    else {
                        $cb->( result 200, $data );
                    }
                }

                return;
            }
        );

        return;
    };

    my $process = sub ($res) {
        if ( !$res ) {
            $cb->($res);
        }
        else {
            for my $ver ( $res->{data}->{values}->@* ) {
                $versions->{ $ver->{name} } = $ver->{links}->{self}->{href};
            }

            if ( $res->{data}->{next} ) {
                $get->( $res->{data}->{next}, __SUB__ );
            }
            else {
                $cb->( result 200, $versions );
            }
        }

        return;
    };

    $get->( "https://api.bitbucket.org/2.0/repositories/@{[$self->id]}/versions", $process );

    return;
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-POSTanewversion
sub create_version ( $self, $ver, $cb ) {
    $ver = version->parse($ver)->normal;

    P->http->post(    #
        "https://api.bitbucket.org/1.0/repositories/@{[$self->id]}/issues/versions",
        headers => {
            AUTHORIZATION => $self->auth,
            CONTENT_TYPE  => 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body      => P->data->to_uri( { name => $ver } ),
        on_finish => sub ($res) {
            if ( !$res ) {
                if ( $res->body->$* =~ /already exists/sm ) {
                    $cb->( result 200, { name => $ver } );
                }
                else {
                    $cb->( result [ $res->status, $res->reason ] );
                }
            }
            else {
                my $data = eval { P->data->from_json( $res->body->$* ) };

                if ($@) {
                    $cb->( result [ 500, 'Error decoding content' ] );
                }
                else {
                    $cb->( result 201, $data );
                }
            }

            return;
        },
    );

    return;
}

# MILESTONES
# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/milestones
sub get_milestones ( $self, $cb ) {
    my $milestones;

    state $get = sub ( $url, $cb ) {
        P->http->get(
            $url,
            headers => {    #
                AUTHORIZATION => $self->auth,
            },
            on_finish => sub ($res) {
                if ( !$res ) {
                    $cb->( result [ $res->status, $res->reason ] );
                }
                else {
                    my $data = eval { P->data->from_json( $res->body->$* ) };

                    if ($@) {
                        $cb->( result [ 500, 'Error decoding content' ] );
                    }
                    else {
                        $cb->( result 200, $data );
                    }
                }

                return;
            }
        );

        return;
    };

    my $process = sub ($res) {
        if ( !$res ) {
            $cb->($res);
        }
        else {
            for my $ver ( $res->{data}->{values}->@* ) {
                $milestones->{ $ver->{name} } = $ver->{links}->{self}->{href};
            }

            if ( $res->{data}->{next} ) {
                $get->( $res->{data}->{next}, __SUB__ );
            }
            else {
                $cb->( result 200, $milestones );
            }
        }

        return;
    };

    $get->( "https://api.bitbucket.org/2.0/repositories/@{[$self->id]}/milestones", $process );

    return;
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-POSTanewmilestone
sub create_milestone ( $self, $ver, $cb ) {
    $ver = version->parse($ver)->normal;

    P->http->post(    #
        "https://api.bitbucket.org/1.0/repositories/@{[$self->id]}/issues/milestones",
        headers => {
            AUTHORIZATION => $self->auth,
            CONTENT_TYPE  => 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body      => P->data->to_uri( { name => $ver } ),
        on_finish => sub ($res) {
            if ( !$res ) {
                if ( $res->body->$* =~ /already exists/sm ) {
                    $cb->( result 200, { name => $ver } );
                }
                else {
                    $cb->( result [ $res->status, $res->reason ] );
                }
            }
            else {
                my $data = eval { P->data->from_json( $res->body->$* ) };

                if ($@) {
                    $cb->( result [ 500, 'Error decoding content' ] );
                }
                else {
                    $cb->( result 201, $data );
                }
            }

            return;
        },
    );

    return;
}

# ISSUES
# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETalistofissuesinarepository%27stracker
sub get_issues ( $self, @ ) {
    my $cb = $_[-1];

    my %args = (
        limit     => 50,
        sort      => 'priority',    # priority, kind, version, component, milestone
        status    => undef,
        milestone => undef,
        @_[ 1 .. $#_ - 1 ],
    );

    P->http->get(                   #
        "https://bitbucket.org/api/1.0/repositories/@{[$self->id]}/issues/?" . P->data->to_uri( \%args ),
        headers   => { AUTHORIZATION => $self->auth },
        on_finish => sub ($res) {
            if ( !$res ) {
                my $data = eval { P->data->from_json( $res->body ) };

                $cb->( result [ $res->status, $data->{error}->{message} || $res->reason ] );
            }
            else {
                my $data = eval { P->data->from_json( $res->body ) };

                if ($@) {
                    $cb->( result [ 500, 'Error decoding respnse' ] );
                }
                else {
                    my $issues;

                    for my $issue ( $data->{issues}->@* ) {
                        $issue->{api} = $self;

                        push $issues->@*, bless $issue, 'Pcore::API::Bitbucket::Issue';
                    }

                    $cb->( result 200, $issues );
                }
            }

            return;
        },
    );

    return;
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETanindividualissue
sub get_issue ( $self, $id, $cb ) {
    P->http->get(
        "https://bitbucket.org/api/1.0/repositories/@{[$self->id]}/issues/$id",
        headers   => { AUTHORIZATION => $self->auth },
        on_finish => sub ($res) {
            if ( !$res ) {
                my $data = eval { P->data->from_json( $res->body ) };

                $cb->( result [ $res->status, $data->{error}->{message} || $res->reason ] );
            }
            else {
                my $data = eval { P->data->from_json( $res->body ) };

                if ($@) {
                    $cb->( result [ 500, 'Error decoding respnse' ] );
                }
                else {
                    $data->{api} = $self;

                    $cb->( result 200, bless $data, 'Pcore::API::Bitbucket::Issue' );
                }
            }

            return;
        },
    );

    return;
}

sub set_issue_status ( $self, $id, $status, $cb ) {
    my $issue = Pcore::API::Bitbucket::Issue->new( { api => $self } );

    $issue->{local_id} = $id;

    $issue->set_status( $status, $cb );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Bitbucket

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
