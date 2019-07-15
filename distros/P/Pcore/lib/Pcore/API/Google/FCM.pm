package Pcore::API::Google::FCM;

use Pcore -class, -res;
use Pcore::Lib::Data qw[to_json from_json];

extends qw[Pcore::API::Google::OAuth];

has scope => ( 'https://www.googleapis.com/auth/firebase.messaging', init_arg => undef );

# https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#Message
sub send ( $self, $data ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $token = $self->get_token;

    return $token if !$token;

    my $url = "https://fcm.googleapis.com/v1/projects/$self->{key}->{project_id}/messages:send";

    my $res = P->http->post(
        $url,
        headers => [
            'Content-Type' => 'application/json',
            Authorization  => "Bearer $token->{data}->{access_token}",
        ],
        data => to_json $data
    );

    if ( !$res ) {
        my $error = $res->{data} ? from_json $res->{data} : undef;

        $res = res $res;

        $res->{reason} = $error->{error}->{message} if $error;
    }
    else {
        $res = res 200, from_json $res->{data};
    }

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Google::FCM

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
