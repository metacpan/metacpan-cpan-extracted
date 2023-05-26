package SyForm::FieldRole::Default;
BEGIN {
  $SyForm::FieldRole::Default::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: A default for the field
$SyForm::FieldRole::Default::VERSION = '0.103';
use Moo::Role;

has default => (
  is => 'ro',
  predicate => 1,
);

around has_value_by_args => sub {
  my ( $orig, $self, %args ) = @_;
  return 1 if $self->$orig(%args);
  return 1 if $self->has_default;
  return 0;
};

around get_value_by_process_args => sub {
  my ( $orig, $self, %args ) = @_;
  return $self->default if !exists($args{$self->name}) && $self->has_default;
  return $self->$orig(%args);
};

1;

__END__

=pod

=head1 NAME

SyForm::FieldRole::Default - A default for the field

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
