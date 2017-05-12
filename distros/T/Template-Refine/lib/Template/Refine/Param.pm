package Template::Refine::Param;
use Moose;

has 'thunk' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub force {
    my $self = shift;
    return $self->thunk->();
}

1;
