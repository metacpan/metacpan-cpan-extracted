package ComponentUI::Controller::TestModel::Baz;

use Moose;
BEGIN { extends 'Reaction::UI::Controller::Collection::CRUD'; }

use ComponentUI::UI::ViewPort::Baz::ListView::Member;

__PACKAGE__->config(
  model_name => 'TestModel',
  collection_name => 'Baz',
  action => {
    base => { Chained => '/base', PathPart => 'testmodel/baz' },
    list => {
      ViewPort => {
        enable_order_by => [qw/id name bool_field description/],
        member_class => 'ComponentUI::UI::ViewPort::Baz::ListView::Member',
        Member => {
          Field => {
            description => {
              max_length => 40,
              layout => 'value/string',
            },
          },
        },
      },
    },
  },
);

1;
