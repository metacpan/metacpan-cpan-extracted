# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar

This package tests the zero-progress handling of progress bar.

=cut

use Test::More tests => 10;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

use_ok 'Term::ProgressBar';

Term::ProgressBar->__force_term (50);

# -------------------------------------

=head2 Tests 2--4: V1 mode

Create a progress bar with fewer than -1 things.
Update it it from 1 to 10.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar displays name

=cut

{
  my $p;
  my $name = 'doing nothing';
  my $err  = capture_stderr {
    lives_ok { $p = Term::ProgressBar->new($name, -1); } 'V1 mode ( 1)';
    lives_ok { $p->update($_) for 1..10 } 'V1 mode ( 2)';
  };

  my @lines = grep { $_ ne ''} split /\r/, $err;
  diag explain @lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/^$name...$/,                                  'V1 mode ( 3)';
}

# -------------------------------------

=head2 Tests 5--7: V2 mode

Create a progress bar with -1 things.
Update it it from 1 to 10.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar displays name

=cut

{
  my $p;
  my $name = 'doing nothing';
  my $err = capture_stderr {
    lives_ok { $p = Term::ProgressBar->new({ count => -1, name => $name }); } 'V2 mode ( 1)';
    lives_ok { $p->update($_) for 1..10 } 'V2 mode ( 2)';
  };

  my @lines = grep {$_ ne ''} split /\r/, $err;
  diag explain @lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/^$name...$/,             'V2 mode ( 3)';
}

# -------------------------------------

=head2 Tests 8--10: V2 mode

Create a progress bar with -1 things and remove = 1.
Update it with -1

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar is removed

=cut

{
  my $p;
  my $name = 'doing nothing';
  my $err = capture_stderr {
    lives_ok { $p = Term::ProgressBar->new({ count => -1, name => $name, remove => 1 }); } 'V2 mode ( 1)';
    lives_ok { $p->update(-1) } 'V2 mode ( 2)';
  };

  my @lines = grep {$_ ne ''} split /\r/, $err;
  diag explain @lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/^\s*$/,             'V2 mode ( 3)';
}

# ----------------------------------------------------------------------------
