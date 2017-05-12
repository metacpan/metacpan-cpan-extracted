package MooseX::MultiObject;
BEGIN {
  $MooseX::MultiObject::VERSION = '0.03';
}
# ABSTRACT: a class that delegates an interface to a set of objects that do that interface
use Moose ();
use Moose::Exporter;
use true;
use MooseX::Types::Set::Object;
use MooseX::APIRole::Internals qw(create_role_for);
use Moose::Util qw(does_role with_traits);
use Moose::Meta::TypeConstraint::Role;
use Moose::Meta::TypeConstraint::Class;
use MooseX::MultiObject::Role;
use MooseX::MultiObject::Meta::Method::MultiDelegation;
use Set::Object qw(set);
use Carp qw(confess);

Moose::Exporter->setup_import_methods(
    with_meta        => ['setup_multiobject'],
    class_metaroles  => { class => ['MooseX::MultiObject::Meta::Class'] },
);

# eventually there will be a metaprotocol for this.  for now... you
# will really like Set::Object, i know it.
sub setup_multiobject {
    my ($meta, %args) = @_;
    my $attribute = $args{attribute} || {
        init_arg => 'objects',
        coerce   => 1,
        is       => 'ro',
    };
    $attribute->{name}    ||= 'set';
    $attribute->{isa}     ||= 'Set::Object';
    $attribute->{default} ||= sub { set };
    $attribute->{coerce}  //= 1;
    $attribute->{handles} ||= {};

    confess 'you already have a set attribute name.  bailing out.'
        if $meta->has_set_attribute_name;

    my $name = delete $attribute->{name};
    $meta->add_attribute( $name => $attribute );
    $meta->set_set_attribute_name( $name ); # set is a verb and a noun!

    confess 'you must not specify both a class and a role'
        if exists $args{class} && exists $args{role};

    my ($role, $tc) = @_;

    if(my $class_name = $args{class}){
        my $class = blessed $class_name ? $class_name : $class_name->meta;
        $role = does_role( $class, 'MooseX::APIRole::Meta' ) ?
            $class->api_role : create_role_for($class);
        $tc = Moose::Meta::TypeConstraint::Class->new( class => $class_name );
    }
    elsif(my $role_name = $args{role}){
        $role = blessed $role_name ? $role_name : $role_name->meta;
        confess "provided role '$role' is not a Moose::Meta::Role!"
            unless $role->isa('Moose::Meta::Role');
        $tc = Moose::Meta::TypeConstraint::Role->new( role => $role );
    }
    else {
        confess 'you must specify either a class or a role'; # OR DIE
    }

    $tc->message(sub {
        my $arg = shift;
        return "'$arg' is not an object that can be added to this multiobject"
    });

    # add adder method -- named verbosely for maximum
    # not-conflicting-with-stuff
    $meta->add_method( add_managed_object => sub {
        my ($self, $thing) = @_;
        $tc->assert_valid($thing);
        $self->$name->insert($thing);
        return $thing;
    });

    # add getter
    $meta->add_method( get_managed_objects => sub {
        my ($self) = @_;
        return $self->$name->members;
    });

    # now invite the superdelegates
    my @methods = grep { $_ ne 'meta' } (
        $role->get_method_list,
        (map { $_->name } $role->get_required_method_list),
    );

    for my $method (@methods) {
        my $metamethod = MooseX::MultiObject::Meta::Method::MultiDelegation->new(
            name          => $method,
            package_name  => $meta->name,
            object_getter => 'get_managed_objects',
            delegate_to   => $method,
        );
        $meta->add_method($method => $metamethod);
    }

    MooseX::MultiObject::Role->meta->apply($meta);
    $role->apply($meta);

    return $meta;
}



=pod

=head1 NAME

MooseX::MultiObject - a class that delegates an interface to a set of objects that do that interface

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package Role;
    use Moose::Role;
    requires 'some_method';

    package Roles;
    use Moose;
    use MooseX::MultiObject;

    setup_multiobject (
        role => 'Role',
    );

    __PACKAGE__->meta->make_immutable;

    my $object = Class::That::Does::Role->new;
    my $another_object = Another::Class::That::Does::Role->new;

    my @results = map { $_->some_method } ($object, $another_object);

    my $both = Roles->new(
        objects => [$object, $another_object],
    );

    my @results = $both->some_methods; # the same result!

    does_role($object, 'Role'); # true
    does_role($both,   'Role'); # true

=head1 DESCRIPTION

Given a role:

    package Some::Role;
    use Moose::Role;
    requires 'foo';
    1;

and some classes that do the role:

    package Class;
    use Moose;
    with 'Some::Role';
    sub foo { ... }
    1;

and something that needs an object that C<does> C<Some::Role>:

    package Consumer;
    use Moose;

    has 'some_roller' => (
        is       => 'ro',
        does     => 'Some::Role',
        requires => 1,
    );

    sub notify_roller { $self->some_roller->foo( ... ) }

    1;

You can say something like:

    Consumer->new( some_roller => Class->new )->notify_roller;

And your roller is notified that C<foo> has occurred.  The problem
comes when you want two objects to get the message:

    Consumer->new( some_roller => [Class->new, Class->new] )->notify_roller;

That fails, because an array cannot C<does_role('Some::Role')>.  That's
where C<MooseX::MultiObject> comes in.  It can create an object that
works like that array:

    package Some::Role::Multi;
    use Moose;
    use MooseX::MultiObject;

    setup_multiobject( role => 'Some::Role' );

    __PACKAGE__->meta->make_immutable;
    1;

Now you can write:

    Consumer->new( some_roller => Some::Role::Multi->new(
        objects => [ Class->new, Class->new ],
    )->notify_roller;

and it works!

=head1 EXPORTS

=head2 setup_multiobject( %args )

You can pass C<setup_multiobject> C<< class => 'ClassName' >> instead
of C<< role => 'Role' >>, and the class's API role will be used as the
role to delegate to.  (See L<MooseX::APIRole> for information on API
roles.)

=head1 METHODS

After calling C<setup_multiobject>, your class becomes able to do the
role that you are delegating, and it also becomes able to do
C<MooseX::MultiObject::Role>.

=head2 add_managed_object

Add an object to the set of objects that the multiobject delegates to.

=head2 get_managed_objects

Return a list of the managed objects.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

