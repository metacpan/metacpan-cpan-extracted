use strict;
use warnings;
use v5.16;
use Test::More;
use TAP::Harness;

# everything down here is *VERY* influenced by:
# https://github.com/bleargh45/TAP-Formatter-JUnit/blob/main/t/formatter.t
# 100x kudos to authors there! 🎉

sub slurp {
  open(my $fh, '<', shift) or die $!;
  local $/ = undef;
  my $content = <$fh>;
  close($fh);
  return $content;
}

my @tests = grep { -f $_ } <t/fixtures/tests/*>;

plan tests => 1 + scalar(@tests);

# Do not render the summary of the fixtures
$ENV{GHA_SKIP_SUMMARY} = '1';

use_ok('TAP::Formatter::GitHubActions');

# Drop all the output until the "= GitHub Actions Report =" header
# if not found return empty string.
sub snip_until_report {
  my $output = shift;

  # Strip until report
  $output = "" unless ($output =~ s/.*^= GitHub Actions Report =//ms);

  # trim leading
  $output =~ s/^\s*//;
  # trim trailing
  $output =~ s/\s*$//;
  # return
  return $output;
}

foreach my $test (@tests) {
  (my $output = $test) =~ s{(/fixtures)/tests/}{$1/output/};

  my $expected = slurp($output);

  my $received = '';
  open(my $fh, '>', \$received);

  eval {
    my $harness = TAP::Harness->new({
        stdout => $fh,
        merge => 1,
        formatter_class => 'TAP::Formatter::GitHubActions',
    });
    $harness->runtests($test);
  };

  $expected = snip_until_report($expected);
  $received = snip_until_report($received);

  my $fail;
  ok($received eq $expected, $test) or ($fail = 1);

  # tap output is quite hard to parse for me...
  # I'll just pretty print it here.
  if (($ENV{RUNNER_DEBUG} || $ENV{TEST_SHOW_FULL_DIFF}) && $fail) {
    $expected =~ s/^/expected:  /mg;
    $received =~ s/^/received:  /mg;
    print STDERR "\n== Expected $output ==\n";
    print STDERR $expected;
    print STDERR "\n====\n";

    print STDERR "\n== Received $output ==\n";
    print STDERR $received;
    print STDERR "\n====\n";
  }
}
