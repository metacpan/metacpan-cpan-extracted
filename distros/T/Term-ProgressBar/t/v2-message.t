# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar

This package tests the basic functionality of Term::ProgressBar.

=cut

use Test::More tests => 11;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

my $MESSAGE1 = 'Walking on the Milky Way';

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

use_ok 'Term::ProgressBar';

Term::ProgressBar->__force_term (50);

# -------------------------------------

=head2 Tests 2--8: Count 1-10

Create a progress bar with 10 things.
Update it it from 1 to 10.  Output a message halfway through.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update (1..5)
(3) Check no exception thrown on message send
(4) Check no exception thrown on update (6..10)
(5) Check message was issued.
(6) Check bar is complete
(7) Check bar number is 100%

=cut
{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new(10); } 'Count 1-10 (1)';
    lives_ok { $p->update($_) for 1..5  }         'Count 1-10 (2)';
    lives_ok { $p->message($MESSAGE1)    }         'Count 1-10 (3)';
    lives_ok { $p->update($_) for 6..10 }         'Count 1-10 (4)';
  };

  $err =~ s!^.*\r!!gm;
  diag "ERR:\n$err\nlength: " . length($err)
    if $ENV{TEST_DEBUG};

  my @lines = split /\n/, $err;

  is $lines[0], $MESSAGE1;
  like $lines[-1], qr/\[=+\]/,            'Count 1-10 (5)';
  like $lines[-1], qr/^\s*100%/,          'Count 1-10 (6)';
}

# -------------------------------------

=head2 Tests 9--11: Message Check

Run a progress bar from 0 to 100, each time calling a message after an update.
This is to check that message preserves the progress bar value correctly.

( 1) Check no exception thrown on creation
( 2) Check no exception thrown on update, message (0..100).
( 3) Check last progress is 100%

=cut

{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new(100); } 'Message Check ( 1)';
    lives_ok { for (0..100) { $p->update($_); $p->message("Hello") } }  'Message Check ( 2)';
  };

  my @err_lines = split /\n/, $err;
  (my $last_line = $err_lines[-1]) =~ tr/\r//d;
  is substr($last_line, 0, 4), '100%',               'Message Check ( 3)';
}

# ----------------------------------------------------------------------------
