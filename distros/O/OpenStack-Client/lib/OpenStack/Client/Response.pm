#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package OpenStack::Client::Response;

use strict;
use warnings;

use base 'HTTP::Response';

sub decode_json {
    my ($self) = @_;

    my $type    = $self->header('Content-Type');
    my $content = $self->decoded_content;

    if ($self->code =~ /^[45]\d{2}$/) {
        $content ||= "@{[$self->code]} Unknown error";

        die $content;
    }

    if (defined $content && length $content) {
        if (lc($type) =~ qr{^application/json}i) {
            return JSON::decode_json($content);
        }
    }

    return $content;
}

1;
