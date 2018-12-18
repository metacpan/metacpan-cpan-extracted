package Pcore::API::SCM;

use Pcore -const, -role, -res;
use Pcore::API::SCM::Const qw[:ALL];
use Pcore::API::SCM::Upstream;
use Pcore::Util::Scalar qw[is_callback];

requires qw[
  _build_upstream
  scm_cmd
  scm_init
  scm_clone
  scm_update
  scm_id
  scm_releases
  scm_is_commited
  scm_addremove
  scm_commit
  scm_push
  scm_set_tag
  scm_get_changesets
];

has root     => ( required => 1 );
has upstream => ( is       => 'lazy' );    # InstanceOf ['Pcore::API::SCM::Upstream'] ]

const our $SCM_TYPE_CLASS => {
    $SCM_TYPE_HG  => 'Pcore::API::SCM::Hg',
    $SCM_TYPE_GIT => 'Pcore::API::SCM::Git',
};

sub new ( $self, $path ) {
    $path = P->path($path)->to_abs;

    my $class;

    if ( -d "$path/.hg" ) {
        $class = $SCM_TYPE_CLASS->{$SCM_TYPE_HG};
    }
    elsif ( -d "$path/.git" ) {
        $class = $SCM_TYPE_CLASS->{$SCM_TYPE_GIT};
    }
    else {
        $path = $path->parent;

        while ($path) {
            if ( -d "$path/.hg" ) {
                $class = $SCM_TYPE_CLASS->{$SCM_TYPE_HG};

                last;
            }
            elsif ( -d "$path/.git" ) {
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

sub scm_clone ( $self, $uri, @args ) {
    my $cb = is_callback $args[-1] ? pop @args : ();

    my %args = (
        type => $SCM_TYPE_HG,
        root => undef,
        @args,
    );

    # can't clone to existing directory
    if ( defined $args{root} && -e $args{root} ) {
        my $res = res [ 500, 'Clone target directory is already exists' ];

        $res = $cb->($res) if $cb;

        return $res;
    }

    my $temp = P->file1->tempdir;

    my $repo;

    if ( defined $args{root} ) {
        $repo = P->class->load( $SCM_TYPE_CLASS->{ $args{type} } )->new( { root => $args{root} } );
    }
    else {
        $repo = P->class->load( $SCM_TYPE_CLASS->{ $args{type} } )->new( { root => $temp } );
    }

    return $repo->scm_clone(
        $temp, $uri,
        sub ($res) {
            if ($res) {
                if ( defined $args{root} ) {
                    P->file->move( $temp, $args{root} );

                    $res->{root} = $args{root};
                }
                else {
                    $res->{root} = $temp;
                }
            }

            return $cb ? $cb->($res) : $res;
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
## |    3 | 69                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
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
