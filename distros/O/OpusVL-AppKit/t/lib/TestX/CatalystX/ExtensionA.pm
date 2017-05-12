package TestX::CatalystX::ExtensionA;

use Moose::Role;
use CatalystX::InjectComponent;
use namespace::autoclean;

our $VERSION = '0.01';

after 'setup_components' => sub
{
    my $class = shift;
    CatalystX::InjectComponent->inject
    (
        into        => $class,
        component   => 'TestX::CatalystX::ExtensionA::Controller::ExtensionA',
        as          => 'Controller::ExtensionA'
    );
    CatalystX::InjectComponent->inject
    (
        into        => $class,
        component   => 'TestX::CatalystX::ExtensionA::Controller::ExtensionA::ExpansionAA',
        as          => 'Controller::ExtensionA::ExpansionAA'
    );

    
    my $config = $class->config;

    # .. get the path for this name space..
    my $path = File::ShareDir::module_dir( __PACKAGE__ );

    # .. add template dir into the config for View::AppKitTT...
    my $inc_path = $config->{'View::AppKitTT'}->{'INCLUDE_PATH'};
    push(@$inc_path, $path . '/root/templates' );
    $config->{'View::AppKitTT'}->{'INCLUDE_PATH'} = $inc_path;

    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $config->{"Plugin::Static::Simple"}->{include_path};
    push(@$static_dirs, $path . '/root' );
    $config->{"Plugin::Static::Simple"}->{include_path} = $static_dirs;

};

1;
