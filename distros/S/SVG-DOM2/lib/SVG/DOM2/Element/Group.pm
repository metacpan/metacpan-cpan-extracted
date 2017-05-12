package SVG::DOM2::Element::Group;

use base "SVG::DOM2::Element::Shape";
use base "SVG::DOM2::Element::Shape::Fill";
use base "SVG::DOM2::Element::Shape::Stroke";
use base "SVG::DOM2::Element::Shape::Font";

sub new
{
	my ($proto, %args) = @_;
	return $proto->SUPER::new('g', %args);
}
sub _can_contain_elements { 1 }
sub has_font { 1 }

return 1;
