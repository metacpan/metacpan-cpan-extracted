package Regexp::Extended::MatchGroup;

use strict;
use Carp;
use Regexp::Extended::MatchArray;
use overload '%{}' => \&gethash, '@{}' => \&getarray;

sub new {
  my ($this, $parent, $name) = @_;
  my $class = ref($this) || $this;
  my $data = {
    'parent'     => $parent,
    'name'       => $name,
    'matches'    => [],
    'subMatches' => {},
  };
  my $self = \$data;
  bless $self, $class;
  return $self;
}

sub gethash {
  my $self = shift;
  my %h;
  tie %h, ref $self, $self;
  \%h;
}

sub getarray {
  my $self = shift;
  my @h;
  tie @h, ref $self, $self;
  \@h;
}

sub TIEARRAY { my $p = shift; bless \ shift, "Regexp::Extended::MatchArray" }

return 1;
