# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;
use Term::ProgressBar;

=head1 Unit Test Package for Term::ProgressBar

This package tests the basic functionality of Term::ProgressBar.

=cut

use Test::More tests => 14;
use Test::Exception;
use Test::Warnings;

use Capture::Tiny qw(capture_stderr);

my $MESSAGE1 = 'Walking on the Milky Way';

# -------------------------------------

=head2 Test 1--5

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

=head2 Tests 6--8: Message Check

Run a progress bar from 0 to 100, each time calling a message after an update.
Check that we still have no output.

=cut

{
  my $err = capture_stderr {
    my $p;
    lives_ok { $p = Term::ProgressBar->new({ count => 100, silent => 1}); } 'Message Check ( 1)';
    lives_ok { for (0..100) { $p->update($_); $p->message("Hello") } }  'Message Check ( 2)';
  };

  ok !$err, 'We should still have no output';
}

# ----------------------------------------------------------------------------

=head2 Tests 9--13: Message Check

Run a progress bar from 0 to 1000, each time calling a message after an update.
Check that we still have no output.

=cut
{
  my $err = capture_stderr {
    my $p;
    my $max_value = 1000;
    my $half_value = int($max_value/2);
    lives_ok { $p = Term::ProgressBar->new({ count => $max_value, silent => 1}); } 'Count 1-1000 (1)';
    my $next_value = 0;
    lives_ok {
      for (my $i=0; $i<$half_value; $i++)
	{
	  $next_value = $p->update($i) if ($i >= $next_value);
	}
    } 'Count 1-1000 (2)';
    lives_ok { $p->message($MESSAGE1)    }         'Count 1-1000 (3)';
    lives_ok {
      for (my $i=$half_value; $i<$max_value; $i++)
	{
	  $next_value = $p->update($i) if ($i >= $next_value);
	}
    } 'Count 1-1000 (4)';
  };

  diag "ERR:\n$err\nlength: " . length($err)
    if $ENV{TEST_DEBUG};
  ok !$err, 'We should still have no output even with warnings enabled';
}

# ----------------------------------------------------------------------------
