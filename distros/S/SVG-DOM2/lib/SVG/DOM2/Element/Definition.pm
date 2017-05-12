package SVG::DOM2::Element::Definition;

use base "XML::DOM2::Element";

use strict;
use warnings;

sub new
{
    my ($proto, $def, %args) = @_;
    my $self = $proto->SUPER::new($def, %args);
	$self->document->addDefinition($self);
	return $self;
}

return 1;
