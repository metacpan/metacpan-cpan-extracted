package Path::Resolver::CustomConverter;
{
  $Path::Resolver::CustomConverter::VERSION = '3.100454';
}
# ABSTRACT: a one-off converter between any two types using a coderef
use Moose;
use namespace::autoclean;

use MooseX::Types;
use MooseX::Types::Moose qw(CodeRef);


has [ qw(input_type output_type) ] => (
  is  => 'ro',
  isa => class_type('Moose::Meta::TypeConstraint'),
  required => 1,
);


has converter => (
  is  => 'ro',
  isa => CodeRef,
  required => 1,
);


sub convert {
  $_[0]->converter->(@_);
}

with 'Path::Resolver::Role::Converter';
1;

__END__

=pod

=head1 NAME

Path::Resolver::CustomConverter - a one-off converter between any two types using a coderef

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $converter = Path::Resolver::CustomConverter->new({
    input_type  => SomeType,
    output_type => AnotherType,
    converter   => sub { ...return an AnotherType value... },
  });

  my $resolver = Path::Resolver::Resolver::Whatever->new({
    converter => $converter,
    ...
  });

  my $another = $resolver->entity_at('/foo/bar/baz.txt');

This class lets you produce one-off converters between any two types using an
arbitrary hunk of code.

=head1 ATTRIBUTES

=head2 input_type

This is the L<Moose::Meta::TypeConstraint> for objects that the converter
expects to be handed as input.

=head2 output_type

This is the L<Moose::Meta::TypeConstraint> for objects that the converter
promises to return as output.

=head2 converter

This is the coderef that will perform the conversion.  It will be called like a
method:  the first argument will be the converter object, followed by the value
to convert.

=head1 METHODS

=head2 convert

This method accepts an input value, passes it to the converter coderef, and
returns the result.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
