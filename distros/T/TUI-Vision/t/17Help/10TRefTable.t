use strict;
use warnings;

use Test::More;
use Scalar::Util qw( weaken );

BEGIN {
  use_ok 'TUI::Help::RefTable';
}

subtest 'Unknown topics are created and known topics are reused' => sub {
  my $table = new_TRefTable( 10, 5 );
  my $reference = $table->getReference( 'Introduction' );
  isa_ok( $reference, 'TReference' );
  is( $reference->topic, 'Introduction', 'stores the topic name' );
  ok( !$reference->resolved, 'new reference is unresolved' );
  is( $reference->val, 0, 'new numeric reference value is zero' );
  is( $table->getCount, 1, 'inserts one reference' );

  $reference->val( 100 );
  $reference->resolved( 1 );
  my $same = $table->getReference( 'Introduction' );
  is( $same, $reference, 'returns the existing record' );
  is( $same->val, 100, 'preserves its numeric value' );
  ok( $same->resolved, 'preserves its resolution flag' );
  is( $table->getCount, 1, 'does not insert a duplicate' );
};

subtest 'Topics are sorted case-sensitively' => sub {
  my $table = new_TRefTable( 10, 5 );
  $table->getReference( $_ ) for qw( gamma alpha beta Alpha );
  $table->getReference( '' );
  is_deeply(
    [ map { $table->at( $_ )->topic } 0 .. $table->getCount - 1 ],
    [ '', qw( Alpha alpha beta gamma ) ],
    'keeps distinct names in case-sensitive order',
  );

  my $index;
  ok( $table->search( 'alpha', \$index ), 'finds a topic by its name' );
  is( $index, 2, 'search reports its sorted position' );
  is( $table->getReference( 'alpha' ), $table->at( $index ),
    'lookup returns the record at that position' );
  ok( !$table->search( 'ALPHA', \$index ),
    'a different capitalization does not match' );
};

subtest 'Freeing entries releases the internally held records' => sub {
  my $table = new_TRefTable( 10, 5 );
  my $first = $table->getReference( 'alpha' );
  weaken( $first );
  $table->atFree( 0 );
  ok( !defined $first, 'atFree releases the removed record' );
  is( $table->getCount, 0, 'atFree removes the table entry' );

  my $second = $table->getReference( 'beta' );
  weaken( $second );
  $table->freeAll();
  ok( !defined $second, 'freeAll releases the stored record' );
  is( $table->getCount, 0, 'freeAll empties the table' );

  my $last = $table->getReference( 'gamma' );
  weaken( $last );
  undef $table;
  ok( !defined $last, 'destruction releases the remaining record' );
};

subtest 'External references remain valid after table destruction' => sub {
  my $table = new_TRefTable( 10, 5 );
  my $reference = $table->getReference( 'Introduction' );
  $reference->resolved( 1 );
  $reference->val( 100 );
  undef $table;
  is( $reference->topic, 'Introduction', 'external record retains its name' );
  is( $reference->val, 100, 'external record retains its value' );
};

done_testing();
