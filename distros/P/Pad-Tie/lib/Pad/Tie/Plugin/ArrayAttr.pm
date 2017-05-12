use strict;
use warnings;

package Pad::Tie::Plugin::ArrayAttr;

use base 'Pad::Tie::Plugin::Base::HashObjectAttr';

sub attr_type { 'array' }

sub sigil { '@' } 

sub array_attr {
  shift->build_attrs(@_);
}

sub ref_for_attr {
  my ($plugin, $ctx, $self, $arg) = @_;
  return $self->{invocant}->{$arg->{method}} ||= [];
}

1;
