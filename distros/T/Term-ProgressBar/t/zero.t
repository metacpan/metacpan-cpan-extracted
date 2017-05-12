# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar

This package tests the zero-progress handling of progress bar.

=cut

use Test::More tests => 9;
use Test::Exception;

use Capture::Tiny qw(capture_stderr);

use_ok 'Term::ProgressBar';

Term::ProgressBar->__force_term (50);

# -------------------------------------

=head2 Tests 2--5: V1 mode

Create a progress bar with 0 things.
Update it it from 1 to 10.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar displays name
(3) Check bar says nothing to do

=cut

{
  my $p;
  my $name = 'doing nothing';
  my $err  = capture_stderr {
    lives_ok { $p = Term::ProgressBar->new($name, 0); } 'V1 mode ( 1)';
    lives_ok { $p->update($_) for 1..10 } 'V1 mode ( 2)';
  };

  my @lines = grep { $_ ne ''} split /\r/, $err;
  diag explain @lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/^$name:/,                                  'V1 mode ( 3)';
  like $lines[-1], qr/\(nothing to do\)/,                        'V1 mode ( 4)';
}

# -------------------------------------

=head2 Tests 6--9: V2 mode

Create a progress bar with 0 things.
Update it it from 1 to 10.

(1) Check no exception thrown on creation
(2) Check no exception thrown on update
(3) Check bar displays name
(4) Check bar says nothing to do

=cut

{
  my $p;
  my $name = 'zero';
  my $err = capture_stderr {
    lives_ok { $p = Term::ProgressBar->new({ count => 0, name => $name }); } 'V2 mode ( 1)';
    lives_ok { $p->update($_) for 1..10 } 'V2 mode ( 2)';
  };

  my @lines = grep {$_ ne ''} split /\r/, $err;
  diag explain @lines
    if $ENV{TEST_DEBUG};
  like $lines[-1], qr/^$name:/,             'V2 mode ( 3)';
  like $lines[-1], qr/\(nothing to do\)/,   'V2 mode ( 4)';
}

# ----------------------------------------------------------------------------
