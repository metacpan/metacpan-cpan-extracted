package OpusVL::FB11X::Preferences;

use v5.24;
use Moose::Role;
use CatalystX::InjectComponent;

our $VERSION = '0.33';

with "OpusVL::FB11::RolesFor::Plugin";

after setup_components => sub {
    my $class = shift;
    my $moduledir = $class->add_paths(__PACKAGE__);
    push $class->config->{'Controller::HTML::FormFu'}->{constructor}->{config_file_path}->@*,  $moduledir . '/root/forms';

    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'OpusVL::FB11X::Model::PreferencesDB',
        as        => 'Model::PreferencesDB'
    );
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'OpusVL::FB11X::Preferences::Controller::Preferences',
        as        => 'Controller::Preferences'
    );

};


1;
