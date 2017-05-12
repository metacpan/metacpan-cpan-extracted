package TAEB::Role::Initialize;
use Moose::Role;

sub initialize { }
after initialize => sub {
    my $self = shift;

    my @attrs = $self->meta->get_all_attributes;
    push @attrs, $self->meta->get_all_class_attributes
        if $self->meta->can('get_all_class_attributes');

    for my $attr (@attrs) {
        next if $attr->is_weak_ref;

        my $class;
        if ($attr->has_type_constraint) {
            my $type_constraint = $attr->type_constraint;
            # XXX: do we care about unions?
            $type_constraint = $type_constraint->type_parameter
                if $type_constraint->is_a_type_of('Maybe');
            # don't check non-classes
            next unless $type_constraint->is_a_type_of('Object');
            $class = $type_constraint->name;
            Class::MOP::load_class($class);
        }
        else {
            my $value = $attr->get_read_method_ref->($self);
            $class = blessed($value);
        }

        next unless $class;
        # don't go into non-cmop classes
        next unless $class->can('meta');
        # don't go into non-moose classes
        next unless $class->meta->can('does_role');
        # don't go into non-taeb classes
        next unless $class->meta->does_role(__PACKAGE__);
        # don't go into attributes we explicitly don't allow
        next if $attr->does('TAEB::Meta::Trait::DontInitialize');

        my $value = $attr->get_read_method_ref->($self);
        next unless $value;
        $value->initialize;
    }
};

no Moose::Role;

1;

