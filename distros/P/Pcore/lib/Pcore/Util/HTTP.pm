package Pcore::Util::HTTP;

use Pcore -export, -res;
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref is_plain_scalarref];

our @EXPORT = [qw[build_headers build_response_headers build_body]];

# https://tools.ietf.org/html/rfc7230#section-3.2
sub build_headers ( @headers ) {
    my $buf = $EMPTY;

    for my $headers (@headers) {
        for ( my $i = 0; $i <= $headers->$#*; $i += 2 ) {
            next if !defined $headers->[ $i + 1 ];

            $buf .= "$headers->[$i]:$headers->[$i + 1]\r\n";
        }
    }

    return \$buf;
}

sub build_response_headers ( $status, @headers ) {
    $status += 0;

    my $reason = P->result->resolve_reason($status);

    return \( "HTTP/1.1 $status $reason\r\n" . build_headers(@headers)->$* );
}

sub build_body ( $data ) {
    my $body = $EMPTY;

    for my $part ( $data->@* ) {
        next if !defined $part;

        if ( !is_ref $part ) {
            $body .= encode_utf8 $part;
        }
        elsif ( is_plain_scalarref $part ) {
            $body .= encode_utf8 $part->$*;
        }
        elsif ( is_plain_arrayref $part ) {
            $body .= join $EMPTY, map { encode_utf8 $_ } $part->@*;
        }
        else {
            die q[Body type isn't supported];
        }
    }

    return \$body;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 14                   | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::HTTP

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
