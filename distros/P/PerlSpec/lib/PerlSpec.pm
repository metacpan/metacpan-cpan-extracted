package PerlSpec;

use warnings;
use strict;

use base qw(Test::More);
use Test::More;

use version; our $VERSION = qv('0.1.0');

our @EXPORT = ( @Test::More::EXPORT, qw(it describe) );

my $spec_desc;

sub it {
  my $description = shift;
  my $block       = shift;

  caller->set_up if caller->can('set_up');
  _evaluate_and_print($description, $block);
  caller->tear_down if caller->can('tear_down');

  return;
}

sub describe {
  $spec_desc = shift;
  my $block  = shift;
  $block->();
  $spec_desc = undef;
  return;
}

sub _evaluate_and_print {
  my $description = shift;
  my $block       = shift;

  subtest _construct_description($description) => sub {
    plan 'no_plan';
    eval {
      $block->();
      1;
    } or do {
      fail($@);
    };
  };
}

sub _construct_description {
  my ($test_desc) = @_;
  my $result = $test_desc;
  $result = "$spec_desc $result" unless ! $spec_desc;
  return $result;
}

1;
