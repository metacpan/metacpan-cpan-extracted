package Pcore::Dist::CLI::PAR;

use Pcore -class;

with qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'build PAR executable',
        opt      => {
            crypt => {
                desc    => 'crypt non-core perl sources with Filter::Crypto',
                negated => 1,
            },
            clean => {
                desc    => 'clean temp dir on exit',
                negated => 1,
            },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    $self->new->run($opt);

    return;
}

sub run ( $self, $opt ) {
    if ( !$self->dist->par_cfg ) {
        if ( P->term->prompt( qq[Create PAR profile?], [qw[yes no]], enter => 1 ) eq 'yes' ) {
            require Pcore::Util::File::Tree;

            # copy files
            my $files = Pcore::Util::File::Tree->new;

            $files->add_dir( $ENV->share->get_storage( 'pcore', 'Pcore' ) . '/par/' );

            $files->render_tmpl(
                {   main_script => 'main.pl',    #
                }
            );

            $files->write_to( $self->dist->root );

            say q[PAR profile was created. You should edit "par.perl" manually.];
        }

        return;
    }
    else {
        $self->dist->build->par( $opt->%* );

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
## |    3 | 31                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::PAR - build PAR executable

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
