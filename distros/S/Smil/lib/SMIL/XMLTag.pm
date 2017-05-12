package SMIL::XMLTag;

$VERSION = "0.898";

use SMIL::XMLBase;

@ISA = qw( SMIL::XMLBase );

use Carp;

sub getAsString {
    my $self = shift;
    my $return_string;
    my $tab = 	$self->getTabBuffer();
    $return_string .= "$tab<" . $self->{_tag} . 
	$self->_build_attributes() . "/>";
    return $return_string;
}

1;
