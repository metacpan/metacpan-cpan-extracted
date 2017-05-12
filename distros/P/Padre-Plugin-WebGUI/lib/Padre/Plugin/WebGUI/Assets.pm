package Padre::Plugin::WebGUI::Assets;
BEGIN {
  $Padre::Plugin::WebGUI::Assets::VERSION = '1.002';
}

# ABSTRACT: WebGUI Asset Tree

use strict;
use warnings;

use Padre::Current ();
use Padre::Logger;
use Padre::Util ();
use Padre::Wx   ();

use base 'Wx::TreeCtrl';

# generate fast accessors
use Class::XSAccessor getters => {
    plugin    => 'plugin',
    connected => 'connected',
    url       => 'url',
};


sub new {
    my $class  = shift;
    my $plugin = shift;

    my $self = $class->SUPER::new( $plugin->main->right, -1, Wx::wxDefaultPosition, Wx::wxDefaultSize,
        Wx::wxTR_HIDE_ROOT | Wx::wxTR_SINGLE | Wx::wxTR_HAS_BUTTONS | Wx::wxTR_LINES_AT_ROOT | Wx::wxBORDER_NONE );

    $self->{plugin} = $plugin;

    # Register event handlers..
    Wx::Event::EVT_TREE_ITEM_ACTIVATED(
        $self, $self,
        sub {
            $self->on_tree_item_activated( $_[1] );
        },
    );

    $self->Hide;

    # Create image list
    my $imglist = Wx::ImageList->new( 16, 16 );
    $self->AssignImageList($imglist);
    $imglist->Add( Padre::Wx::Icon::find('status/padre-plugin') );

    return $self;
}


sub right { $_[0]->GetParent }


sub main { $_[0]->GetGrandParent }


sub gettext_label { Wx::gettext('Asset Tree') }


sub clear { $_[0]->DeleteAllItems }


sub update_gui {
    my $self = shift;
    if ( $self->connected ) {
        $self->update_gui_connected;
    }
    else {
        $self->update_gui_disconnected;
    }
}


sub update_gui_disconnected {
    my $self = shift;

    $self->{connected} = 0;

    $self->Freeze;
    $self->clear;

    my $root = $self->AddRoot( Wx::gettext('Asset Tree'), -1, -1, Wx::TreeItemData->new('') );
    my $connect = $self->AppendItem( $root, 'Connect', -1, -1, Wx::TreeItemData->new( { connect => 1 } ), );
    $self->SetItemTextColour( $connect, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->SetItemImage( $connect, 0 );
    $self->GetBestSize;

    $self->Thaw;
}


sub update_gui_connected {
    my $self = shift;

    $self->{connected} = 1;

    # Show loading indicator
    $self->Freeze;
    $self->clear;

    my $tmp_root = $self->AddRoot( Wx::gettext('Asset Tree'), -1, -1, Wx::TreeItemData->new('') );
    my $status = $self->AppendItem( $tmp_root, 'Loading..', -1, -1, Wx::TreeItemData->new( { loading => 1 } ), );
    $self->SetItemTextColour( $status, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->SetItemImage( $status, 0 );
    $self->GetBestSize;

    $self->Thaw;

    # Force window update
    $self->Update;

    # Now actually connect..
    $self->Freeze;
    $self->clear;

    my $root = $self->AddRoot( Wx::gettext('Asset Tree'), -1, -1, Wx::TreeItemData->new('') );
    my $refresh = $self->AppendItem( $root, 'Refresh', -1, -1, Wx::TreeItemData->new( { refresh => 1 } ), );
    $self->SetItemTextColour( $refresh, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
    $self->SetItemImage( $refresh, 0 );

    if ( my $assets = $self->build_asset_tree ) {
        update_treectrl( $self, $assets, $root );

        # Register right-click event handler
        Wx::Event::EVT_TREE_ITEM_RIGHT_CLICK( $self, $self, \&on_tree_item_right_click, );

        $self->GetBestSize;
        $self->Thaw;
    }
    else {

        # Reset back to disconnected state
        $self->GetBestSize;
        $self->Thaw;
        $self->update_gui_disconnected;
    }
}


sub build_asset_tree {
    my $self = shift;

    # Create a user agent object
    use LWP::UserAgent;
    my $ua       = LWP::UserAgent->new;
    my $response = $ua->get( $self->url . '?op=padre&func=list' );
    unless ( $response->header('Padre-Plugin-WebGUI') ) {
        $self->main->error("The server does not appear to have the Padre::Plugin::WebGUI content handler installed");
        return;
    }
    if ( !$response->is_success ) {
        $self->main->error( "The server said:\n" . $response->status_line );
        return;
    }

    my $assets = $response->content;

    # TRACE($assets) if DEBUG;

    use JSON;
    $assets = eval { decode_json($assets) };
    if ($@) {
        TRACE($@) if DEBUG;
        $self->main->error("The server sent an invalid response, please try again (and check the logs)");
        return;
    }
    else {
        return $assets;
    }
}


sub edit_asset {
    my $self = shift;
    my $item = shift;

    # Create new editor tab
    my $main = $self->main;
    $main->on_new();
    my $editor = $main->current->editor or return;
    my $doc = $editor->{Document};

    # Set WebGUI Asset mime-type and rebless
    my %registered_documents = $self->plugin->registered_documents;
    my $mimetype             = lc $item->{className};
    $mimetype =~ s/.*:://;
    $mimetype = "application/x-webgui-$mimetype";

    # Fall-back to generic 'asset' mime-type
    $mimetype = "application/x-webgui-asset" unless $registered_documents{$mimetype};
    TRACE("Using mimetype: $mimetype for $item->{className}") if DEBUG;
    $doc->set_mimetype($mimetype);

    # Rebless
    $doc->editor->padre_setup;
    $doc->rebless;

    return unless $doc->isa('Padre::Document::WebGUI::Asset');

    # Load asset
    $doc->load_asset( $item->{assetId}, $self->url );

    # Fake-save tab so that it isn't in the unsaved state
    my $id   = $main->find_id_of_editor($editor);
    my $page = $main->notebook->GetPage($id);
    $page->SetSavePoint;

    # Set tab icon
    if ( my $icon = $self->get_item_icon( $item->{icon} ) ) {
        $main->notebook->SetPageBitmap( $id, $icon );
    }

    $main->refresh;
}


sub on_tree_item_right_click {
    my ( $self, $event ) = @_;

    my $showMenu = 0;
    my $menu     = Wx::Menu->new;
    my $item     = $self->GetPlData( $event->GetItem );

    if ( defined $item ) {
        my $submenu;

        $submenu = $menu->Append( -1, Wx::gettext("Details..") );
        Wx::Event::EVT_MENU(
            $self, $submenu,
            sub {
                $self->on_tree_item_activated( $event, { action => 'details' } );
            },
        );

        $submenu = $menu->Append( -1, Wx::gettext("Edit") );
        Wx::Event::EVT_MENU(
            $self, $submenu,
            sub {
                $self->edit_asset($item);
            },
        );

        $showMenu++;
    }

    if ( $showMenu > 0 ) {
        my $x = $event->GetPoint->x;
        my $y = $event->GetPoint->y;
        $self->PopupMenu( $menu, $x, $y );
    }

    return;
}


sub on_tree_item_activated {
    my ( $self, $event, $opts ) = @_;
    $opts ||= {};

    # Get the target item
    my $item = $self->GetPlData( $event->GetItem );
    return if not defined $item;

    if ( $item->{connect} ) {
        my $url =
          $self->main->prompt( 'Enter a URL to connect to, for example: http://admin:123qwe@dev.localhost.localdomain',
            'Connect To Server', 'wg_url' );
        return unless $url;
        $self->{url} = $url;
        $self->update_gui_connected;
        return;
    }

    elsif ( $item->{refresh} ) {
        $self->update_gui_connected;
        return;
    }

    elsif ( $opts->{action} && $opts->{action} eq 'details' ) {
        my $str = q{};
        for my $key ( sort keys %$item ) {
            $str .= qq{$key:\t\t $item->{$key}\n};
        }
        $self->main->error($str);
    }

    else {

        # Default event is double-click
        $self->edit_asset($item);
    }

    return;
}

my $image_lookup;


sub get_item_image {
    my $self = shift;
    my $icon = shift;

    $icon =~ s{.*/}{};
    my $imglist = $self->GetImageList;
    if ( !$image_lookup->{$icon} ) {
        my $index = $imglist->Add(
            Wx::Bitmap->new( $self->plugin->plugin_directory_share . "/icons/16x16/$icon", Wx::wxBITMAP_TYPE_GIF ) );
        $image_lookup->{$icon} = $index;
    }
    return $image_lookup->{$icon} || 0;
}


sub get_item_icon {
    my $self  = shift;
    my $icon  = shift;
    my $index = $self->get_item_image($icon);
    return $self->GetImageList->GetIcon($index);
}


sub update_treectrl {
    my ( $self, $items, $parent ) = @_;

    foreach my $item ( @{$items} ) {
        my $node = $self->AppendItem( $parent, $item->{menuTitle}, -1, -1, Wx::TreeItemData->new( {%$item} ), );
        $self->SetItemTextColour( $node, Wx::Colour->new( 0x00, 0x00, 0x7f ) );
        $self->SetItemImage( $node, $self->get_item_image( $item->{icon} ) );

        # Recurse, adding children to $node
        update_treectrl( $self, $item->{children}, $node );
    }

    return;
}


1;

__END__
=pod

=head1 NAME

Padre::Plugin::WebGUI::Assets - WebGUI Asset Tree

=head1 VERSION

version 1.002

=head1 METHODS

=head2 plugin

Accessor

=head2 connected

Accessor

=head2 url

Accessor

=head2 new

constructor

=head2 right

Accessor

=head2 main

Accessor

=head2 gettext_label

Accessor

=head2 clear

Accessor

=head2 update_gui

=head2 update_gui_disconnected

=head2 update_gui_connected

=head2 build_asset_tree

generate the list of assets
todo - make this lazy-load for better performance

=head2 edit_asset

=head2 on_tree_item_right_click

=head2 on_tree_item_activated

event handler for item activation

=head2 get_item_image

=head2 get_item_icon

=head2 update_treectrl

=head2 TRACE

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

