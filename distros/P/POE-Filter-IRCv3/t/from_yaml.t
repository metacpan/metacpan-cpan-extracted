use strict; use warnings FATAL => 'all';

# This should be genericized out to a standalone IRC parser testsuite ...

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(
      skip_all => 'these tests are for release candidate testing'
    );
  }
}

use lib 't/inc';

use POE::Filter::IRCv3;
my $filter = new_ok( 'POE::Filter::IRCv3' => [ colonify => 1 ] );

use Test::More;
use TestFilterHelpers;

use YAML::XS 'LoadFile';

my $testset = LoadFile 't/inc/ircbasic.yml';
die 'Broken YAML test set at t/inc/ircbasic.yml' unless $testset;
die "Expected ARRAY but got $testset" unless ref $testset eq 'ARRAY';

for my $test (@$testset) {
  _validate_test($test);
  _run_test($test);
}

done_testing;

sub _validate_test {
  my ($test) = @_;

  unless (ref $test eq 'HASH') {
    die "Expected HASH but got $test"
  }

  for my $toplev_key (keys %$test) {
    unless ($toplev_key =~ m/^(name|input|expect)$/) {
      die "Unexpected top-level key $toplev_key"
    }
  }

  my $name   = $test->{name};
  my $input  = $test->{input};
  my $expect = $test->{expect};

  die "Expected 'name:' to be a string but got $name" 
    if !$name or ref $name;
  die "Expected 'input:' to be a string but got $input" 
    if !$input or ref $input;
    
  die "Expected 'expect:' to be a HASH but got $expect"
    unless ref $expect eq 'HASH';
  die "Expected 'expect:' HASH to have keys"
    unless keys %$expect;

  for my $expect_key (keys %$expect) {
    die "Unexpected 'expect:' key $expect_key"
      unless $expect_key =~ m/^(command|prefix|params|tags)$/;
  }

  $test
}

sub _run_test {
  my ($test) = @_;

  get_ok $filter, $test->{input} => +{
    raw_line => $test->{input},
    %{ $test->{expect} }
  }, 
  $test->{name};
}
