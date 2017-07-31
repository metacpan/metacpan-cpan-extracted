package Pcore::API::ReCaptcha v0.2.2;

use Pcore -dist, -class, -result;
use Pcore::Util::Data qw[from_json];

has secret_key => ( is => 'ro', isa => Str, required => 1 );

has site_key => ( is => 'ro', isa => Str );

# https://developers.google.com/recaptcha/docs/

sub verify ( $self, $response, $user_ip = undef, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    P->http->post(
        'https://www.google.com/recaptcha/api/siteverify',
        accept_compressed => 0,
        headers           => {    #
            CONTENT_TYPE => 'application/x-www-form-urlencoded',
        },
        body => P->data->to_uri(
            {   secret   => $self->{secret_key},
                response => $response,
                remoteip => $user_ip,
            }
        ),
        on_finish => sub ($res) {
            my $api_res;

            if ( !$res ) {
                $api_res = result [ $res->status, $res->reason ];
            }
            else {
                my $data = from_json( $res->body );

                if ( $data->{success} ) {
                    $api_res = result 200,
                      { callenge_ts => $data->{callenge_ts},
                        hostname    => $data->{hostname},
                      };
                }
                else {
                    $api_res = result 400,
                      error => $data->{'error-codes'},
                      data  => {
                        callenge_ts => $data->{callenge_ts},
                        hostname    => $data->{hostname},
                      };
                }
            }

            $cb->($api_res) if $cb;

            $blocking_cv->($api_res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
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
