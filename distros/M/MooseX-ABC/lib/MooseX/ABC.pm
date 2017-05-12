package MooseX::ABC;
BEGIN {
  $MooseX::ABC::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::ABC::VERSION = '0.06';
}
use Moose 0.94 ();
use Moose::Exporter;
# ABSTRACT: abstract base classes for Moose



sub requires {
    shift->add_required_method(@_);
}

Moose::Exporter->setup_import_methods(
    with_meta => [qw(requires)],
);

sub init_meta {
    my ($package, %options) = @_;

    Carp::confess("Can't make a role into an abstract base class")
        if Class::MOP::class_of($options{for_class})->isa('Moose::Meta::Role');

    Moose::Util::MetaRole::apply_metaroles(
        for             => $options{for_class},
        class_metaroles => {
            class => ['MooseX::ABC::Trait::Class'],
        },
    );
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $options{for_class},
        roles => ['MooseX::ABC::Role::Object'],
    );

    Class::MOP::class_of($options{for_class})->is_abstract(1);

    return Class::MOP::class_of($options{for_class});
}


1;

__END__
=pod

=head1 NAME

MooseX::ABC - abstract base classes for Moose

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  package Shape;
  use Moose;
  use MooseX::ABC;

  requires 'draw';

  package Circle;
  use Moose;
  extends 'Shape';

  sub draw {
      # stuff
  }

  my $shape = Shape->new; # dies
  my $circle = Circle->new; # succeeds

  package Square;
  use Moose;
  extends 'Shape'; # dies, since draw is unimplemented

=head1 DESCRIPTION

B<< NOTE: This module is almost certainly a bad idea. You really want to just be using a L<role|Moose::Role> instead! >>

This module adds basic abstract base class functionality to Moose. Doing C<use
MooseX::ABC> turns the using class into an abstract class - it cannot be
instantiated. It also allows you to mark certain methods in the class as
L</required>, meaning that if a class inherits from this class without
implementing that method, it will die at compile time. Abstract subclasses are
exempt from this, however - if you extend a class with another class which uses
C<MooseX::ABC>, it will not be required to implement every required method (and
it can also add more required methods of its own). Only concrete classes
(classes which do not use C<MooseX::ABC>) are required to implement all of
their ancestors' required methods.

=head1 FUNCTIONS

=head2 requires METHOD_NAMES

Takes a list of methods that classes inheriting from this one must implement.
If a class inherits from this class without implementing each method listed
here, an error will be thrown when compiling the class.

=head1 SEE ALSO

L<Moose>

L<Moose::Role>

=for Pod::Coverage   init_meta

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

