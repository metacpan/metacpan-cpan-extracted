#!/usr/bin/env perl

use strict;
use warnings;

use Schema::Test;

my $schema = Schema::Test->new(version => '0.3.0');

print $schema->schema, "\n";
print $schema->version, "\n";

# Output:
# Schema::Test::0_3_0
# 0.3.0