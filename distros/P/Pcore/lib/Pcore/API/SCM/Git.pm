package Pcore::API::SCM::Git;

use Pcore -class, -result;
use Pcore::API::SCM::Const qw[:SCM_TYPE];
use Pcore::Util::Scalar qw[is_plain_arrayref];

with qw[Pcore::API::SCM];

sub _build_upstream ($self) {
    if ( -f "$self->{root}/.git/config" ) {
        my $config = P->file->read_text("$self->{root}/.git/config");

        return Pcore::API::SCM::Upstream->new( { uri => $1, local_scm_type => $SCM_TYPE_GIT } ) if $config->$* =~ /\s*url\s*=\s*(.+?)$/sm;
    }

    return;
}

sub _scm_cmd ( $self, $cmd, $root = undef, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my $chdir_guard = $root ? P->file->chdir( $self->{root} ) : undef;

    my @cmd = ( 'git', $cmd->@* );

    # git "clone" and "init" does not support --porcelain -z options
    push @cmd, qw[--porcelain -z] if $cmd->[0] ne 'init' && $cmd->[0] ne 'clone';

    P->pm->run_proc(
        \@cmd,
        stdout    => 1,
        stderr    => 1,
        on_finish => sub ($proc) {
            my $res;

            if ( $proc->is_success ) {
                $res = result 200, $proc->stdout ? [ split /\x00/sm, $proc->stdout ] : undef;
            }
            else {
                $res = result [ 500, $proc->stderr ? ( $proc->stderr =~ /\A(.+?)\n/sm )[0] : () ];
            }

            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub scm_cmd ( $self, $cmd, $cb = undef ) {
    return $self->_scm_cmd( $cmd, $self->{root}, $cb );
}

sub scm_init ( $self, $root, $cb = undef ) {
    return $self->_scm_cmd( [ 'init', $root ], undef, $cb );
}

sub scm_clone ( $self, $root, $uri, $cb = undef ) {
    return $self->_scm_cmd( [ 'clone', $uri, $root ], undef, $cb );
}

sub scm_id ( $self, $cb = undef ) {
    ...;

    return;
}

sub scm_releases ( $self, $cb = undef ) {
    ...;

    return;
}

sub scm_is_commited ( $self, $cb = undef ) {
    ...;

    return;
}

sub scm_addremove ( $self, $cb = undef ) {
    ...;

    return;
}

sub scm_commit ( $self, $msg, $args = undef, $cb = undef ) {
    ...;

    return;
}

sub scm_push ( $self, $cb = undef ) {
    ...;

    return;
}

sub scm_set_tag ( $self, $tags, $force = undef, $cb = undef ) {
    ...;

    return;
}

sub scm_get_changesets ( $self, $tag = undef, $cb = undef ) {
    ...;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 67, 73, 79, 85, 91,  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |      | 97, 103, 109         |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM::Git

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
