package TAP::Spec::BailOut;
BEGIN {
  $TAP::Spec::BailOut::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::BailOut::VERSION = '0.10';
}
# ABSTRACT: A TAP Bail Out! line
use Mouse;
use namespace::autoclean;


has 'reason' => (
  is => 'rw',
  isa => 'Str',
  predicate => 'has_reason',
);


sub as_tap {
  my ($self) = @_;

  my $tap = "Bail out!";
  $tap .= " " . $self->reason if $self->has_reason;
  $tap .= "\n";

  return $tap;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::BailOut - A TAP Bail Out! line

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 reason

B<Optional>: The reason why testing was ended.

=head1 METHODS

=head2 $bail_out->as_tap

TAP representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
