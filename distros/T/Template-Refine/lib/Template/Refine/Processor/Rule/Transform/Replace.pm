package Template::Refine::Processor::Rule::Transform::Replace;
use Moose;

with 'Template::Refine::Processor::Rule::Transform';

has 'replacement' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub transform {
    my ($self, $node) = @_;
    return $self->replacement->($node);
}

1;
