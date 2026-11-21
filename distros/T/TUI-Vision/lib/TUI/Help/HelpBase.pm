package TUI::Help::HelpBase;
# ABSTRACT: paragraph and reference records for the help system

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Class::Struct;

struct TParagraph => [
  next => '$',
  wrap => '$',
  size => '$',
  text => '$',
];

struct TCrossRef => [
  ref    => '$',
  offset => '$',
  length => '$',
];

struct TReference => [
  topic    => '$',
  resolved => '$',
  val      => '$',
];

1

__END__

=pod

=head1 NAME

TUI::Help::HelpBase - paragraph and reference records for the help system

=head1 SYNOPSIS

  use TUI::Help::HelpBase;

  my $paragraph = TParagraph->new(
    wrap => 1,
    size => 9,
    text => 'Help text',
  );
  my $crossRef = TCrossRef->new(
    ref    => 100,
    offset => 0,
    length => 4,
  );
  my $reference = TReference->new(
    topic    => 'Introduction',
    resolved => 1,
    val      => 100,
  );

=head1 DESCRIPTION

This module defines the C<TParagraph> and C<TCrossRef> records of the
Turbo Vision help-base design, and the C<TReference> record of the original
Borland help compiler. All three are array-based L<Class::Struct> objects
with named constructors and read/write field accessors.

All fields use scalar storage. The field descriptions below use the type
names from L<TUI::toolkit::Types> to describe expected values, not enforced
constraints: C<Class::Struct> does not validate these types or calculate
field values. Unspecified fields are initially undefined.

None of these records derives from C<TObject> or provides streaming methods.

=head2 Commonly Used Features

Create records with named field values, then use the generated accessors
to read or update individual fields. Paragraphs can be linked through their
C<next> accessors; the final paragraph has an undefined C<next> value.

=head1 STRUCTURES

=head2 TParagraph

  my $paragraph = TParagraph->new(
    next => undef,
    wrap => 1,
    size => 9,
    text => 'Help text',
  );
  $paragraph->next( $nextParagraph );

Contains the following fields in header order:

=over

=item next

C<Maybe[Object]>. Reference to the next C<TParagraph>, or C<undef> at the end
of the paragraph chain.

=item wrap

C<Bool>. Indicates whether word wrapping is enabled for the paragraph.

=item size

C<PositiveOrZeroInt>. Paragraph text size, supplied by the caller.

=item text

C<Str>. Paragraph text.

=back

=head2 TCrossRef

  my $crossRef = TCrossRef->new( ref => 100, offset => 0, length => 4 );
  my $context = $crossRef->ref();

Contains the following fields in header order:

=over

=item ref

C<Int>. Referenced help context.

=item offset

C<Int>. Cross-reference offset.

=item length

C<PositiveOrZeroInt>. Cross-reference text length.

=back

=head2 TReference

  my $reference = TReference->new(
    topic    => 'Introduction',
    resolved => 1,
    val      => 100,
  );
  my $value = $reference->val();

Contains the following fields in header order:

=over

=item topic

C<Str>. Referenced topic name.

=item resolved

C<Bool>. Indicates whether the topic reference has been resolved.

=item val

C<PositiveOrZeroInt>. Numeric reference value. Only the numeric value of
the original C<Content> union is represented; fix-up lists are not supported.

=back

=head1 SEE ALSO

L<THelpTopic|TUI::Help::HelpTopic>

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
