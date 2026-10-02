use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Validate::StringLookupValidator';
}

my ( $v, $list );

subtest 'Collection creation' => sub {
  lives_ok {
    $list = TStringCollection->new( limit => 3, delta => 0 );
    $list->insert( $_ ) for qw( foo bar baz );
  } 'StringCollection created and populated';
  isa_ok( $list, TStringCollection );
};

subtest 'Validator creation' => sub {
  lives_ok {
    $v = TUI::Validate::StringLookupValidator->new( strings => $list );
  } 'Object created';
  isa_ok( $v, TStringLookupValidator );
};

subtest 'lookup / isValid' => sub {
  ok( $v->lookup( 'foo' ),  'Known string accepted' );
  ok( $v->isValid( 'bar' ), 'isValid delegates to lookup' );
  ok( !$v->lookup( 'qux' ), 'Unknown string rejected' );
  ok( !$v->isValid( '' ),   'Empty string rejected' );
};

subtest 'newStringList replaces list' => sub {
  lives_ok {
    $list = TStringCollection->new( limit => 2, delta => 0 );
    $list->insert( $_ ) for qw( abc def );
  } 'New StringCollection created and populated';

  lives_ok {
    $v->newStringList( $list );
  } 'newStringList does not die';

  ok( $v->lookup( 'abc' ),  'New list accepted value' );
  ok( !$v->lookup( 'foo' ), 'Old list value rejected' );
};

done_testing();
