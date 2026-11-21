package TUI::Objects::Streamable;
# ABSTRACT: defines the role TStreamable

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStreamable
);

sub TStreamable() { __PACKAGE__ }

sub read  : method;
sub write : method;

sub DOES {
  my $proto = shift;
  return 1 if defined $_[0] && $_[0] eq __PACKAGE__;
  return $proto->UNIVERSAL::DOES(@_);
}

1;

__END__

=pod

=head1 NAME

TUI::Objects::Streamable - defines the role TStreamable

=head1 DESCRIPTION

C<TStreamable> identifies objects that participate in the L<TUI::Vision> object
persistence mechanism.

Classes performing this role must implement C<write> and C<read>. C<write>
stores the persistent state of an object in a L<TStream|TUI::Objects::Stream>, 
while C<read> restores that state from a stream.

L<TStream|TUI::Objects::Stream> recognizes objects performing this role and
preserves their object identity when the persistent object graph is
reconstructed.

=head1 REQUIRED METHODS

=head2 read

  $self = $self->read($stream);

Restores the persistent state of the object from C<$stream>. Returns the 
updated object.

=head2 write

  $self->write($stream);

Writes the persistent state of the object to C<$stream>.

=head1 SEE ALSO

L<TStream|TUI::Objects::Stream>,
L<TUI::Manual::09>

=head1 AUTHOR

=over

=item * J. Schneider <brickpool@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2021-2026 the L</AUTHOR> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
