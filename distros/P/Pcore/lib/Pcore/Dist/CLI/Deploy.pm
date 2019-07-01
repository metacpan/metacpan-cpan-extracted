package Pcore::Dist::CLI::Deploy;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'deploy distribution',
        opt      => {
            all        => { desc => 'implies --devel, --recommends and --suggeests', },
            install    => { desc => 'install "bin" to $PATH and "lib" to $PERL5LIB', },
            devel      => { desc => 'cpanm --with-develop', },
            recommends => { desc => 'cpanm --with-recommends', },
            suggests   => { desc => 'cpanm --with-suggests', },
            verbose    => { desc => 'cpanm --verbose', },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    $dist->build->deploy( $opt->%* );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 12                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Deploy - deploy distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
