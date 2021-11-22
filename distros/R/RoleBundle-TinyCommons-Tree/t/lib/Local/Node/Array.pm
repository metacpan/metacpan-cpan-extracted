package # hide from PAUSE
    Local::Node::Array;

use Tree::Object::Array::Glob qw(id);

use Role::Tiny::With;

with 'Role::TinyCommons::Tree::Node';
with 'Role::TinyCommons::Tree::NodeMethods';
with 'Role::TinyCommons::Tree::FromStruct';

1;
