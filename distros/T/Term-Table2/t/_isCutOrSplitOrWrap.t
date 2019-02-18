#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $isIntFlag;
my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _isInt => sub { return $isIntFlag },
  ]
);

subtest 'Failure' => sub {
  $isIntFlag = '';
  is(_isCutOrSplitOrWrap(), 0, 'Not an integer');

  $isIntFlag = 1;
  is(_isCutOrSplitOrWrap(3), '', 'Invalid value');
};

subtest 'Success' => sub {
  $isIntFlag = 1;
  is(_isCutOrSplitOrWrap(0), 1, 'CUT');
  is(_isCutOrSplitOrWrap(1), 1, 'SPLIT');
  is(_isCutOrSplitOrWrap(2), 1, 'WRAP');
};

done_testing();