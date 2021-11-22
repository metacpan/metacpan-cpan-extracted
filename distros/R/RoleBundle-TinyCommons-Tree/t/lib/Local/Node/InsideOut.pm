package # hide from PAUSE
    Local::Node::InsideOut;

# a Class::InsideOut-based tree node class

use Role::Tiny::With;

with 'Role::TinyCommons::Tree::Node'; # won't work?
with 'Role::TinyCommons::Tree::NodeMethods';
with 'Role::TinyCommons::Tree::FromStruct';

use Class::InsideOut qw(public register id);

BEGIN {
    public parent => my %parent;
    public children => my %children;
    public id => my %id;

    sub new {
        my $self = register(shift);
        $children{ id $self } ||= [];
        $self;
    }
}

1;
