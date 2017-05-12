package TAP::Spec::TestResult;
BEGIN {
  $TAP::Spec::TestResult::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::TestResult::VERSION = '0.10';
}
# ABSTRACT: The results of a single test
use Mouse;
use Mouse::Util::TypeConstraints;
use namespace::autoclean;

enum 'TAP::Spec::TestStatus' => ('ok', 'not ok');
enum 'TAP::Spec::Directive' => qw(SKIP TODO);
subtype 'TAP::Spec::TestNumber' => as 'Int', where { $_ > 0 };


has 'status' => (
  is => 'rw',
  isa => 'TAP::Spec::TestStatus',
  required => 1,
);


has 'number' => (
  is => 'rw',
  isa => 'TAP::Spec::TestNumber',
  predicate => 'has_number',
);


has 'description' => (
  is => 'rw',
  isa => 'Str',
  predicate => 'has_description',
);


has 'directive' => (
  is => 'rw',
  isa => 'TAP::Spec::Directive',
  predicate => 'has_directive',
);


has 'reason' => (
  is => 'rw',
  isa => 'Str',
  predicate => 'has_reason',
);


sub passed {
    my $self = shift;

    return 1 if $self->status eq 'ok';
    return 1 if $self->has_directive and $self->directive eq 'TODO';
    return '';
}


sub as_tap {
  my ($self) = @_;

  my $tap = $self->status;
  $tap .= " " . $self->number if $self->has_number;
  $tap .= " " . $self->description if $self->has_description;
  if ($self->has_directive) {
    $tap .= " # " . $self->directive;
    $tap .= " " . $self->reason if $self->has_reason;
  }
  $tap .= "\n";
  return $tap;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::TestResult - The results of a single test

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 status

B<Required>: The status of the test ("ok" or "not ok").

=head2 number

B<Optional>: Test number.

=head2 description

B<Optional>: Test description.

=head2 directive

B<Optional>: A test directive (SKIP or TODO).

=head2 reason

B<Optional>: A reason associated with the directive.

=head1 METHODS

=head2 $result->passed

Whether the test is considered to have passed. A test passes if its status
is 'ok' or if it is a TODO test.

=head2 $result->as_tap

TAP representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
