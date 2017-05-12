package ShardedKV::Storage::Memory;
$ShardedKV::Storage::Memory::VERSION = '0.20';
use Moose;
# ABSTRACT: Testing storage backend for in-memory storage

with 'ShardedKV::Storage';

has 'hash' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { +{} },
);

sub get {
  my ($self, $key) = @_;
  return $self->{hash}{$key};
}

sub set {
  my ($self, $key, $value_ref) = @_;
  $self->{hash}{$key} = $value_ref;
  return 1;
}

sub delete {
  my ($self, $key) = @_;
  delete $self->{hash}{$key};
  return();
}

# This is a noop for the Memory storage
sub reset_connection { }

no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

ShardedKV::Storage::Memory - Testing storage backend for in-memory storage

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

A C<ShardedKV> storage backend that uses a Perl in-memory hash for
storage. It is mainly intended for testing.

Implements the C<ShardedKV::Storage> role.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Storage>

=back

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# vim: ts=2 sw=2 et
