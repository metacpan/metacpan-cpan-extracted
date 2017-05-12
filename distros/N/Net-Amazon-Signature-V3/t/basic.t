use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use aliased 'Net::Amazon::Signature::V3';

validate_class V3, (
    attributes => [ qw{ id key         } ],
    methods    => [ qw{ signed_headers } ],
);

# XXX some actual tests of the functionality would be nice

done_testing;
