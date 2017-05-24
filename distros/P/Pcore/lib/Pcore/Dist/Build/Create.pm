package Pcore::Dist::Build::Create;

use Pcore -const, -class;
use Pcore::Dist;
use Pcore::API::SCM;
use Pcore::Util::File::Tree;
use Pcore::API::SCM qw[:CONST];

const our $SCM_NAME_TYPE => {
    hg    => $SCM_TYPE_HG,
    git   => $SCM_TYPE_GIT,
    hggit => $SCM_TYPE_GIT,
};

has build => ( is => 'ro', isa => InstanceOf ['Pcore::Dist::Build'], required => 1 );

has base_path => ( is => 'ro', isa => Str,  required => 1 );
has namespace => ( is => 'ro', isa => Str,  required => 1 );    # Dist::Name
has cpan      => ( is => 'ro', isa => Bool, default  => 0 );
has upstream => ( is => 'ro', isa => Enum [qw[bitbucket github]], default => 'bitbucket' );    # create upstream repository
has upstream_namespace => ( is => 'ro', isa => Str );                                                  # upstream repository namespace
has private            => ( is => 'ro', isa => Bool, default => 0 );
has scm                => ( is => 'ro', isa => Enum [ keys $SCM_NAME_TYPE->%* ], default => 'hg' );    # SCM for upstream repository

has scm_type => ( is => 'lazy', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ], init_arg => undef );
has target_path => ( is => 'lazy', isa => Str,     init_arg => undef );
has tmpl_params => ( is => 'lazy', isa => HashRef, init_arg => undef );

has upstream_api => ( is => 'ro', isa => Object, init_arg => undef );

our $ERROR;

sub BUILDARGS ( $self, $args ) {
    $args->{namespace} =~ s/-/::/smg if $args->{namespace};

    return $args;
}

sub _build_scm_type ($self) {
    return $SCM_NAME_TYPE->{ $self->scm };
}

sub _build_target_path ($self) {
    return P->path( $self->base_path, is_dir => 1 )->realpath->to_string . lc( $self->namespace =~ s[::][-]smgr );
}

sub _build_tmpl_params ($self) {
    return {
        dist_name         => $self->namespace =~ s/::/-/smgr,                                            # Package-Name
        dist_path         => lc $self->namespace =~ s/::/-/smgr,                                         # package-name
        module_name       => $self->namespace,                                                           # Package::Name
        author            => $ENV->user_cfg->{_}->{author},
        author_email      => $ENV->user_cfg->{_}->{email},
        copyright_year    => P->date->now->year,
        copyright_holder  => $ENV->user_cfg->{_}->{copyright_holder} || $ENV->user_cfg->{_}->{author},
        license           => $ENV->user_cfg->{_}->{license},
        cpan_distribution => $self->cpan,
        pcore_version     => $ENV->pcore->version->normal,
    };
}

sub run ($self) {
    if ( -e $self->target_path ) {
        $ERROR = 'Target path already exists';

        return;
    }

    if ( $self->upstream eq 'github' ) {

        # GitHub support only git SCM
        $self->{scm} = 'git' if $self->{scm} eq 'hg';
    }

    # create upstream repo
    if ( $self->upstream ) {
        return if !$self->_create_upstream_repo;
    }

    # copy files
    my $files = Pcore::Util::File::Tree->new;

    $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/dist/' );

    if ( $self->upstream ) {
        if ( $self->scm_type == $SCM_TYPE_HG ) {
            $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/hg/' );
        }
        elsif ( $self->scm_type == $SCM_TYPE_GIT ) {
            $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/git/' );
        }
    }

    $files->move_file( 'lib/_MainModule.pm', 'lib/' . $self->namespace =~ s[::][/]smgr . '.pm' );

    # rename share/_dist.perl -> share/dist.perl
    $files->move_file( 'share/_dist.perl', 'share/dist.perl' );

    $files->render_tmpl( $self->tmpl_params );

    $files->write_to( $self->target_path );

    my $dist = Pcore::Dist->new( $self->target_path );

    # update dist after create
    $dist->build->update;

    return $dist;
}

sub _create_upstream_repo ($self) {
    if ( $self->upstream eq 'bitbucket' ) {
        require Pcore::API::Bitbucket;

        $self->{upstream_api} = Pcore::API::Bitbucket->new(
            {   repo_name => lc $self->namespace =~ s[::][-]smgr,
                namespace => $self->upstream_namespace || $ENV->user_cfg->{BITBUCKET}->{namespace},
                scm_type  => $self->scm_type,
            }
        );
    }
    elsif ( $self->upstream eq 'github' ) {
        require Pcore::API::GitHub;

        $self->{upstream_api} = Pcore::API::GitHub->new(
            {   repo_name => lc $self->namespace =~ s[::][-]smgr,
                namespace => $self->upstream_namespace || $ENV->user_cfg->{GITHUB}->{namespace},
            }
        );
    }

    my $confirm = P->term->prompt( qq[Create upstream repository "@{[$self->{upstream_api}->id]}" on @{[$self->upstream]}?], [qw[yes no exit]], enter => 1 );

    if ( $confirm eq 'no' ) {
        return 1;
    }
    elsif ( $confirm eq 'exit' ) {
        $ERROR = 'Error creating upstream repository';

        return;
    }

    print 'Creating upstream repository ... ';

    my $res = $self->{upstream_api}->create_repo( is_private => $self->private );

    if ( !$res->is_success ) {
        $ERROR = $res->reason;

        say 'error';

        return;
    }

    say 'done';

    return if !$self->_clone_upstream_repo;

    return 1;
}

sub _clone_upstream_repo ($self) {
    my $clone_uri;

    if   ( $self->scm eq 'hggit' ) { $clone_uri = $self->upstream_api->clone_uri_ssh_hggit }
    else                           { $clone_uri = $self->upstream_api->clone_uri_ssh }

    print qq[Cloning upstream repository "$clone_uri" ... ];

    if ( my $res = Pcore::API::SCM->scm_clone( $self->target_path, $clone_uri ) ) {
        say 'done';

        return 1;
    }
    else {
        $ERROR = $res->reason;

        say 'error';

        return;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Create

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
