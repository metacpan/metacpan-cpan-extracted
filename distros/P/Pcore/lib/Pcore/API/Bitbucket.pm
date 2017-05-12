package Pcore::API::Bitbucket;

use Pcore -class, -result;
use Pcore::API::Bitbucket::Issue;
use Pcore::API::SCM qw[:CONST];

has api_username => ( is => 'ro', isa => Str, required => 1 );
has api_password => ( is => 'ro', isa => Str, required => 1 );
has repo_name    => ( is => 'ro', isa => Str, required => 1 );
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
    $args->{api_username} ||= $ENV->user_cfg->{'Pcore::API::Bitbucket'}->{api_username} if $ENV->user_cfg->{'Pcore::API::Bitbucket'}->{api_username};

    $args->{api_password} ||= $ENV->user_cfg->{'Pcore::API::Bitbucket'}->{api_password} if $ENV->user_cfg->{'Pcore::API::Bitbucket'}->{api_password};

    $args->{namespace} ||= $ENV->user_cfg->{'Pcore::API::Bitbucket'}->{namespace} if $ENV->user_cfg->{'Pcore::API::Bitbucket'}->{namespace};

    return $args;
}

sub _build_namespace ($self) {
    return $self->api_username;
}

sub _build_id ($self) {
    return $self->namespace . q[/] . $self->repo_name;
}

sub _build_auth ($self) {
    return 'Basic ' . P->data->to_b64( $self->api_username . q[:] . $self->api_password, q[] );
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

# ISSUES
sub issues ( $self, @ ) {
    my $cb = $_[-1];

    # https://confluence.atlassian.com/bitbucket/issues-resource-296095191.html#issuesResource-GETalistofissuesinarepository%27stracker
    my %args = (
        limit     => 50,
        id        => undef,
        sort      => 'priority',    # priority, kind, version, component, milestone
        status    => undef,
        milestone => undef,
        splice @_, 1, -1,
    );

    my $id = delete $args{id};

    my $url = do {
        if ($id) {
            "https://bitbucket.org/api/1.0/repositories/@{[$self->id]}/issues/$id";
        }
        else {
            "https://bitbucket.org/api/1.0/repositories/@{[$self->id]}/issues/?" . P->data->to_uri( \%args );
        }
    };

    P->http->get(    #
        $url,
        headers   => { AUTHORIZATION => $self->auth },
        on_finish => sub ($res) {
            my $json = P->data->from_json( $res->body );

            if ($id) {
                my $issue;

                if ($json) {
                    $issue = Pcore::API::Bitbucket::Issue->new( { api => $self } );

                    $issue->@{ keys $json->%* } = values $json->%*;
                }

                $cb->($issue);
            }
            else {
                my $issues;

                if ( $json->{issues} && $json->{issues}->@* ) {
                    for ( $json->{issues}->@* ) {
                        my $issue = Pcore::API::Bitbucket::Issue->new( { api => $self } );

                        $issue->@{ keys $_->%* } = values $_->%*;

                        push $issues->@*, $issue;
                    }
                }

                $cb->($issues);
            }

            return;
        },
    );

    return;
}

sub create_version ( $self, $ver, $cb ) {
    my $url = "https://api.bitbucket.org/1.0/repositories/@{[$self->id]}/issues/versions";

    $ver = version->parse($ver)->normal;

    P->http->post(    #
        $url,
        headers => {
            AUTHORIZATION => $self->auth,
            CONTENT_TYPE  => 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body      => P->data->to_uri( { name => $ver } ),
        on_finish => sub ($res) {
            my $id;

            $id = P->data->from_json( $res->body )->{id} if $res->status == 200;

            $cb->($id);

            return;
        },
    );

    return;
}

sub create_milestone ( $self, $milestone, $cb ) {
    my $url = "https://api.bitbucket.org/1.0/repositories/@{[$self->id]}/issues/milestones";

    P->http->post(    #
        $url,
        headers => {
            AUTHORIZATION => $self->auth,
            CONTENT_TYPE  => 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body      => P->data->to_uri( { name => $milestone } ),
        on_finish => sub ($res) {
            my $id;

            $id = P->data->from_json( $res->body )->{id} if $res->status == 200;

            $cb->($id);

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

sub create_repo ( $self, @ ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my %args = (
        cb          => undef,
        scm_type    => $self->scm_type,
        is_private  => 0,
        description => undef,
        fork_police => 'allow_forks',     # allow_forks, no_public_forks, no_forks
        language    => 'perl',
        has_issues  => 1,
        has_wiki    => 1,
        splice @_, 1
    );

    given ( delete $args{scm_type} ) {
        when ($SCM_TYPE_HG)  { $args{scm} = 'hg' }
        when ($SCM_TYPE_GIT) { $args{scm} = 'git' }
        default              { die 'Invalid SCM type' }
    }

    my $cb = delete $args{cb};

    my $url = "https://api.bitbucket.org/2.0/repositories/@{[$self->id]}";

    P->http->post(    #
        $url,
        headers => {
            AUTHORIZATION => $self->auth,
            CONTENT_TYPE  => 'application/json',
        },
        body      => P->data->to_json( \%args ),
        on_finish => sub ($res) {
            my $api_res;

            my $json = $res->body ? P->data->from_json( $res->body ) : undef;

            if ( $res->status != 200 ) {
                $api_res = result [ $res->status, $json && $json->{error}->{message} ? $json->{error}->{message} : $res->reason ];
            }
            else {
                if ( $json->{error} ) {
                    $api_res = result [ 569, $json->{error}->{message} ];
                }
                else {
                    $api_res = result 200;
                }
            }

            $cb->($api_res) if $cb;

            $blocking_cv->send($api_res) if $blocking_cv;

            return;
        },
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 254                  | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
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
