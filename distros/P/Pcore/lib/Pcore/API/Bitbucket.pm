package Pcore::API::Bitbucket;

use Pcore -class, -res;
use Pcore::Lib::Scalar qw[is_plain_coderef];

has username => ( required => 1 );
has password => ( required => 1 );

has _auth => ( is => 'lazy', init_arg => undef );

sub BUILDARGS ( $self, $args = undef ) {
    $args->{username} ||= $ENV->user_cfg->{BITBUCKET}->{username} if $ENV->user_cfg->{BITBUCKET}->{username};

    $args->{password} ||= $ENV->user_cfg->{BITBUCKET}->{password} if $ENV->user_cfg->{BITBUCKET}->{password};

    return $args;
}

sub _build__auth ($self) {
    return 'Basic ' . P->data->to_b64( "$self->{username}:$self->{password}", $EMPTY );
}

sub _req1 ( $self, $method, $endpoint, $data = undef ) {
    my $res = P->http->$method(
        'https://bitbucket.org/api/1.0' . $endpoint,
        headers => [
            Authorization  => $self->_auth,
            'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
        ],
        data => $data ? P->data->to_uri($data) : undef
    );

    if ( !$res ) {
        return res [ $res->{status}, $res->{reason} ], $res->{data};
    }
    else {
        my $data = $res->{data} && $res->{data}->$* ? P->data->from_json( $res->{data} ) : undef;

        return res $res->{status}, $data;
    }
}

sub _req2 ( $self, $method, $endpoint, $data = undef ) {
    my $res = P->http->$method(
        'https://api.bitbucket.org/2.0' . $endpoint,
        headers => [
            Authorization  => $self->_auth,
            'Content-Type' => 'application/json',
        ],
        data => $data ? P->data->to_json($data) : undef
    );

    $data = $res->{data} && $res->{data}->$* ? P->data->from_json( $res->{data} ) : undef;

    if ( !$res ) {
        return res [ $res->{status}, $data->{error}->{message} // $res->{reason} ];
    }
    else {
        return res $res->{status}, $data;
    }
}

# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D#post
sub create_repo ( $self, $repo_id, %args ) {
    %args = (

        # common atts
        description => undef,
        has_issues  => 1,
        has_wiki    => 1,
        is_private  => 0,

        # bitbucket attrs
        fork_police => 'allow_forks',    # allow_forks, no_public_forks, no_forks
        language    => 'perl',
        %args,
    );

    return $self->_req2( 'post', "/repositories/$repo_id", \%args );
}

# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D#delete
sub delete_repo ( $self, $repo_id ) {
    return $self->_req2( 'delete', "/repositories/$repo_id", undef );
}

# VERSIONS
# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/versions
sub get_versions ( $self, $repo_id ) {
    my $versions;

    my $page = 1;

  GET_PAGE:
    my $res = $self->_req2( 'get', "/repositories/$repo_id/versions?page=$page&pagelen=100" );

    if ($res) {
        for my $ver ( $res->{data}->{values}->@* ) {
            $versions->{ $ver->{name} } = $ver->{links}->{self}->{href};
        }

        if ( $res->{data}->{next} ) {
            $page++;

            goto GET_PAGE;
        }
        else {
            return res 200, $versions;
        }
    }
    else {
        return $res;
    }
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-POSTanewversion
sub create_version ( $self, $repo_id, $ver ) {
    my $res = $self->_req1( 'post', "/repositories/$repo_id/issues/versions", { name => version->parse($ver)->normal } );

    if ( !$res && $res->{data}->$* =~ /already exists/sm ) {
        $res->set_status(200);
    }

    return $res;
}

# MILESTONES
# https://developer.atlassian.com/bitbucket/api/2/reference/resource/repositories/%7Busername%7D/%7Brepo_slug%7D/milestones
sub get_milestones ( $self, $repo_id ) {
    my $versions;

    my $page = 1;

  GET_PAGE:
    my $res = $self->_req2( 'get', "/repositories/$repo_id/milestones?page=$page&pagelen=100" );

    if ($res) {
        for my $ver ( $res->{data}->{values}->@* ) {
            $versions->{ $ver->{name} } = $ver->{links}->{self}->{href};
        }

        if ( $res->{data}->{next} ) {
            $page++;

            goto GET_PAGE;
        }
        else {
            return res 200, $versions;
        }
    }
    else {
        return $res;
    }
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-POSTanewmilestone
sub create_milestone ( $self, $repo_id, $ver ) {
    my $res = $self->_req1( 'post', "/repositories/$repo_id/issues/milestones", { name => version->parse($ver)->normal } );

    if ( !$res && $res->{data}->$* =~ /already exists/sm ) {
        $res->set_status(200);
    }

    return $res;
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETalistofissuesinarepository%27stracker
sub get_issues ( $self, $repo_id, %args ) {
    %args = (
        sort   => 'priority',    # priority, kind, version, component, milestone
        status => undef,
        start  => 0,
        limit  => 50,            # 50 - max.
        %args,
    );

    # remove undefined args
    for ( keys %args ) { delete $args{$_} if !defined $args{$_} }

    my $issues;

    my $res = $self->_req1( 'get', "/repositories/$repo_id/issues?" . P->data->to_uri( \%args ) );

    if ($res) {
        for my $issue ( $res->{data}->{issues}->@* ) {
            $issues->{ $issue->{local_id} } = $issue;
        }

        return res 200, data => $issues, total => $res->{data}->{count};
    }
    else {
        return $res;
    }
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETanindividualissue
sub get_issue ( $self, $repo_id, $issue_id ) {
    return $self->_req1( 'get', "/repositories/$repo_id/issues/$issue_id" );
}

# https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-Updateanexistingissue
sub update_issue ( $self, $repo_id, $issue_id, $data ) {
    return $self->_req1( 'put', "/repositories/$repo_id/issues/$issue_id", $data );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 202                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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
