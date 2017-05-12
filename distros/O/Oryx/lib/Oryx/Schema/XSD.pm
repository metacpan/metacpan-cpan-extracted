package Oryx::Schema::XSD;

use XML::DOM::Lite qw(Document);

our $XSD_TYPES = {
    'xsd:token'        => 'String',
    'xsd:string'       => 'Text',
    'xsd:integer'      => 'Integer',
    'xsd:float'        => 'Float',
    'xsd:dateTime'     => 'DateTime',
    'xsd:boolean'      => 'Boolean',
    'xsd:base64Binary' => 'Binary',
};

our $TYPE_2_XSD = { reverse %$XSD_TYPES };

sub complexType {
    my ($self, $class, $doc) = @_;
    $doc ||= Document->new();

    my $complexType = $doc->createElement('xsd:complexType');
    $complexType->setAttribute("name", $class);
    my $all = $doc->createElement("xsd:all");
    $complexType->appendChild($all);

    foreach (values %{$class->attributes}) {
        my $attribute = $doc->createElement("xsd:attribute");
        $attribute->setAttribute("name", $_->name);
        $attribute->setAttribute("type", $TYPE_2_XSD->{$_->type});
        $all->appendChild($attribute);
    }

    foreach (values %{$class->associations}) {
        my $element = $doc->createElement("xsd:element");
        $element->setAttribute("name", $_->role);
        $all->appendChild($element);

        if ($_->type eq "Reference") {
            $element->setAttribute("type", $_->class);
        }
        else {
            my $complexType2 = $doc->createElement("xsd:complexType");
            $element->appendChild($complexType2);

            my $sequence = $doc->createElement("xsd:sequence");
            $complexType2->appendChild($sequence);

            my $element2 = $doc->createElement("xsd:element");
            $element2->setAttribute("name", $_->class->name);
            $element2->setAttribute("type", $_->class);
            $sequence->appendChild($element2);

            if ($_->type eq "Hash") {
                my $attribute = $doc->createElement("xsd:attribute");
                $attribute->setAttribute("name", "keys");
                $attribute->setAttribute("type", "NMTOKENS");
                $sequence->appendChild($attribute);
            }
        }
    }
    return $complexType;
}

sub generate {
    my ($self, $schema) = @_;
    my $doc = Document->new();

    my $xsdschema = $doc->createElement("xsd:schema");
    $xsdschema->setAttribute('xmlns:xsd', 'http://www.w3.org/2001/XMLSchema');
    $doc->appendChild($xsdschema);

    foreach my $class ($schema->classes) {
        $xsdschema->appendChild($self->complexType($class, $doc));
    }

    return $doc;
}


