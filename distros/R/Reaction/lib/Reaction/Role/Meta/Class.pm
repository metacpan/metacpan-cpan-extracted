package Reaction::Role::Meta::Class;

use Moose::Role;

around initialize => sub {
    my $super = shift;
    my $class = shift;
    my $pkg   = shift;
    $super->($class, $pkg, 'attribute_metaclass' => 'Reaction::Meta::Attribute', @_ );
};

around add_role => sub {
    my $orig = shift;
    my $self = shift;
    my ($role) = @_;

    my @roles = grep { !$_->isa('Moose::Meta::Role::Composite') }
                     $role->calculate_all_roles;
    my @bad_roles = map { Moose::Util::does_role($_, 'MooseX::Role::Parameterized::Meta::Trait::Parameterized') ? $_->genitor->name : $_->name }
                    grep { $_->get_attribute_list > 0 }
                    grep { !Moose::Util::does_role($_->applied_attribute_metaclass, 'Reaction::Role::Meta::Attribute') }
                    @roles;

    if (@bad_roles) {
        my $plural = @bad_roles > 1;
        warn "You are applying the role" . ($plural ? "s " : " ")
           . join(", ", @bad_roles)
           . " to the Reaction::Class " . $self->name
           . ", but " . ($plural ? "these roles do" : "that role does")
           . " not use Reaction::Role or"
           . " Reaction::Role::Parameterized. In Moose versions greater than"
           . " 2.0, this will cause the special behavior of Reaction"
           . " attributes to no longer be applied to attributes defined"
           . " in " . ($plural ? "these roles" : "this role")
           . ". You should replace 'use Moose::Role' with"
           . " 'use Reaction::Role' or 'use MooseX::Role::Parameterized' with"
           . " 'use Reaction::Role::Parameterized'.";
    }

    $self->$orig(@_);
} if Moose->VERSION >= 1.9900;

1;
