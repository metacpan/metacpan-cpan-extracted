package Pcore::Core::Inline;

use Pcore;

if ( $ENV->{is_par} ) {
    $INC{'Inline.pm'} = $INC{'Pcore/Core/Inline.pm'};    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    state $init = !!require XSLoader;

    *Inline::import = sub {
        my $caller = caller;

        XSLoader::load $caller;

        return;
    };
}
else {
    state $init = !!require Inline;

    Inline->import(
        config => (
            directory         => $ENV->{INLINE_DIR},
            autoname          => 0,
            clean_after_build => 1,
            clean_build_area  => 1,
        )
    );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 43                   | Documentation::RequirePodLinksIncludeText - Link L<Inline> on line 59 does not specify text                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Inline - Pcore Inline wrapper

=head1 SYNOPSIS

=head1 DESCRIPTION

Inline wrapper provides centralized configuration and PAR compatibility layer.

=head1 SEE ALSO

L<Inline>

=cut
