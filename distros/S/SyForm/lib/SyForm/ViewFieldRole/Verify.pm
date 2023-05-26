package SyForm::ViewFieldRole::Verify;
BEGIN {
  $SyForm::ViewFieldRole::Verify::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Trait for SyForm fields of SyForm::Results and SyForm::Values attributes
$SyForm::ViewFieldRole::Verify::VERSION = '0.103';
use Moo::Role;

has is_invalid => (
  is => 'lazy',
);

sub _build_is_invalid {
  my ( $self ) = @_;
  return $self->is_valid ? 0 : 1;
}

has is_valid => (
  is => 'lazy',
);

sub _build_is_valid {
  my ( $self ) = @_;
  my @errors = @{$self->errors};
  return scalar @errors > 0 ? 0 : 1;
}

has errors => (
  is => 'lazy',
);

sub _build_errors {
  my ( $self ) = @_;
  return $self->results->does('SyForm::ResultsRole::Success')
    ? $self->results->syccess_result->errors($self->name) : [];
}

# sub has_original_value {
#   my ( $self ) = @_;
#   return $self->has_value;
# }

# sub original_value {
#   my ( $self ) = @_;
#   return $self->results->verify_results->get_original_value($self->name);
# }

1;

__END__

=pod

=head1 NAME

SyForm::ViewFieldRole::Verify - Trait for SyForm fields of SyForm::Results and SyForm::Values attributes

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
