package Template::Refine::Processor::Rule;
use Moose;

has 'selector' => (
    is       => 'ro',
    does     => 'Template::Refine::Processor::Rule::Select',
    required => 1,
);

has 'transformer' => ( # <insert movie reference>
    is       => 'ro',
    does     => 'Template::Refine::Processor::Rule::Transform',
    required => 1,
);

# modifies DOM in place
sub process {
    my ($self, $dom) = @_;
    my @nodes = $self->selector->select($dom);
    $_->replaceNode($self->transformer->transform($_)) for @nodes;
    return;
}

1;
