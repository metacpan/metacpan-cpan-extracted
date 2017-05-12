package MooseX::RelatedClassRoles;
our $VERSION = '0.004';

# ABSTRACT: Apply roles to a class related to yours
use MooseX::Role::Parameterized;

parameter name => (
  isa      => 'Str',
  required => 1,
);

parameter class_accessor_name => (
  isa      => 'Str',
  lazy     => 1,
  default  => sub { $_[0]->name . '_class' },
);

parameter apply_method_name => (
  isa      => 'Str',
  lazy     => 1,
  default  => sub { 'apply_' . $_[0]->class_accessor_name . '_roles' },
);

# This is undocumented because you shouldn't use it unless you really know you
# have to.
parameter require_class_accessor => (
  isa      => 'Bool',
  default  => 1,
);

role {
  my $p = shift;

  my $class_accessor_name = $p->class_accessor_name;
  my $apply_method_name   = $p->apply_method_name;

  requires $class_accessor_name
    if $p->require_class_accessor;

  method $apply_method_name => sub {
    my $self = shift;
    my $meta = Moose::Meta::Class->create_anon_class(
      superclasses => [ $self->$class_accessor_name ],
      roles        => [ @_ ],
      cache        => 1,
    );
    $self->$class_accessor_name($meta->name);
  };
};

no MooseX::Role::Parameterized;
1;




=pod

=head1 NAME

MooseX::RelatedClassRoles - Apply roles to a class related to yours

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package My::Class;
    use Moose;

    has driver_class => (
      isa => 'MyApp::Driver',
    );

    with 'MooseX::RelatedClassRoles' => { name => 'driver' };

    # ...

    my $obj = My::Class->new(driver_class => "Some::Driver");
    $obj->apply_driver_class_roles("Other::Driver::Role");

=head1 DESCRIPTION

Frequently, you have to use a class that provides some C<foo_class> accessor or
attribute as a method of dependency injection.  Use this role when you'd rather
apply roles to make your custom C<foo_class> instead of manually setting up a
subclass.

=head1 PARAMETERS

=head2 name

A string naming the related class.  C<driver> in the L</SYNOPSIS>.  Required.

=head2 class_accessor_name

A string naming the related class accessor.  C<driver_class> in the
L</SYNOPSIS>.  Defaults to appending C<_class> to the C<name>.

=head2 apply_method_name

A string naming the role applying method.  C<apply_driver_class_names> in the
L</SYNOPSIS>.  Defaults to adding C<apply_> and C<_names> to the
C<class_accessor_name>.

=head1 BLAME

    Florian Ragwitz (rafl)

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Hans Dieter Pearcey <hdp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut 



__END__

