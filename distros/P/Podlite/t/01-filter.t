#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

# Test 1: Module can be required (not 'use' to avoid filtering this test)
require_ok('Podlite');

# Create a test script with Podlite markup
my $test_script = <<'END_SCRIPT';
use strict;
use warnings;


use Podlite;

my $x = 1;

=head1 DESCRIPTION
=para
This is a Podlite description that should be filtered out.

=para
This paragraph should also be removed.

my $y = 2;

=begin comment
This is a comment block
that spans multiple lines
=end comment

my $z = 3;

=for table :caption<Example>
Column1    Column2
Data1      Data2

my $result = $x + $y + $z;

=item Task item 1
=item Task item 2

print "Result: $result\n";

=begin data
This is test data
that should be preserved
in DATA section
=end data

1;
END_SCRIPT

# Test 2-4: the script compiles and runs
my $compile = run_perl($test_script, switches => ['-c']);
ok($compile->{stderr} =~ /syntax OK/, 'Script compiles with Podlite markup')
    or diag("Compile output: $compile->{stderr}");
my $run = run_perl($test_script);
ok($run->{stdout} =~ /Result: 6/, 'Script executes correctly')
    or diag("Run output: $run->{stdout}$run->{stderr}");
is($run->{exit}, 0, 'Script exits cleanly');

# Test 6-7-8: Create a script that uses DATA
my $data_script = <<'END_DATA_SCRIPT';
use strict;
use warnings;


use Podlite;

=head1 TESTING DATA
=para
This should be removed.

=begin data
Line 1 of data
Line 2 of data
Line 3 of data
=end data

=para
More documentation to remove.

while (<DATA>) {
    print "DATA: $_";
}

1;
END_DATA_SCRIPT

my $data_run = run_perl($data_script);
my $data_output = $data_run->{stdout} . $data_run->{stderr};
ok($data_output =~ /DATA: Line 1 of data/, 'DATA section preserved - line 1')
    or diag("Data output: $data_output");
ok($data_output =~ /DATA: Line 2 of data/, 'DATA section preserved - line 2');
ok($data_output =~ /DATA: Line 3 of data/, 'DATA section preserved - line 3');

# Test line numbering (test 9 in future)
my $line_test_script = <<'END_LINE_SCRIPT';
use strict;
use warnings;


use Podlite;

my $a = 1;  # Line 6

=head1 Section
=para
Some text that will be removed
but line numbers preserved

my $b = 2;  # Line 13 (should still be line 13 after filtering)

sub test_line {
    die "Error at line " . __LINE__;  # Should report correct line
}

test_line();
END_LINE_SCRIPT

# The line numbers should be preserved even after filtering
my $line_output = run_perl($line_test_script)->{stderr};
# Line 16 is where __LINE__ appears
ok($line_output =~ /line 17/, 'Line numbers preserved after filtering')
    or diag("Line output: $line_output");

done_testing();
