#!/usr/bin/env perl
# A reproducer for an upstream Future::AsyncAwait defect, kept here because
# Net::Async::Authentik can be driven into it through its public API, and
# because the distribution cannot design around it.
#
#   $ for i in 1 2 3; do perl docs/future-asyncawait-0.71-crash.pl >/dev/null 2>&1; echo $?; done
#   134
#   134
#   134
#
# The message varies: "double free or corruption (out)", "free(): invalid
# pointer", or a plain segmentation fault. Observed with
# Future::AsyncAwait 0.71 (the newest on CPAN as of 2026-10-04), Future 0.52,
# perl 5.40.1. Nothing of this distribution is involved: no IO::Async, no
# Moo, no HTTP client.
#
# The trigger is an `async sub` that is still SUSPENDED when the process
# ends and whose saved frame holds a REFERENCE argument. The corruption
# happens in global destruction, after the program's own work is finished.
#
# What changes it, measured:
#   * a string instead of the reference      -> clean
#   * only `my (...) = @_;` before the await -> clean (the reference does not
#                                               reach the saved frame)
#   * whether the awaited future is held     -> no difference
#   * holding or ->retain-ing the returned future -> no difference
#   * letting the future finish before the process ends -> clean
#
# So the only thing a caller can do is let its futures finish. That is what
# the POD of Net::Async::Authentik says, and this is why it says it.

use strict;
use warnings;

use Future;
use Future::AsyncAwait;

async sub suspended_at_exit {
  my ( $self, $argument ) = @_;
  # any statement here that makes the argument reach the saved frame will do;
  # a validation guard is the shape this distribution has everywhere
  die 'needs an argument' unless defined $argument && length $argument;
  await Future->new;                  # nothing will ever complete this
  return 'never reached';
}

{
  my $future = suspended_at_exit( 'self', {} );   # a reference argument
}

print "the work is done; what follows is global destruction\n";
