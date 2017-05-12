# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar

This package tests the moving target functionality of Term::ProgressBar.

=cut

use Test::More tests => 7;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

use_ok 'Term::ProgressBar';

Term::ProgressBar->__force_term (50);

# -------------------------------------

=head2 Tests 2--7: Count 1-20

Create a progress bar with 10 things.
Update it it from 1 to 5.
Change target to 20.
Update it from 11 to 20.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update (1..5)
(3) Check no exception thrown on target update
(4) Check no exception thrown on update (6..10)
(5) Check bar is complete
(6) Check bar number is 100%

=cut

my $err = capture_stderr {
  my $p;
  lives_ok { $p = Term::ProgressBar->new(10); } 'Count 1-20 (1)';
  lives_ok { $p->update($_) for 1..5  }    'Count 1-20 (2)';
  lives_ok { $p->target(20)    }           'Count 1-20 (3)';
  lives_ok { $p->update($_) for 11..20 }   'Count 1-20 (4)';
};

$err =~ s!^.*\r!!gm;
diag "ERR:\n$err\nlength: " . length($err)
    if $ENV{TEST_DEBUG};

my @lines = split /\n/, $err;

like $lines[-1], qr/\[=+\]/,            'Count 1-20 (5)';
like $lines[-1], qr/^\s*100%/,          'Count 1-20 (6)';
