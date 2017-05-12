package Pcore::API::SCM;

use Pcore -const, -class, -export => { CONST => [qw[$SCM_TYPE_HG $SCM_TYPE_GIT]] };

const our $SCM_TYPE_HG  => 1;
const our $SCM_TYPE_GIT => 2;

require Pcore::API::SCM::Upstream;

has type => ( is => 'ro', isa => Enum [ $SCM_TYPE_HG, $SCM_TYPE_GIT ], required => 1 );
has root => ( is => 'ro', isa => Str, required => 1 );

has upstream => ( is => 'lazy', isa => Maybe [Object], init_arg => undef );
has server => ( is => 'lazy', isa => ConsumerOf ['Pcore::API::SCM::Server'], init_arg => undef );

around new => sub ( $orig, $self, $path ) {
    $path = P->path( $path, is_dir => 1 )->realpath;

    my $type;

    if ( -d "$path/.hg/" ) {
        $type = $SCM_TYPE_HG;
    }
    elsif ( -d "$path/.git/" ) {
        $type = $SCM_TYPE_GIT;
    }
    else {
        $path = $path->parent;

        while ($path) {
            if ( -d "$path/.hg/" ) {
                $type = $SCM_TYPE_HG;

                last;
            }
            elsif ( -d "$path/.git/" ) {
                $type = $SCM_TYPE_GIT;

                last;
            }

            $path = $path->parent;
        }
    }

    if ($type) {
        return $self->$orig( { type => $type, root => $path->to_string } );
    }

    return;
};

# SCM INIT
sub scm_init ( $self, $root, $type = $SCM_TYPE_HG, $cb = undef ) {
    my $server = $self->_get_server($type);

    if ( !$server ) {
        return;
    }
    else {
        my $blocking_cv = defined wantarray ? AE::cv : undef;

        $server->scm_init(
            $root,
            sub ($res) {
                if ( $res->is_success ) {
                    $res = $self->new($root);
                }
                else {
                    undef $res;
                }

                $cb->($res) if $cb;

                $blocking_cv->($res) if $blocking_cv;

                return;
            }
        );

        return $blocking_cv ? $blocking_cv->recv : ();
    }
}

# SCM CLONE
sub scm_clone ( $self, $root, $uri, @args ) {
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : undef;

    # can't clone to existed directory
    if ( -d $root ) {
        $cb->(undef) if $cb;

        return;
    }

    my $upstream = Pcore::API::SCM::Upstream->new( { uri => $uri } );

    my $server = $self->_get_server( $upstream->local_scm_type );

    my $temp = P->file->tempdir;

    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $server->scm_clone(
        $root,
        sub ($res) {
            if ( $res->is_success ) {
                P->file->move( $temp->path, $root );

                $res = $self->new($root);
            }
            else {
                undef $root;
            }

            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        },
        [ $temp->path, $uri, @args, ]
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub _get_server ( $self, $type ) {
    if ( $type == $SCM_TYPE_HG ) {
        require Pcore::API::SCM::Server::Hg;

        return Pcore::API::SCM::Server::Hg->new;
    }
    elsif ( $type == $SCM_TYPE_GIT ) {
        require Pcore::API::SCM::Server::Git;

        return Pcore::API::SCM::Server::Git->new;
    }

    return;
}

sub _build_server ($self) {
    return $self->_get_server( $self->type );
}

sub _build_upstream ($self) {
    return $self->server->scm_upstream( $self->root );
}

sub scm_cmd ( $self, @cmd ) {
    return $self->_request( 'scm_cmd', [@cmd] );
}

sub scm_id ( $self, $cb = undef ) {
    return $self->_request( 'scm_id', [$cb] );
}

sub scm_releases ( $self, $cb = undef ) {
    return $self->_request( 'scm_releases', [$cb] );
}

sub scm_is_commited ( $self, $cb = undef ) {
    return $self->_request( 'scm_is_commited', [$cb] );
}

sub scm_addremove ( $self, $cb = undef ) {
    return $self->_request( 'scm_addremove', [$cb] );
}

sub scm_commit ( $self, $message, @args ) {
    return $self->_request( 'scm_commit', [ $message, @args ] );
}

sub scm_push ( $self, $cb = undef ) {
    return $self->_request( 'scm_push', [$cb] );
}

sub scm_set_tag ( $self, $tag, @ ) {
    return $self->_request( 'scm_set_tag', [ splice @_, 1 ] );
}

sub _request ( $self, $method, $args ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my $cb = ref $args->[-1] eq 'CODE' ? pop $args->@* : undef;

    $self->server->$method(
        $self->root,
        sub ($res) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        },
        $args
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 54                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
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
