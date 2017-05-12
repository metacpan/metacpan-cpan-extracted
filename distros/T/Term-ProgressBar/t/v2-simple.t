# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar

This package tests the basic functionality of Term::ProgressBar.

=cut

use Test::More tests => 31;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

use_ok 'Term::ProgressBar';

Term::ProgressBar->__force_term (50);

# -------------------------------------

=head2 Tests 2--16: Count 1-10

Create a progress bar with 10 things.
Update it it from 1 to 10.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar is complete
(4) Check bar number is 100%
(5--15) Check bar has no minor characters at any point

=cut
{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new(10); } 'Count 1-10 (1)';
    lives_ok { $p->update($_) for 1..10 } 'Count 1-10 (2)';
  };

  my @lines = grep {$_ ne ''} split /\r/, $err;
  diag explain \@lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/\[=+\]/,            'Count 1-10 (3)';
  like $lines[-1], qr/^\s*100%/,          'Count 1-10 (4)';
  like $lines[$_], qr/\[[= ]+\]/, sprintf('Count 1-10 (%d)', 5+$_)
    for 0..10;
}
# -------------------------------------

=head2 Tests 17--30: Count 1-9

Create a progress bar with 10 things.
Update it it from 1 to 9.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar is incomplete
(4) Check bar number is 90%
(5--14) Check bar has no minor characters at any point

=cut

{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new(10); } 'Count 1-9 (1)';
    lives_ok { $p->update($_) for 1..9 } 'Count 1-9 (2)';
  };

  my @lines = grep $_ ne '', split /\r/, $err;
  diag explain \@lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/\[=+ +\]/,          'Count 1-9 (3)';
  like $lines[-1], qr/^\s*90%/,           'Count 1-9 (4)';
  like $lines[$_], qr/\[[= ]+\]/, sprintf('Count 1-9 (%d)', 5+$_)
    for 0..9;
}
# -------------------------------------

=head2 Test 31

Make sure the same progress bar text is not printed twice to the
terminal (in the case of an update that is too little to affect the
percentage or displayed bar).

=cut
{
  my $err = capture_stderr {
    my $tp = Term::ProgressBar->new(1000000);
    $tp->update($_) foreach (0, 1);
  };

  my @lines = grep {$_ ne ''} split /\r/, $err;
  diag explain \@lines
    if $ENV{TEST_DEBUG};
  is scalar @lines, 1;
}
