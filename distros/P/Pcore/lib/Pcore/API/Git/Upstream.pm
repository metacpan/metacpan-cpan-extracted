package Pcore::API::Git::Upstream;

use Pcore -class;
use Pcore::API::Git qw[:ALL];

has repo_namespace => ( required => 1 );    # Str
has repo_name      => ( required => 1 );    # Str
has repo_id        => ( required => 1 );    # Str
has host           => ( required => 1 );
has hosting    => ();                       # Enum [ $GIT_UPSTREAM_BITBUCKET, $GIT_UPSTREAM_GITHUB, $GIT_UPSTREAM_GITLAB ]
has ssh_port   => ();
has https_port => ();

# https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a
sub BUILDARGS ( $self, $args ) {
    if ( my $url = delete $args->{url} ) {

        # git@github.com:softvisio/phonegap.git
        if ( $url =~ m[\Agit@([[:alnum:].-]+?):([[:alnum:]]+?)/([[:alnum:]]+)]sm ) {
            $args->{host}           = $1;
            $args->{repo_namespace} = $2;
            $args->{repo_name}      = $3;
        }

        # https://github.com/softvisio/phonegap.git
        # git://github.com/softvisio/phonegap.git
        # ssh://git@github.com/softvisio/phonegap.git
        else {
            $url = P->uri($url);

            $args->{host} = $url->{host}->{name};

            if ( $url->{port} ) {
                if ( $url->{scheme} eq 'https' ) {
                    $args->{https_port} = $url->{port} if $url->{port} != 443;
                }
                else {
                    $args->{ssh_port} = $url->{port} if $url->{port} != 22;
                }
            }

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

    if ( $args->{host} ) {
        $args->{hosting} ||= $GIT_UPSTREAM_HOST_NAME->{ $args->{host} } if exists $GIT_UPSTREAM_HOST_NAME->{ $args->{host} };
    }
    elsif ( $args->{hosting} ) {
        $args->{host} ||= $GIT_UPSTREAM_NAME_HOST->{ $args->{hosting} } if exists $GIT_UPSTREAM_NAME_HOST->{ $args->{hosting} };
    }

    return $args;
}

sub get_hosting_api ( $self, $args = undef ) {
    return if !$self->{hosting};

    my $api;

    if ( $self->{hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
        require Pcore::API::Bitbucket;

        $api = Pcore::API::Bitbucket->new( $args // () );
    }
    elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITHUB ) {
        require Pcore::API::GitHub;

        $api = Pcore::API::GitHub->new( $args // () );
    }
    elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITLAB ) {
        require Pcore::API::GitLab;

        $api = Pcore::API::GitLab->new( $args // () );
    }

    return $api;
}

sub get_clone_url ( $self, $url_type = $GIT_UPSTREAM_URL_SSH ) {
    my $url = $url_type == $GIT_UPSTREAM_URL_HTTPS ? 'https://' : 'ssh://git@';

    $url .= $self->{host};

    if ( $url_type == $GIT_UPSTREAM_URL_HTTPS ) {
        $url .= ":$self->{http_port}" if $self->{http_port};
    }
    else {
        $url .= ":$self->{ssh_port}" if $self->{ssh_port};
    }

    $url .= "/$self->{repo_id}";

    return $url;
}

sub get_wiki_clone_url ( $self, $url_type = $GIT_UPSTREAM_URL_SSH ) {
    my $url = $self->get_clone_url($url_type);

    if ( $self->{hosting} && $self->{hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
        $url .= '/wiki';
    }
    else {
        $url .= '.wiki';
    }

    return $url;
}

sub get_cpan_meta ( $self) {
    my $cpan_meta = {
        homepage   => "https://$self->{host}/$self->{repo_id}",
        bugtracker => {                                           #
            web => "https://$self->{host}/$self->{repo_id}/issues",
        },
        repository => {
            type => 'git',
            url  => $self->get_clone_url($GIT_UPSTREAM_URL_HTTPS),
            web  => "https://$self->{host}/$self->{repo_id}"
        },
    };

    if ( $self->{hosting} ) {
        if ( $self->{hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
            $cpan_meta->{bugtracker}->{web} = "https://bitbucket.org/$self->{repo_id}/issues?status=new&status=open";
        }
        elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITHUB ) {
            $cpan_meta->{bugtracker}->{web} = "https://github.com/$self->{repo_id}/issues?q=is%3Aopen+is%3Aissue";
        }
        elsif ( $self->{hosting} eq $GIT_UPSTREAM_GITLAB ) {
            $cpan_meta->{bugtracker}->{web} = "https://gitlab.com/$self->{repo_id}/issues";
        }
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
## |    3 | 90, 107              | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
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
