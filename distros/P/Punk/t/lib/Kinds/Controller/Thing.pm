package Kinds::Controller::Thing;
use strict;
use warnings;

# The controller t/67-route-spec.t resolves `cb => 'Thing#show'` against, to
# prove the spec form uses the same resolver the positional form does.
sub show { $_[0]->text('from-controller') }

1;
