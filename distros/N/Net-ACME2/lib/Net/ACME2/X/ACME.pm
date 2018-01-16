package Net::ACME2::X::ACME;

use strict;
use warnings;

use parent qw( Net::ACME2::X::Base );

#named args required:
#
#   http
#   acme
#
#optional:
#   headers
#
sub new {
    my ( $self, $args_hr ) = @_;

    my $http = $args_hr->{'http'};

    my $http_str = join( ' ', $http->get('status'), $http->get('reason') );
    my $url = $http->get('url');

    my $acme_str = $args_hr->{'acme'}->to_string();

    return $self->SUPER::new(
        "“$url” indicated an ACME error: $http_str ($acme_str).",
        $args_hr,
    );
}

1;
