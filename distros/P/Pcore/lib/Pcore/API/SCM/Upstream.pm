package Pcore::API::SCM::Upstream;

use Pcore -const, -class;
use Pcore::API::SCM qw[:CONST];

const our $SCM_HOSTING_BITBUCKET => 1;
const our $SCM_HOSTING_GITHUB    => 2;

const our $SCM_HOSTING_CLASS => {
    $SCM_HOSTING_BITBUCKET => 'Pcore::API::Bitbucket',
    $SCM_HOSTING_GITHUB    => 'Pcore::API::GitHub',
};

has uri => ( is => 'ro', isa => InstanceOf ['Pcore::Util::URI'], required => 1 );
has local_scm_type => ( is => 'lazy', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ] );

has host => ( is => 'lazy', isa => Str, init_arg => undef );
has path => ( is => 'lazy', isa => Str, init_arg => undef );
has hosting => ( is => 'lazy', isa => Maybe [ Enum [ $SCM_HOSTING_BITBUCKET, $SCM_HOSTING_GITHUB ] ], init_arg => undef );
has hosting_api_class => ( is => 'lazy', isa => Maybe [Str], init_arg => undef );
has namespace => ( is => 'lazy', isa => Str, init_arg => undef );
has repo_name => ( is => 'lazy', isa => Str, init_arg => undef );
has remote_scm_type => ( is => 'lazy', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ], init_arg => undef );

has clone_uri_https       => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_ssh         => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_https_hggit => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_ssh_hggit   => ( is => 'lazy', isa => Str, init_arg => undef );

# NOTE https://bitbucket.org/repo_owner/repo_name - upstream SCM type can't be recognized correctly, use ".git" suffix fot git repositories

# hggit upstream url type:
# [SSH]     git+ssh://git@github.com:zdm/test.git
# [SSH]     git+ssh://git@github.com:zdm/test
# [INVALID] ssh://git@github.com:zdm/test.git
# [INVALID] ssh://git@github.com:zdm/test
# [INVALID] git@github.com:zdm/test.git - clone remote using SSH, but set upstream repo to local path in hgrc
# [INVALID] git@github.com:zdm/test - clone remote using SSH, but set upstream repo to local path in hgrc
# [HTTPS]   https://github.com/zdm/test.git
# [INVALID] https://github.com/zdm/test - without .git suffix hggit can't recognize, that this is a git upstream
# [HTTPS]   git://github.com/zdm/test.git
# [HTTPS]   git://github.com/zdm/test

# git upstream url type:
# [INVALID] git+ssh://git@github.com:zdm/test.git
# [INVALID] git+ssh://git@github.com:zdm/test
# [INVALID] ssh://git@github.com:zdm/test.git
# [INVALID] ssh://git@github.com:zdm/test
# [SSH]     git@github.com:zdm/test.git
# [SSH]     git@github.com:zdm/test
# [HTTPS]   https://github.com/zdm/test.git
# [HTTPS]   https://github.com/zdm/test
# [HTTPS]   git://github.com/zdm/test.git
# [HTTPS]   git://github.com/zdm/test

# hg upstream url type:
# ssh://hg@bitbucket.org/zdm/test
# https://zdm@bitbucket.org/zdm/test
# http://zdm@bitbucket.org/zdm/test

sub BUILDARGS ( $self, $args ) {
    $args->{uri} = P->uri( $args->{uri}, authority => 1, base => 'ssh:' ) if !ref $args->{uri};

    return $args;
}

sub _build_host ($self) {
    return $self->uri->host->name;
}

# TODO maybe rename to id
sub _build_path ($self) {
    if ( $self->remote_scm_type == $SCM_TYPE_HG ) {
        return $self->uri->path->to_string;
    }
    else {
        if ( $self->uri->port ) {
            return q[/] . $self->uri->port . $self->uri->path->to_string;
        }
        else {
            return $self->uri->path->to_string;
        }
    }
}

sub _build_hosting ($self) {
    if   ( $self->host eq 'bitbucket.org' ) { return $SCM_HOSTING_BITBUCKET }
    if   ( $self->host eq 'github.com' )    { return $SCM_HOSTING_GITHUB }
    else                                    {return}
}

sub _build_hosting_api_class ($self) {
    if   ( $self->hosting ) { return $SCM_HOSTING_CLASS->{ $self->hosting } }
    else                    {return}
}

# TODO rename to owner
sub _build_namespace ($self) {
    return ( $self->path =~ m[/(.+?)/]sm )[0];
}

# TODO rename to slug
sub _build_repo_name ($self) {
    return ( $self->path =~ m[/.+?/([[:alnum:]_-]+)]sm )[0];
}

sub _build_remote_scm_type ($self) {
    my $uri = $self->uri;

    if ( $self->{local_scm_type} && $self->{local_scm_type} == $SCM_TYPE_GIT ) {
        return $SCM_TYPE_GIT;
    }
    elsif ( $self->hosting && $self->hosting == $SCM_HOSTING_GITHUB ) {
        return $SCM_TYPE_GIT;
    }
    elsif ( $uri->scheme =~ /git/sm ) {
        return $SCM_TYPE_GIT;
    }
    elsif ( $uri->scheme =~ /ssh/sm && $uri->username eq 'git' ) {
        return $SCM_TYPE_GIT;
    }
    else {
        return $SCM_TYPE_GIT if $uri->path =~ /[.]git\z/sm;
    }

    return $SCM_TYPE_HG;
}

# TODO impossible to detect local SCM type, using remote url only
sub _build_local_scm_type ($self) {
    if ( $self->uri->scheme =~ /\Agit[+]/sm ) {
        return $SCM_TYPE_HG;
    }
    else {
        return $self->remote_scm_type;
    }
}

sub _build_clone_uri_https ($self) {
    return 'https://' . $self->host . q[/] . $self->path;
}

sub _build_clone_uri_ssh ($self) {
    return 'ssh://' . $self->uri->username . q[@] . $self->host . q[/] . $self->path;
}

sub _build_clone_uri_https_hggit ($self) {
    if ( $self->local_scm_type == $SCM_TYPE_HG ) {
        return $self->clone_uri_https;
    }
    else {
        return 'git+' . $self->clone_uri_https;
    }
}

sub _build_clone_uri_ssh_hggit ($self) {
    if ( $self->local_scm_type == $SCM_TYPE_HG ) {
        return $self->clone_uri_ssh;
    }
    else {
        return 'git+' . $self->clone_uri_ssh;
    }
}

sub hosting_api ($self) {
    return if !$self->hosting_api_class;

    return P->class->load( $self->hosting_api_class )->new( { namespace => $self->namespace, repo_name => $self->repo_name, scm_type => $self->remote_scm_type } );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM::Upstream

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
