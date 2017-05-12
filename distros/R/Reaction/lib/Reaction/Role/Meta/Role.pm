package Reaction::Role::Meta::Role;

use Moose::Role;

around initialize => sub {
    my $super = shift;
    my $class = shift;
    my $pkg   = shift;
    $super->($class, $pkg, 'applied_attribute_metaclass' => 'Reaction::Meta::Attribute', @_ );
};

1;
