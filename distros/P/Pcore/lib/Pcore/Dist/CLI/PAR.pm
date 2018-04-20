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
    my $dist = $self->get_dist;

    if ( !$dist->par_cfg ) {
        if ( P->term->prompt( qq[Create PAR profile?], [qw[yes no]], enter => 1 ) eq 'yes' ) {
            require Pcore::Util::File::Tree;

            # copy files
            my $files = Pcore::Util::File::Tree->new;

            $files->add_dir( $ENV->{share}->get_storage( 'Pcore', 'dist-tmpl' ) . '/par/' );

            $files->render_tmpl( { main_script => 'main.pl' } );

            $files->write_to( $dist->root );

            say q[PAR profile was created. You should edit "par.ini" manually.];
        }

        return;
    }
    else {
        $dist->build->par( $opt->%* );

        return;
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 27                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
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
