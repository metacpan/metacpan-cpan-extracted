package Pcore::API::Git::Upstream;

use Pcore -class;
use Pcore::API::Git qw[:ALL];

has repo_namespace => ( required => 1 );    # Str
has repo_name      => ( required => 1 );    # Str
has repo_id        => ( required => 1 );    # Str
has hosting        => ( required => 1 );    # Enum [ $GIT_UPSTREAM_BITBUCKET, $GIT_UPSTREAM_GITHUB, $GIT_UPSTREAM_GITLAB ]

# https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a
sub BUILDARGS ( $self, $args ) {

    # git@github.com:softvisio/phonegap.git
    if ( my $url = delete $args->{url} ) {
        if ( $url =~ m[\Agit@([[:alnum:].-]+?):([[:alnum:]]+?)/([[:alnum:]]+)]sm ) {
            $args->{hosting}        = $GIT_UPSTREAM_NAME->{$1};
            $args->{repo_namespace} = $2;
            $args->{repo_name}      = $3;
        }

        # https://github.com/softvisio/phonegap.git
        # git://github.com/softvisio/phonegap.git
        # ssh://git@github.com/softvisio/phonegap.git
        else {
            $url = P->uri($url);

            $args->{hosting} = $GIT_UPSTREAM_NAME->{ $url->{host} };

            ( $args->{repo_namespace}, $args->{repo_name} ) = ( $url->{path} =~ m[/([[:alnum:]_-]+)/([[:alnum:]_-]+)]smi );
        }

        $args->{repo_id} = "$args->{repo_namespace}/$args->{repo_name}";
    }
    else {
        if ( $args->{repo_id} ) {
            ( $args->{repo_namespace}, $args->{repo_name} ) = split m[/]sm, $args->{repo_id};
        }
        else {
            $args->{repo_id} = "$args->{repo_namespace}/$args->{repo_name}";
        }
    }

    return $args;
}

sub get_hosting_api ( $self, $args = undef ) {
    if ( $self->{hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
        require Pcore::API::Bitbucket;

        return Pcore::API::Bitbucket->new( $args // () );
    }
    elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITHUB ) {
        require Pcore::API::GitHub;

        return Pcore::API::GitHub->new( $args // () );
    }
    elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITLAB ) {
        require Pcore::API::GitLab;

        return Pcore::API::GitLab->new( $args // () );
    }

    return;
}

sub get_clone_url ( $self, $url_type = $GIT_UPSTREAM_URL_SSH ) {
    my $url = $url_type == $GIT_UPSTREAM_URL_HTTPS ? 'https://' : 'ssh://git@';

    $url .= "$GIT_UPSTREAM_HOST->{$self->{hosting}}/$self->{repo_id}";

    return $url;
}

sub get_wiki_clone_url ( $self, $url_type = $GIT_UPSTREAM_URL_SSH ) {
    my $url = $self->get_clone_url($url_type);

    if ( $self->{hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
        $url .= '/wiki';
    }
    else {
        $url .= '.wiki';
    }

    return $url;
}

sub get_cpan_meta ( $self) {
    my $cpan_meta;

    if ( $self->{hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
        $cpan_meta = {
            homepage   => "https://bitbucket.org/$self->{repo_id}/overview",
            bugtracker => {                                                    #
                web => "https://bitbucket.org/$self->{repo_id}/issues?status=new&status=open",
            },
            repository => {
                type => 'git',
                url  => $self->get_clone_url($GIT_UPSTREAM_URL_HTTPS),
                web  => "https://bitbucket.org/$self->{repo_id}/overview",
            },
        };
    }
    elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITHUB ) {
        $cpan_meta = {
            homepage   => "https://github.com/$self->{repo_id}",
            bugtracker => {                                        #
                web => "https://github.com/$self->{repo_id}/issues?q=is%3Aopen+is%3Aissue",
            },
            repository => {
                type => 'git',
                url  => $self->get_clone_url($GIT_UPSTREAM_URL_HTTPS),
                web  => "https://github.com/$self->{repo_id}",
            },
        };
    }
    elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITLAB ) {

        # TODO
        ...;
    }

    return $cpan_meta;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 67, 75               | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 120                  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Git::Upstream

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
