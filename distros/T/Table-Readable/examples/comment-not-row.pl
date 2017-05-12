#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Table::Readable 'read_table';
my $table = <<EOF;
row: 1
# comment
some: thing

row: 2
EOF
my @rows = read_table ($table, scalar => 1);
print scalar (@rows), "\n";

