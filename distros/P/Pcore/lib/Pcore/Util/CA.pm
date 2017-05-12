package Pcore::Util::CA;

use Pcore -class;

sub update ($cb = undef) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    print 'updating ca_file.pem ... ';

    require Pcore::HTTP;

    P->http->get(
        'https://curl.haxx.se/ca/cacert.pem',
        tls_ctx   => $Pcore::HTTP::TLS_CTX_HIGH,
        on_finish => sub ($res) {
            my $status;

            if ($res) {
                $ENV->share->store( '/data/ca_file.pem', $res->body, 'Pcore' );

                $status = 1;

                say 'done';
            }
            else {
                say 'error';
            }

            $cb->($status) if $cb;

            $blocking_cv->($status) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub ca_file {
    return $ENV->share->get('/data/ca_file.pem') // undef;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::CA

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
