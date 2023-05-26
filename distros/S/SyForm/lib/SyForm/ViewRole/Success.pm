package SyForm::ViewRole::Success;
BEGIN {
  $SyForm::ViewRole::Success::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Fetching success value from SyForn::Results of give back true
$SyForm::ViewRole::Success::VERSION = '0.103';
use Moo::Role;

use overload 'bool' => sub { $_[0]->success };

has success => (
  is => 'lazy',
);

sub _build_success {
  my ( $self ) = @_;
  return $self->results->does('SyForm::ResultsRole::Success')
    ? $self->results->success : 1;
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewRole::Success - Fetching success value from SyForn::Results of give back true

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
