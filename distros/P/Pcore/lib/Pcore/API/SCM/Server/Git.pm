package Pcore::API::SCM::Server::Git;

use Pcore -class, -result;
use Pcore::API::SCM qw[:CONST];
use Pcore::API::SCM::Upstream;

with qw[Pcore::API::SCM::Server];

sub scm_upstream ( $self, $root ) {
    if ( -f "$root/.git/config" ) {
        my $config = P->file->read_text("$root/.git/config");

        return Pcore::API::SCM::Upstream->new( { uri => $1, local_scm_type => $SCM_TYPE_GIT } ) if $config->$* =~ /\s*url\s*=\s*(.+?)$/sm;
    }

    return;
}

sub scm_cmd ( $self, $root, $cb, $cmd ) {
    my $chdir_guard = $root ? P->file->chdir($root) : undef;

    my @cmd = ( 'git', $cmd->@* );

    # git clone does not support --porcelain -z options
    push @cmd, qw[--porcelain -z] if $cmd->[0] ne 'clone';

    P->pm->run_proc(
        \@cmd,
        stdout    => 1,
        stderr    => 1,
        on_finish => sub ($proc) {
            my $api_res;

            if ( $proc->is_success ) {
                $api_res = result 200, $proc->stdout ? [ split /\x00/sm, $proc->stdout ] : undef;
            }
            else {
                $api_res = result [ 500, $proc->stderr ? ( $proc->stderr =~ /\A(.+?)\n/sm )[0] : () ];
            }

            $cb->($api_res);

            return;
        }
    );

    return;
}

sub scm_id ( $self, $root, $cb, $args ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_init ( $self, $root, $cb, $args = undef ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_clone ( $self, $root, $cb, $args ) {
    my ( $path, $uri, %args ) = $args->@*;

    my @cmd = qw[clone];

    push @cmd, $uri, $path;

    $self->scm_cmd( undef, $cb, \@cmd );

    return;
}

sub scm_releases ( $self, $root, $cb, $args ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_is_commited ( $self, $root, $cb, $args ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_addremove ( $self, $root, $cb, $args ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_commit ( $self, $root, $cb, $args ) {
    my $message = $args->[0];

    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_push ( $self, $root, $cb, $args ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_set_tag ( $self, $root, $cb, $args ) {
    my ( $tag, %args ) = $args->@*;

    $tag = [$tag] if !ref $tag;

    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

sub scm_get_changesets ( $self, $tag, $cb ) {
    ...;    ## no critic qw[ControlStructures::ProhibitYadaOperator]
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM::Server::Git

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
