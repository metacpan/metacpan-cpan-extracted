package Template::Refine::Processor::Rule::Select;
use Moose::Role;

requires 'select';

before 'select' => sub {
    my ($self, $doc) = @_;
    confess 'The document must be an XML::LibXML::Document' 
      unless eval { $doc->isa('XML::LibXML::Document') };
};

1;
