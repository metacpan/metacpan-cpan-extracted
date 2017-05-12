package Diff;

=head1 NAME

Diff - provide a facility like the common 'diff' utility

=head1 DESCRIPTION

Use L<Algorithm::Diff> if available, else use homebrew kludge.

$Id: Diff.pm,v 1.4 2010-05-05 22:01:12 simeon Exp $

=cut

use strict;
use warnings;
 
use Test::More;

use base qw(Exporter);
our @EXPORT = qw(diff);

my $diff_function=\&_mydiff;
BEGIN {
  eval {
    require Algorithm::Diff;
    $diff_function=\&Algorithm::Diff::diff;
  };
  if ($@) {
    diag "WARNING -- Algorithm::Diff not installed -- install this if you want helpfull debugging information for any mistmatches. Using homebrew diff instead ($@)";
  }
}


=head1 FUNCTIONS

=head2 diff($aref,$bref)

@$aref and @$bref are arrays, compared element by element. Comparison is
returned as a string, empty if @$aref and @$bref are the same. 

See L<Algorithm::Diff> for details of that, L<_mydiff> for trivially
simple alternative.

=cut

sub diff {
  return(&$diff_function(@_));
}


=head2 _mydiff($aref,$bref)

Simplest possible diff which handles only changed lines.

=cut

sub _mydiff {
  my ($aref,$bref)=@_;
  my $ai=0;
  my $bi=0;
  while (not ($ai==scalar(@$aref) and $bi==scalar(@$bref))) {
    if ($ai>=scalar(@$aref) or $bi>=scalar(@$bref) or $aref->[$ai] ne $bref->[$bi]) {
      return([[['+',$ai+1,($ai>=scalar(@$aref)?'END':$aref->[$ai])],
               ['-',$bi+1,($bi>=scalar(@$bref)?'END':$bref->[$bi])]]]);
    }
    $ai++; $bi++;
  }
  return();
};

1;
