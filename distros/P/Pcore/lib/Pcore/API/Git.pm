package Pcore::API::Git;

use Pcore -class, -res, -const, -export;
use Pcore::Util::Scalar qw[is_plain_arrayref];

has root        => ( required => 1 );
has max_threads => 50;

has upstream => ( is => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::API::Git::Upstream'] ]

our $EXPORT = {
    GIT_UPSTREAM_URL => [qw[$GIT_UPSTREAM_URL_LOCAL $GIT_UPSTREAM_URL_HTTPS $GIT_UPSTREAM_URL_SSH]],
    GIT_UPSTREAM     => [qw[$GIT_UPSTREAM_HOST $GIT_UPSTREAM_NAME $GIT_UPSTREAM_BITBUCKET $GIT_UPSTREAM_GITHUB $GIT_UPSTREAM_GITLAB]],
};

const our $GIT_UPSTREAM_URL_LOCAL => 1;
const our $GIT_UPSTREAM_URL_HTTPS => 2;
const our $GIT_UPSTREAM_URL_SSH   => 3;

const our $GIT_UPSTREAM_BITBUCKET => 'bitbucket';
const our $GIT_UPSTREAM_GITHUB    => 'github';
const our $GIT_UPSTREAM_GITLAB    => 'gitlab';

const our $GIT_UPSTREAM_HOST => {
    $GIT_UPSTREAM_BITBUCKET => 'bitbucket.org',
    $GIT_UPSTREAM_GITHUB    => 'github.com',
    $GIT_UPSTREAM_GITLAB    => 'gitlab.com',
};

const our $GIT_UPSTREAM_NAME => { map { $GIT_UPSTREAM_HOST->{$_} => $_ } keys $GIT_UPSTREAM_HOST->%* };

around new => sub ( $orig, $self, $path = undef, $search = undef ) {
    return $self->$orig( { root => $path } ) if !defined $path;

    $path = P->path($path)->to_abs;

    my $found;

    if ( -d "$path/.git" ) {
        $found = 1;
    }
    elsif ($search) {
        $path = $path->parent;

        while ($path) {
            if ( -d "$path/.git" ) {
                $found = 1;

                last;
            }

            $path = $path->parent;
        }
    }

    return $self->$orig( { root => $path } ) if $found;

    return;
};

sub _build_upstream ($self) {
    require Pcore::API::Git::Upstream;

    my $url = $self->git_run('ls-remote --get-url');

    return if !$url || !$url->{data};

    chomp $url->{data};

    return Pcore::API::Git::Upstream->new( { url => $url->{data} } ) if $url && $url->{data};

    return;
}

sub git_run ( $self, $cmd, $root = undef ) {
    $root = $self->{root} if @_ == 2;    # use default value if root arg is not exists

    my $proc = P->sys->run_proc(
        [ is_plain_arrayref $cmd ? ( 'git', ( defined $root ? ( '-C', $root ) : () ), $cmd->@* ) : 'git ' . ( defined $root ? qq[-C "$root" ] : $EMPTY ) . $cmd ],
        use_fh => 1,
        stdout => 1,
        stderr => 1,
    );

    $proc->capture;

    my $res;

    if ( $proc->is_success ) {
        $res = res 200, $proc->{stdout} ? $proc->{stdout}->$* : undef;
    }
    else {
        $res = res [ 500, $proc->{stderr} ? $proc->{stderr}->$* : $EMPTY ];
    }

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Git

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
