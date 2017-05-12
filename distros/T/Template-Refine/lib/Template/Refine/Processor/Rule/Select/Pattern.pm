package Template::Refine::Processor::Rule::Select::Pattern;
use Moose::Role;

with 'Template::Refine::Processor::Rule::Select';

has 'pattern' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
