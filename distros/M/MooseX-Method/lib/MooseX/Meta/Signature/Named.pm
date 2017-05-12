package MooseX::Meta::Signature::Named;

use Moose;

use Moose::Util qw/does_role/;
use MooseX::Meta::Parameter::Moose;
use MooseX::Method::Exception;

with qw/MooseX::Meta::Signature/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub _parameter_metaclass { 'MooseX::Meta::Parameter::Moose' }

sub new {
  my ($class,%parameters) = @_;

  my $self = $class->meta->new_object;

  $self->{'%!parameter_map'} = {};

  for (keys %parameters) {
    my $parameter = $parameters{$_};

    if (ref $parameter eq 'HASH') {
      if (exists $parameter->{metaclass}) {
        $parameter = $parameter->{metaclass}->new ($parameter);
      } else {
        $parameter = $self->_parameter_metaclass->new ($parameter);
      }
    }

    MooseX::Method::Exception->throw ("Parameter must be a MooseX::Meta::Parameter or coercible into one")
      unless does_role ($parameter,'MooseX::Meta::Parameter');

    $self->{'%!parameter_map'}->{$_} = $parameter;
  }

  return $self;
}

sub validate {
  my $self = shift;

  my $args;

  if (ref $_[0] eq 'HASH') {
    $args = $_[0];
  } else {
    $args = { @_ };
  }

  my $name;

  eval {
    for (keys %{$self->{'%!parameter_map'}}) {
      $name = $_;

      $args->{$_} = $self->{'%!parameter_map'}->{$_}->validate (( exists $args->{$_} ? $args->{$_} : ()));
    }
  };

  if ($@) {
    if (blessed $@ && $@->isa ('MooseX::Method::Exception')) {
      $@->error ("Parameter ($name): " . $@->error);

      $@->rethrow;
    } else {
      die $@;
    }
  }

  return $args;
}

sub export {
  my ($self) = @_;

  my $export = {};

  $export->{$_} = $self->{'%!parameter_map'}->{$_}->export
    for keys %{$self->{'%!parameter_map'}};

  return $export;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Signature::Named - Named signature metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Signature::Named;

  my $signature = MooseX::Meta::Signature::Named->new (
    foo => { required => 1 },
    bar => { required => 1 },
  );

  my $results;

  eval {
    $results = $signature->validate (foo => 1);
  };

  print Dumper($signature->export);

=head1 METHODS

=over 4

=item B<validate>

Validate the arguments against the signature. Accepts arguments in the
form of a hashref or a hash. Returns a hashref of the validated
arguments or throws an exception on validation error.

=item B<export>

Exports a data structure representing the signature.

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

