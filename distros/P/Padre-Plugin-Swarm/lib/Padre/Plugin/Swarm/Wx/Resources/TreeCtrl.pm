package Padre::Plugin::Swarm::Wx::Resources::TreeCtrl;

use 5.008;
use strict;
use warnings;
use File::Copy;
use File::Spec      ();
use File::Basename  ();
use Padre::Current  ();
use Padre::Util     ();
use Padre::Wx       ();
use Padre::Constant ();

our $VERSION = '0.2';
our @ISA     = 'Wx::TreeCtrl';


## ALMOST all cargo from the Padre directory class

# Creates a new Directory Browser object
sub new {
	my $class = shift;
	my $panel = shift;
	my %args = @_;
	my $self  = $class->SUPER::new(
		$panel,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTR_HIDE_ROOT | Wx::wxTR_SINGLE | Wx::wxTR_FULL_ROW_HIGHLIGHT | Wx::wxTR_HAS_BUTTONS
			| Wx::wxTR_LINES_AT_ROOT | Wx::wxBORDER_NONE
	);
	
	# Yuk - TODO event subscriptions 'after' geometry handles this ?
	$self->{universe} =  $args{universe} ;
	
	# Files that must be skipped
	$self->{CACHED} = {};

	# Selected item of each project
	$self->{current_item} = {};

	# Create the image list
	my $images = Wx::ImageList->new( 16, 16 );
	$self->{file_types} = {
		upper => $images->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_GO_DIR_UP', 'wxART_OTHER_C', [ 16, 16 ] ),
		),
		folder => $images->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_FOLDER', 'wxART_OTHER_C', [ 16, 16 ] ),
		),
		package => $images->Add(
			Wx::ArtProvider::GetBitmap( 'wxART_NORMAL_FILE', 'wxART_OTHER_C', [ 16, 16 ] ),
		),
	};
	$self->AssignImageList($images);

	# Set up the events
	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self, $self,
		\&_on_tree_item_activated
	);
#
#	Wx::Event::EVT_SET_FOCUS(
#		$self,
#		sub {
#			$_[0]->parent->refresh;
#		},
#	);
#
#	Wx::Event::EVT_TREE_ITEM_MENU(
#		$self, $self,
#		\&_on_tree_item_menu,
#	);
#
#	Wx::Event::EVT_TREE_SEL_CHANGED(
#		$self, $self,
#		\&_on_tree_sel_changed,
#	);
#
#	Wx::Event::EVT_TREE_ITEM_EXPANDING(
#		$self, $self,
#		\&_on_tree_item_expanding,
#	);
	
# who cares?
#	Wx::Event::EVT_TREE_ITEM_COLLAPSING(
#		$self, $self,
#		\&_on_tree_item_collapsing,
#	);

#	Wx::Event::EVT_TREE_END_LABEL_EDIT(
#		$self, $self,
#		\&_on_tree_end_label_edit,
#	);
	
# No dragonslop
#	Wx::Event::EVT_TREE_BEGIN_DRAG(
#		$self, $self,
#		\&_on_tree_begin_drag,
#	);
#
#	Wx::Event::EVT_TREE_END_DRAG(
#		$self, $self,
#		\&_on_tree_end_drag,
#	);

	# Set up the root
	my $root = $self->AddRoot(
		Wx::gettext('Swarm'),
		-1, -1,
		Wx::TreeItemData->new(
			{       
				node => 'swarm',
				type => 'folder',
			}
		),
	);
	$self->_update_root_data;
	# Ident to sub nodes
	$self->SetIndent(10);

	return $self;
}

sub universe { $_[0]->{universe} }

# Returns the Directory Panel object reference
sub parent {
	$_[0]->GetParent;
}

# Traverse to the search widget
sub search {
	$_[0]->GetParent->search;
}

# Returns the main object reference
sub main {
	$_[0]->GetParent->main;
}

sub current {
	Padre::Current->new( main => $_[0]->main );
}

# Updates the gui if needed
# TODO refresh should be passed the node to refresh
# and maintain the expand/collapse state of the control
sub refresh {
	my $self   = shift;
	# Gets Root node
	my $root = $self->GetRootItem;

	# Lock the gui here to make the updates look slicker
	# The locker holds the gui freeze until the update is done.
	my $lock = $self->main->lock('UPDATE');
	$self->_update_root_data;


	# Checks expanded sub folders and its content recursively
	#$_update_subdirs( $self, $root );
}

# Updates root nodes data to the current project
# Called when turned beteween projects
use Data::Dumper;

sub _update_root_data {
	my $self    = shift;

	# Updates Root node data
	my $root = $self->GetRootItem;
	$self->DeleteChildren($root);
	my $data = $self->GetPlData($root);
	my $geo = $self->universe->geometry;
	foreach my $user ( $geo->get_users ) {
		my $user_node = 
			$self->AppendItem( $root, $user , -1 , -1 ,
			Wx::TreeItemData->new(	{ type => 'user' , node=>$user })
		);
		
		my @resources = $geo->graph->successors($user);
		foreach my $resource ( @resources ) {
			$self->AppendItem( 
				$user_node , $resource , -1 , -1 ,
				Wx::TreeItemData->new(	
					{ type =>'editor'  , resource=>$resource } 
				)
			);
		}
	}
	
}


sub _list_resources {
	my $self      = shift;
	my $node      = shift;
	my $node_data = $self->GetPlData($node);
	my @nodes = $self->plugin->geometry->get_successors( $node_data );
	
	# Delete node children and populates it again
	$self->DeleteChildren($node);
	foreach my $each (@nodes) {
		my $new_elem = $self->AppendItem(
			$node,
			$each->{name},
			$self->{file_types}->{ $each->{type} },
			-1,
			Wx::TreeItemData->new(
				{   name => $each->{name},
					dir  => $each->{dir},
					type => $each->{type},
				}
			)
		);
		if ( $each->{type} eq 'folder' ) {
			$self->SetItemHasChildren( $new_elem, 1 );
		}
	}
}


# Runs thought a directory content recursively looking if each EXPANDED item   #
# has changed and updates it                                                   #
sub _update_subnodes {
	my ( $self, $root ) = @_;
	my $parent  = $self->parent;
	my $plugin = $self->plugin;
	my $geometry = $plugin->geometry;
	my $node = $root->GetData;
	my @children = $geometry->successors( $node );
	my $new_root = $self->AppendItem( $root , "$node" );
	$self->AppendItem( $new_root, "$_" ) for @children;
	

}




# Action that must be executed when a item is activated
# Called when the item is actived
sub _on_tree_item_activated {
	my ( $self, $event ) = @_;
	my $parent    = $self->parent;
	my $node      = $event->GetItem;
	my $node_data = $self->GetPlData($node);

	# If its a folder expands/collapses it and returns
	# or makes it the current project folder, depending
	# of the mode view
	if ( $node_data->{type} eq 'folder' ) {
			$self->Toggle($node);
	}
	
	if ($node_data->{type} eq 'editor' ) {
		## Another FIXME!
		$self->universe->send(
			{ type=>'gimme',
			  resource => $node_data->{resource} }
		);
	}

	# Open the clicked resource

	return;
}


# Caches the item path as current selected item
# Called when a item is selected
sub _on_tree_sel_changed {
	my ( $self, $event ) = @_;
	return if not $self->parent->can('project_dir');
	my $node_data = $self->GetPlData( $event->GetItem );

	# Caches the item path
	$self->{current_item}->{ $self->parent->project_dir } =
		File::Spec->catfile( $node_data->{dir}, $node_data->{name} );
}

# Expands the node and loads its content.
# Called when a folder is expanded.
sub _on_tree_item_expanding {
	my ( $self, $event ) = @_;
	my $node      = $event->GetItem;
	my $node_data = $self->GetPlData($node);

	# Returns if a search is being done (expands only the browser listing)
	return if !defined( $self->search );
	return if $self->search->{in_use}->{ $self->parent->project_dir };

	# The item complete path
	my $path = File::Spec->catfile( $node_data->{dir}, $node_data->{name} );

	# Cache the expanded state of the node
	$self->{CACHED}->{ $self->parent->project_dir }->{Expanded}->{$path} = 1;

	# Updates the node content if it changed or has no child
	if ( $self->_updated_dir($path) or !$self->GetChildrenCount($node) ) {
		$self->_list_dir($node);
	}
}

# Deletes nodes Expanded cache param.
# Called when a folder is collapsed.
sub _on_tree_item_collapsing {
	my ( $self, $event ) = @_;
	my $node        = $event->GetItem;
	my $node_data   = $self->GetPlData($node);
	my $project_dir = $self->parent->project_dir;

	# If it is the Root node, set Expanded to 0
	if ( $node == $self->GetRootItem ) {
		$self->{CACHED}->{$project_dir}->{Expanded}->{$project_dir} = 0;
		return;
	}

	# Deletes cache expanded state of the node
	delete $self->{CACHED}->{$project_dir}->{Expanded}
		->{ File::Spec->catfile( $node_data->{dir}, $node_data->{name} ) };
}

# If the item is not the root node let it to be dragged.
# Called when a item is dragged.
sub _on_tree_begin_drag {
	my ( $self, $event ) = @_;
	my $node      = $event->GetItem;
	my $node_data = $self->GetPlData($node);

	# Only drags if it's not the Root node
	# and if it's not the upper item
	if (    $node != $self->GetRootItem
		and $node_data->{type} ne 'upper' )
	{
		$self->{dragged_item} = $node;
		$event->Allow;
	}
}

# If dragged to a different folder, tries to move (renaming) it to the new
# folder.
# Called just after the item is dragged.
sub _on_tree_end_drag {
	my ( $self, $event ) = @_;
	my $node      = $event->GetItem;
	my $node_data = $self->GetPlData($node);

	# If drops to a file, the new destination will be it's folder
	if ( $node->IsOk and ( !$self->ItemHasChildren($node) and $node_data->{type} ne 'upper' ) ) {
		$node = $self->GetItemParent($node);
	}

	# Returns if the target node doesn't exists
	return unless $node->IsOk;

	# Gets dragged and target nodes data
	my $new_data = $self->GetPlData($node);
	my $old_data = $self->GetPlData( $self->{dragged_item} );

	# Returns if the target is the file parent
	my $from = $old_data->{dir};
	my $to = File::Spec->catfile( $new_data->{dir}, $new_data->{name} );
	return if $from eq $to;

	# The file complete name (path and its name) before and after the move
	my $old_file = File::Spec->catfile( $old_data->{dir}, $old_data->{name} );
	my $new_file = File::Spec->catfile( $to, $old_data->{name} );

	# Alerts if there is a file with the same name in the target
	if ( -e $new_file ) {
		Wx::MessageBox(
			Wx::gettext('A file with the same name already exists in this directory'),
			Wx::gettext('Error'),
			Wx::wxOK | Wx::wxCENTRE | Wx::wxICON_ERROR
		);
		return;
	}

	# Pops up a menu to confirm the
	# action do be done
	my $menu = Wx::Menu->new;

	# Move file or directory
	my $menu_mv = $menu->Append(
		-1,
		Wx::gettext('Move here')
	);
	Wx::Event::EVT_MENU(
		$self, $menu_mv,
		sub { $self->_rename_or_move( $old_file, $new_file ) }
	);

	# Copy file
	unless ( -d $old_file ) {
		my $menu_cp = $menu->Append(
			-1,
			Wx::gettext('Copy here')
		);
		Wx::Event::EVT_MENU(
			$self, $menu_cp,
			sub { $self->_copy( $old_file, $new_file ) }
		);
	}

	# Cancel action
	$menu->AppendSeparator();
	my $menu_cl = $menu->Append(
		-1,
		Wx::gettext('Cancel')
	);

	# Pops up the context menu
	my $x = $event->GetPoint->x;
	my $y = $event->GetPoint->y;
	$self->PopupMenu( $menu, $x, $y );
}

# Shows up a context menu above an item with its controls
# the file if don't.
# Called when a item context menu is requested.
sub _on_tree_item_menu {
	my ( $self, $event ) = @_;
	my $node      = $event->GetItem;
	my $node_data = $self->GetPlData($node);

	# Do not show if it is the upper item
	return if defined( $node_data->{type} ) and ( $node_data->{type} eq 'upper' );

	$node_data->{type} ||= ''; # Defined but empty

	my $menu          = Wx::Menu->new;
	my $selected_dir  = $node_data->{dir};
	my $selected_path = File::Spec->catfile( $node_data->{dir}, $node_data->{name} );

	# Default action - same when the item is activated
	my $default = $menu->Append(
		-1,
		Wx::gettext( $node_data->{type} eq 'folder' ? 'Open Folder' : 'Open File' )
	);
	Wx::Event::EVT_MENU(
		$self, $default,
		sub { $self->_on_tree_item_activated($event) }
	);


	Wx::Event::EVT_MENU(
		$self,
		$menu->Append( -1, Wx::gettext('Open In File Browser') ),
		sub {

			#Open the current node in file browser
			require Padre::Wx::Directory::OpenInFileBrowserAction;
			Padre::Wx::Directory::OpenInFileBrowserAction->new->open_in_file_browser($selected_path);
		}
	);

	$menu->AppendSeparator();

	# Rename and/or move the item
	my $rename = $menu->Append( -1, Wx::gettext('Rename / Move') );
	Wx::Event::EVT_MENU(
		$self, $rename,
		sub {
			$self->EditLabel($node);
		},
	);

	# Move item to trash
	# Note: File::Remove->trash() only works on Mac
	# Please see ticket:553 (http://padre.perlide.org/trac/ticket/553)
	if ( Padre::Constant::MAC or Padre::Constant::WIN32 ) {
		my $trash = $menu->Append( -1, Wx::gettext('Move to trash') );
		Wx::Event::EVT_MENU(
			$self, $trash,
			sub {
				eval {
					if (Padre::Constant::WIN32)
					{

						# WIN32
						require Padre::Util::Win32;
						Padre::Util::Win32::Recycle($selected_path);
					} else {

						# MAC
						require File::Remove;
						File::Remove->trash($selected_path);
					}
				};
				if ($@) {
					my $error_msg = $@;
					Wx::MessageBox(
						$error_msg, Wx::gettext('Error'),
						Wx::wxOK | Wx::wxCENTRE | Wx::wxICON_ERROR
					);
				}
				return;
			},
		);
	}

	# Delete item
	my $delete = $menu->Append( -1, Wx::gettext('Delete') );
	Wx::Event::EVT_MENU(
		$self, $delete,
		sub {

			my $dialog = Wx::MessageDialog->new(
				$self,
				Wx::gettext('Are you sure you want to delete this item?') . $/ . $selected_path,
				Wx::gettext('Delete'),
				Wx::wxYES_NO | Wx::wxICON_QUESTION | Wx::wxCENTRE
			);
			return if $dialog->ShowModal == Wx::wxID_NO;

			eval {
				require File::Remove;
				File::Remove->remove($selected_path);
			};
			if ($@) {
				my $error_msg = $@;
				Wx::MessageBox(
					$error_msg, Wx::gettext('Error'),
					Wx::wxOK | Wx::wxCENTRE | Wx::wxICON_ERROR
				);
			}
			return;
		},
	);

	# ?????
	if ( defined $node_data->{type} and ( $node_data->{type} eq 'modules' or $node_data->{type} eq 'pragmata' ) ) {
		my $pod = $menu->Append( -1, Wx::gettext("Open &Documentation") );
		Wx::Event::EVT_MENU(
			$self, $pod,
			sub {

				# TO DO Fix this wasting of objects (cf. Padre::Wx::Menu::Help)
				require Padre::Wx::DocBrowser;
				my $help = Padre::Wx::DocBrowser->new;
				$help->help( $node_data->{name} );
				$help->SetFocus;
				$help->Show(1);
				return;
			},
		);
	}
	$menu->AppendSeparator();

	# Shows / Hides hidden files - applied to each directory
	my $hiddenFiles     = $menu->AppendCheckItem( -1, Wx::gettext('Show hidden files') );
	my $applies_to_node = $node;
	my $applies_to_path = $selected_path;
	if ( $node_data->{type} ne 'folder' ) {
		$applies_to_path = $selected_dir;
		$applies_to_node = $self->GetParent($node);
	}

	my $cached = defined($applies_to_path) ? \%{ $self->{CACHED}->{$applies_to_path} } : undef;
	my $show = $cached->{ShowHidden};
	$hiddenFiles->Check($show);
	Wx::Event::EVT_MENU(
		$self,
		$hiddenFiles,
		sub {
			$cached->{ShowHidden} = !$show;
			$self->_list_dir($applies_to_node);
		},
	);

	# Updates the directory listing
	my $reload = $menu->Append( -1, Wx::gettext('Reload') );
	Wx::Event::EVT_MENU(
		$self, $reload,
		sub {
			delete $self->{CACHED}->{ $self->GetPlData($node)->{dir} }->{Change};
		}
	);

	# Pops up the context menu
	my $x = $event->GetPoint->x;
	my $y = $event->GetPoint->y;
	$self->PopupMenu( $menu, $x, $y );

	return;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
