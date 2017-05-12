package TestX::CatalystX::ExtensionA::Controller::ExtensionA::ExpansionAA;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'ExtensionA',
    appkit_order                => 10,
    appkit_icon                 => 'static/images/flagA.jpg',
    appkit_myclass              => 'TestX::CatalystX::ExtensionA::ExpansionAA',
    appkit_method_group         => 'Extension A sub controller',
    appkit_method_group_order   => 1,
    appkit_shared_module        => 'ExtensionA',
);

sub home
    :Path
    :Args(0)
    :NavigationName('Expanded Action')
    :AppKitFeature('Extension A')
    :NavigationOrder(1)
#    :AppKitRolesAllowed('Administrator')
{
    my ($self, $c) = @_;
    $c->stash->{template} = 'extensiona.tt';
    $c->stash->{custom_string} = 'The is the home action from the ExpansionAA subcontroler in ExtensionA';
}

sub startchain
    :Chained('/')
    :PathPart('start')
    :CaptureArgs(0)
    :AppKitFeature('Extension A')
#    :AppKitRolesAllowed('Administrator')
{
    my ($self, $c) = @_;
    $c->stash->{template} = 'extensiona.tt';
    $c->stash->{custom_string} = 'Start Chained actions...';
}
sub midchain
    :Chained('startchain')
    :PathPart('mid')
    :CaptureArgs(0)
#    :AppKitRolesAllowed('Administrator')
    :AppKitFeature('Extension A')
{
    my ($self, $c) = @_;
    $c->stash->{custom_string} .= 'Middle of Chained actions...';
}
sub endchain
    :Chained('midchain')
    :PathPart('end')
    :Args(0)
    :NavigationName('Expanded Chained Action')
    :NavigationOrder(2)
    :AppKitFeature('Extension A')
#    :AppKitRolesAllowed('Administrator')
{
    my ($self, $c) = @_;
    $c->stash->{custom_string} .= 'End of Chained actions.';
}

1;
__END__
