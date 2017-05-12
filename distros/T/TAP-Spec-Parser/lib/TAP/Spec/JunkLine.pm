package TAP::Spec::JunkLine;
BEGIN {
  $TAP::Spec::JunkLine::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::JunkLine::VERSION = '0.10';
}
# ABSTRACT: A line of non-TAP data in a TAP stream
use Mouse;
use namespace::autoclean;


has 'text' => (
  is => 'rw',
  isa => 'Str',
  required => 1,
);


sub as_tap {
  my ($self) = @_;

  return "## JUNK LINE: " . $self->text . "\n";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::JunkLine - A line of non-TAP data in a TAP stream

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 text

B<Required>: the comment text.

=head1 METHODS

=head2 $comment->as_tap

TAP representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
