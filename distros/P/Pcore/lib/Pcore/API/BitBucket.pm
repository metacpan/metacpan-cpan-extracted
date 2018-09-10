package Pcore::API::BitBucket;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_coderef];
use Pcore::API::SCM::Const qw[:SCM_TYPE];

has username => ( is => 'ro', isa => Str, required => 1 );
has password => ( is => 'ro', isa => Str, required => 1 );

has _auth => ( is => 'lazy', isa => Str, init_arg => undef );

sub BUILDARGS ( $self, $args = undef ) {
    $args->{username} ||= $ENV->user_cfg->{BITBUCKET}->{username} if $ENV->user_cfg->{BITBUCKET}->{username};

    $args->{password} ||= $ENV->user_cfg->{BITBUCKET}->{password} if $ENV->user_cfg->{BITBUCKET}->{password};

    return $args;
}

sub _build__auth ($self) {
    return 'Basic ' . P->data->to_b64( "$self->{username}:$self->{password}", q[] );
}

sub _req1 ( $self, $method, $endpoint, $data, $cb = undef ) {
    return P->http->$method(
        'https://bitbucket.org/api/1.0' . $endpoint,
        headers => [
            Authorization  => $self->_auth,
            'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
        ],
        data => $data ? P->data->to_uri($data) : undef,
        sub ($res) {
            my $api_res;

            if ( !$res ) {
                $api_res = res [ $res->{status}, $res->{reason} ], $res->{data};
            }
            else {
                my $data = $res->{data} && $res->{data}->$* ? P->data->from_json( $res->{data} ) : undef;

                $api_res = res $res->{status}, $data;
            }

            return $cb ? $cb->{$api_res} : $api_res;
        }
    );
}

sub _req2 ( $self, $method, $endpoint, $data, $cb = undef ) {
    return P->http->$method(
        'https://api.bitbucket.org/2.0' . $endpoint,
        headers => [
            Authorization  => $self->_auth,
            'Content-Type' => 'application/json',
        ],
        data => $data ? P->data->to_json($data) : undef,
        sub ($res) {
            my $data = $res->{data} && $res->{data}->$* ? P->data->from_json( $res->{data} ) : undef;

            my $api_res;

            if ( !$res ) {
                $api_res = res [ $res->{status}, $data->{error}->{message} // $res->{reason} ];
            }
            else {
                $api_res = res $res->{status}, $data;
            }

            return $cb ? $cb->($api_res) : $api_res;
        }
    );
}

# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D#post
sub create_repo ( $self, $repo_id, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = (

        # common atts
        description => undef,
        has_issues  => 1,
        has_wiki    => 1,
        is_private  => 0,

        # bitbucket attrs
        scm         => $SCM_TYPE_HG,
        fork_police => 'allow_forks',    # allow_forks, no_public_forks, no_forks
        language    => 'perl',
        @args,
    );

    return $self->_req2( 'post', "/repositories/$repo_id", \%args, $cb );
}

# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D#delete
sub delete_repo ( $self, $repo_id, $cb = undef ) {
    return $self->_req2( 'delete', "/repositories/$repo_id", undef, $cb );
}

# VERSIONS
# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/versions
sub get_versions ( $self, $repo_id, $cb = undef ) {
    my $cv = P->cv;

    my $versions;

    my $get = sub ($page) {
        my $sub = __SUB__;

        $self->_req2(
            'get',
            "/repositories/$repo_id/versions?page=$page&pagelen=100",
            undef,
            sub ($res) {
                if ($res) {
                    for my $ver ( $res->{data}->{values}->@* ) {
                        $versions->{ $ver->{name} } = $ver->{links}->{self}->{href};
                    }

                    if ( $res->{data}->{next} ) {
                        $sub->( ++$page );
                    }
                    else {
                        my $api_res = res 200, $versions;

                        $cv->( $cb ? $cb->($api_res) : $api_res );
                    }
                }
                else {
                    $cv->( $cb ? $cb->($res) : $res );
                }

                return;
            }
        );

        return;
    };

    $get->(1);

    return defined wantarray ? $cv->recv : ();
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-POSTanewversion
sub create_version ( $self, $repo_id, $ver, $cb = undef ) {
    return $self->_req1(
        'post',
        "/repositories/$repo_id/issues/versions",
        { name => version->parse($ver)->normal },
        sub ($res) {
            if ( !$res && $res->{data}->$* =~ /already exists/sm ) {
                $res->set_status(200);
            }

            return $cb ? $cb->($res) : $res;
        }
    );
}

# MILESTONES
# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/milestones
sub get_milestones ( $self, $repo_id, $cb = undef ) {
    my $cv = P->cv;

    my $versions;

    my $get = sub ($page) {
        my $sub = __SUB__;

        $self->_req2(
            'get',
            "/repositories/$repo_id/milestones?page=$page&pagelen=100",
            undef,
            sub ($res) {
                if ($res) {
                    for my $ver ( $res->{data}->{values}->@* ) {
                        $versions->{ $ver->{name} } = $ver->{links}->{self}->{href};
                    }

                    if ( $res->{data}->{next} ) {
                        $sub->( ++$page );
                    }
                    else {
                        my $api_res = res 200, $versions;

                        $cv->( $cb ? $cb->($api_res) : $api_res );
                    }
                }
                else {
                    $cv->( $cb ? $cb->($res) : $res );
                }

                return;
            }
        );

        return;
    };

    $get->(1);

    return defined wantarray ? $cv->recv : ();
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-POSTanewmilestone
sub create_milestone ( $self, $repo_id, $ver, $cb = undef ) {
    return $self->_req1(
        'post',
        "/repositories/$repo_id/issues/milestones",
        { name => version->parse($ver)->normal },
        sub ($res) {
            if ( !$res && $res->{data}->$* =~ /already exists/sm ) {
                $res->set_status(200);
            }

            return $cb ? $cb->($res) : $res;
        }
    );
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETalistofissuesinarepository%27stracker
sub get_issues ( $self, $repo_id, @args ) {
    my $cv = P->cv;

    my $cb = is_plain_coderef $args[-1] ? pop @args : ();

    my %args = (
        sort   => 'priority',    # priority, kind, version, component, milestone
        status => undef,
        start  => 0,
        limit  => 50,            # 50 - max.
        @args,
    );

    # remove undefined args
    for ( keys %args ) { delete $args{$_} if !defined $args{$_} }

    my $issues;

    my $get = sub ($page) {
        my $sub = __SUB__;

        $self->_req1(
            'get',
            "/repositories/$repo_id/issues?" . P->data->to_uri( \%args ),
            undef,
            sub ($res) {
                if ($res) {
                    for my $issue ( $res->{data}->{issues}->@* ) {
                        $issues->{ $issue->{local_id} } = $issue;
                    }

                    my $api_res = res 200, data => $issues, total => $res->{data}->{count};

                    $cv->( $cb ? $cb->($api_res) : $api_res );
                }
                else {
                    $cv->( $cb ? $cb->($res) : $res );
                }

                return;
            }
        );

        return;
    };

    $get->(1);

    return defined wantarray ? $cv->recv : ();
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETanindividualissue
sub get_issue ( $self, $repo_id, $issue_id, $cb = undef ) {
    return $self->_req1( 'get', "/repositories/$repo_id/issues/$issue_id", undef, $cb );
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-Updateanexistingissue
sub update_issue ( $self, $repo_id, $issue_id, $data, $cb = undef ) {
    return $self->_req1( 'put', "/repositories/$repo_id/issues/$issue_id", $data, $cb );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 276, 281             | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::BitBucket

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
