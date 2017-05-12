package TAP::Spec::Plan::Todo;
BEGIN {
  $TAP::Spec::Plan::Todo::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Plan::Todo::VERSION = '0.10';
}
# ABSTRACT: A legacy TAP plan indicating TODO tests
use Mouse;
use namespace::autoclean;
extends 'TAP::Spec::Plan::Simple';


has 'skipped_tests' => (
  is => 'rw',
  isa => 'ArrayRef',
  required => 1,
);


around 'as_tap' => sub {
  my ($self, $inner) = @_;

  my $tap = $inner->();
  my $append = " todo";
  $append .= " $_" for @{ $self->skipped_tests };
  $tap =~ s/$/$append/;
  return $tap;
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::Plan::Todo - A legacy TAP plan indicating TODO tests

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 skipped_tests

B<Required>: An arrayref of the test numbers that should be considered
TODO.

=head1 METHODS

=head2 $plan->as_tap

TAP Representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
