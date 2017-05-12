package Scene::Graph::Node::Transform;
use Moose;

extends 'Scene::Graph::Node';

has 'rotation' => (
    traits => [ 'Number' ],
    is => 'rw',
    isa => 'Num',
    handles => {
        rotate => 'add'
    }
);

has 'scaling_x' => (
    traits => [ 'Number' ],
    is => 'rw',
    isa => 'Num',
    handles => {
         scale_x => 'add'
    }
);

has 'scaling_y' => (
    traits => [ 'Number' ],
    is => 'rw',
    isa => 'Num',
    handles => {
         scale_y => 'add'
    }
);

has 'translation_x' => (
    traits => [ 'Number' ],
    is => 'rw',
    isa => 'Num',
    handles => {
         translate_x => 'add'
    }
);

has 'translation_y' => (
    traits => [ 'Number' ],
    is => 'rw',
    isa => 'Num',
    handles => {
         translate_y => 'add'
    }
);

__PACKAGE__->meta->make_immutable;

1;
