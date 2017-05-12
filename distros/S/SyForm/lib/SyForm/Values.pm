package SyForm::Values;
BEGIN {
  $SyForm::Values::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Values given of the fields through the process args
$SyForm::Values::VERSION = '0.102';
use Moo;

with qw(
  MooX::Traits
  SyForm::ValuesRole::Verify
);

has syform => (
  is => 'ro',
  required => 1,
  handles => [qw(
    field
    field_names
  )],
);

has values => (
  is => 'ro',
  required => 1,
);
sub as_hashref { $_[0]->values }

has results => (
  is => 'lazy',
);

sub _build_results {
  my ( $self ) = @_;
  my $results;
  eval {
    my %results_args;
    for my $field ($self->syform->fields->Values) {
      my %field_results_args = $field->results_args_by_values($self);
      $results_args{$_} = $field_results_args{$_} for keys %field_results_args;
    }
    $results = $self->create_results( %results_args );
  };
  SyForm->throw( UnknownErrorOnValuesBuildResults => $self, $@ ) if $@;
  return $results;
}

sub create_results {
  my ( $self, %args ) = @_;
  my %results;
  for my $field ($self->syform->fields->Values) {
    my $name = $field->name;
    $results{$name} = delete $args{$name} if exists $args{$name};
  }
  return $self->syform->loaded_results_class->new({
    values => $self,
    results => { %results },
    %args
  });
}

sub get_value {
  my ( $self, $name ) = @_;
  return $self->values->{$name};
}

sub has_value {
  my ( $self, $name ) = @_;
  return exists($self->values->{$name}) ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

SyForm::Values - Values given of the fields through the process args

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
