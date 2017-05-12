# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;
use Term::ProgressBar;

=head1 Unit Test Package for Term::ProgressBar

This package tests the basic functionality of Term::ProgressBar.

=cut

use Test::More tests => 8;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

my $MESSAGE1 = 'Walking on the Milky Way';

# -------------------------------------

=head2 Test

Create a progress bar with 10 things.
Update it it from 1 to 10.  Verify that it has no output.

=cut
{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new({ count => 10, silent => 1}); } 'Count 1-10 (1)';
    lives_ok { $p->update($_) for 1..5  }         'Count 1-10 (2)';
    lives_ok { $p->message($MESSAGE1)    }         'Count 1-10 (3)';
    lives_ok { $p->update($_) for 6..10 }         'Count 1-10 (4)';
  };

  diag "ERR:\n$err\nlength: " . length($err)
    if $ENV{TEST_DEBUG};
  ok !$err, 'We should have no output';
}

# -------------------------------------

=head2 Tests 9--11: Message Check

Run a progress bar from 0 to 100, each time calling a message after an update.
Check that we still have no output.

=cut

{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new({ count => 100, silent => 1}); } 'Message Check ( 1)';
    lives_ok { for (0..100) { $p->update($_); $p->message("Hello") } }  'Message Check ( 2)';
  };

  ok !$err, 'We should sill have no output';
}

# ----------------------------------------------------------------------------
