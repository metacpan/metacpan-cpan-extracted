package Pcore::Dist::CLI::Create;

use Pcore -class;
use Pcore::Dist;
use Pcore::API::SCM::Const qw[:ALL];

with qw[Pcore::Core::CLI::Cmd];

# CLI
sub CLI ($self) {
    my $tmpl_cfg = P->cfg->load( $ENV->share->get( 'cfg.ini', storage => 'dist-tmpl', lib => 'Pcore' ) );

    return {
        abstract => 'create new distribution',
        name     => 'new',
        opt      => {
            tmpl => {
                desc => 'template name:' . $LF . join( $LF, map {"\t\t$_\t$tmpl_cfg->{$_}->{desc}"} keys $tmpl_cfg->%* ),
                isa  => [ keys $tmpl_cfg->%* ],
                min  => 1,
            },
            hosting => {
                short   => 'H',
                desc    => qq[define hosting for upstream repository. Possible values: "$SCM_HOSTING_BITBUCKET", "$SCM_HOSTING_GITHUB"],
                isa     => [ $SCM_HOSTING_BITBUCKET, $SCM_HOSTING_GITHUB ],
                default => $SCM_HOSTING_BITBUCKET,
            },
            private => {
                desc    => 'create private upstream repository',
                default => 0,
            },
            scm => {
                short   => 'S',
                desc    => qq[upstream repository SCM type. Applied only for "bitbucket". Possible values: "$SCM_TYPE_HG", "$SCM_TYPE_GIT"],
                isa     => [ $SCM_TYPE_HG, $SCM_TYPE_GIT ],
                default => $SCM_TYPE_HG,
            },
            namespace => {
                short => 'N',
                desc  => 'upstream repository namespace',
                isa   => 'Str',
            },
            local_scm => {
                short   => 's',
                desc    => qq[local repository SCM type. Applied only if remote SCM is "git". Possible values: "$SCM_TYPE_HG", "$SCM_TYPE_GIT"],
                isa     => [ $SCM_TYPE_HG, $SCM_TYPE_GIT ],
                default => $SCM_TYPE_HG,
            },
        },
        arg => [    #
            dist_namespace => { type => 'Str', },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    require Pcore::Dist::Build;

    my $status = Pcore::Dist::Build->new->create( {
        base_path               => $ENV->{START_DIR},
        dist_namespace          => $arg->{dist_namespace},
        tmpl                    => $opt->{tmpl},
        upstream_hosting        => $opt->{hosting},
        is_private              => $opt->{private},
        upstream_scm_type       => $opt->{scm},
        local_scm_type          => $opt->{local_scm},
        upstream_repo_namespace => $opt->{namespace},
    } );

    exit 3 if !$status;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Create - create new distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
