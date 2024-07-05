#!/usr/bin/perl
use strict; use warnings;
use Carp 'confess';

use Test::More tests=>4;
use Test::Exception;

use Sub::Curried;

curry trace ($a, $b, $c, $d) {
  confess('test');
}

eval { trace(1)->(2)->(3, 4); };
my $ctrace = $@;
eval { trace(1, 2, 3, 4); };
my $ntrace = $@;

like $ctrace, qr/^[^\n]*\n\s*[\w:]+\(1, 2, 3, 4\)/,
  'All arguments passed in the deepest stack frame';
like $ctrace, qr/^[^\n]*\n\s*main::trace/, 'Subroutine name';
is scalar(@{[$ctrace=~/main::trace/g]}), 2, 'Curried stack trace depth';
is scalar(@{[$ntrace=~/main::trace/g]}), 1, 'Non-curried stack trace depth';
