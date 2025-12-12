#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most tests => 5;
use FindBin;
use lib "$FindBin::Bin/../lib";  # add the lib directory to @INC

use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);

# Test the date validation function.
ok(is_valid_datetime("2025-06-28"), 'Valid date in YYYY-MM-DD format passes');
ok(is_valid_datetime("2025-06-28T15:00"), 'Valid date in YYYY-MM-DDTHH:MM format passes');
ok(!is_valid_datetime("28/06/2025"), 'Invalid date in DD/MM/YYYY format fails');

# Test the dynamic vocabulary loader.
my %vocab = load_dynamic_vocabulary();
ok(%vocab, "Dynamic vocabulary loaded with at least one class");
ok(scalar(keys %vocab) > 100, "Dynamic vocabulary returns a significant number of classes");

done_testing();
