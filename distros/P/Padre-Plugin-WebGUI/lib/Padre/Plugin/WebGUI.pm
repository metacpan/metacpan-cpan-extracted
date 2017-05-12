package Padre::Plugin::WebGUI;
BEGIN {
  $Padre::Plugin::WebGUI::VERSION = '1.002';
}

# ABSTRACT: Developer tools for WebGUI
use strict;
use warnings;

use base 'Padre::Plugin';
use Padre::Logger;
use Padre::Util ('_T');
use Padre::Plugin::WebGUI::Assets;


# Used to control dev niceties
my $DEV_MODE = 0;


sub plugin_name {
    return _T("WebGUI");
}


sub padre_interfaces {
    'Padre::Plugin' => 0.43,
      ;
}


sub registered_documents {
    'application/x-webgui-asset'      => 'Padre::Document::WebGUI::Asset',
      'application/x-webgui-template' => 'Padre::Document::WebGUI::Asset::Template',
      'application/x-webgui-snippet'  => 'Padre::Document::WebGUI::Asset::Snippet',
      ;
}


sub plugin_directory_share {
    my $self = shift;

    my $share = $self->SUPER::plugin_directory_share;
    return $share if $share;

    # Try this one instead (for dev version)
    my $path = Cwd::realpath( File::Spec->join( File::Basename::dirname(__FILE__), '../../../', 'share' ) );
    return $path if -d $path;

    return;
}


sub plugin_enable {
    my $self = shift;

    TRACE('Enabling Padre::Plugin::WebGUI') if DEBUG;

    # workaround Padre bug
    my %registered_documents = $self->registered_documents;
    while ( my ( $k, $v ) = each %registered_documents ) {
        Padre::MimeTypes->add_highlighter_to_mime_type( $k, $v );
    }

    # Create empty config object if it doesn't exist
    my $config = $self->config_read;
    if ( !$config ) {
        $self->config_write( {} );
    }

    return 1;
}


# called when the plugin is disabled/reloaded
sub plugin_disable {
    my $self = shift;

    TRACE('Disabling Padre::Plugin::WebGUI') if DEBUG;

    if ( my $asset_tree = $self->{asset_tree} ) {
        $self->main->right->hide($asset_tree);
        delete $self->{asset_tree};
    }

    # Unload all private classese here, so that they can be reloaded
    require Class::Unload;
    Class::Unload->unload('Padre::Plugin::WebGUI::Assets');

    # I think this would be bad if a doc was open when you reloaded the plugin, but handy when developing
    if ($DEV_MODE) {
        Class::Unload->unload('Padre::Document::WebGUI::Asset');
    }
}


sub menu_plugins {
    my $self = shift;
    my $main = shift;

    $self->{menu} = Wx::Menu->new;

    # Asset Tree
    $self->{asset_tree_toggle} = $self->{menu}->AppendCheckItem( -1, _T("Show Asset Tree"), );
    Wx::Event::EVT_MENU( $main, $self->{asset_tree_toggle}, sub { $self->toggle_asset_tree } );

    # Turn on Asset Tree as soon as Plugin is enabled
    # Disabled - we can't have this here because menu_plugins is called repeatedly
    #    if ( $self->config_read->{show_asset_tree} ) {
    #        $self->{asset_tree_toggle}->Check(1);
    #
    #        $self->toggle_asset_tree;
    #    }

    # Online Resources
    my $resources_submenu = Wx::Menu->new;
    my %resources         = $self->online_resources;
    while ( my ( $name, $resource ) = each %resources ) {
        Wx::Event::EVT_MENU( $main, $resources_submenu->Append( -1, $name ), $resource, );
    }
    $self->{menu}->Append( -1, _T("Online Resources"), $resources_submenu );

    # About
    Wx::Event::EVT_MENU( $main, $self->{menu}->Append( -1, _T("About"), ), sub { $self->show_about }, );

    # Reload (handy when developing this plugin)
    if ($DEV_MODE) {
        $self->{menu}->AppendSeparator;

        Wx::Event::EVT_MENU(
            $main,
            $self->{menu}->Append( -1, _T("Reload WebGUI Plugin\tCtrl+Shift+R"), ),
            sub { $main->ide->plugin_manager->reload_current_plugin },
        );
    }

    # Return our plugin with its label
    return ( $self->plugin_name => $self->{menu} );
}


sub online_resources {
    my %RESOURCES = (
        'Bug Tracker' => sub {
            Padre::Wx::launch_browser('http://webgui.org/bugs');
        },
        'Community Live Support' => sub {
            Padre::Wx::launch_irc( 'irc.freenode.org' => 'webgui' );
        },
        'GitHub - WebGUI' => sub {
            Padre::Wx::launch_browser('http://github.com/plainblack/webgui');
        },
        'GitHub - WGDev' => sub {
            Padre::Wx::launch_browser('http://github.com/haarg/wgdev');
        },
        'Planet WebGUI' => sub {
            Padre::Wx::launch_browser('http://patspam.com/planetwebgui');
        },
        'RFE Tracker' => sub {
            Padre::Wx::launch_browser('http://webgui.org/rfe');
        },
        'Stats' => sub {
            Padre::Wx::launch_browser('http://webgui.org/webgui-stats');
        },
        'WebGUI.org' => sub {
            Padre::Wx::launch_browser('http://webgui.org');
        },
        'Wiki' => sub {
            Padre::Wx::launch_browser('http://webgui.org/community-wiki');
        },
    );
    return map { $_ => $RESOURCES{$_} } sort { $a cmp $b } keys %RESOURCES;
}


sub show_about {
    my $self = shift;

    # Generate the About dialog
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::WebGUI");
    $about->SetDescription( <<"END_MESSAGE" );
WebGUI Plugin for Padre
http://patspam.com
END_MESSAGE
    $about->SetVersion($Padre::Plugin::WebGUI::VERSION);

    # Show the About dialog
    Wx::AboutBox($about);

    return;
}


sub ping { 1 }


sub toggle_asset_tree {
    my $self = shift;

    return unless $self->ping;

    my $asset_tree = $self->asset_tree;
    if ( $self->{asset_tree_toggle}->IsChecked ) {
        $self->main->right->show($asset_tree);
        $asset_tree->update_gui;
        $self->config_write( { %{ $self->config_read }, show_asset_tree => 1 } );
    }
    else {
        $self->main->right->hide($asset_tree);
        $self->config_write( { %{ $self->config_read }, show_asset_tree => 0 } );
    }

    $self->main->aui->Update;
    $self->ide->save_config;

    return;
}


sub asset_tree {
    my $self = shift;

    if ( !$self->{asset_tree} ) {
        $self->{asset_tree} = Padre::Plugin::WebGUI::Assets->new($self);
    }
    return $self->{asset_tree};
}


1;

__END__
=pod

=head1 NAME

Padre::Plugin::WebGUI - Developer tools for WebGUI

=head1 VERSION

version 1.002

=head1 SYNOPSIS

cpan install Padre::Plugin::WebGUI;

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

This plugin adds a "WebGUI" item to the Padre plugin menu, with a bunch of WebGUI-oriented features.

=head1 METHODS

=head2 plugin_name

The plugin name to show in the Plugin Manager and menus

=head2 padre_interfaces

Declare the Padre interfaces this plugin uses

=head2 registered_documents

Register the document types that we want to handle

=head2 plugin_directory_share

=head2 plugin_enable

called when the plugin is enabled

=head2 plugin_disable

=head2 menu_plugins

=head2 online_resources

=head2 show_about

=head2 ping

=head2 toggle_asset_tree

Toggle the asset tree panel on/off
N.B. The checkbox gets checked *before* this method runs

=head2 asset_tree

=head2 TRACE

=head1 SEE ALSO

WebGUI - http://webgui.org

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

