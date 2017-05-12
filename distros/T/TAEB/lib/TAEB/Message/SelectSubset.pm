package TAEB::Message::SelectSubset;
use Moose::Role;

has items => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has _is_selected => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [ 0 x shift->items ] },
);

sub select {
    my $self = shift;

    for my $selection (@_) {
        for my $index (0 .. $self->items - 1) {
            my $item = $self->items->[$index];
            $self->_is_selected->[$index] = 1 if $item eq $selection;
        }
    }
}

sub selected {
    my $self = shift;

    return map  { $self->items->[$_] }
           grep { $self->_selected->[$_] }
           0 .. $self->items - 1;
}

no Moose::Role;

1;

