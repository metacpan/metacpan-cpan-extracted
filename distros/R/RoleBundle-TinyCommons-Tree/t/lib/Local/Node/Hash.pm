package # hide from PAUSE
    Local::Node::Hash;

# a hash-based tree node class

use Role::Tiny::With;

with 'Role::TinyCommons::Tree::Node';
with 'Role::TinyCommons::Tree::NodeMethods';
with 'Role::TinyCommons::Tree::FromStruct';

sub new {
    my $class = shift;
    my %attrs = @_;
    $attrs{parent} //= undef;
    $attrs{children} //= [];
    bless \%attrs, $class;
}

sub parent {
    my $self = shift;
    $self->{parent} = $_[0] if @_;
    $self->{parent};
}

sub children {
    my $self = shift;

    $self->{children} = $_[0] if @_;

    # we deliberately do this for testing, to make sure that the node methods
    # can work with both children returning arrayref or list
    if (rand() < 0.5) {
        return $self->{children};
    } else {
        return @{ $self->{children} };
    }
}

sub id {
    my $self = shift;
    $self->{id} = $_[0] if @_;
    $self->{id};
}

1;
