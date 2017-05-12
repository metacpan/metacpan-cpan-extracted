package MooseX::AttributeDefaults;
use Moose::Role;

requires qw(default_options);

our $VERSION = '0.02';

before '_process_options' => sub {
  my ($class, $name, $options) = @_;
  my %defaults = $class->default_options($name);
  foreach my $k (keys %defaults) { 
    $options->{$k} = $defaults{$k} unless (defined $options->{$k});
  }
};

no Moose::Role; 1;

__END__

=head1 NAME

MooseX::AttributeDefaults - Role to provide default option for your attribute 
metaclasses

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Although you can do similar things by overriding attributes in subclasses of
Moose::Meta::Attribute, there are a couple of gotchas (as of this writing, for
instance, overriding 'is' does nothing at all).  This role abstracts the 
implementation details of the available workarounds.

    package My::Custom::Metaclass;
    use Moose;

    extends 'Moose::Meta::Attribute';
    with    'MooseX::AttributeDefaults';

    sub default_options {
      my ($class, $name) = @_;
      
      return (
        is      => 'ro',
        isa     => 'Str',
        default => "default value for $name";
      );
    }

    package Some::Class;
    use Moose;

    has 'attr' => (
      metaclass => 'My::Custom::Metaclass',
      predicate => 'has_attr',
    );

    # 'attr' is a ro string with "default value for attr" as its 
    # default and a 'has_attr' predicate

    ### Or as a trait instead of a metaclass
    
    package Acme::Common::Array;
    use Moose::Role;

    with qw(MooseX::AttributeDefaults);

    sub default_options {
      is      => 'ro',
      isa     => 'ArrayRef',
      default => sub { [] },
    }

    package Some::Class;
    use Moose;
    use MooseX::AttributeHelpers;

    has attr => (
      metaclass => 'Collection::Array',
      traits    => [qw(Acme::Common::Array)],
      provides  => {
        'push' => 'add_attr',
      },
    );

=head1 REQUIRED METHODS

=head2 default_options

Return a list of options to default to.  This is called as a class method with
the attribute name as its only argument.

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 Paul Driver.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
