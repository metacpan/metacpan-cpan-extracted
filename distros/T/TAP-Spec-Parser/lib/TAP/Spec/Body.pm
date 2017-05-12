package TAP::Spec::Body;
BEGIN {
  $TAP::Spec::Body::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Body::VERSION = '0.10';
}
# ABSTRACT: The main body of a TAP testset
use Mouse;
use namespace::autoclean;

use TAP::Spec::Comment ();
use TAP::Spec::JunkLine ();
use TAP::Spec::TestResult ();
use TAP::Spec::BailOut ();


has 'lines' => (
  is => 'rw',
  isa => 'ArrayRef',
  predicate => 'has_lines',
);


sub tests {
  my ($self) = @_;

  return () unless $self->has_lines;
  return grep $_->isa('TAP::Spec::TestResult'), @{ $self->lines };
}


sub as_tap {
  my ($self) = @_;

  my $tap = "";
  return "" unless $self->has_lines;

  for my $line (@{ $self->lines }) {
    $tap .= $line->as_tap;
  }

  return $tap;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::Body - The main body of a TAP testset

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 lines

B<Optional>: The lines (TestResults, Comments, BailOuts) of the body.
TODO: remove the predicate and make it default => [] once Regexp::Grammars
calls constructors.

=head1 METHODS

=head2 $body->tests

Returns a list of the test results from the C<lines>.

=head2 $body->as_tap

TAP representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
