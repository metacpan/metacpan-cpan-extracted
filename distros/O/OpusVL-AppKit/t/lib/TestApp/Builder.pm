package TestApp::Builder;

use Moose;
use File::ShareDir;

extends 'OpusVL::AppKit::Builder';

override _build_superclasses => sub {
    return [ 'OpusVL::AppKit' ]
};

override _build_plugins => sub
{   
    my $plugins = super();

    push @$plugins, qw(
        +TestX::CatalystX::ExtensionA
        +TestX::CatalystX::ExtensionB
    );

    return $plugins;
};

override _build_config => sub
{
    my $self   = shift;
    my $config = super(); # Get what CatalystX::AppBuilder gives you

    # .. get the path for this name space..
    my $path = File::ShareDir::module_dir( 'TestApp' );

    # .. point the AppKitAuth Model to the correct DB file....
    $config->{'Model::AppKitAuthDB'} = 
    {
        schema_class => 'OpusVL::AppKit::Schema::AppKitAuthDB',
        connect_info =>
        {   
            dsn             => 'dbi:SQLite:' . $path . '/root/db/appkit_auth.db',
            user            => '',
            password        => '',
            on_connect_call => 'use_foreign_keys',
        }
    };

    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $config->{"Plugin::Static::Simple"}->{include_path};
    push(@$static_dirs, $path . '/root' );
    $config->{"Plugin::Static::Simple"}->{include_path} = $static_dirs;

    # .. allow access regardless of ACL rules...
    $config->{'appkit_can_access_actionpaths'} = ['test/custom'];
    $config->{'appkit_display_app_version'} = 1;

    # DEBUGIN!!!!
    $config->{'appkit_can_access_everything'} = 0;  

    $config->{appkit_app_order} = [
        qw/TestApp::Controller::ExtensionA TestApp::Controller::ExtensionB TestApp::Controller::Test/
    ];

    return $config;
};

1;

__END__
