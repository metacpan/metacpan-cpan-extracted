package Pcore::Dist::Build::Create;

use Pcore -class, -res;
use Pcore::Dist;
use Pcore::Lib::File::Tree;
use Pcore::API::Git qw[:ALL];
use Pcore::API::Git::Upstream;

has base_path      => ( required => 1 );    # Str
has dist_namespace => ( required => 1 );    # Str, Dist::Name
has dist_name      => ( required => 1 );    # Str, Dist-Name
has tmpl           => ( required => 1 );    # Str, Dist-Name

has upstream_hosting        => $GIT_UPSTREAM_BITBUCKET;    # Enum [ $GIT_UPSTREAM_BITBUCKET, $GIT_UPSTREAM_GITHUB, $GIT_UPSTREAM_GITLAB ]
has is_private              => 0;                          # Bool
has upstream_repo_namespace => ();                         # Maybe [Str]

has target_path => ( is => 'lazy', init_arg => undef );    # Str
has tmpl_params => ( is => 'lazy', init_arg => undef );    # HashRef

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

    # add git files
    if ( $self->{upstream_hosting} ) {
        $files->add_dir( $ENV->{share}->get_location('/Pcore/dist-tmpl') . '/git' );
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
    my $upstream_repo_namespace = $self->{upstream_repo_namespace} // do {
        if ( $self->{upstream_hosting} eq $GIT_UPSTREAM_BITBUCKET ) {
            $ENV->user_cfg->{BITBUCKET}->{default_repo_namespace};
        }
        elsif ( $self->{upstream_hosting} eq $GIT_UPSTREAM_GITHUB ) {
            $ENV->user_cfg->{GITHUB}->{default_repo_namespace};
        }
        elsif ( $self->{upstream_hosting} eq $GIT_UPSTREAM_GITLAB ) {
            $ENV->user_cfg->{GITLAB}->{default_repo_namespace};
        }
    };

    my $upstream_repo_id = "$upstream_repo_namespace/" . lc $self->{dist_name};

    my $confirm = P->term->prompt( qq[Create upstream repository "$upstream_repo_id" on $self->{upstream_hosting}?], [qw[yes no exit]], enter => 1 );

    if ( $confirm eq 'no' ) {
        return res 200;
    }
    elsif ( $confirm eq 'exit' ) {
        return res [ 500, 'Creating upstream repository cancelled' ];
    }

    print 'Creating upstream repository ... ';

    my $upstream = Pcore::API::Git::Upstream->new( {
        hosting => $self->{upstream_hosting},
        repo_id => $upstream_repo_id,
    } );

    my $hosting_api = $upstream->get_hosting_api;

    my $create_res = $hosting_api->create_repo( $upstream_repo_id, is_private => $self->{is_private} );

    say $create_res;

    return $create_res if !$create_res;

    # clone repo
    my $clone_uri = $upstream->get_clone_url($GIT_UPSTREAM_URL_SSH);

    print qq[Cloning upstream repository "$clone_uri" ... ];

    my $res = Pcore::API::Git->git_run_no_root( [ 'clone', $clone_uri, $self->target_path ] );

    say $res;

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 95                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
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
