package SVG::DOM2::Element::Definition::radialGradient;

use base "SVG::DOM2::Element::Definition";

use strict;
use warnings;

sub new
{
    my ($proto, %args) = @_;
    my $self = $proto->SUPER::new('radialGradient', %args);
	return $self;
}

return 1;
