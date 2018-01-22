package Pcore::Dist::Build::Create;

use Pcore -class, -result;
use Pcore::Dist;
use Pcore::Util::File::Tree;
use Pcore::API::SCM::Const qw[:ALL];
use Pcore::API::SCM;
use Pcore::API::SCM::Upstream;

has base_path      => ( is => 'ro', isa => Str, required => 1 );
has dist_namespace => ( is => 'ro', isa => Str, required => 1 );    # Dist::Name
has dist_name      => ( is => 'ro', isa => Str, required => 1 );    # Dist-Name

has is_cpan => ( is => 'ro', isa => Bool, default => 0 );
has upstream_hosting => ( is => 'ro', isa => Enum [ $SCM_HOSTING_BITBUCKET, $SCM_HOSTING_GITHUB ], default => $SCM_HOSTING_BITBUCKET );
has is_private => ( is => 'ro', isa => Bool, default => 0 );
has upstream_scm_type => ( is => 'ro', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ], default => $SCM_TYPE_HG );
has local_scm_type    => ( is => 'ro', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ], default => $SCM_TYPE_HG );
has upstream_repo_namespace => ( is => 'ro', isa => Maybe [Str] );

has target_path => ( is => 'lazy', isa => Str,     init_arg => undef );
has tmpl_params => ( is => 'lazy', isa => HashRef, init_arg => undef );

sub BUILDARGS ( $self, $args ) {
    $args->{dist_namespace} =~ s/-/::/smg;
    $args->{dist_name} = $args->{dist_namespace} =~ s/::/-/smgr;

    return $args;
}

sub _build_target_path ($self) {
    return P->path( $self->base_path, is_dir => 1 )->realpath->to_string . lc $self->{dist_name};
}

sub _build_tmpl_params ($self) {
    return {
        dist_name         => $self->{dist_name},                                                         # Package-Name
        dist_path         => lc $self->{dist_name},                                                      # package-name
        module_name       => $self->{dist_namespace},                                                    # Package::Name
        author            => $ENV->user_cfg->{_}->{author},
        author_email      => $ENV->user_cfg->{_}->{email},
        copyright_year    => P->date->now->year,
        copyright_holder  => $ENV->user_cfg->{_}->{copyright_holder} || $ENV->user_cfg->{_}->{author},
        license           => $ENV->user_cfg->{_}->{license},
        cpan_distribution => $self->{is_cpan},
        pcore_version     => $ENV->pcore->version->normal,
    };
}

sub run ($self) {
    if ( -e $self->target_path ) {
        my $res = result [ 500, 'Target path already exists' ];

        say $res;

        return $res;
    }

    # create upstream repo
    if ( $self->{upstream_hosting} ) {
        my $res = $self->_create_upstream_repo;

        return $res if !$res;
    }

    # copy files
    my $files = Pcore::Util::File::Tree->new;

    $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/dist/' );

    if ( $self->{upstream_hosting} ) {
        if ( $self->{local_scm_type} eq $SCM_TYPE_HG ) {
            $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/hg/' );
        }
        elsif ( $self->{local_scm_type} eq $SCM_TYPE_GIT ) {
            $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/git/' );
        }
    }

    $files->move_file( 'lib/_MainModule.pm', 'lib/' . ( $self->{dist_name} =~ s[-][/]smgr ) . '.pm' );

    # rename share/_dist.perl -> share/dist.perl
    $files->move_file( 'share/_dist.perl', 'share/dist.perl' );

    $files->render_tmpl( $self->tmpl_params );

    $files->write_to( $self->target_path );

    my $dist = Pcore::Dist->new( $self->target_path );

    # update dist after create
    $dist->build->update;

    return result 200;
}

sub _create_upstream_repo ($self) {
    my $upstream_repo_namespace = $self->{upstream_repo_namespace} // ( $self->{upstream_hosting} eq $SCM_HOSTING_BITBUCKET ? $ENV->user_cfg->{BITBUCKET}->{default_repo_namespace} : $ENV->user_cfg->{GITHUB}->{default_repo_namespace} );

    my $upstream_repo_id = "$upstream_repo_namespace/" . lc $self->{dist_name};

    my $confirm = P->term->prompt( qq[Create upstream $self->{upstream_scm_type} repository "$upstream_repo_id" on $self->{upstream_hosting}?], [qw[yes no exit]], enter => 1 );

    if ( $confirm eq 'no' ) {
        return result 200;
    }
    elsif ( $confirm eq 'exit' ) {
        return result [ 500, 'Creating upstream repository cancelled' ];
    }

    print 'Creating upstream repository ... ';

    my $scm_upstream = Pcore::API::SCM::Upstream->new( {
        scm_type => $self->{upstream_scm_type},
        hosting  => $self->{upstream_hosting},
        repo_id  => $upstream_repo_id,
    } );

    my $hosting_api = $scm_upstream->get_hosting_api;

    my $create_res = $hosting_api->create_repo( $upstream_repo_id, is_private => $self->{is_private}, scm => $self->{upstream_scm_type} );

    say $create_res;

    return $create_res if !$create_res;

    # clone repo
    my $clone_uri = $scm_upstream->get_clone_url( $SCM_URL_TYPE_SSH, $self->{local_scm_type} );

    print qq[Cloning upstream repository "$clone_uri" ... ];

    my $clone_res = Pcore::API::SCM->scm_clone( $clone_uri, $self->target_path, $self->{local_scm_type} );

    say $clone_res;

    return $clone_res;
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
