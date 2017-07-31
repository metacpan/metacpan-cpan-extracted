package Pcore::API::SCM;

use Pcore -const, -role;
use Pcore::API::SCM::Const qw[:ALL];
use Pcore::API::SCM::Upstream;

requires qw[_build_upstream scm_cmd scm_init scm_clone scm_id scm_releases scm_is_commited scm_addremove scm_commit scm_push scm_set_tag scm_get_changesets];

has root => ( is => 'ro', isa => Str, required => 1 );
has upstream => ( is => 'lazy', isa => Maybe [ InstanceOf ['Pcore::API::SCM::Upstream'] ], init_arg => undef );

const our $SCM_TYPE_CLASS => {
    $SCM_TYPE_HG  => 'Pcore::API::SCM::Hg',
    $SCM_TYPE_GIT => 'Pcore::API::SCM::Git',
};

sub new ( $self, $path ) {
    $path = P->path( $path, is_dir => 1 )->realpath;

    my $class;

    if ( -d "$path/.hg/" ) {
        $class = $SCM_TYPE_CLASS->{$SCM_TYPE_HG};
    }
    elsif ( -d "$path/.git/" ) {
        $class = $SCM_TYPE_CLASS->{$SCM_TYPE_GIT};
    }
    else {
        $path = $path->parent;

        while ($path) {
            if ( -d "$path/.hg/" ) {
                $class = $SCM_TYPE_CLASS->{$SCM_TYPE_HG};

                last;
            }
            elsif ( -d "$path/.git/" ) {
                $class = $SCM_TYPE_CLASS->{$SCM_TYPE_GIT};

                last;
            }

            $path = $path->parent;
        }
    }

    if ($class) {
        return P->class->load($class)->new( { root => $path->to_string } );
    }

    return;
}

sub scm_init ( $self, $root, $scm_type = $SCM_TYPE_HG, $cb = undef ) {
    $self = P->class->load( $SCM_TYPE_CLASS->{$scm_type} )->new( { root => $root } );

    return $self->scm_init( $root, $cb );
}

sub scm_clone ( $self, $uri, $root, $scm_type = $SCM_TYPE_HG, $cb = undef ) {

    # can't clone to existing directory
    if ( -d $root ) {
        $cb->(undef) if $cb;

        return;
    }

    $self = P->class->load( $SCM_TYPE_CLASS->{$scm_type} )->new( { root => $root } );

    my $temp = P->file->tempdir;

    return $self->scm_clone(
        $temp->path,
        $uri,
        sub ($res) {
            P->file->move( $temp->path, $root ) if $res;

            $cb->($res) if $cb;

            return;
        }
    );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 54, 60               | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
