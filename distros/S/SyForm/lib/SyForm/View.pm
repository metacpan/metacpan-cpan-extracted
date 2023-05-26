package SyForm::View;
BEGIN {
  $SyForm::View::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Container for SyForm::Results and SyForm::ViewField
$SyForm::View::VERSION = '0.103';
use Moo;
use Tie::IxHash;
use Module::Runtime qw( use_module );

with qw(
  MooX::Traits
  SyForm::ViewRole::Success
  SyForm::ViewRole::Verify
  SyForm::ViewRole::HTML
  SyForm::ViewRole::Bootstrap
);

has results => (
  is => 'ro',
  required => 1,
  handles => [qw(
    syform
    values
  )],
);
sub has_results { 1 } # results should be optional

has field_names => (
  is => 'lazy',
);

sub _build_field_names {
  my ( $self ) = @_;
  return [ map { $_->name } $self->fields->Values ];
}

has fields => (
  is => 'lazy',
  init_arg => undef,
);
sub viewfields { shift->fields }
sub field { shift->fields->FETCH(@_) }
sub viewfield { shift->fields->FETCH(@_) }

sub _build_fields {
  my ( $self ) = @_;
  my $fields = Tie::IxHash->new;
  for my $field ($self->syform->fields->Values) {
    $fields->Push(map { $_->name, $_ } $field->viewfields_for_view($self))
      if $field->can('viewfields_for_view');
  }
  return $fields;
}

1;

__END__

=pod

=head1 NAME

SyForm::View - Container for SyForm::Results and SyForm::ViewField

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
