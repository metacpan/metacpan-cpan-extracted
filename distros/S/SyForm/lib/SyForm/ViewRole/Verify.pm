package SyForm::ViewRole::Verify;
BEGIN {
  $SyForm::ViewRole::Verify::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Trait for SyForm fields of SyForm::Results and SyForm::Values attributes
$SyForm::ViewRole::Verify::VERSION = '0.102';
use Moo::Role;

requires qw(
  success
);

has error_count => (
  is => 'lazy',
);

sub _build_error_count {
  my ( $self ) = @_;
  return $self->results->errors($self->name);
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewRole::Verify - Trait for SyForm fields of SyForm::Results and SyForm::Values attributes

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
