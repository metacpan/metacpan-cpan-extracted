use strict;
use Test::More;
use Test::Exception;
use Ouch;
use 5.020;
use experimental qw< postderef >;
no warnings qw< experimental::postderef >;

use Ordeal::Model;
use Ordeal::Model::Backend::Raw;

my $CRLF = "\x{0d}\x{0a}";
my %data = (
   cards => [
      {
         id => 'd6-1',
         data => "http://example.com/d6-1.png$CRLF",
         contant_type => 'text/uri-list'
      },
      {
         id => 'd6-2',
         data => "http://example.com/d6-2.png$CRLF",
         contant_type => 'text/uri-list'
      },
      {
         id => 'd6-3',
         data => "http://example.com/d6-3.png$CRLF",
         contant_type => 'text/uri-list'
      },
      {
         id => 'd6-4',
         data => "http://example.com/d6-4.png$CRLF",
         contant_type => 'text/uri-list'
      },
      {
         id => 'd6-5',
         data => "http://example.com/d6-5.png$CRLF",
         contant_type => 'text/uri-list'
      },
      {
         id => 'd6-6',
         data => "http://example.com/d6-6.png$CRLF",
         contant_type => 'text/uri-list'
      },
   ],
   decks => [
      {
         id => 'd6',
         cards => [qw< d6-1 d6-2 d6-3 d6-4 d6-5 d6-6 >],
      }
   ],
);
my $model;
lives_ok {
   $model = Ordeal::Model->new( backend => ['Raw' => data => \%data])
} 'constructor successful';
isa_ok $model, 'Ordeal::Model';

throws_ok { $model->get_deck('inexistent') } qr{not found},
  'inexistent identifier';

my $deck;
lives_ok { $deck = $model->get_deck('d6') } 'valid deck is found';

is $deck->id,      'd6', 'deck id';
is $deck->name,    'd6', 'deck name';
is $deck->group,   '',   'deck group';
is $deck->n_cards, 6,    'cards (faces) in loaded deck';

is_deeply [map { $_->id } $deck->cards], [
   qw< d6-1 d6-2 d6-3 d6-4 d6-5 d6-6 >],
  'cards (faces) in expected order';

done_testing();
