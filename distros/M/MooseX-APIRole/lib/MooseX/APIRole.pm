package MooseX::APIRole;
BEGIN {
  $MooseX::APIRole::VERSION = '0.01';
}
# ABSTRACT: automatically create API roles for your classes and roles
use Moose ();
use Moose::Exporter;
use Carp qw(confess);
use true;

Moose::Exporter->setup_import_methods(
    with_meta       => [qw/set_api_role_name apply_api_role make_api_role/],
    class_metaroles => { class => ['MooseX::APIRole::Meta'] },
    role_metaroles  => { role  => ['MooseX::APIRole::Meta'] },
);

sub set_api_role_name {
    my ($meta, $name) = @_;
    confess 'if you want a named api role, you should supply the name (retardo)'
        if !$name;

    $meta->set_api_role_name($name);
    return $meta;
}

sub apply_api_role {
    my ($meta) = @_;
    $meta->get_api_role->apply($meta); # meta.
    return $meta;
}

sub make_api_role {
    my ($meta, $name) = @_;
    set_api_role_name($meta, $name);
    apply_api_role($meta);
    return $meta;
}



=pod

=head1 NAME

MooseX::APIRole - automatically create API roles for your classes and roles

=head1 VERSION

version 0.01

=head1 SYNOPSIS

If you write a Moose class like this:

    package Class;
    use Moose;
    use MooseX::APIRole;
    use true;
    use namespace::autoclean;

    sub foo {}

    make_api_role 'Class::API';

    __PACKAGE__->meta->make_immutable;

C<MooseX::APIRole> will automatically create an API role like this:

    package Class::API;
    use Moose::Role;

    requires 'foo';

And apply it to your class.

If you forget what you called the API role, or don't want the API role to have a name,
you can get at it via the metaclass:

    my $role = Class->meta->get_api_role;

You can then treat C<$role> like you would any other role.

You can also create API roles for roles:

    package Role;
    use Moose::Role;
    use MooseX::APIRole;
    use true;
    use namespace::autoclean;

    sub foo {}
    requires 'bar';

    make_api_role 'Role::API';

This results in the following role:

    package Role::API;
    use Moose::Role;

    requires 'foo';
    requires 'bar';

If you do not call C<make_api_role> or C<apply_api_role>, you can
still get the lazily-built anonymous API role via the metaclass.  But
the class won't C<does_role> the role, which could be confusing.

=head1 DESCRIPTION

Inheritance is handled such that if C<Subclass> extends C<Class> with
API role C<APIRole>, C<Subclass> will also do the C<APIRole>.  The
same applies to roles; if C<Role> does C<RoleAPI> and C<AnotherRole>
consumes C<Role>, then C<AnotherRole> will also do C<RoleAPI>.

Wunderbar.

=head1 FUNCTIONS

You can control the behavior of this module by calling these imported
functions:

=head2 set_api_role_name(ClassName)

This is the namespace that you want the API role to be in.  The
results of using an existing class name are undefined.  It's likely
that demons will come out of your nose and all your plants will die.
So come up with a unique name.

=head2 apply_api_role

If you want the API role to be applied to your class or role, call this function.

You almost always want to do this, but it can't be done automatically
for the same reason that C<< Class->meta->make_immutable >> can't be
done automatically.

=head2 make_api_role(ClassName)

Works like C<set_api_role_name> followed by C<apply_api_role>.

=head1 SEE ALSO

See L<MooseX::APIRole::Meta> for the metaclass attributes you get.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

