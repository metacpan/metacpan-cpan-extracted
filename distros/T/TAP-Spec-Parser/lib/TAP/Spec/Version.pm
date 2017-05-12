package TAP::Spec::Version;
BEGIN {
  $TAP::Spec::Version::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Version::VERSION = '0.10';
}
# ABSTRACT: A TAP version number specification
use Mouse;
use namespace::autoclean;


has 'version_number' => (
  is => 'rw',
  isa => 'Int',
  required => 1,
);


sub as_tap {
  my ($self) = @_;

  return "TAP version " . $self->version_number . "\n";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::Version - A TAP version number specification

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 version_number

B<Required>: The TAP version number (integer).

=head1 METHODS

=head2 $version->as_tap

TAP representation.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
