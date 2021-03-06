package Pcore::Dist::CLI::Crypt::Encrypt;

use Pcore -class, -ansi;
use Package::Stash::XS qw[];

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'Encrypt perl files',
        opt      => {
            force     => { desc => 'skip prompt', },
            recursive => { desc => 'recursive', },
            protect   => { desc => 'remove Filter::Crypto::CryptFile from the perl distribution' },
            verbose   => { desc => 'verbose output' },
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
        my $confirm = P->term->prompt( q[WARNING!!! This operation is not reversible? Are you sure to continue?], [qw[yes no]], enter => 1 );

        return if $confirm eq 'no';
    }

    my $root = $arg->{path} ? P->path( $arg->{path} ) : $self->get_dist->{root};

    if ( -f $root ) {
        $self->_process_file( $root, $opt->{verbose} );
    }
    elsif ( -d $root ) {
        for my $path ( $root->read_dir( max_depth => $opt->{recursive} ? 0 : 1, abs => 1, is_dir => 0 )->@* ) {
            $self->_process_file( $path, $opt->{verbose} );
        }
    }
    else {
        say qq[Can't open "$root".];

        exit 3;
    }

    say 'ENCRYPTED' if $opt->{verbose};

    # allow encrypted code to be loaded into the current process
    my $stash = Package::Stash::XS->new('B');
    $stash->remove_symbol('$VERSION');

    if ( $opt->{protect} && ( my $mod = P->perl->module('Filter/Crypto/CryptFile.pm') ) ) {
        my $auto_deps = $mod->auto_deps;

        say qq[unlink: "@{[ $mod->path ]}"] if $opt->{verbose};

        unlink $mod->path or die $!;

        for my $dep ( values $auto_deps->%* ) {
            say qq[unlink: "$dep"] if $opt->{verbose};

            unlink $dep or die $!;
        }

        say 'PROTECTED' if $opt->{verbose};
    }

    return;
}

sub _process_file ( $self, $path, $verbose ) {
    if ( $path->mime_has_tag( 'perl', 1 ) && !$path->mime_has_tag( 'perl-cpanfile', 1 ) ) {
        print qq[encrypt: "$path" ... ] if $verbose;
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

        say 'done' if $verbose;
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
## |    1 | 55                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
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
