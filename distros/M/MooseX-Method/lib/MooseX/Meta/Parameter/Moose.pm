package MooseX::Meta::Parameter::Moose;

use Moose;

use Moose::Util::TypeConstraints;
use MooseX::Method::Exception;
use Scalar::Util qw/blessed/;

with qw/MooseX::Meta::Parameter/;

has isa             => (is => 'bare', isa => 'Str | Object');
has does            => (is => 'bare', isa => 'Str');
has required        => (is => 'bare', isa => 'Bool');
has default         => (is => 'bare', isa => 'Defined');
has coerce          => (is => 'bare', isa => 'Bool');
has type_constraint => (is => 'bare', isa => 'Moose::Meta::TypeConstraint');

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub BUILD {
  my ($self) = @_;

  if (defined $self->{isa}) {
    if (blessed ($self->{isa})) {
      if ($self->{isa}->isa ('Moose::Meta::TypeConstraint')) {
        $self->{type_constraint} = $self->{isa};
      } else {
        MooseX::Method::Exception->throw ("You cannot specify an object as type if it's not a type constraint");
      }
    } else {
      if ($self->{isa} =~ /\|/) {
        my @type_constraints = split /\s*\|\s*/,$self->{isa};

        $self->{type_constraint} = Moose::Util::TypeConstraints::create_type_constraint_union (@type_constraints);
      } else {
        my $constraint = find_type_constraint ($self->{isa});     
          
        $constraint = subtype ('Object',where { $_->isa ($self->{isa}) })
          unless defined $constraint;

        $self->{type_constraint} = $constraint;
      }
    }
  }

  if ($self->{coerce}) {
    MooseX::Method::Exception->throw ("You cannot set coerce if type does not support this")
      unless defined $self->{type_constraint} && $self->{type_constraint}->has_coercion;
  }

  return;
}

sub validate {
  my ($self,$value) = @_;

  my $provided = ($#_ > 0 ? 1 : 0);

  if (! $provided && defined $self->{default}) {
    if (ref $self->{default} eq 'CODE') {
      $value = $self->{default}->();
    } else {
      $value = $self->{default};
    }

    $provided = 1;
  }

  if ($provided) {
    if (defined $self->{type_constraint}) {
      my $constraint = $self->{type_constraint};

      unless ($constraint->check ($value)) {
        if ($self->{coerce}) {
          my $return = $constraint->coerce ($value);

          MooseX::Method::Exception->throw ("Argument isn't ($self->{isa})")
            unless $constraint->check ($return);

          $value = $return;
        } else {
          MooseX::Method::Exception->throw ("Argument isn't ($self->{isa})");
        }
      }
    }

    if (defined $self->{does}) {
      unless (blessed $value && $value->can ('does') && $value->does ($self->{does})) {
        MooseX::Method::Exception->throw ("Does not do ($self->{does})");
      }
    }
  } elsif ($self->{required}) {
    MooseX::Method::Exception->throw ("Must be specified");
  }

  return $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Parameter::Moose - Moose style parameter metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Parameter::Moose;

  my $parameter = MooseX::Meta::Parameter::Moose->new (isa => 'Int');

  my $result;

  eval {
    $result = $parameter->validate ("foo");
  };

  print Dumper($parameter->export);

=head1 METHODS

=over 4

=item B<validate>

Takes an argument, validates it, and returns the argument or possibly
a coerced version of it. Exceptions are thrown on validation failure.

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

