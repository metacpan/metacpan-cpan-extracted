use strict;
use warnings;

package Moose::Micro;
our $VERSION = '0.002';


use Moose ();
use Moose::Exporter;
use B::Hooks::EndOfScope;

my ($import, $unimport);
BEGIN {
  ($import, $unimport) = Moose::Exporter->build_import_methods(
    also => 'Moose',
  );
}

sub import {
  my $class = shift;
  my $attributes = shift;

  my $caller = caller;

  on_scope_end {
    my $meta = Moose::Meta::Class->initialize($caller);
    $meta->add_attribute(@$_) for $class->attribute_list($caller, $attributes);
  };

  unshift @_, $class;
  goto &$import;
}

sub unimport { goto &$unimport }

sub attribute_list {
  my ($self, $pkg, $attributes) = @_;

  my @attributes;

  my ($required, $optional) = split /\s*;\s*/, $attributes;

  for my $attr (grep { length } split /\s+/, $required) {
    my ($name, %args) = $self->attribute_args($pkg, $attr);
    $args{required} = 1;
    push @attributes, [ $name, %args ];
  }

  for my $attr (grep { length } split /\s+/, $optional) {
    my ($name, %args) = $self->attribute_args($pkg, $attr);
    push @attributes, [ $name, %args ];
  }

  return @attributes;
}

sub attribute_args {
  my ($self, $pkg, $attribute) = @_;

  my %args = (
    is => 'rw',
  );

  if ($attribute =~ s/^([\$\@\%])//) {
    my $type = $1;
    %args = (%args, $self->type_constraint_for($type));
  }

  if ($attribute =~ s/^\!//) {
    %args = (%args, accessor => "_$attribute");
  }

  if ($pkg->can("_build_$attribute")) {
    $args{lazy_build} = 1;
  }

  return ($attribute => %args);
}

my %TC = (
  '$' => 'Value|ScalarRef|CodeRef|RegexpRef|GlobRef|Object',
  '@' => 'ArrayRef',
  '%' => 'HashRef',
);

sub type_constraint_for {
  my ($self, $sigil) = @_;

  return (isa => $TC{$sigil});
}

1;

__END__

=head1 NAME

Moose::Micro - succinctly specify Moose attributes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  package MyClass;
  use Moose::Micro 'foo $bar @baz; %!quux';

=head1 DESCRIPTION

Moose::Micro makes it easy to declare Moose attributes without a lot of typing.

=head1 SYNTAX

The argument to C<use Moose::Micro> is a list of attribute names, which is
split on whitespace.  Any attributes named before the (optional) semicolon are
required; any after it are not.

Sigils are optional, and impose the following type constraints:

=over

=item * C<@>: ArrayRef

=item * C<%>: HashRef

=item * C<$>: anything under Defined that isn't one of the above

=back

No sigil means no type constraint.

Following the sigil or prefixing the attribute name with C<!> makes the
attribute 'private'; that is, the generated accessor will start with C<_>,
e.g.:

  !foo $!bar

If your class has a method named C<_build_$attribute>, C<< lazy_build => 1 >>
is added to the attribute definition.

=head1 LIMITATIONS

All attributes are declared C<< is => 'rw' >>.

There is no way to specify many options, like default, builder, handles, etc.

=head1 METHODS

These are all internals that you probably don't care about.  They'll be
documented when they're stable.

=head2 attribute_list

=head2 attribute_args

=head2 type_constraint_for

=head2 unimport

=head1 SEE ALSO

L<Moose>

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Hans Dieter Pearcey. This is free
software; you can redistribute it and/or modify it under the same terms as perl
itself. 

=cut