package TestX::CatalystX::ExtensionA::Controller::ExtensionA;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'ExtensionA',
    appkit_icon                 => 'static/images/flagA.jpg',
    appkit_myclass              => 'TestX::CatalystX::ExtensionA',
    appkit_method_group         => 'Extension A',
    appkit_method_group_order   => 2,
    appkit_shared_module        => 'ExtensionA',
);

sub home
    :Path
    :Args(0)
    :NavigationHome
    :AppKitFeature('Extension A')
#    :AppKitRolesAllowed('Administrator')
{
    my ($self, $c) = @_;
    $c->stash->{template} = 'extensiona.tt';
}

sub table
    : Local
    : Args(0)
    : NavigationName('Table test')
    : AppKitFeature('Extension A')
{
    my ($self, $c) = @_;
}

__END__
