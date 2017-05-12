package Pcore::Dist::CLI::Wiki;

use Pcore -class;
use Pcore::API::SCM qw[:CONST];

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'generate wiki pages', };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    $self->new->run($opt);

    return;
}

sub run ( $self, $args ) {
    if ( !-d $self->dist->root . 'wiki/' ) {
        my $confirm = P->term->prompt( qq[Wiki wasn't found. Clone upstream wiki?], [qw[yes no]], enter => 1 );

        exit 3 if $confirm eq 'no';

        exit 3 if !$self->_clone_upstream_wiki;
    }

    $self->dist->build->wiki->run;

    return;
}

sub _clone_upstream_wiki ($self) {
    if ( !$self->dist->scm ) {
        say q[SCM wasn't found];

        return;
    }
    elsif ( !$self->dist->scm->upstream || !$self->dist->scm->upstream->hosting_api_class ) {
        say q[Invalid SCM upstream];

        return;
    }

    my $upstream = $self->dist->scm->upstream;

    my $upstream_api = $upstream->hosting_api;

    my $clone_uri;

    if ( $upstream->local_scm_type == $SCM_TYPE_HG ) {
        if   ( $upstream->remote_scm_type == $SCM_TYPE_HG ) { $clone_uri = $upstream_api->clone_uri_wiki_ssh }
        else                                                { $clone_uri = $upstream_api->clone_uri_wiki_ssh_hggit }
    }
    else {
        $clone_uri = $upstream_api->clone_uri_wiki_ssh;
    }

    print qq[Cloning upstream wiki "$clone_uri" ... ];

    if ( my $res = Pcore::API::SCM->scm_clone( $self->dist->root . '/wiki/', $clone_uri, update => 'tip' ) ) {
        say 'done';

        return 1;
    }
    else {
        say $res->reason;

        return;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 20                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 27, 38               | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Wiki - generate wiki pages

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
