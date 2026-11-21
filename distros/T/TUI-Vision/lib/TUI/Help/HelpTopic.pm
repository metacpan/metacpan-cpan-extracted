package TUI::Help::HelpTopic;
# ABSTRACT: help-topic paragraphs, wrapping, and cross-references

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THelpTopic
  new_THelpTopic
);

use Storable qw( freeze thaw );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Const qw( INT_MAX );
use TUI::Help::HelpBase;
use TUI::Objects::Object;
use TUI::Objects::Stream;
use TUI::Objects::Streamable;

sub THelpTopic() { __PACKAGE__ }
sub name() { 'THelpTopic' }
sub new_THelpTopic { __PACKAGE__->from(@_) }

extends TObject;
with: *DOES = TStreamable->can('DOES');

# public attributes
has paragraphs => ( is => 'rw', default => 0 );
has numRefs    => ( is => 'rw', default => 0 );
has crossRefs  => ( is => 'rw' );

# private attributes
has width         => ( is => 'bare', default => 0 );
has lastOffset    => ( is => 'bare', default => 0 );
has lastLine      => ( is => 'bare', default => INT_MAX );
has lastParagraph => ( is => 'bare' );

# private methods
my (
  $wrapText,
  $readParagraphs,
  $readCrossRefs,
  $writeParagraphs,
  $writeCrossRefs,
  $disposeParagraphs
);

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->$disposeParagraphs();
  undef $self->{crossRefs};
  return;
}

sub addCrossRef {    # void ($ref)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $ref ) = $sig->( @_ );
  my $p = TCrossRef->new();
  @$p = @$ref;
  $self->{crossRefs}[ $self->{numRefs} ] = $p;
  ++$self->{numRefs};
  return;
}

sub addParagraph {    # void ($p)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $p ) = $sig->( @_ );
  if ( !$self->{paragraphs} ) {
    $self->{paragraphs} = $p;
  }
  else {
    my $pp = $self->{paragraphs};
    my $back = $pp;
    while ( $pp ) {
      $back = $pp;
      $pp = $pp->next;
    }
    $back->next( $p );
  }
  $p->next( undef );
  return;
}

sub getCrossRef {    # void ($i, $loc, \$length, \$ref)
  state $sig = signature(
    method => Object,
    pos    => [
      Int,
      Object,
      ScalarRef[PositiveOrZeroInt],
      ScalarRef[Int],
    ],
  );
  my ( $self, $i, $loc, $length, $ref ) = $sig->( @_ );
  assert ( $i >= 0 && $i < $self->{numRefs} );
  my $paraOffset = 0;
  my $curOffset  = 0;
  my $oldOffset  = 0;
  my $line       = 0;
  my $crossRef   = $self->{crossRefs}[$i];
  my $offset     = $crossRef->offset;
  my $p          = $self->{paragraphs};
  while ( $paraOffset + $curOffset < $offset ) {
    my $buffer = '';
    $oldOffset = $paraOffset + $curOffset;
    $self->$wrapText(
      $p->text, $p->size, \$curOffset, $p->wrap, \$buffer, $p->size,
    );
    ++$line;
    if ( $curOffset >= $p->size ) {
      $paraOffset += $p->size;
      $p = $p->next;
      $curOffset = 0;
    }
  }
  $loc->x( $offset - $oldOffset - 1 );
  $loc->y( $line );
  $$length = $crossRef->length;
  $$ref = $crossRef->ref;
  return;
}

sub getLine {    # $line ($line, \$buffer, $buflen)
  state $sig = signature(
    method => Object,
    pos    => [Int, ScalarRef[Str], Int],
  );
  my ( $self, $line, $buffer, $buflen ) = $sig->( @_ );
  my ( $offset, $p );
  if ( $self->{lastLine} < $line ) {
    my $i = $line;
    $line -= $self->{lastLine};
    $self->{lastLine} = $i;
    $offset = $self->{lastOffset};
    $p = $self->{lastParagraph};
  }
  else {
    $p = $self->{paragraphs};
    $offset = 0;
    $self->{lastLine} = $line;
  }
  $$buffer = '';
  while ( $p ) {
    while ( $offset < $p->size ) {
      my $lineBuf = '';
      --$line;
      $self->$wrapText(
        $p->text, $p->size, \$offset, $p->wrap, \$lineBuf, $p->size,
      );
      $$buffer = substr( $lineBuf, 0, $buflen );
      if ( $line == 0 ) {
        $self->{lastOffset} = $offset;
        $self->{lastParagraph} = $p;
        return $$buffer;
      }
    }
    $p = $p->next;
    $offset = 0;
  }
  $$buffer = '';
  return $$buffer;
}

sub getNumCrossRefs {    # $count ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{numRefs};
}

sub numLines {    # $count ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $lines = 0;
  for ( my $p = $self->{paragraphs}; $p; $p = $p->next ) {
    my $offset = 0;
    while ( $offset < $p->size ) {
      my $buffer = '';
      ++$lines;
      $self->$wrapText(
        $p->text, $p->size, \$offset, $p->wrap, \$buffer, $p->size,
      );
    }
  }
  return $lines;
}

sub setCrossRef {    # void ($i, $ref)
  state $sig = signature(
    method => Object,
    pos    => [Int, Object],
  );
  my ( $self, $i, $ref ) = $sig->( @_ );
  assert ( $i >= 0 );
  if ( $i < $self->{numRefs} ) {
    my $p = TCrossRef->new();
    @$p = @$ref;
    $self->{crossRefs}[$i] = $p;
  }
  return;
}

sub setNumCrossRefs {    # void ($i)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $i ) = $sig->( @_ );
  assert ( $i >= 0 );
  return 
    if $self->{numRefs} == $i;

  if ( $i < $self->{numRefs} ) {
    splice @{ $self->{crossRefs} }, $i;
  }
  else {
    push @{ $self->{crossRefs} },
      map { TCrossRef->new() } $self->{numRefs} .. $i - 1;
  }
  $self->{numRefs} = $i;
  return;
}

sub setWidth {    # void ($aWidth)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $aWidth ) = $sig->( @_ );
  $self->{width} = $aWidth;
  return;
}

sub _wrapText { goto $wrapText }
$wrapText = sub {    # $text ($self, $text, $size, \$offset, $wrap, \$lineBuf, $lineBufLen)
  my ( $self, $text, $size, $offset, $wrap, $lineBuf, $lineBufLen ) = @_;
  assert ( @_ == 7 );
  assert ( is_Object $self );
  assert ( is_Str $text );
  assert ( is_Int $size );
  assert ( is_ScalarRef $offset and is_Int $$offset );
  assert ( is_Bool $wrap );
  assert ( is_ScalarRef $lineBuf and is_Str $$lineBuf );
  assert ( is_Int $lineBufLen );

  my $start = $$offset;
  my $remaining = substr( $text, $start, $size - $start );
  my $length = length $remaining;
  if ( $remaining =~ /\A[^\0]*?(\R)/ ) {
    $length = $+[1];
  }

  my $width = $self->{width};
  if ( $wrap && $length >= $width ) {
    my $end = $start + $width;
    if ( $end > $size ) {
      $end = $size;
    }
    else {
      my $textWithinWidth = substr( $text, $start, $width + 1 );
      if ( $textWithinWidth =~ /\s\S*\z/
          && $-[0] > 0 ) {
        $end = $start + $-[0] + 1;
      }
      else {
        my $rest = substr( $text, $end, $size - $end );
        $end = $rest =~ /\s/ ? $end + $-[0] + 1 : $size;
      }
    }
    $end = $start + $width if $end == $start;
    $length = $end - $start;
  }

  $length = $lineBufLen if $length > $lineBufLen;
  $$lineBuf = substr( $text, $start, $length );
  $$lineBuf =~ s/\0.*\z//s;
  $$lineBuf =~ s/\R\z//;
  $$offset += $length;
  return $$lineBuf;
};

$readParagraphs = sub {    # void ($self, $s)
  my ( $self, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $s );
  assert ( Storable::is_retrieving );
  my $count = $s->get();
  $self->{paragraphs} = 0;
  for ( 1 .. $count ) {
    my $size = $s->get();
    my $wrap = $s->get();
    my $text = $s->get();
    $self->addParagraph(
      TParagraph->new( size => $size, wrap => $wrap, text => $text ),
    );
  }
  return;
};

$readCrossRefs = sub {    # void ($self, $s)
  my ( $self, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $s );
  assert ( Storable::is_retrieving );
  $self->{numRefs} = $s->get();
  $self->{crossRefs} = [];
  for ( 1 .. $self->{numRefs} ) {
    my $ref = $s->get();
    my $offset = $s->get();
    my $length = $s->get();
    push @{ $self->{crossRefs} }, TCrossRef->new(
      ref => $ref, offset => $offset, length => $length,
    );
  }
  return;
};

$writeParagraphs = sub {    # void ($self, $s)
  my ( $self, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $s );
  assert ( Storable::is_storing );
  my $count = 0;
  for ( my $p = $self->{paragraphs}; $p; $p = $p->next ) {
    ++$count;
  }
  $s->put( $count );
  for ( my $p = $self->{paragraphs}; $p; $p = $p->next ) {
    $s->put( $p->size, $p->wrap, substr( $p->text, 0, $p->size ) );
  }
  return;
};

$writeCrossRefs = sub {    # void ($self, $s)
  my ( $self, $s ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Object $s );
  assert ( Storable::is_storing );
  $s->put( $self->{numRefs} );
  for my $i ( 0 .. $self->{numRefs} - 1 ) {
    my $ref = $self->{crossRefs}[$i];
    $s->put( $ref->ref, $ref->offset, $ref->length );
  }
  return;
};

$disposeParagraphs = sub {    # void ($self)
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  undef $self->{paragraphs};
  return;
};

sub STORABLE_freeze {    # @list ($cloning)
  my ( $self, $cloning ) = @_;
  assert ( is_Object $self );
  assert ( is_Bool $cloning );
  assert ( not $cloning );

  my $stream = TStream->new();
  $self->write( $stream );
  return freeze $stream;
}

sub STORABLE_attach {    # $obj ($cloning, $serialized)
  my ( $class, $cloning, $serialized ) = @_;
  assert ( is_Str $class );
  assert ( is_Bool $cloning );
  assert ( is_Str $serialized );
  assert ( not $cloning );

  my $self = $class->build();
  my $stream = thaw $serialized;
  return $self->read( $stream );
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  assert ( Storable::is_storing );
  $self->$writeParagraphs( $os );
  $self->$writeCrossRefs( $os );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  assert ( Storable::is_retrieving );
  $self->$readParagraphs( $is );
  $self->$readCrossRefs( $is );
  $self->{width} = 0;
  $self->{lastLine} = INT_MAX;
  return $self;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new();
}

1

__END__

=pod

=head1 NAME

TUI::Help::HelpTopic - help-topic paragraphs, wrapping, and cross-references

=head1 HIERARCHY

  TObject
    THelpTopic

=head1 SYNOPSIS

  use TUI::Help;

  my $topic = new_THelpTopic();
  $topic->setWidth( 40 );
  my $text = 'Introduction to the help system';
  $topic->addParagraph(
    TParagraph->new( text => $text, size => length( $text ), wrap => 1 ),
  );
  my $buffer = '';
  my $line = $topic->getLine( 1, \$buffer, 80 );

=head1 DESCRIPTION

C<THelpTopic> follows the I<Turbo Vision> topic design. It holds a linked list 
of paragraphs and an array of cross-references. The C<TParagraph> and
C<TCrossRef> records are defined in L<TUI::Help::HelpBase>. L<TUI::Help> does 
not export them, but they are available once it is loaded.

Paragraphs may use explicit line breaks or word wrapping at the configured
width. Wrapping retains the whitespace at a word boundary and does not
split long words merely to fit the width. Line breaks are recognized with
Perl's C<\R> and removed from returned text. Unlike the original fixed
buffers, internal line processing has no 256-character limit.

Displayed lines are numbered from one. Cross-reference array indices
are zero-based; their text offsets are one-based across concatenated
paragraph text. Cross-reference locations use a zero-based column and a
one-based displayed line.

The topic supports C<Storable> persistence through
L<TStreamable|TUI::Objects::Streamable> and L<TStream|TUI::Objects::Stream>. 
Paragraph text, sizes, wrap flags, and cross-reference values are preserved. 
The display width and line-reading cache are not persisted; set the width again 
after restoring a topic.

=head2 Commonly Used Features

Set the width, append paragraphs, and use L</numLines> and L</getLine>
to read the displayed text. Sequential line requests reuse a cached
paragraph position; requests for earlier lines restart from the beginning.
Finish constructing the topic and setting its width before reading lines,
since changes do not reset this cache.

Add cross-references by value, then use L</getCrossRef> to translate their
text offsets into displayed locations. Scalar output parameters use scalar
references.

=head1 ATTRIBUTES

The following attributes are read/write. Use the methods below to keep
the paragraph chain and cross-reference count consistent.

=over

=item paragraphs

C<Object> when populated: the first C<TParagraph> in the linked list.
Initially C<0>, indicating an empty topic.

=item numRefs

C<Int>. Number of cross-references, initially zero.

=item crossRefs

C<ArrayRef[Object]> when populated, containing C<TCrossRef> records.
Initially undefined. New records allocated by L</setNumCrossRefs> have
undefined fields until filled by L</setCrossRef>.

=back

=head1 CONSTRUCTOR

=head2 new

  my $topic = THelpTopic->new();

Creates an empty topic with zero cross-references and an initial width of
zero. Takes no arguments.

=head2 new_THelpTopic

  my $topic = new_THelpTopic();

Factory for the same empty topic.

=head1 METHODS

=head2 addCrossRef

  $topic->addCrossRef( $ref );

Appends a value copy of the C<TCrossRef> object and increments the count.
Later changes to the supplied record do not change the stored copy.

=head2 addParagraph

  $topic->addParagraph( $p );

Appends the C<TParagraph> object to the paragraph chain without copying it.
Its C<next> field is set to C<undef>, making it the final paragraph.
Supply C<text> as C<Str>, C<size> as the text length, and C<wrap> as C<Bool>.

=head2 getCrossRef

  $topic->getCrossRef( $i, $loc, \$length, \$ref );

Accepts C<$i> as C<Int>, a C<TPoint> object, C<ScalarRef[PositiveOrZeroInt]>
for length, and C<ScalarRef[Int]> for the target context. Initialize the
referenced scalars before calling.

Updates the point's zero-based column and one-based line, and writes the
stored length and target context to the scalar outputs. The index must be
within the current cross-reference count; an assertion checks this
precondition. The stored offset must not exceed the total length of the
paragraph text; a larger offset is not checked and fails with a Perl error.

=head2 getLine

  my $line = $topic->getLine( $lineNumber, \$buffer, $buflen );

Accepts a one-based C<Int> line number, C<ScalarRef[Str]> output buffer,
and C<Int> output length limit. Initialize the buffer to a string first.
Returns the displayed line as C<Str> and writes the same text to the buffer.

At most C<$buflen> characters are returned; truncation does not change
where the next displayed line starts. A missing line returns an empty
string and clears the output buffer.

=head2 getNumCrossRefs

  my $count = $topic->getNumCrossRefs();

Returns the current cross-reference count as C<Int>.

=head2 numLines

  my $count = $topic->numLines();

Counts displayed lines across all paragraphs using the current width and
each paragraph's wrap flag. Returns C<Int>; an empty topic returns zero.

=head2 setCrossRef

  $topic->setCrossRef( $i, $ref );

Replaces the record at C<Int> index C<$i> with a value copy of the supplied
C<TCrossRef>. An index at or beyond the count is ignored. The index must
be non-negative; an assertion checks this precondition.

=head2 setNumCrossRefs

  $topic->setNumCrossRefs( $i );

Sets the cross-reference count to C<Int> C<$i>, preserving existing records
up to the new count. Growing appends empty C<TCrossRef> records; shrinking
discards the trailing records. An unchanged count does nothing.

The count must be non-negative; an assertion checks this precondition.
Fill newly allocated records before requesting their displayed locations.

=head2 setWidth

  $topic->setWidth( $aWidth );

Sets the C<Int> word-wrapping width. Does not reset the line-reading cache.
Paragraphs with wrapping disabled are not limited to this width.

=head1 SEE ALSO

L<TUI::Help>, L<TUI::Help::HelpBase>, L<THelpFile|TUI::Help::HelpFile>,
L<THelpIndex|TUI::Help::HelpIndex>, L<TObject|TUI::Objects::Object>

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
