package # hide from PAUSE
    Local::Node::Moose;

use Moose;

has parent   => (is=>'rw');
has children => (is=>'rw');
has id       => (is=>'rw');

use Role::Tiny::With;

with 'Role::TinyCommons::Tree::Node';
with 'Role::TinyCommons::Tree::NodeMethods';
with 'Role::TinyCommons::Tree::FromStruct';

1;
