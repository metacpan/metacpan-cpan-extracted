package Net::HTTP2::Response;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::Response - HTTP/2 Response

=head1 DESCRIPTION

This class represents an HTTP/2 response.

=cut

#----------------------------------------------------------------------

use constant {
    _HEADERS_AR => 0,
    _DATA => 1,
    _STATUS => 2,
    _HEADERS_HR => 3,
};

#----------------------------------------------------------------------

=head1 METHODS

=cut

# Not called publicly.
sub new {
    my ($class, $headers_ar, $data) = @_;

    return bless [$headers_ar, $data], $class;
}

=head2 $str = I<OBJ>->content()

Returns the response payload, or undef if the payload was
delivered to an C<on_data> handler. (See L<Net::HTTP2::Client>’s
C<request()> method.)

=cut

sub content { $_[0][ _DATA ] }

=head2 $num = I<OBJ>->status()

Returns the (numeric) HTTP statis.

(NB: HTTP/2 doesn’t have response status strings as HTTP/1 has.)

=cut

sub status {
    $_[0]->headers() if !defined $_[0][ _STATUS ];
    return $_[0][ _STATUS ];
}

=head2 $yn = I<OBJ>->success()

Returns a boolean that indicates whether the response indicates
success.

=cut

sub success {
    my $status = $_[0]->status();

    return ($status >= 200) && ($status <= 299);
}

=head2 $hr = I<OBJ>->headers()

Returns a hash reference similar to that in
L<HTTP::Tiny::UA::Response>’s method of the same name.

=cut

sub headers {
    if (!$_[0][ _HEADERS_HR ]) {
        my $headers_ar = $_[0][ _HEADERS_AR ];

        my %headers;
        $_[0][ _HEADERS_HR ] = \%headers;

        for (my $h=0; $h < @$headers_ar; $h+=2) {
            my ($name, $value) = @{$headers_ar}[ $h, $h+1 ];

            if ($name eq ':status') {
                $_[0][ _STATUS ] = $value;
            }
            elsif (exists $headers{$name}) {
                if ('ARRAY' eq ref $headers{$name}) {
                    push @{$headers{$name}}, $value;
                }
                else {
                    $headers{$name} = [ $headers{$name}, $value ];
                }
            }
            else {
                $headers{$name} = $value;
            }
        }
    }

    return $_[0][ _HEADERS_HR ];
}

1;

