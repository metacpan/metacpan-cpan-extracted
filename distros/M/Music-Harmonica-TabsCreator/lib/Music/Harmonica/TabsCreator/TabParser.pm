package Music::Harmonica::TabsCreator::TabParser;

use 5.036;
use strict;
use warnings;
use utf8;

use Readonly;

our $VERSION = '0.05';

# This class converts a tab into tones (degrees) relative to the key of C4.
# It accepts an input specifying the tuning of an harmonica.

sub new ($class, $tab_to_tones) {
  # We order the keys by length, so that we match the longest ones first.
  my $re = join('|', map { quotemeta } sort { length $b <=> length $a } keys %{$tab_to_tones});
  my $self = bless {
    tab_to_tones => $tab_to_tones,
    tab_re => qr/$re/,
  }, $class;
  return $self;
}

sub parse ($self, $tab) {
  my @out;
  pos($tab) = 0;
  while (pos($tab) < length($tab)) {
    next if $tab =~ m/\G\h+/gc;

    if ($tab =~ m/\G(\v+)/gc) {
      push @out, $1;
      next;
    }

    if ($tab =~ m/ \G \# \s* ( .*? (?:\r\n|\n|\r|\v|\z) )/xgc) {
      push @out, $1;
      next;
    }

    if ($tab =~ m/\G($self->{tab_re})/gc) {
      push @out, $self->{tab_to_tones}{$1};
      next;
    }

    my $pos = pos($tab);
    substr $tab, $pos, 0, '-->';
    $pos++;
    die "Invalid syntax in the input tab at character ${pos}: ${tab}\n";
  }
  return wantarray ? @out : \@out;
}

1;
