use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::HelpFile';
  use_ok 'TUI::Help::HelpBase';
  use_ok 'TUI::Objects::Object';
}

my $emptySource = '';
open my $emptyStream, '<:raw', \$emptySource or die $!;

subtest 'topicDefinition' => sub {
  my $self = THelpFile->new( stream => $emptyStream );
  my $i = 0;
  my $definition =
    TUI::Help::HelpFile::_topicDefinition( $self, 'First', \$i );
  is_deeply( [ $definition->topic, $definition->value, $i ],
    [ 'First', 3, 5 ], 'automatic numbering starts at three' );

  my $line = '  Named = 40, Next';
  $i = 0;
  $definition = TUI::Help::HelpFile::_topicDefinition( $self, $line, \$i );
  is_deeply(
    [ $definition->topic, $definition->value, substr( $line, $i ) ],
    [ 'Named', 40, ', Next' ], 'explicit ID leaves the following comma',
  );
  ++$i;
  $definition = TUI::Help::HelpFile::_topicDefinition( $self, $line, \$i );
  is_deeply( [ $definition->topic, $definition->value, $i ],
    [ 'Next', 41, length( $line ) ],
    'automatic numbering continues after an explicit ID' );
};

subtest 'topicDefinitionList' => sub {
  my $self = THelpFile->new( stream => $emptyStream );
  my $line = '>> First=50, Second,Third=70 trailing';
  my $i = 2;
  my $head =
    TUI::Help::HelpFile::_topicDefinitionList( $self, $line, \$i );
  my @definitions;
  for ( my $p = $head; $p; $p = $p->next ) {
    push @definitions, [ $p->topic, $p->value ];
  }
  is_deeply( \@definitions,
    [ [ 'Third', 70 ], [ 'Second', 51 ], [ 'First', 50 ] ],
    'links definitions in reverse order with mixed ID forms' );
  is( substr( $line, $i ), ' trailing',
    'starts at the supplied offset and leaves trailing text unread' );
};

subtest 'topicHeader' => sub {
  my $self = THelpFile->new( stream => $emptyStream );
  my $head = TUI::Help::HelpFile::_topicHeader(
    $self, " \t. tOpIc Header=80, Alias",
  );
  is_deeply(
    [ $head->topic, $head->value, $head->next->topic,
      $head->next->value, $head->next->next ],
    [ 'Alias', 81, 'Header', 80, undef ],
    'accepts whitespace and mixed-case TOPIC and parses the list',
  );
  is( TUI::Help::HelpFile::_topicHeader( $self, 'ordinary text' ),
    undef, 'ignores lines without a command prefix' );
  is( TUI::Help::HelpFile::_topicHeader( $self, '.TOPICextra Name' ),
    undef, 'rejects a keyword without a token boundary' );
};

subtest 'scanForCrossRefs' => sub {
  my $self = TObject->new();
  my @cases = (
    {
      name => 'literal and escaped opening braces',
      line => 'literal {{braces} and }} ::.',
      text => 'literal {braces} and }} ::.',
      offset => 0,
      refs => [],
    },
    {
      name => 'aliases, spaces, and offsets after removed markup',
      line => 'See {file open dialog:FileOpen}, then {Exit}.',
      text => "See file\xFFopen\xFFdialog, then Exit.",
      offset => 17,
      refs => [
        [ 'FileOpen', 22, 16 ],
        [ 'Exit', 45, 4 ],
      ],
    },
    {
      name => 'escaped colons and closing braces',
      line => '{A:: B}}:Target} / {C::D}}E}',
      text => "A:\xFFB} / C:D}E",
      offset => 0,
      refs => [
        [ 'Target', 1, 5 ],
        [ 'C:D}E', 9, 5 ],
      ],
    },
    {
      name => 'adjacent one-character references',
      line => '{A}{B}',
      text => 'AB',
      offset => 0,
      refs => [
        [ 'A', 1, 1 ],
        [ 'B', 2, 1 ],
      ],
    },
  );

  for my $case ( @cases ) {
    subtest $case->{name} => sub {
      my $line = $case->{line};
      my @refs;
      TUI::Help::HelpFile::_scanForCrossRefs(
        $self, \$line, $case->{offset}, \@refs,
      );
      is( $line, $case->{text}, 'produces the displayed text' );
      my @expected;
      for my $ref ( @{ $case->{refs} } ) {
        push @expected, {
          topic => $ref->[0],
          crossRef => TCrossRef->new(
            ref => scalar @expected,
            offset => $ref->[1],
            length => $ref->[2],
          ),
        };
      }
      is_deeply( \@refs, \@expected,
        'collects topic names and TCrossRef records in text order' );
    };
  }

  my $line = '{Next}';
  my $previous = {
    topic => 'Earlier',
    crossRef => TCrossRef->new( ref => 0, offset => 1, length => 7 ),
  };
  my @refs = ( $previous );
  TUI::Help::HelpFile::_scanForCrossRefs( $self, \$line, 20, \@refs );
  is_deeply( \@refs, [
    $previous,
    {
      topic => 'Next',
      crossRef => TCrossRef->new( ref => 1, offset => 21, length => 4 ),
    },
  ], 'appends references and continues numbering across lines' );
};

subtest 'isEndParagraph' => sub {
  my $self = TObject->new();
  my @cases = (
    [ '', [ 1, 1, 1 ], 'empty line' ],
    [ "\0text", [ 1, 1, 1 ], 'leading NUL' ],
    [ '.TOPIC Next', [ 1, 1, 1 ], 'leading command character' ],
    [ "\x1Atext", [ 1, 1, 1 ], 'DOS end-of-file marker' ],
    [ 'text', [ 0, 0, 1 ], 'unindented text' ],
    [ ' text', [ 0, 1, 0 ], 'space-indented text' ],
    [ "\ttext", [ 0, 0, 1 ], 'tab is not a leading space' ],
    [ ' .TOPIC Next', [ 0, 1, 0 ], 'indented dot is not a command' ],
  );
  for my $case ( @cases ) {
    my ( $line, $expected, $name ) = @$case;
    for my $state ( 0 .. 2 ) {
      is(
        0 + TUI::Help::HelpFile::_isEndParagraph( $self, $line, $state ),
        $expected->[$state], "$name, state $state",
      );
    }
  }
};

subtest 'readParagraph' => sub {
  my $self = THelpFile->new( stream => $emptyStream );
  my $source = join "\r\n",
    '; ignored', '', 'Alpha {Beta:Target}', 'continued',
    ' fixed', ' ; literal', '', 'Final', '.TOPIC Next', '';
  open my $file, '<:raw', \$source or die $!;
  my $offset = 10;
  my @refs;
  my $paragraph =
    TUI::Help::HelpFile::_readParagraph( $self, $file, \$offset, \@refs );
  my $expected = "\nAlpha Beta continued ";
  is_deeply(
    [ $paragraph->text, $paragraph->size, 0 + $paragraph->wrap,
      $paragraph->next ],
    [ $expected, length( $expected ), 1, undef ],
    'joins wrapped lines, preserves leading blanks, and skips comments',
  );
  is( $offset, 10 + length( $expected ), 'advances the topic offset' );
  is_deeply( \@refs, [
    {
      topic => 'Target',
      crossRef => TCrossRef->new( ref => 0, offset => 18, length => 4 ),
    },
  ], 'reference offset includes the leading blank and prior topic text' );

  my $expectedOffset = $offset;
  for my $case ( [ " fixed\n ; literal\n", 0 ], [ "\nFinal ", 1 ] ) {
    $paragraph =
      TUI::Help::HelpFile::_readParagraph( $self, $file, \$offset, \@refs );
    is_deeply(
      [ $paragraph->text, $paragraph->size, 0 + $paragraph->wrap ],
      [ $case->[0], length( $case->[0] ), $case->[1] ],
      'reads the next paragraph with its own wrapping mode',
    );
    $expectedOffset += length( $case->[0] );
    is( $offset, $expectedOffset, 'accumulates paragraph sizes' );
  }
  is(
    TUI::Help::HelpFile::_readParagraph( $self, $file, \$offset, \@refs ),
    undef, 'a topic header does not produce a paragraph',
  );
  is( $offset, $expectedOffset, 'a header does not advance the offset' );
  is( scalar readline( $file ), ".TOPIC Next\r\n",
    'leaves the topic header unread' );
  close $file or die $!;
};

subtest 'readParagraph at end of input' => sub {
  my $self = THelpFile->new( stream => $emptyStream );
  for my $source ( '', "\n; ignored\n", 'last' ) {
    open my $file, '<:raw', \$source or die $!;
    my $offset = 0;
    my @refs;
    my $paragraph =
      TUI::Help::HelpFile::_readParagraph( $self, $file, \$offset, \@refs );
    if ( $source eq 'last' ) {
      is( $paragraph->text, 'last ', 'accepts a final line without newline' );
      is( $offset, 5, 'counts the final wrapped separator' );
      is(
        TUI::Help::HelpFile::_readParagraph(
          $self, $file, \$offset, \@refs,
        ),
        undef, 'the following read reaches EOF',
      );
    }
    else {
      is( $paragraph, undef, 'empty input or only blanks has no paragraph' );
      is( $offset, 0, 'no paragraph leaves the offset unchanged' );
    }
    close $file or die $!;
  }
};

subtest 'readParagraph rejects an unterminated reference' => sub {
  my $self = THelpFile->new( stream => $emptyStream );
  my $source = 'text {unfinished';
  open my $file, '<:raw', \$source or die $!;
  my $offset = 0;
  my @refs;
  is(
    TUI::Help::HelpFile::_readParagraph( $self, $file, \$offset, \@refs ),
    undef, 'does not return a paragraph after reporting the parse error',
  );
  is( $offset, 0, 'a rejected paragraph does not advance the offset' );
  close $file or die $!;
};

subtest 'readTopic' => sub {
  my $source = join "\r\n",
    '; ignored', '', '.topic Start=10, Begin',
    'See {next:Later} and {self:Start}.',
    '.TOPIC Later=20', ' Back {Start}.', "\cZ", '.TOPIC Ignored=99', '';
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  my $first = index( $source, 'See' );
  my $later = index( $source, ' Back' );
  my $topic = TUI::Help::HelpFile::_readTopic( $helpFile, $first );
  isa_ok( $topic, 'TUI::Help::HelpTopic' );
  $topic->setWidth( 80 );
  my $buffer = '';
  is( $topic->getLine( 1, \$buffer, 80 ), 'See next and self. ',
    'reads the indexed paragraph instead of the next stream position' );
  is_deeply( [ map { $_->ref } @{ $topic->crossRefs } ], [ 20, 10 ],
    'resolves forward and self references from the complete name table' );

  $topic = TUI::Help::HelpFile::_readTopic( $helpFile, $later );
  is( $topic->paragraphs->text, " Back Start.\n",
    'reads the later topic with preserved line breaks' );
  is( $topic->crossRefs->[0]->ref, 10, 'resolves a backward reference' );
  $topic = TUI::Help::HelpFile::_readTopic(
    $helpFile, $helpFile->index->position( 11 ),
  );
  is( $topic->paragraphs->text, 'See next and self. ',
    'can seek back and read the earlier topic through its alias' );

  close $stream or die $!;
};

subtest 'unresolved references retain an invalid context' => sub {
  my $source = ".TOPIC Known=7\n{Missing}\n";
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  my ( $topic, @warnings );
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $topic = TUI::Help::HelpFile::_readTopic(
      $helpFile, $helpFile->index->position( 7 ),
    );
  }
  like( join( '', @warnings ), qr/Unresolved forward reference "Missing"/,
    'reports the missing topic rather than substituting context zero' );
  is( $topic->crossRefs->[0]->ref, -1,
    'keeps the original invalid-context value' );
  close $stream or die $!;
};

subtest 'topicDefinition counter after failed indexing' => sub {
  my $source = ".TOPIC Same=10\nfirst\n.TOPIC Same=20\nsecond\n";
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  my $offset = 0;
  my $definition =
    TUI::Help::HelpFile::_topicDefinition( $helpFile, 'Auto', \$offset );
  is( $definition->value, 3, 'failed loading does not change the ID counter' );
  close $stream or die $!;
};

subtest 'body parsing is deferred until readTopic' => sub {
  my $source = ".TOPIC Broken=10\ntext {unfinished\n.TOPIC Good=20\nok\n";
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  is(
    TUI::Help::HelpFile::_readTopic(
      $helpFile, $helpFile->index->position( 10 ),
    ),
    undef, 'reports a malformed body when that topic is requested',
  );
  my $topic = TUI::Help::HelpFile::_readTopic(
    $helpFile, $helpFile->index->position( 20 ),
  );
  is( $topic->paragraphs->text, 'ok ',
    'a failed read does not prevent reading another valid topic' );
  close $stream or die $!;
};

close $emptyStream or die $!;
done_testing();
