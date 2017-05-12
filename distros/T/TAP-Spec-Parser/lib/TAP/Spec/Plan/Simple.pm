package TAP::Spec::Plan::Simple;
BEGIN {
  $TAP::Spec::Plan::Simple::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Plan::Simple::VERSION = '0.10';
}
# ABSTRACT: A basic TAP plan with a number of tests
use Mouse;
use namespace::autoclean;
extends 'TAP::Spec::Plan';


has 'number_of_tests' => (
  is => 'rw',
  isa => 'Num',
  required => 1,
);


sub as_tap {
  my ($self) = @_;
  return "1.." . $self->number_of_tests . "\n";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::Plan::Simple - A basic TAP plan with a number of tests

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 number_of_tests

B<Required>: The number of tests planned

=head1 METHODS

=head2 $plan->as_tap

TAP representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
