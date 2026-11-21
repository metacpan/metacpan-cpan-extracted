use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::HelpFile';
  use_ok 'TUI::Objects::Point';
}

subtest 'getTopic and invalidTopic' => sub {
  my $source = ".topic Start=10, Alias\nSee {next:Later}.\n"
    . ".topic Later=20\n Back {Start}.\n";
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  my $topic = $helpFile->getTopic( 10 );
  isa_ok( $topic, 'TUI::Help::HelpTopic' );
  $topic->setWidth( 80 );
  my $buffer = '';
  is( $topic->getLine( 1, \$buffer, 80 ), 'See next. ',
    'reads the indexed topic text' );
  my $point = TPoint->new();
  my ( $length, $ref ) = ( 0, 0 );
  $topic->getCrossRef( 0, $point, \$length, \$ref );
  is_deeply( [ $point->x, $point->y, $length, $ref ], [ 4, 1, 4, 20 ],
    'resolves a forward reference in the returned topic' );

  $topic = $helpFile->getTopic( 20 );
  is( $topic->paragraphs->text, " Back Start.\n",
    'reads another topic using its context' );
  is( $topic->crossRefs->[0]->ref, 10, 'resolves a backward reference' );
  $topic = $helpFile->getTopic( 11 );
  is( $topic->paragraphs->text, 'See next. ',
    'an alias reads the same topic after another lookup' );

  for my $context ( 12, 100, -1 ) {
    my $missing = $helpFile->getTopic( $context );
    isa_ok( $missing, 'TUI::Help::HelpTopic' );
    is( $missing->paragraphs->text, "\n No help available in this context.",
      "context $context receives the default missing-help text" );
  }
  {
    local $TUI::Help::HelpFile::invalidContext = "Custom\nmessage";
    my $missing = $helpFile->invalidTopic();
    is_deeply(
      [ $missing->paragraphs->text, $missing->paragraphs->size,
        0 + $missing->paragraphs->wrap, $missing->paragraphs->next,
        $missing->getNumCrossRefs ],
      [ "Custom\nmessage", length( "Custom\nmessage" ), 0, undef, 0 ],
      'invalidTopic uses the current text in one unwrapped paragraph',
    );
    $missing = $helpFile->getTopic( 99 );
    is( $missing->paragraphs->text, "Custom\nmessage",
      'missing contexts also use the customized text' );
  }
  close $stream or die $!;
};

subtest 'getTopic reports malformed topic bodies' => sub {
  my $source = ".topic Broken=10\ntext {unfinished\n"
    . ".topic Good=20\nvalid\n";
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  is( $helpFile->getTopic( 10 ), undef,
    'does not disguise an indexed topic parse error as missing help' );
  is( $helpFile->getTopic( 20 )->paragraphs->text, 'valid ',
    'a later valid topic remains accessible' );
  close $stream or die $!;
};

subtest 'indexes headers without taking ownership of the handle' => sub {
  my $source = join "\r\n",
    '; ignored', '', '.topic Start=10, Begin',
    'See {next:Later} and {self:Start}.',
    '.TOPIC Later=20', ' Back {Start}.', "\cZ", '.TOPIC Ignored=99', '';
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  my $first = index( $source, 'See' );
  my $later = index( $source, ' Back' );
  is_deeply(
    [ map { $helpFile->index->position( $_ ) } 10, 11, 20 ],
    [ $first, $first, $later ],
    'indexes paragraph positions and maps aliases to the same content',
  );
  is( $helpFile->index->position( 99 ), -1,
    'does not index headers after the DOS end-of-file marker' );

  undef $helpFile;
  ok( defined fileno( $stream ),
    'destroying HelpFile leaves the handle open' );
  close $stream or die $!;
};

subtest 'automatic IDs are local to each help source' => sub {
  my $source = ".TOPIC Auto\ntext\n";
  open my $stream, '<:raw', \$source or die $!;
  seek( $stream, 0, 2 ) or die $!;
  for ( 1 .. 2 ) {
    my $helpFile = THelpFile->new( stream => $stream );
    is( $helpFile->index->position( 3 ), length( ".TOPIC Auto\n" ),
      'starts at the beginning and assigns context three' );
    is( $helpFile->index->position( 4 ), -1, 'no ID leaks from another load' );
  }
  close $stream or die $!;
};

subtest 'duplicate topic names leave the default data intact' => sub {
  my $source = ".TOPIC Same=10\nfirst\n.TOPIC Same=20\nsecond\n";
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  isa_ok( $helpFile, THelpFile );
  is_deeply(
    [ $helpFile->index->size, 0 + $helpFile->modified, $helpFile->indexPos ],
    [ 0, 0, 0 ], 'keeps the default data instead of a partial index',
  );
  ok( defined fileno( $stream ),
    'failed loading leaves the handle open' );
  close $stream or die $!;
};

done_testing();
