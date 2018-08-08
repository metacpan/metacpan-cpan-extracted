package Pcore::Util::CA;

use Pcore -class;

sub update ($cb = undef) {
    print 'updating ca_file.pem ... ';

    return P->http->get(
        'https://curl.haxx.se/ca/cacert.pem',
        sub ($res) {
            my $status;

            say $res;

            if ($res) {
                $ENV->{share}->write( 'Pcore', 'data/ca_file.pem', $res->{data} );

                $status = 1;
            }

            return $cb ? $cb->($status) : $status;
        }
    );
}

sub ca_file {
    return $ENV->{share}->get('data/ca_file.pem');
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
