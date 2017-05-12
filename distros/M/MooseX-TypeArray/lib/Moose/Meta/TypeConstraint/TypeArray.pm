
use strict;
use warnings;

package Moose::Meta::TypeConstraint::TypeArray;
BEGIN {
  $Moose::Meta::TypeConstraint::TypeArray::VERSION = '0.1.0';
}

# ABSTRACT: Moose 'TypeArray' Base type constraint type.

use metaclass;

# use Moose::Meta::TypeCoercion::TypeArray;
use Moose::Meta::TypeConstraint;
use Try::Tiny;
use parent 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute(
  'combining' => (
    accessor => 'combined_constraints',
    default  => sub { [] },
  )
);

__PACKAGE__->meta->add_attribute(
  'internal_name' => (
    accessor => 'internal_name',
    default  => sub { [] },
  )
);

__PACKAGE__->meta->add_attribute( '_default_message' => ( accessor => '_default_message', ) );

my $_default_message_generator = sub {
  my ( $name, $constraints_ ) = @_;
  my (@constraints) = @{$constraints_};

  return sub {
    my $value = shift;
    require MooseX::TypeArray::Error;
    my %errors = ();
    for my $type (@constraints) {
      if ( my $error = $type->validate($value) ) {
        $errors{ $type->name } = $error;
      }
    }
    return MooseX::TypeArray::Error->new(
      name   => $name,
      value  => $value,
      errors => \%errors,
    );
  };
};

sub get_message {
  my ( $self, $value ) = @_;
  my $msg = $self->message || $self->_default_message;
  local $_ = $value;
  return $msg->($value);
}

sub new {
  my ( $class, %options ) = @_;

  my $name = 'TypeArray(' . ( join q{,}, sort { $a cmp $b } map { $_->name } @{ $options{combining} } ) . ')';

  my $self = $class->SUPER::new(
    name          => $name,
    internal_name => $name,

    %options,
  );
  $self->_default_message( $_default_message_generator->( $self->name, $self->combined_constraints ) )
    unless $self->has_message;

  return $self;
}

sub _actually_compile_type_constraint {
  my $self        = shift;
  my @constraints = @{ $self->combined_constraints };
  return sub {
    my $value = shift;
    foreach my $type (@constraints) {
      return if not $type->check($value);
    }
    return 1;
  };
}

sub validate {
  my ( $self, $value ) = @_;
  foreach my $type ( @{ $self->combined_constraints } ) {
    return $self->get_message($value) if defined $type->validate($value);
  }
  return;
}

1;

__END__
=pod

=head1 NAME

Moose::Meta::TypeConstraint::TypeArray - Moose 'TypeArray' Base type constraint type.

=head1 VERSION

version 0.1.0

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

