# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar

This package tests the basic functionality of Term::ProgressBar.

=cut

use Test::More tests => 9;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

use Term::ProgressBar;

Term::ProgressBar->__force_term (50);

# -------------------------------------

=head2 Tests 2--10: Count 1-10

Create a progress bar with 10 things.  Invoke ETA and name on it.
Update it it from 1 to 10.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update 1..5
(3) Check no exception thrown on message issued
(4) Check no exception thrown on update 6..10
(5) Check message seen
(6) Check bar is complete
(7) Check bar number is 100%
(8) Check --DONE-- issued
(9) Check estimation done

=cut

{
  my $err = capture_stderr {
    my $p;
    lives_ok {
                $p = Term::ProgressBar->new({count => 10, name => 'fred',
                                             ETA => 'linear'});
              } 'Count 1-10 (1)';
    lives_ok { for (1..5) { $p->update($_); sleep 1 } }
              'Count 1-10 (2)';
    lives_ok { $p->message('Hello Mum!') }  'Count 1-10 (3)';
    lives_ok { for (6..10) { $p->update($_); sleep 1 } } 'Count 1-10 (4)';
  };

  my @lines = grep $_ ne '', split /[\n\r]+/, $err;
  diag explain \@lines
    if $ENV{TEST_DEBUG};
  ok grep $_ eq 'Hello Mum!', @lines;
  like $lines[-1], qr/\[=+\]/,                  'Count 1-10 (6)';
  like $lines[-1], qr/^fred: \s*100%/,          'Count 1-10 (7)';
  like $lines[-1], qr/D[ \d]\dh\d{2}m\d{2}s$/,  'Count 1-10 (8)';
  like $lines[-2], qr/ Left$/,                  'Count 1-10 (9)';
}

# ----------------------------------------------------------------------------
