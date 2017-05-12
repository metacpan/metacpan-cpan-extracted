package TestApp::Controller::REST;

use 5.010;
use Moose;
use Data::Dumper;
use Try::Tiny;

BEGIN {
    extends 'Catalyst::Controller::REST';
    with 'OpusVL::AppKit::RolesFor::Controller::GUI';
}

__PACKAGE__->config(
    appkit_name               => 'Vehicles',
    appkit_shared_module      => 'Vehicle',
    appkit_myclass            => 'Cygnus::AppKitX::Vehicle',
    appkit_method_group       => 'Manage vehicles',
);

sub vehicle
    : Local
    : ActionClass('REST')
    : Args(1) 
    : AppKitFeature('Raise VMA')
{ }

sub vehicle_GET
    : AppKitFeature('Raise VMA')
{
    my ($self, $c, $id) = @_;

    unless($id > 10)
    {
        $self->status_not_found($c, message => 'Vehicle not found');
        $c->detach;
    }
    $self->status_ok(
        $c,
        entity => {
            stock_id => $id,
            source_code => 'Test',
        },
    );
}

sub no_permission
    : Local
    : ActionClass('REST')
    : Args(1) 
    : AppKitFeature('Feature Not allowed')
{ }

sub no_permission_GET
{
    my ($self, $c, $id) = @_;

    die 'This is just a test action to prove the permissions work, you shouldn\'t be able to run this code.';
}

1;

