package TUI::Help::HelpFile;
# ABSTRACT: help-source indexing and topic parsing

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THelpFile
  new_THelpFile
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Help::Const qw(
  MAXHELPTOPICID
  :wrapXXXX
);
use TUI::Help::HelpBase;
use TUI::Help::HelpIndex;
use TUI::Help::HelpTopic;
use TUI::Help::RefTable;
use TUI::Help::TopicDefinition;
use TUI::MsgBox::Const qw( mfError mfOKButton );
use TUI::MsgBox::MsgBoxText qw( messageBox );
use TUI::Objects::Object;

sub THelpFile() { __PACKAGE__ }
sub new_THelpFile { __PACKAGE__->from(@_) }

# global variables
our $invalidContext = "\n No help available in this context.";

extends TObject;

# public attributes
has stream   => ( is => 'rw', default => undef );
has modified => ( is => 'rw', default => false );
has index    => ( is => 'rw', default => undef );
has indexPos => ( is => 'rw', default => 0 );

# private attributes
has references  => ( is => 'bare' );
has helpCounter => ( is => 'bare', default => 2 );    # 1 is hcDragging.
has parseError  => ( is => 'bare' );

# private methods
my (
  $error,
  $readLine,
  $processText,
  $readTopic,
  $topicDefinition,
  $topicDefinitionList,
  $topicHeader,
  $scanForCrossRefs,
  $isEndParagraph,
  $readParagraph
);

my $commandChar = '.';

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      stream => FileHandle,
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{index}      = THelpIndex->new();
  $self->{references} = TRefTable->new( limit => 5, delta => 5 );
  unless ( seek( $self->{stream}, 0, 0 ) ) {
    $self->$error( "Cannot seek to start of help source: $!" );
    return;
  }
  $self->$processText();
  return;
}

sub from {    # $helpFile ($s)
  state $sig = signature(
    method => 1,
    pos    => [FileHandle],
  );
  my ( $class, $s ) = $sig->( @_ );
  return $class->new( stream => $s );
}

sub getTopic {    # $topic ($context)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $context ) = $sig->( @_ );
  return $self->invalidTopic()
    if $context < 0;
  my $position = $self->{index}->position( $context );
  return $self->invalidTopic()
    if $position < 0;
  return $self->$readTopic( $position );
}

sub invalidTopic {    # $topic ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $topic = THelpTopic->new();
  $topic->addParagraph(
    TParagraph->new(
      text => $invalidContext,
      size => length( $invalidContext ),
      wrap => false,
      next => undef,
    ),
  );
  return $topic;
}

sub recordPositionInIndex {    # void ($context)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $context ) = $sig->( @_ );
  ...
}

sub putTopic {    # void ($topic)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $topic ) = $sig->( @_ );
  ...;
  return;
}

$error = sub {    # void ($self, $text)
  my ( $self, $text ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $text );
  $self->{parseError} = $text;
  messageBox( $text, mfError | mfOKButton );
  return;
};

$readLine = sub {    # $line|undef ($self, $textFile)
  my ( $self, $textFile ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_FileHandle $textFile );

  local $/ = "\n";
  local $! = 0;
  my $line = readline( $textFile );
  unless ( defined $line ) {
    $self->$error( "Cannot read help source: $!" ) if $!;
    return undef;
  }
  $line =~ s/(?:\r?\n|\r)\z//;
  return $line;
};

#
# Help source format, adapted from the Turbo Vision help compiler:
#
# THelpFile indexes a seekable text source and reads topics on demand. It
# does not generate a compiled help file or a separate context file.
#
# A topic begins with a header of the form:
#
#   .topic symbol[=number][, symbol[=number]...]
#
# Multiple symbols give the same topic different numeric contexts. The first
# automatic number is 3; after an explicit number, automatic numbering
# continues from that number. For example:
#
#   .topic FileOpen=3, OpenFile, FFileOpen
#
# assigns contexts 3, 4, and 5 to the three names. Later topic headers
# must start at the beginning of a line.
#
# Text following a header forms the topic body. Adjacent lines beginning
# without a space form a wrapped paragraph. Lines beginning with a space
# retain their line breaks and are not wrapped. Blank lines and a change
# between these modes separate paragraphs. Lines beginning with ';' are
# skipped.
#
#   .topic FileOpen
#    File|Open
#    ---------
#   This text is wrapped to fit the help window.
#
# Cross-references use {text} or {text:alias}; text is displayed and the
# optional alias names the destination topic. For example:
#
#   See the {file open dialog:FileOpen} or {ChDir}.
#
# Outside a reference, '{{' produces a literal '{'. Inside a reference,
# double ':' or '}' to produce a literal character. References can point
# forward: all topic names are indexed before a topic is read. An unknown
# name produces a warning when the topic is read and uses context -1;
# requesting that context returns the invalid-topic message.
#
$processText = sub {    # $bool ($self)
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );

  my $stream = $self->{stream};
  my $index = THelpIndex->new();
  my $references = TRefTable->new( limit => 5, delta => 5 );
  my $counter = $self->{helpCounter};
  $self->{parseError} = undef;
  {
    local $self->{helpCounter} = $counter;
    my $seenTopic = false;
    while ( defined( my $line = $self->$readLine( $stream ) ) ) {
      last if $line =~ /\A[\0\cZ]/;
      next if $line eq '' || $line =~ /\A;/;
      if ( $seenTopic ) {
        next unless $line =~ /\A\Q$commandChar\E/;
      }
      elsif ( $line !~ /\A[ \t]*\Q$commandChar\E/ ) {
        $self->$error( 'TOPIC expected' );
        return false;
      }

      my $definitions = $self->$topicHeader( $line );
      return false unless $definitions;
      my $position = tell( $stream );
      if ( $position < 0 ) {
        $self->$error( "Cannot tell help source position: $!" );
        return false;
      }
      for ( my $p = $definitions; $p; $p = $p->next ) {
        my $reference = $references->getReference( $p->topic );
        if ( $reference->resolved ) {
          $self->$error( 'Redefinition of ' . $p->topic );
          return false;
        }
        $reference->val( $p->value );
        $reference->resolved( true );
        $index->add( $p->value, $position );
      }
      $seenTopic = true;
    }
    return false if defined $self->{parseError};
    $counter = $self->{helpCounter};
  }
  $self->{index} = $index;
  $self->{references} = $references;
  $self->{helpCounter} = $counter;
  return true;
};

# Read a topic's paragraphs at an indexed position and resolve its references.
sub _readTopic { goto $readTopic }
$readTopic = sub {    # $topic|undef ($self, $position)
  my ( $self, $position ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_PositiveOrZeroInt $position );

  my $stream = $self->{stream};
  $self->{parseError} = undef;
  unless ( seek( $stream, $position, 0 ) ) {
    $self->$error( "Cannot seek to help topic: $!" );
    return undef;
  }
  my $topic = THelpTopic->new();
  my $offset = 0;
  my @refs;
  while ( my $paragraph =
      $self->$readParagraph( $stream, \$offset, \@refs ) ) {
    $topic->addParagraph( $paragraph );
  }
  return undef if defined $self->{parseError};

  for my $entry ( @refs ) {
    my $reference = $self->{references}->getReference( $entry->{topic} );
    if ( $reference->resolved ) {
      $entry->{crossRef}->ref( $reference->val );
    }
    else {
      Carp::carp( 'Unresolved forward reference "' . $entry->{topic} . '"' );
      $entry->{crossRef}->ref( -1 );
    }
    $topic->addCrossRef( $entry->{crossRef} );
  }
  return $topic;
};

# Extracts the next topic definition from the given line at i.
sub _topicDefinition { goto $topicDefinition }
$topicDefinition = sub {    # $definition|undef ($self, $line, \$i)
  my ( $self, $line, $i ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $line );
  assert ( is_ScalarRef $i and is_PositiveOrZeroInt $$i );

  pos( $line ) = $$i;
  unless ( $line =~ /
      \G[ \t]*+([A-Za-z0-9_]+|[^\0])
      (?:[ \t]*(=)[ \t]*+([A-Za-z0-9_]+|[^\0])?)?
    /gcx ) {
    $$i = length( $line ) if $$i < length( $line );
    $self->$error( 'Expected topic definition' );
    return undef;
  }

  my ( $topic, $equals, $value ) = ( $1, $2, $3 );
  $$i = pos( $line );
  if ( defined $equals ) {
    if ( !defined $value || $value !~ /\A[0-9]+\z/ ) {
      $self->$error( 'Expected numeric' );
      return undef;
    }
    $self->{helpCounter} = 0 + $value;
  }
  else {
    ++$self->{helpCounter};
  }

  if ( $self->{helpCounter} > MAXHELPTOPICID ) {
    $self->$error(
      "Topic id for topic '$topic' exceeds limit of " . MAXHELPTOPICID,
    );
    return undef;
  }

  return TTopicDefinition->new(
    topic => $topic, value => $self->{helpCounter},
  );
};

# Extracts a list of topic definitions from the given line at i.
sub _topicDefinitionList { goto $topicDefinitionList }
$topicDefinitionList = sub {    # $topicList|undef ($self, $line, \$i)
  my ( $self, $line, $i ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $line );
  assert ( is_ScalarRef $i and is_PositiveOrZeroInt $$i );

  my $topicList;
  while ( true ) {
    my $p = $self->$topicDefinition( $line, $i );
    return undef unless $p;
    $p->next( $topicList );
    $topicList = $p;
    pos( $line ) = $$i;
    last unless $line =~ /\G[ \t]*,/gc;
    $$i = pos( $line );
  }
  return $topicList;
};

# Parse a topic header.
sub _topicHeader { goto $topicHeader }
$topicHeader = sub {    # $topicList|undef ($self, $line)
  my ( $self, $line ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $line );

  return undef unless $line =~ /\A[ \t]*\Q$commandChar\E/gc;
  unless ( $line =~ /\G[ \t]*([A-Za-z0-9_]+)/gc
      && uc( $1 ) eq 'TOPIC' ) {
    $self->$error( 'TOPIC expected' );
    return undef;
  }
  my $i = pos( $line );
  return $self->$topicDefinitionList( $line, \$i );
};

sub _scanForCrossRefs { goto $scanForCrossRefs }
$scanForCrossRefs = sub {    # $bool ($self, \$line, $offset, $xRefs)
  my ( $self, $line, $offset, $xRefs ) = @_;
  assert ( @_ == 4 );
  assert ( is_Object $self );
  assert ( is_ScalarRef $line and is_Str $$line );
  assert ( is_PositiveOrZeroInt $offset );
  assert ( is_ArrayRef $xRefs );

  # The base offset includes text buffered earlier in this paragraph.
  my $text = $$line;
  my $result = '';
  pos( $text ) = 0;
  while ( $text =~ /\G([^{]*)(\{\{|\{|\z)/gc ) {
    my ( $plain, $opening ) = ( $1, $2 );
    $result .= $plain;
    last if $opening eq '';
    if ( $opening eq '{{' ) {
      $result .= '{';
      next;
    }

    my $start = pos( $text ) - 1;
    unless ( $text =~ /\G((?:[^}]|\}\})*+)\}/gc ) {
      $$line = $result . substr( $text, $start );
      $self->$error( 'Unterminated topic reference.' );
      return false;
    }
    my $reference = $1;
    $reference =~ s/\}\}/}/g;

    my ( $display, $topic );
    if ( $reference =~ /\A((?:[^:]|::)*+):(.*)\z/s ) {
      ( $display, $topic ) = ( $1, $2 );
      $display =~ s/::/:/g;
    }
    else {
      $reference =~ s/::/:/g;
      ( $display, $topic ) = ( $reference, $reference );
    }

    push @$xRefs, {
      topic => $topic,
      crossRef => TCrossRef->new(
        ref    => scalar @$xRefs,
        offset => $offset + length( $result ) + 1,
        length => length( $display ),
      ),
    };
    $display =~ tr/ /\xFF/;
    $result .= $display;
  }
  $$line = $result;
  return true;
};

sub _isEndParagraph { goto $isEndParagraph }
$isEndParagraph = sub {    # $bool ($self, $line, $state)
  my ( $self, $line, $state ) = @_;
  assert ( @_ == 3 );
  assert ( is_Object $self );
  assert ( is_Str $line );
  assert ( is_Int $state );

  return true if $line =~ /\A(?:\z|[\0\cZ]|\Q$commandChar\E)/;
  return true if $state == wrapping && $line =~ /\A /;
  return true if $state == notWrapping && $line !~ /\A /;
  return false;
};

# Read a paragraph from a seekable source, collecting cross-references.
# Returns undef when no paragraph is found; leaves the boundary line unread.
sub _readParagraph { goto $readParagraph }
$readParagraph = sub {    # $paragraph|undef ($self, $textFile, \$offset, $xRefs)
  my ( $self, $textFile, $offset, $xRefs ) = @_;
  assert ( @_ == 4 );
  assert ( is_Object $self );
  assert ( is_FileHandle $textFile );
  assert ( is_ScalarRef $offset and is_PositiveOrZeroInt $$offset );
  assert ( is_ArrayRef $xRefs );

  my $text = '';
  my $state = undefined;
  while ( true ) {
    my $position = tell( $textFile );
    if ( $position < 0 ) {
      $self->$error( "Cannot tell help source position: $!" );
      return undef;
    }
    my $line = $self->$readLine( $textFile );
    unless ( defined $line ) {
      return undef if defined $self->{parseError};
      last;
    }
    next if $line =~ /\A;/;
    if ( $state == undefined && $line eq '' ) {
      $text .= "\n";
      next;
    }
    if ( $self->$isEndParagraph( $line, $state ) ) {
      unless ( seek( $textFile, $position, 0 ) ) {
        $self->$error( "Cannot restore help source position: $!" );
        return undef;
      }
      last;
    }
    $state = $line =~ /\A / ? notWrapping : wrapping
      if $state == undefined;
    return undef unless $self->$scanForCrossRefs(
      \$line, $$offset + length( $text ), $xRefs,
    );
    $text .= $line . ( $state == wrapping ? ' ' : "\n" );
  }
  return undef if $state == undefined;

  $$offset += length( $text );
  return TParagraph->new(
    text => $text,
    size => length( $text ),
    wrap => $state == wrapping ? true : false,
    next => undef,
  );
};

1

__END__

=pod

=head1 NAME

TUI::Help::HelpFile - help-source indexing and topic parsing

=head1 HIERARCHY

  TObject
    THelpFile

=head1 SYNOPSIS

  use TUI::Help;

  open my $source, '<', 'help.txt' or die $!;
  my $helpFile = new_THelpFile( $source );
  my $topic = $helpFile->getTopic( 3 );

  # Topics are read on demand, so close the handle only after the last read.
  close $source or die $!;

=head1 DESCRIPTION

This module adapts C<THelpFile> to read help source text directly rather
than a compiled TVHC file. Construction scans topic headers and records
their names, numeric contexts, and source positions. Topic bodies are
parsed internally on demand, with references resolved against the complete
name table. No compiler output, symbol file, or stream fix-ups are used.

The supplied C<FileHandle> must be open for reading and seekable. Scanning
starts at the beginning and stops at EOF or a DOS Ctrl-Z marker.
The caller opens and closes the handle; this class does neither and does
not require a filename.

The public update methods below remain abstract.

=head2 Commonly Used Features

Pass an already open source handle to the constructor. The context index
is then available through C<index>. Aliases share a source position, and
automatic topic numbering starts at three independently for each instance.
Keep the source open and unchanged while the help file is in use.
Use L</getTopic> to retrieve a topic by its numeric context.

=head1 VARIABLES

=head2 $invalidContext

C<$invalidContext> is the text used by L</invalidTopic>.
It is a global package variable and is not exported. Its initial value is
C<"\n No help available in this context.">.

=head1 ATTRIBUTES

The following attributes are read/write:

=over

=item stream

The caller-owned source C<FileHandle> supplied to the constructor.

=item modified

C<Bool> modification flag, initially false.

=item index

The C<THelpIndex> built during construction. It maps context IDs to source
positions immediately after their topic headers, not compiled-file offsets.

=item indexPos

C<Int>, initially zero. Retained from the original help-file interface;
source indexing does not use this field.

=back

=head1 CONSTRUCTOR

=head2 new

  my $helpFile = THelpFile->new( stream => $s );

Accepts an open, seekable C<FileHandle>. Scans the source headers and builds
the context index without parsing topic bodies. Parser and I/O errors are
reported with a message box, not exceptions. If indexing fails, construction
still returns an object with its default empty index and name table; no
partially collected definitions are retained. The supplied handle remains
associated with the object and owned by the caller.

=head2 new_THelpFile

  my $helpFile = new_THelpFile( $s );

Positional factory for the same constructor.

=head1 METHODS

=head2 getTopic

  my $topic = $helpFile->getTopic( $context );

Accepts an C<Int> context. Reads the indexed topic from the source and
returns a C<THelpTopic>. A missing or negative context returns the topic
from L</invalidTopic>. If reading an indexed topic fails, the error is
reported and the method returns C<undef>.

=head2 invalidTopic

  my $topic = $helpFile->invalidTopic();

Returns a new C<THelpTopic> with a single unwrapped paragraph containing
L</$invalidContext>.

=head2 putTopic

  $helpFile->putTopic( $topic );

Accepts a topic object. This method remains abstract and raises
C<Unimplemented>.

=head2 recordPositionInIndex

  $helpFile->recordPositionInIndex( $context );

Accepts an integer context. This method remains abstract and raises
C<Unimplemented>.

=head1 SEE ALSO

L<TUI::Help>, L<TObject|TUI::Objects::Object>

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
