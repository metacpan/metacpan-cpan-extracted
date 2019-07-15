package Pcore::Dist::CLI::PAR;

use Pcore -class;

extends qw[Pcore::Dist::CLI];

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
            force => {
                desc    => 'do not check for uncommited changes',
                default => 0,
            },
        },
        arg => [
            script => {
                min => 0,
                max => 0,
            },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $dist = $self->get_dist;

    if ( !$dist->par_cfg ) {
        if ( P->term->prompt( q[Create PAR profile?], [qw[yes no]], enter => 1 ) eq 'yes' ) {
            require Pcore::Lib::File::Tree;

            # copy files
            my $files = Pcore::Lib::File::Tree->new;

            $files->add_dir( $ENV->{share}->get_location('/Pcore/dist-tmpl') . '/par/' );

            $files->render_tmpl( { main_script => 'main.pl' } );

            $files->write_to( $dist->{root} );

            say q[PAR profile was created. You should edit "par.yaml" manually.];
        }

        return;
    }
    else {
        $dist->build->par( $opt->%*, script => $arg->{script} );

        return;
    }

    return;
}

1;
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
