#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::IRI qw(check_iri);
use Unicode::UTF8 qw(decode_utf8);

my $self = {
        'key' => decode_utf8('https://michal.josef.špaček'),
};
check_iri($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok