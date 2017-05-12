package
  MxreTestUtils;
use Test::More;
use strict; use warnings FATAL => 'all';
use parent 'Exporter';

our @EXPORT = qw/
  test_expected_ok
/;

sub test_expected_ok {
  my ($got, $expected, $desc) = @_;
  $desc = defined $desc ? $desc : 'Unnamed test';

  for my $test (keys %$expected) {

    unless (exists $got->{$test}) {
      fail($desc);
      diag("No result for test '$test'");
      next
    }

    if (ref $expected->{$test}) {
      is_deeply($got->{$test}, $expected->{$test}, $test)
    } else {
      is($got->{$test}, $expected->{$test}, $test)
        or diag ("$desc failed")
    }

  }

  is_deeply($got, $expected, $desc)
}

1;
