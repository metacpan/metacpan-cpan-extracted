use strict;
use warnings;

package Pad::Tie::Plugin::ScalarAttr;

use base 'Pad::Tie::Plugin::Base::HashObjectAttr';

sub attr_type { 'scalar' }

sub sigil { '$' } 

sub scalar_attr {
  shift->build_attrs(@_);
}

sub ref_for_attr {
  my ($plugin, $ctx, $self, $arg) = @_;
  return \$self->{invocant}->{$arg->{method}};
}

1;
