package Pcore::API::ReCaptcha v0.2.8;

use Pcore -dist, -class, -res;
use Pcore::Util::Data qw[from_json];

has secret_key => ( required => 1 );    # Str

has site_key => ();                     # Str

# https://developers.google.com/recaptcha/docs/

sub verify ( $self, $response, $user_ip = undef, $cb = undef ) {
    return P->http->post(
        'https://www.google.com/recaptcha/api/siteverify',
        accept_compressed => 0,
        headers           => [          #
            'Content-Type' => 'application/x-www-form-urlencoded',
        ],
        data => P->data->to_uri( {
            secret   => $self->{secret_key},
            response => $response,
            remoteip => $user_ip,
        } ),
        sub ($res) {
            my $api_res;

            if ( !$res ) {
                $api_res = res [ $res->{status}, $res->{reason} ];
            }
            else {
                my $data = from_json( $res->{data} );

                if ( $data->{success} ) {
                    $api_res = res 200,
                      { callenge_ts => $data->{callenge_ts},
                        hostname    => $data->{hostname},
                      };
                }
                else {
                    $api_res = res 400,
                      error => $data->{'error-codes'},
                      data  => {
                        callenge_ts => $data->{callenge_ts},
                        hostname    => $data->{hostname},
                      };
                }
            }

            return $cb ? $cb->($api_res) : $api_res;
        }
    );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ReCaptcha

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by zdm.

=cut
