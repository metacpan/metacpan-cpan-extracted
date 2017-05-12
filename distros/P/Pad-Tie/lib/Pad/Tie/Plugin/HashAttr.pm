use strict;
use warnings;

package Pad::Tie::Plugin::HashAttr;

use base 'Pad::Tie::Plugin::Base::HashObjectAttr';

sub attr_type { 'hash' }

sub sigil { '%' } 

sub hash_attr {
  shift->build_attrs(@_);
}

sub ref_for_attr {
  my ($plugin, $ctx, $self, $arg) = @_;
  return $self->{invocant}->{$arg->{method}} ||= {};
}

1;
