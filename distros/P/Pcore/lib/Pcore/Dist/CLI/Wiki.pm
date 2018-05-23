package Pcore::Dist::CLI::Wiki;

use Pcore -class;
use Pcore::API::SCM::Const qw[:ALL];

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return { abstract => 'generate wiki pages', };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    if ( !-d $dist->root . 'wiki/' ) {
        my $confirm = P->term->prompt( qq[Wiki wasn't found. Clone upstream wiki?], [qw[yes no]], enter => 1 );

        exit 3 if $confirm eq 'no';

        exit 3 if !$self->_clone_upstream_wiki($dist);
    }

    $dist->build->wiki->run;

    return;
}

sub _clone_upstream_wiki ( $self, $dist ) {
    if ( !$dist->scm || !$dist->scm->upstream ) {
        say q[SCM wasn't found];

        return;
    }

    my $clone_uri = $dist->scm->upstream->get_wiki_clone_url;

    print qq[Cloning upstream wiki "$clone_uri" ... ];

    my $res = Pcore::API::SCM->scm_clone( $clone_uri, $dist->root . '/wiki/', $SCM_TYPE_HG );

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
## |    3 | 16                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
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
