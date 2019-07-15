package Pcore::Dist::Build::Create;

use Pcore -class, -res;
use Pcore::Dist;
use Pcore::Lib::File::Tree;
use Pcore::API::SCM::Const qw[:ALL];
use Pcore::API::SCM;
use Pcore::API::SCM::Upstream;

has base_path      => ( required => 1 );    # Str
has dist_namespace => ( required => 1 );    # Str, Dist::Name
has dist_name      => ( required => 1 );    # Str, Dist-Name
has tmpl           => ( required => 1 );    # Str, Dist-Name

has upstream_hosting        => $SCM_HOSTING_BITBUCKET;    # Enum [ $SCM_HOSTING_BITBUCKET, $SCM_HOSTING_GITHUB ]
has is_private              => 0;                         # Bool
has upstream_scm_type       => $SCM_TYPE_HG;              # Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ]
has local_scm_type          => $SCM_TYPE_HG;              # Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ]
has upstream_repo_namespace => ();                        # Maybe [Str]

has target_path => ( is => 'lazy', init_arg => undef );   # Str
has tmpl_params => ( is => 'lazy', init_arg => undef );   # HashRef

sub BUILDARGS ( $self, $args ) {
    $args->{dist_namespace} =~ s/-/::/smg;
    $args->{dist_name} = $args->{dist_namespace} =~ s/::/-/smgr;

    return $args;
}

sub _build_target_path ($self) {
    return P->path( $self->{base_path} )->to_abs . '/' . lc $self->{dist_name};
}

sub _build_tmpl_params ($self) {
    return {
        dist_name               => $self->{dist_name},                                               # Package-Name
        dist_path               => lc $self->{dist_name},                                            # package-name
        module_name             => $self->{dist_namespace},                                          # Package::Name
        author                  => $ENV->user_cfg->{author},
        author_email            => $ENV->user_cfg->{email},
        copyright_year          => P->date->now->year,
        copyright_holder        => $ENV->user_cfg->{copyright_holder} || $ENV->user_cfg->{author},
        license                 => $ENV->user_cfg->{license},
        pcore_version           => $ENV->{pcore}->version->normal,
        cpan_distribution       => 0,
        dockerhub_pcore_repo_id => $ENV->{pcore}->docker->{repo_id},
    };
}

sub run ($self) {
    if ( -e $self->target_path ) {
        my $res = res [ 500, 'Target path already exists' ];

        say $res;

        return $res;
    }

    # create upstream repo
    if ( $self->{upstream_hosting} ) {
        my $res = $self->_create_upstream_repo;

        return $res if !$res;
    }

    # copy files
    my $files = Pcore::Lib::File::Tree->new;

    my $tmpl_cfg = $ENV->{share}->read_cfg('/Pcore/dist-tmpl/cfg.ini');

    my $tmpl_params = $self->tmpl_params;

    my $add_dir = sub ($name) {
        if ( my $parent = $tmpl_cfg->{$name}->{parent} ) {
            __SUB__->($parent);
        }

        my $tmpl_path = $ENV->{share}->get_location('/Pcore/dist-tmpl') . "/tmpl-$name/";

        $files->add_dir($tmpl_path) if -d $tmpl_path;

        $tmpl_params->{cpan_distribution} = $tmpl_cfg->{$name}->{cpan} if defined $tmpl_cfg->{$name}->{cpan};

        return;
    };

    $add_dir->( $self->{tmpl} );

    # add SCM files
    if ( $self->{upstream_hosting} ) {
        if ( $self->{local_scm_type} eq $SCM_TYPE_HG ) {
            $files->add_dir( $ENV->{share}->get_location('/Pcore/dist-tmpl') . '/hg/' );
        }
        elsif ( $self->{local_scm_type} eq $SCM_TYPE_GIT ) {
            $files->add_dir( $ENV->{share}->get_location('Pcore/dist-tmpl') . '/git/' );
        }
    }

    $files->move_tree( '\Alib/__dist_path__', 'lib/' . $self->{dist_name} =~ s[-][/]smgr );

    # rename dist cfg template
    $files->move_file( "share/_dist_.yaml", "share/dist.yaml" );

    $files->render_tmpl($tmpl_params);

    $files->write_to( $self->target_path );

    my $dist = Pcore::Dist->new( $self->target_path );

    # update dist after create
    $dist->build->update;

    return res 200;
}

sub _create_upstream_repo ($self) {
    my $upstream_repo_namespace = $self->{upstream_repo_namespace} // ( $self->{upstream_hosting} eq $SCM_HOSTING_BITBUCKET ? $ENV->user_cfg->{BITBUCKET}->{default_repo_namespace} : $ENV->user_cfg->{GITHUB}->{default_repo_namespace} );

    my $upstream_repo_id = "$upstream_repo_namespace/" . lc $self->{dist_name};

    my $confirm = P->term->prompt( qq[Create upstream $self->{upstream_scm_type} repository "$upstream_repo_id" on $self->{upstream_hosting}?], [qw[yes no exit]], enter => 1 );

    if ( $confirm eq 'no' ) {
        return res 200;
    }
    elsif ( $confirm eq 'exit' ) {
        return res [ 500, 'Creating upstream repository cancelled' ];
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

    my $clone_res = Pcore::API::SCM->scm_clone( $clone_uri, root => $self->target_path, type => $self->{local_scm_type} );

    say $clone_res;

    return $clone_res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 103                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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
