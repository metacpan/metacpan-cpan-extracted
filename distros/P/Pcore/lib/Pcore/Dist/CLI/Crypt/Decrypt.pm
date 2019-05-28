package Pcore::Dist::CLI::Crypt::Decrypt;

use Pcore -class, -ansi;
use Filter::Crypto::CryptFile;

extends qw[Pcore::Dist::CLI];

sub CLI ($self) {
    return {
        abstract => 'Decrypt perl files',
        opt      => { recursive => { desc => 'recursive', }, },
        arg      => [
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
    my $code = P->file->read_bin($path);

    my $hashbang = $EMPTY;

    # remove hashbang
    if ( $code =~ s/\A(#!.+?\n)//sm ) {
        $hashbang = $1;
    }

    # file is encrypted
    if ( $code =~ /\Ause Filter::Crypto::Decrypt;/sm ) {
        my $temp = P->file1->tempfile;

        P->file->write_bin( $temp, $code );

        Filter::Crypto::CryptFile::crypt_file( "$temp", Filter::Crypto::CryptFile::CRYPT_MODE_DECRYPTED() );

        # decryption error
        if ($Filter::Crypto::CryptFile::ErrStr) {
            say qq[Can't decrypt "$path", $Filter::Crypto::CryptFile::ErrStr];
        }
        else {
            P->file->write_bin( $path, $hashbang . P->file->read_bin($temp) );
        }
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Crypt::Decrypt - decrypt perl files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
