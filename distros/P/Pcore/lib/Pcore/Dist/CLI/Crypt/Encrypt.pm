package Pcore::Dist::CLI::Crypt::Encrypt;

use Pcore -class, -ansi;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'Encrypt perl files',
        opt      => {
            force     => { desc => 'skip prompt', },
            recursive => { desc => 'recursive', },
        },
        arg => [
            path => {
                desc => 'path to the root directory to encrypt perl files recursively',
                isa  => 'Path',
                min  => 0,
                max  => 1,
            },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    if ( !$opt->{force} ) {
        my $confirm = P->term->prompt( qq[WARNING!!! This operation is not reversible? Are you sure to continue?], [qw[yes no]], enter => 1 );

        return if $confirm eq 'no';
    }

    my $root = $arg->{path} ? P->path( $arg->{path} ) : $self->get_dist->{root};

    if ( -f $root ) {
        $self->_process_file($root);
    }
    elsif ( -d $root ) {
        for my $path ( $root->read_dir( max_depth => $opt->{recursive} ? 0 : 1, abs => 1, is_dir => 0 )->@* ) {
            $self->_process_file($path);
        }
    }
    else {
        say qq[Can't open "$root".];
    }

    return;
}

sub _process_file ( $self, $path ) {
    if ( $path->mime_has_tag( 'perl', 1 ) && !$path->mime_has_tag( 'perl-cpanfile', 1 ) ) {
        my $res = P->src->compress(
            path   => $path,
            filter => {
                perl_compress_keep_ln => 1,
                perl_strip_comment    => 1,
                perl_strip_pod        => 1,
                perl_encrypt          => 1,
            }
        );

        die qq[Can't encrypt "$path", $res] if !$res;
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

Pcore::Dist::CLI::Crypt::Encrypt - encrypt perl files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
