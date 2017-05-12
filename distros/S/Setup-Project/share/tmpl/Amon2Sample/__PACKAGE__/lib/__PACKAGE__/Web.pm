package <% $package %>::Web;
use strict;
use warnings;
use utf8;
use parent qw(<% $package %> Amon2::Web);

sub dispatch {
    my ($c) = @_;
    return $c->create_simple_status_page(200, 'OK');
}

1;
