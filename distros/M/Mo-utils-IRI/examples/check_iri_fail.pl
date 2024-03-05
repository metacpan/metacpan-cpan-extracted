#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::IRI qw(check_iri);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_iri',
};
check_iri($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' doesn't contain valid IRI.