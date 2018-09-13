# inspired by:
use strict;
use Test::More;
use Test::Exception;
use Path::Tiny;
use Ouch;

use Ordeal::Model;
use Ordeal::Model::Backend::PlainFile;

my $dir = path(__FILE__)->parent->child('ordeal-data');
my $model =
  Ordeal::Model->new(PlainFile => [base_directory => $dir->absolute]);

isa_ok $model, 'Ordeal::Model';

throws_ok { $model->get_card('mah') } qr{invalid identifier},
  'invalid identifier';
throws_ok { $model->get_card('inexistent-1-ciao.png') } qr{not found},
  'inexistent identifier';
throws_ok { $model->get_card('inexistent-1-ciao.gif') }
qr{invalid extension}, 'invalid extension';

my $card;
lives_ok { $card = $model->get_card('group1-03-wtf.svg') }
'valid card is found';
isa_ok $card, 'Ordeal::Model::Card';
isa_ok $card->{data}, 'CODE';

is $card->id,           'group1-03-wtf.svg', 'card id';
is $card->name,         'group1-03-wtf',     'card name';
is $card->group,        '',                  'card group';
is $card->content_type, 'image/svg+xml',     'card content-type';

(my $data = $card->data) =~ s{\s+\z}{}mxs;
is $data, 'This is group1-03-wtf.svg', 'card data';

SKIP: {
   skip 'card listing disabled for the moment';
   my @all = $model->get_cards();
   is scalar(@all), 6, 'got all cards';

   my @group1 = $model->get_cards(query => {group => 'group1'});
   is scalar(@group1), 3, 'group1 cards';
   is $_->group, 'group1', 'card is in right group' for @group1;

   {
      my $group2 = $model->get_cards(query => {group => 'group2'});
      isa_ok $group2, 'CODE';
      my $item = $group2->();
      isa_ok $item, 'Ordeal::Model::Card';
      $item = $group2->();
      is $item, undef, 'no more in group2';
   }

   my @mixed =
     $model->get_cards(query => {group => [qw< group2 public >]});
   is scalar(@mixed), 3, '3 items from mixed query';

   @mixed = $model->get_cards(
      query => {group => 'group2', id => 'group1-03-wtf.svg'});
   is scalar(@mixed), 0, 'no result for impossible query';
} ## end SKIP:

done_testing();
