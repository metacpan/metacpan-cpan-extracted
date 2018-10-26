#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package Test::OpenStack::Client::Message;

use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;

    $opts{'headers'} ||= {};
    $opts{'content'} ||= '';

    my %headers = map {
        lc $_ => $opts{'headers'}->{$_}
    } keys %{$opts{'headers'}};

    $headers{'content-type'} ||= 'application/json';

    if (defined $opts{'content'}) {
        $headers{'content-length'} ||= length $opts{'content'};
    }

    return bless {
        %opts,
        'headers' => \%headers
    }, $class;
}

sub header ($$@) {
    my ($self, $name, $value) = @_;
    my $key = lc $name;

    $self->{'headers'}->{$key} = $value if defined $value;

    return $self->{'headers'}->{$key};
}

sub content ($@) {
    my ($self, $value) = @_;

    $self->{'content'} = $value if defined $value;

    return $self->{'content'};
}

sub decoded_content ($) {
    shift->content;
}

1;
