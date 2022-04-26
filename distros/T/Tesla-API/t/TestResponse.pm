package TestResponse;

# Used as the response object for _tesla_api_call()

use warnings;
use strict;

use Carp qw(croak);
use Data::Dumper;
use JSON;

sub new {
    if (scalar @_ != 5) {
        croak "TestResponse::new() requires four params";
    }

    my ($class, $is_success, $code, $json, $status_line) = @_;

    return bless {
        is_success      => $is_success,
        code            => $code,
        decoded_content => $json,
        status_line     => $status_line,
    }, $class;
}
sub is_success {
    return $_[0]->{is_success};
}
sub code {
    return $_[0]->{code};
}
sub decoded_content {
    return $_[0]->{decoded_content};
}
sub status_line {
    return $_[0]->{status_line};
}
1;