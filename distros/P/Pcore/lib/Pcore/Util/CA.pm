package Pcore::Util::CA;

use Pcore -class;

sub update ($cb = undef) {
    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    print 'updating ca_file.pem ... ';

    P->http->get(
        'https://curl.haxx.se/ca/cacert.pem',
        sub ($res) {
            my $status;

            if ($res) {
                $ENV->share->store( '/data/ca_file.pem', $res->{body}, 'Pcore' );

                $status = 1;

                say 'done';
            }
            else {
                say 'error';
            }

            $rouse_cb ? $cb ? $rouse_cb->( $cb->($status) ) : $rouse_cb->($status) : $cb ? $cb->($status) : ();

            return;
        }
    );

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
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
