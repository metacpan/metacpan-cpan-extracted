package OpusVL::AppKit::Builder;

##################################################################################################################################
# use lines.
##################################################################################################################################
use Moose;
use File::ShareDir qw/module_dir/;
use OpusVL::AppKit::Form::Login;

##################################################################################################################################
# moose calls.
##################################################################################################################################
#
# The following Moose calls are used to interact with the CatalystX::AppBuilder. You can see it overrides the building of 2
# AppBuilder variables forcing the AppBuilder to create our Builder object with our own Plugins and Config.
#
# FYI: the 2 varables are
#   plugins     - ArrayRef of Plugin names to load.
#   config      - HashRef of configuration for the application.
#
#################################################################################################################################

extends 'CatalystX::AppBuilder';

override _build_plugins => sub 
{
    my $plugins = super();

    push @$plugins, qw(
        ConfigLoader::Environment
        Static::Simple
        CustomErrorMessage
        Authentication
        Authorization::Roles
        Session
        Session::Store::FastMmap
        Session::State::Cookie
        Cache
        +CatalystX::SimpleLogin
        +CatalystX::VirtualComponents
        +OpusVL::AppKit::Plugin::AppKit
        +OpusVL::AppKit::Plugin::AppKitControllerSorter
    );

    return $plugins;
};

override _build_config => sub 
{
    my $self   = shift;
    my $config = super(); # Get what CatalystX::AppBuilder gives you

    # .. get the path for this name space..
    my $path = File::ShareDir::module_dir( 'OpusVL::AppKit' );

    $config->{'default_view'}                                       = 'AppKitTT';

    $config->{'custom-error-message'}                               = { 'error-template' => 'error.tt' };

    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $config->{"Plugin::Static::Simple"}->{include_path};
    push(@$static_dirs, $path . '/root' );
    $config->{"Plugin::Static::Simple"}->{include_path}      = $static_dirs;
    $config->{"Plugin::Static::Simple"}->{ignore_extensions} = [qw/tt tt2 db yml/];
    $config->{encoding} = 'UTF-8';

    # FIXME: this line appears to cause a problem
    #$config->{'Controller::HTML::FormFu'}->{constructor}->{config_file_path} = [ $path . '/root/forms' ];

    # .. add template dir into the config for View::PDF::Reuse...
    my $pdf_path = $config->{'View::PDF::Reuse'}->{'INCLUDE_PATH'};
    push(@$pdf_path, $path . '/root/templates' );
    $config->{'View::PDF::Reuse'}->{'INCLUDE_PATH'} = $pdf_path;

    # .. add template dir into the config for View::AppKitTT...
    my $inc_path = $config->{'View::AppKitTT'}->{'INCLUDE_PATH'};
    push(@$inc_path, $path . '/root/templates' );

    # Configure View::AppKitTT...
    my $tt_dirs = $config->{'View::AppKitTT'}->{'INCLUDE_PATH'};
    # ...(add to include_path)..
    push(@$tt_dirs, $self->inherited_path_to('root','templates') );
    push(@$tt_dirs, $path . '/root/templates' );
    $config->{'View::AppKitTT'}->{'INCLUDE_PATH'}         = $tt_dirs;
    $config->{'View::AppKitTT'}->{'TEMPLATE_EXTENSION'}   = '.tt';
    $config->{'View::AppKitTT'}->{'WRAPPER'}              = 'wrapper.tt';
    $config->{'View::AppKitTT'}->{'PRE_PROCESS'}          = 'preprocess.tt';

    # This is the latest place this can be done and actually have an effect.
    $config->{'View::AppKitTT'}->{RECURSION}              = 1;

    $config->{'custom-error-message'}->{'view-name'} = 'AppKitTT';
    # Configure session handling..
    $config->{'Plugin::Session'} ||= {};
    $config->{'Plugin::Session'}->{flash_to_stash} = 1;

    $config->{'Plugin::Authentication'} =
    {
            default_realm   => 'appkit',
            appkit          => 
            {
                credential => 
                {
                   class              => 'Password',
                   password_type      => 'self_check',
                },
                store => 
                {
                   class              => 'DBIx::Class',
                   user_model         => 'AppKitAuthDB::User',   
                   role_relation      => 'roles',
                   role_field         => 'role',
                }
            },
    };

    $config->{'View::Email'} =
    {
        stash_key   => 'email',
        default     => 
        {
            content_type    => 'text/plain',
            charset         => 'utf-8'
        },
        sender  => 
        {
            mailer          => 'SMTP',
        }
    };

    # set the appkit_friendly_name..
    $config->{'application_name'} = "OpusVL::AppKit";

    # we can turn off access controller... but ONLY FOR DEBUGGIN!
    $config->{'appkit_can_access_everything'} = 0;

    # Configure AppKit Plugin access denied..
    $config->{'appkit_access_denied'}    = "access_notallowed";

    $config->{'Controller::Login'} = 
    {
        traits => [ 
        '+OpusVL::AppKit::TraitFor::Controller::Login::SetHomePageFlag', 
        '+OpusVL::AppKit::TraitFor::Controller::Login::NewSessionIdOnLogin', 
        '-Login::WithRedirect' 
        ],
        login_form_class => 'OpusVL::AppKit::Form::Login',
    };

    $config->{'Plugin::Cache'}{backend} = {
        class => 'Cache::FastMmap',
    };

    # Password constraint config
    $config->{'AppKit'}->{'password_min_characters'} = 8;
    $config->{'AppKit'}->{'password_force_numerics'} = 0;
    $config->{'AppKit'}->{'password_force_symbols'}  = 0;
    
    # unbuffer stdout and stderr to prevent logging 
    # getting clogged up.
    select( ( select(\*STDERR), $|=1 )[0] );
    select( ( select(\*STDOUT), $|=1 )[0] );

    # NOTE: if you want to use Memcahced in your app add this to your builder,
    #
    # $config->{'Plugin::Cache'}{backend} = {
    #     class   => "Cache::Memcached::libmemcached",
    #     servers => ['127.0.0.1:11211'],
    #     debug   => 2,
    # };

    # set this up empty for now.
    $config->{'View::Excel'} = { etp_config => { INCLUDE_PATH => [] }};

    return $config;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Builder

=head1 VERSION

version 2.29

=head1 SYNOPSIS

    See: OpusVL::AppKit

    Inheriting this app using AppBuilder will give your application the following:

        Catalyst::Plugin::Static::Simple
        Catalyst::Plugin::CustomErrorMessage
        Catalyst::Plugin::Authentication
        Catalyst::Plugin::Authorization::Roles
        Catalyst::Plugin::Session
        Catalyst::Plugin::Session::Store::FastMmap
        Catalyst::Plugin::Session::State::Cookie
        CatalystX::SimpleLogin
        CatalystX::VirtualComponents
        OpusVL::AppKit::Plugin::AppKit

        Controller::Root

        View::AppKitTT
        View::Email
        View::Download
        View::JSON
        View::Excel

    Plugins
        All the standard ones we use as per their documentation.
        We have created our own AppKit Plugin, which is used to drive the AppKit specific code . At the moment it is used
        for ACL rules, Portlets and Navigation... I guess in time it will evolve, but now works ok.

    Controllers
    
    The Root controller is used to drive the GUI, it is pretty simple so could be over written if required (i think?).
    The Root controller (and any you want to work with the GUI) are based on the L<OpusVL::AppKit::Base::Controller>, this
    turns a controller into an "AppKit aware" controller and it can tell the AppKit what its name is, what Porlets it has, etc.
    See L<OpusVL::AppKit::Base::Controller> for more information.

    Views

    Currently only the AppKitTT view is used and this is to create the GUI... the view is configured for the GUI, but it could be reused (i think).
    The other views are available to be utilised in furture development.

=head1 DESCRIPTION

    This extends CatalystX::AppBuilder so the OpusVL::AppKit can be inherited.

    Here we set the configuration required for the AppKit to run (inside another app)
    
    The supporting files like templates etc. are stored in the modules 'auto' directory
    see. L<File::ShareDir>

    This creates a catalyst app with the following Plugins loaded:
        L<Catalyst::Plugin::Static::Simple>
        L<Catalyst::Plugin::Unicode>
        L<Catalyst::Plugin::CustomErrorMessage>
        L<Catalyst::Plugin::Authentication>
        L<Catalyst::Plugin::Authorization::Roles>
        L<Catalyst::Plugin::Session>
        L<Catalyst::Plugin::Session::Store::FastMmap>
        L<Catalyst::Plugin::Session::State::Cookie>
        L<CatalystX::SimpleLogin>
        L<CatalystX::VirtualComponents>
        L<OpusVL::AppKit::Plugin::AppKit>

    This also configures the application in the following way:

        default_view                    - Set to 'AppKitTT'
        custom-error-message            - enable customer error msg.
        static                          - set static to auto dir
        OpusVL::AppKit::Plugin::AppKit  - used to config ACL rules.
        View::AppKitTT                  - set include paths, wrapper, etc.
        Plugin::Authentication          - used to authenicate users.
        View::Email                     - use to send any emails

=head1 NAME

    OpusVL::AppKit::Builder - Builder class for OpusVL::AppKit

=head1 SEE ALSO

    L<File::ShareDir>,
    L<CatalystX::AppBuilder>,
    L<OpusVL::AppKit>,
    L<Catalyst>

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
