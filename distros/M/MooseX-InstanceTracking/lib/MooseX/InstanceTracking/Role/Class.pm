package MooseX::InstanceTracking::Role::Class;
use Moose::Role;
use Set::Object::Weak;

has _instances => (
    isa     => 'Set::Object::Weak',
    default => sub { Set::Object::Weak->new },
    lazy    => 1,
    handles => {
        instances         => 'members',
        _track_instance   => 'insert',
        _untrack_instance => 'remove',
    },
);

sub get_all_instances {
    my $self = shift;
    map { $_->meta->instances } $self->name, $self->subclasses;
}

around '_construct_instance', '_clone_instance' => sub {
    my $orig = shift;
    my $self = shift;

    my $instance = $orig->($self, @_);
    $self->_track_instance($instance);

    return $instance;
};

after rebless_instance => sub {
    my $self     = shift;
    my $instance = shift;

    $self->_track_instance($instance);
};

before rebless_instance_away => sub {
    my $self     = shift;
    my $instance = shift;

    $self->_untrack_instance($instance);
};

around _inline_generate_instance => sub {
    my $orig = shift;
    my ($self, $var, $class_var) = @_;

    my @generate_instance = $orig->(@_);

    return (
        @generate_instance,
        'Moose::Meta::Class->initialize(' . $class_var . ')->_track_instance(' . $var . ');',
    );
};

1;

