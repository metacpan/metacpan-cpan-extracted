package MouseX::Foreign::Meta::Role::Method::Constructor;
use Mouse::Role;

around _generate_constructor => sub {
    my($next, undef, $meta, $option) = @_;

    # The foreign superlcass must have the new method
    my $foreign_buildargs  = $meta->name->can('FOREIGNBUILDARGS');
    my $foreign_superclass = $meta->foreign_superclass;
    my $super_new          = $foreign_superclass->can('new');
    my $needs_buildall     = !$foreign_superclass->can('BUILDALL');

    return sub {
        my $class  = shift;
        my $args = $class->BUILDARGS(@_);
        my $object = $foreign_buildargs
            ? $class->$super_new($class->$foreign_buildargs(@_))
            : $class->$super_new(                           @_ );
        $object->meta->_initialize_object($object, $args);
        $object->BUILDALL($args) if $needs_buildall;

        return $object;
    };
};

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::Foreign::Meta::Role::Method::Constructor - The MouseX::Foreign meta method constructor role

=head1 DESCRIPTION

This is the meta method constructor role for MouseX::Foreign.

=head1 SEE ALSO

L<MouseX::Foreign>

=cut
