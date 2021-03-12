#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC qw(read_sxc);
#use Data::Dumper;

my $d = dirname($0);
my $file = "$d/merged.ods";

my $book_h_ref = read_sxc( $file );
use Data::Dumper;
print Dumper [ map { $book_h_ref->{$_} } sort keys %$book_h_ref ];
# Output:
# $VAR1 = [ [ [ 'a1', 'b1' ], [ 'a2', 'b2' ] ], [ [ 'A1', 'B1' ], [ 'A2', 'B2' ] ] ];


my $book_a_ref = read_sxc( $file, { OrderBySheet => 1 } );

isn't $book_a_ref->[0], undef, "When ordering by sheet name, we don't lose the sheets";

use Data::Dumper; print Dumper $book_a_ref;
# Output original:
# $VAR1 = [ undef, undef ];
# Output with applied patch:
# $VAR1 = [ [ [ 'a1', 'b1' ], [ 'a2', 'b2' ] ], [ [ 'A1', 'B1' ], [ 'A2', 'B2' ] ] ];
