use Test2::V0 -no_srand => 1;
use PeekPoke::FFI qw( peek poke );
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1, lang => 'ASM' );

subtest default => sub {

  { package FooBytes;
    use FFI::Platypus::Record;
    record_layout_1(
      'uint8[32]' => 'foo',
    );
  }

  my $rec = FooBytes->new;
  my $add = $ffi->cast( 'record(FooBytes)*' => 'opaque', $rec );

  $rec->foo(10, 42);

  is( peek($add + 10), 42 );

  poke($add + 11, 99 );

  is( $rec->foo(11), 99 );

};

subtest oo => sub {

  { package FooInts;
    use FFI::Platypus::Record;
    record_layout_1(
      'sint32[32]' => 'foo',
    );
  }

  my $rec = FooInts->new;
  my $add = $ffi->cast( 'record(FooInts)*' => 'opaque', $rec );
  my $pp = PeekPoke::FFI->new(
    type => 'sint32',
    base => $add,
  );

  $rec->foo(10, -4200);

  is( $pp->peek(10), -4200 );

  $pp->poke(11, 99);

  is( $rec->foo(11), 99 );

};

done_testing;


