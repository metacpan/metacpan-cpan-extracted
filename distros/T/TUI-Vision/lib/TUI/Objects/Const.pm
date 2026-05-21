package TUI::Objects::Const;

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  ccNotFound
  maxCollectionSize
);

our %EXPORT_TAGS = (
);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

use Config;
use TUI::Const qw( UINT_MAX );

use constant {
  ccNotFound => -1
};

# The calculation of 'maxCollectionSize' uses the size of a pointer to 
# determine the maximum number of elements in the collection. 
use constant {
  maxCollectionSize => int( ( UINT_MAX - 16 ) / $Config{ptrsize} ),
};

1

__END__

=pod

=head1 NAME

TUI::Objects::Const - constants for object and collection components

=head1 SYNOPSIS

  use TUI::Objects::Const qw(:all);

  # or import specific constants
  use TUI::Objects::Const qw(ccNotFound maxCollectionSize);

=head1 DESCRIPTION

C<TUI::Objects::Const> defines constants used by the TUI::Vision object and
collection infrastructure.

The constants in this module are used by collection classes and related object
management code to represent special index values and size limits.

This module only defines constants. The semantic meaning and practical usage of
these constants is documented in the corresponding object and collection
modules, such as C<TCollection> and C<TSortedCollection>.

=head1 CONSTANTS

=head2 Collection index constants

Constants representing special index values used by collection classes.

These values are typically returned by search operations to indicate that an
element could not be found.

=head2 Collection size limits

Constants defining maximum collection sizes.

These values are derived from platform characteristics and are used internally
to limit the number of elements in collections.

=head1 EXPORT TAGS

This module provides the following export behavior:

=over

=item *

Individual constants may be imported explicitly.

=item *

The C<:all> tag imports all constants defined by this module.

=back

=head1 SEE ALSO

L<TUI::Objects::Collection>,
L<TUI::Objects::SortedCollection>

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
