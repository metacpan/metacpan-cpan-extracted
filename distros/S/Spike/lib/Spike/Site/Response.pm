package Spike::Site::Response;

use strict;
use warnings;

use base qw(Plack::Response Spike::Object);

sub new {
    my ($proto, $status, $headers) = splice @_, 0, 3;
    my $class = ref $proto || $proto;

    $headers = !$headers ? [] : ref $headers eq 'HASH' ? [ %$headers ] : $headers;

    if (ref $headers eq 'ARRAY') {
        unshift @$headers, ('Content-Type', 'text/html; charset=utf-8');
    }

    return $class->SUPER::new($status, $headers, @_);
}

1;
