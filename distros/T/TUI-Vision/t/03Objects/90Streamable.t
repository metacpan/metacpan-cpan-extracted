use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'UNIVERSAL::Object';
  use_ok 'TUI::Objects::Stream';
  use_ok 'TUI::Objects::Streamable';
  use_ok 'TUI::Objects::Collection';
}

subtest 'TStreamable role' => sub {
  ok(
    TCollection->DOES( TStreamable ),
    'TCollection performs TStreamable'
  );

  ok(
    TCollection->can( 'read' ),
    'read is implemented'
  );

  ok(
    TCollection->can( 'write' ),
    'write is implemented'
  );
};

subtest 'TStream stores first TStreamable as ptObject' => sub {
  my $object = bless { str => 'test' }, TStreamable;
  my $stream = new_TStream();

  is(
    $stream->put( $object ),
    $stream,
    'put returns the stream'
  );

  isa_ok(
    $stream->[0],
    TStream->ptObject
  );

  ok(
    defined $stream->[0][0],
    'ptObject contains an object id'
  );

  ok(
    defined $stream->[0][1],
    'ptObject contains serialized object data'
  );

  my $copy = $stream->get;

  isa_ok( $copy, TStreamable );

  is(
    $copy->{str}, 'test',
    'TStream restores packed TStreamable'
  );
};

subtest 'TStream stores repeated TStreamable as ptIndexed' => sub {
  my $object = bless { str => 'test' }, TStreamable;
  my $stream = new_TStream();

  $stream->put( $object, $object );

  my $first  = $stream->[0];
  my $second = $stream->[1];

  isa_ok( $first, TStream->ptObject );
  isa_ok( $second, TStream->ptIndexed );

  is(
    $first->[0], $$second,
    'ptIndexed contains the id of the first object'
  );

  $first  = $stream->get;
  $second = $stream->get;

  is(
    $second, $first,
    'repeated TStreamable restores the same object'
  );

  is(
    $first->{str}, 'test',
    'first reference retains data'
  );

  is(
    $second->{str}, 'test',
    'repeated reference retains data'
  );
};

subtest 'TStream keeps distinct TStreamables distinct' => sub {
  my $first  = bless { str => 'test' }, TStreamable;
  my $second = bless { str => 'test' }, TStreamable;
  my $stream = new_TStream();

  $stream->put( $first, $second );

  $first = $stream->[0];
  $second = $stream->[1];

  isa_ok( $first, TStream->ptObject );
  isa_ok( $second, TStream->ptObject );

  isnt(
    $first->[0], $second->[0],
    'distinct objects receive distinct ids'
  );

  my $firstCopy  = $stream->get;
  my $secondCopy = $stream->get;

  isnt(
    $secondCopy, $firstCopy,
    'distinct TStreamables remain distinct'
  );

  is(
    $firstCopy->{str}, 'test',
    'first object retains data'
  );

  is(
    $secondCopy->{str}, 'test',
    'second object retains data'
  );
};

subtest 'TStream leaves ordinary values unchanged' => sub {
  my $stream = new_TStream();

  $stream->put( undef, 42, 'test' );

  is(
    $stream->get, undef,
    'undef remains unchanged'
  );

  is(
    $stream->get, 42,
    'number remains unchanged'
  );

  is(
    $stream->get, 'test',
    'string remains unchanged'
  );
};

subtest 'TStream packs mixed values without stopping early' => sub {
  my $first  = bless { str => 'first'  }, TStreamable;
  my $second = bless { str => 'second' }, TStreamable;
  my $stream = new_TStream();

  is(
    $stream->put( 10, $first, 20, $second, 30 ),
    $stream,
    'put returns the stream'
  );

  is(
    $stream->get, 10,
    'first scalar retains its position'
  );

  my $firstCopy = $stream->get;

  isa_ok( $firstCopy, TStreamable );

  is(
    $firstCopy->{str}, 'first',
    'first object retains its data'
  );

  is(
    $stream->get, 20,
    'middle scalar retains its position'
  );

  my $secondCopy = $stream->get;

  isa_ok( $secondCopy, TStreamable );

  is(
    $secondCopy->{str}, 'second',
    'second object retains its data'
  );

  is(
    $stream->get, 30,
    'last scalar retains its position'
  );
};

subtest 'TStream preserves identity across nested streams' => sub {
  my $object = bless { str => 'shared' }, TStreamable;

  my $firstStream  = new_TStream();
  my $secondStream = new_TStream();

  $firstStream->put( $object );
  $secondStream->put( $object );

  isa_ok( $firstStream->[0], TStream->ptObject );
  isa_ok( $secondStream->[0], TStream->ptIndexed );

  is(
    ${ $secondStream->[0] },
    $firstStream->[0][0],
    'nested streams use the same object id'
  );

  my $firstCopy  = $firstStream->get;
  my $secondCopy = $secondStream->get;

  is(
    $secondCopy,
    $firstCopy,
    'nested streams restore the same object'
  );

  is(
    $secondCopy->{str},
    'shared',
    'object shared across streams retains data'
  );
};

done_testing();