package Path::Resolver::CustomConverter 3.100455;
# ABSTRACT: a one-off converter between any two types using a coderef
use Moose;
use namespace::autoclean;

use MooseX::Types;
use MooseX::Types::Moose qw(CodeRef);

#pod =head1 SYNOPSIS
#pod
#pod   my $converter = Path::Resolver::CustomConverter->new({
#pod     input_type  => SomeType,
#pod     output_type => AnotherType,
#pod     converter   => sub { ...return an AnotherType value... },
#pod   });
#pod
#pod   my $resolver = Path::Resolver::Resolver::Whatever->new({
#pod     converter => $converter,
#pod     ...
#pod   });
#pod
#pod   my $another = $resolver->entity_at('/foo/bar/baz.txt');
#pod
#pod This class lets you produce one-off converters between any two types using an
#pod arbitrary hunk of code.
#pod
#pod =attr input_type
#pod
#pod This is the L<Moose::Meta::TypeConstraint> for objects that the converter
#pod expects to be handed as input.
#pod
#pod =attr output_type
#pod
#pod This is the L<Moose::Meta::TypeConstraint> for objects that the converter
#pod promises to return as output.
#pod
#pod =cut

has [ qw(input_type output_type) ] => (
  is  => 'ro',
  isa => class_type('Moose::Meta::TypeConstraint'),
  required => 1,
);

#pod =attr converter
#pod
#pod This is the coderef that will perform the conversion.  It will be called like a
#pod method:  the first argument will be the converter object, followed by the value
#pod to convert.
#pod
#pod =cut

has converter => (
  is  => 'ro',
  isa => CodeRef,
  required => 1,
);

#pod =method convert
#pod
#pod This method accepts an input value, passes it to the converter coderef, and
#pod returns the result.
#pod
#pod =cut

sub convert {
  $_[0]->converter->(@_);
}

with 'Path::Resolver::Role::Converter';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::CustomConverter - a one-off converter between any two types using a coderef

=head1 VERSION

version 3.100455

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
