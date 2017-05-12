# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Term::ProgressBar v1.0 Compatibility

This script is based on the test script for Term::ProgressBar version 1.0,
and is intended to test compatibility with that version.

=cut

# Utility -----------------------------

use Test::More tests => 9;

use Term::ProgressBar;
use POSIX qw<floor ceil>;
use Capture::Tiny qw(capture);

$| = 1;

my $count = 100;

diag 'create a bar';
my $test_str = 'test';

my $tp;
{
  my ($out, $err) = capture { $tp = Term::ProgressBar->new($test_str, $count); };
  isa_ok $tp, 'Term::ProgressBar';
  is $out, '', 'empty stdout';
  is $err, "$test_str: ";
}

diag 'do half the stuff and check half the bar has printed';
my $halfway = floor($count / 2);
{
  my ($out, $err) = capture { $tp->update foreach (0 .. $halfway - 1) };
  is $out, '', 'empty stdout';
  is $err, ('#' x floor(50 / 2));
}

# do the rest of the stuff and check the whole bar has printed
{
   my ($out, $err) = capture { $tp->update foreach ($halfway .. $count - 1) };
   is $out, '', 'empty stdout';
   is $err, ('#' x ceil(50 / 2)) . "\n";
}

# try to do another item and check there is an error
eval { $tp->update };
my $err = $@;
ok defined($err);
is substr($err, 0, length(Term::ProgressBar::ALREADY_FINISHED)),
          Term::ProgressBar::ALREADY_FINISHED;
