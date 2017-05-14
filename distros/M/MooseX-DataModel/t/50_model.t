#!/usr/bin/env perl

my $json = q'{ "menu": {
   "id": "file",
   "value": "File",
   "items": [
     {"value": "New", "onclick": "CreateNewDoc()"},
     {"value": "Open", "onclick": "OpenDoc()"},
     {"value": "Close"}
   ],
   "menus": {
     "menu1": { "value": "New" },
     "menu2": { "value": "Open" }
   }
 }
}';

package Test01 {
  use MooseX::DataModel;

  key menu => ( required => 1, isa => 'MenuSpec');
}

package MenuSpec {
  use MooseX::DataModel;
  key id => ( required => 1, isa => 'Str');
  key value => ( required => 1, isa => 'Str');
  array items => ( isa => 'MenuItem' );
  object menus => ( isa => 'MenuItem' );
}

package MenuItem {
  use MooseX::DataModel;
  key 'value' => (isa => 'Str', required => 1);
  key 'onclick' => (isa => 'Str');
}

use Data::Printer;
use Test::More;

my $model = Test01->MooseX::DataModel::new_from_json($json);

isa_ok($model, 'Test01');
isa_ok($model->menu, 'MenuSpec');
isa_ok($model->menu->items, 'ARRAY');
isa_ok($model->menu->items->[0], 'MenuItem');

isa_ok($model->menu, 'MenuSpec');
isa_ok($model->menu->menus, 'HASH');
isa_ok($model->menu->menus->{ menu1 }, 'MenuItem');

done_testing;
