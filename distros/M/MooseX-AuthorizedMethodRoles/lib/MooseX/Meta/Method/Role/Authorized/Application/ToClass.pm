package MooseX::Meta::Method::Role::Authorized::Application::ToClass;
use Moose::Role;
use Moose::Util::MetaRole;

after apply => sub {
    my ($self, $role_source, $role_dest, $args) = @_;
#warn("toclass",$self, $role_source, $role_dest, $args);
    Moose::Util::MetaRole::apply_base_class_roles
        (
         for   => $role_dest->name,
         roles => ['MooseX::Meta::Method::Role::Authorized']
        );
};

1;
