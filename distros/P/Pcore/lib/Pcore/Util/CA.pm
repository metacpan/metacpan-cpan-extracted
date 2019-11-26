package Pcore::Util::CA;

use Pcore -class;

sub update {
    print 'updating cacert.pem ... ';

    my $res = P->http->get('https://curl.haxx.se/ca/cacert.pem');

    my $status;

    say $res;

    if ($res) {
        $ENV->{share}->write( '/Pcore/data/cacert.pem', $res->{data} );

        $status = 1;
    }

    return $status;
}

sub ca_file {
    return $ENV->{share}->get('data/cacert.pem');
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
