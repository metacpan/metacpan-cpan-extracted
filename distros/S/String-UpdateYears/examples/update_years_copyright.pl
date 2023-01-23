#!/usr/bin/env perl

use strict;
use warnings;

use String::UpdateYears qw(update_years);
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $input = decode_utf8('© 1977-2022 Michal Josef Špaček');
my $output = update_years($input, {}, 2023);

# Print input and output.
print 'Input: '.encode_utf8($input)."\n";
print 'Output: '.encode_utf8($output)."\n";

# Output:
# Input: © 1987-2022 Michal Josef Špaček
# Output: © 1987-2023 Michal Josef Špaček