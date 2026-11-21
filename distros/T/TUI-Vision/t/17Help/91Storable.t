use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Stream';
  use_ok 'TUI::Help::RefTable';
  use_ok 'TUI::Help::HelpTopic';
  use_ok 'TUI::Help::HelpIndex';
}

subtest 'TRefTable streams metadata but not reference records' => sub {
  my $table = TRefTable->new( limit => 10, delta => 5 );
  $table->getReference( 'beta' );
  my $reference = $table->getReference( 'alpha' );
  $reference->resolved( 1 );
  $reference->val( 100 );

  my $restored = thaw( freeze( $table ) );
  isa_ok( $restored, TRefTable );
  is( $restored->getCount, 2,  'restores the reference count' );
  is( $restored->limit,    10, 'restores the capacity' );
  is( $restored->delta,    5,  'restores the growth increment' );
  ok( !$restored->duplicates, 'preserves the flag after the empty item data' );
  is_deeply(
    [ $restored->at( 0 ), $restored->at( 1 ) ], [ undef, undef ],
    'readItem returns undefined entries instead of records'
  );
};

subtest 'THelpTopic streams content but not display state' => sub {
  my $topic = new_THelpTopic();
  $topic->addParagraph(
    TParagraph->new( text => 'alpha beta', size => 10, wrap => 1 ),
  );
  $topic->addParagraph(
    TParagraph->new( text => "tail\nend", size => 8, wrap => 0 ),
  );
  $topic->addCrossRef(
    TCrossRef->new( ref => 100, offset => 7, length => 4 ),
  );
  $topic->addCrossRef(
    TCrossRef->new( ref => 200, offset => 11, length => 4 ),
  );
  $topic->setWidth( 40 );
  my $buffer = '';
  is(
    $topic->getLine( 1, \$buffer, 80 ), 'alpha beta',
    'populates the source line cache at a different width'
  );

  my $stream = TStream->new();
  $stream->put( $topic, $topic );
  my $input    = thaw( freeze( $stream ) );
  my $restored = $input->get();
  isa_ok( $restored, THelpTopic );
  is(
    $input->get(), $restored,
    'repeated stream references restore the same topic object'
  );
  is( $restored->numLines, 4, 'display width resets to zero' );
  $restored->setWidth( 5 );
  is(
    $restored->getLine( 2, \$buffer, 80 ), 'beta',
    'reading resumes from a fresh cache rather than the source position'
  );
  is_deeply(
    [ map { $restored->getLine( $_, \$buffer, 80 ) } 1 .. 4 ],
    [ 'alpha ', 'beta', 'tail', 'end' ],
    'preserves paragraph order, text, sizes, and wrap flags',
  );
  is( $restored->getNumCrossRefs, 2, 'restores both cross-references' );
  my $point = TPoint->new();
  my ( $length, $ref ) = ( 0, 0 );
  for my $i ( 0 .. 1 ) {
    $restored->getCrossRef( $i, $point, \$length, \$ref );
    is_deeply(
      [ $point->x, $point->y, $length, $ref ],
      [ 0, $i + 2, 4, ( $i + 1 ) * 100 ],
      'preserves cross-reference values and displayed location'
    );
  }
}; #/ 'THelpTopic streams content but not display state' => sub

subtest 'THelpIndex streams positions and allocated slots' => sub {
  my $index = new_THelpIndex();
  $index->add( 2,   0 );
  $index->add( 3,  -5 );
  $index->add( 14, 940 );

  my $restored = thaw( freeze( $index ) );
  isa_ok( $restored, THelpIndex );
  is( $restored->size, 20, 'preserves allocated unused slots' );
  is_deeply(
    [ map { $restored->position( $_ ) } 0, 2,  3, 14,  19, 20 ],
    [ -1,                                  0, -5, 940, -1, -1 ],
    'preserves recorded positions and missing-context results',
  );
  $restored->add( 20, 1500 );
  is( $restored->size,           30,   'restored index grows in blocks of ten' );
  is( $restored->position( 20 ), 1500, 'stores a new position after growth' );
  is( $restored->position( 14 ), 940,  'growth preserves restored positions' );
};

done_testing();
