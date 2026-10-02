package TUI::Gadgets::LineCollection;
# ABSTRACT: Implement a line collection for the framework.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TLineCollection
  new_TLineCollection
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Objects::Collection;

sub TLineCollection() { __PACKAGE__ }
sub new_TLineCollection { __PACKAGE__->from(@_) }

extends TCollection;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      limit => Int, { alias => 'lim' },
      delta => Int,
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($lim, $delta)
  state $sig = signature(
    method => 1,
    pos => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( limit => $args[0], delta => $args[1] );
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::LineCollection - collection specialized for storing text lines

=head1 HIERARCHY

  TObject
    TNSCollection
      TCollection
        TLineCollection

=head1 SYNOPSIS

  use TUI::Gadgets::LineCollection;

  my $lines = TLineCollection->new( limit => 5, delta => 5 );
  $lines->insert('First line');
  $lines->insert('Second line');

=head1 DESCRIPTION

C<TLineCollection> is a specialized L<TCollection|TUI::Objects::Collection> 
used for storing text lines.

It is primarily used by file viewing components and other gadgets that need
to maintain a collection of strings representing individual lines of text.

Apart from its constructor interface, all collection management behavior is
inherited unchanged from L<TCollection|TUI::Objects::Collection>.

=head1 CONSTRUCTOR

=head2 new

  my $lines = TLineCollection->new(
    limit => $limit,
    delta => $delta,
  );

Creates a new line collection.

=over

=item limit

Initial capacity of the collection (I<Int>).

=item delta

Growth increment of the collection (I<Int>).

=back

=head2 new_TLineCollection

  my $lines = new_TLineCollection(
    $limit,
    $delta
  );

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and
is provided for compatibility with traditional I<Turbo Vision> construction
patterns.

=head1 SEE ALSO

L<TCollection|TUI::Objects::Collection>,
L<TFileViewer|TUI::Gadgets::FileViewer>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
