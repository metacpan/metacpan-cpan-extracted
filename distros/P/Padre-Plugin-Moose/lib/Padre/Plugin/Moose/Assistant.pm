package Padre::Plugin::Moose::Assistant;

use 5.008;
use Moose;
use Padre::Wx::Role::Dialog              ();
use Padre::Plugin::Moose::FBP::Assistant ();

our $VERSION = '0.21';
our @ISA     = qw{
	Padre::Wx::Role::Dialog
	Padre::Plugin::Moose::FBP::Assistant
};

sub new {
	my $class  = shift;
	my $plugin = shift;


	my $self = $class->SUPER::new( $plugin->main );

	# Store the plugin object for future usage
	$self->{plugin} = $plugin;

	# Center & title
	$self->CenterOnParent;
	$self->SetTitle(
		sprintf( Wx::gettext('Moose Assistant %s - Written for fun by Ahmad M. Zawawi (azawawi)'), $VERSION ) );

	# Restore defaults
	$self->restore_defaults;

	# TODO Bug Alias to fix the wxFormBuilder bug regarding this one
	$self->{inspector}->SetRowLabelSize(0);

	# Hide the inspector as needed
	$self->show_inspector(undef);

	# Setup preview editor
	my $preview = $self->{preview};
	require Padre::Document;
	$preview->{Document} = Padre::Document->new( mimetype => 'application/x-perl', );
	$preview->{Document}->set_editor($preview);
	$preview->SetLexer('application/x-perl');

	# Syntax highlight Moose keywords
	require Padre::Plugin::Moose::Util;
	Padre::Plugin::Moose::Util::add_moose_keywords_highlighting(
		$plugin->{config}->{type}, $preview->{Document},
		$preview
	);

	$preview->Show(1);

	$self->show_code_in_preview(1);

	return $self;
}

# This is called to start and show the dialog
sub run {
	my $self = shift;

	# Apply the current theme to the preview editor
	my $style = $self->main->config->editor_style;
	my $theme = Padre::Wx::Theme->find($style)->clone;
	$theme->apply( $self->{preview} );

	$self->ShowModal;
}

# Set up the events
sub on_grid_cell_change {
	my $self = shift;

	my $element = $self->{current_element} or return;

	if ( $element->does('Padre::Plugin::Moose::Role::CanHandleInspector') ) {
		$element->read_from_inspector( $self->{inspector} );
	}

	$self->show_code_in_preview(0);

	return;
}

sub on_tree_selection_change {
	my $self    = shift;
	my $event   = shift;
	my $tree    = $self->{tree};
	my $item    = $event->GetItem or return;
	my $element = $tree->GetPlData($item) or return;

	my $is_parent  = $element->does('Padre::Plugin::Moose::Role::HasClassMembers');
	my $is_program = $element->isa('Padre::Plugin::Moose::Program');

	# Show/Hide the inspector as needed
	$self->show_inspector( $is_program ? undef : $element );

	# Display help about the current element
	$self->{help}->SetValue( $element->provide_help );

	$self->{current_element} = $element;

	# Find parent element
	if ( $element->does('Padre::Plugin::Moose::Role::ClassMember') ) {
		$self->{current_parent} = $tree->GetPlData( $tree->GetItemParent($item) );
	} else {
		$self->{current_parent} = $element if $is_parent;
	}

	$self->Layout;

	# TODO improve the crude workaround to positioning
	unless ($is_program) {
		my $preview  = $self->{preview};
		my $line_num = 0;
		for my $line ( split /\n/, $preview->GetText ) {
			my $name = quotemeta $element->name;
			if ( $line =~ /$name/ ) {
				my $position = $preview->PositionFromLine($line_num);
				$preview->SetCurrentPos($position);
				$preview->SetAnchor($position);
				$preview->ScrollToLine($line_num);
				last;
			}
			$line_num++;
		}
	}

	return;
}

sub show_code_in_preview {
	my $self               = shift;
	my $should_select_item = shift;

	eval {

		# Generate code
		my $config = $self->{plugin}->{config};
		my $code   = $self->{program}->generate_code(
			{   type                => $config->{type},
				comments            => $config->{comments},
				sample_code         => $config->{sample_code},
				namespace_autoclean => $config->{namespace_autoclean},
			}
		);

		# And show it in preview editor
		my $preview = $self->{preview};
		$preview->SetReadOnly(0);
		$preview->SetText($code);
		$preview->SetReadOnly(1);

		# Update tree
		$self->update_tree($should_select_item);
	};
	if ($@) {
		$self->error( sprintf( Wx::gettext('Error:%s'), $@ ) );
	}

	return;
}

sub update_tree {
	my $self               = shift;
	my $should_select_item = shift;
	my $tree               = $self->{tree};
	my $lock               = $self->lock_update($tree);

	$tree->DeleteAllItems;

	my $selected_item;

	my $program      = $self->{program};
	my $program_node = $tree->AddRoot(
		Wx::gettext('Program'),
		-1,
		-1,
		Wx::TreeItemData->new($program)
	);

	if ( $program eq $self->{current_element} ) {
		$selected_item = $program_node;
	}

	for my $class ( @{ $program->roles }, @{ $program->classes } ) {
		my $class_node = $tree->AppendItem(
			$program_node,
			$class->name,
			-1, -1,
			Wx::TreeItemData->new($class)
		);
		for my $class_item ( @{ $class->attributes }, @{ $class->subtypes }, @{ $class->methods } ) {
			my $class_item_node = $tree->AppendItem(
				$class_node,
				$class_item->name,
				-1, -1,
				Wx::TreeItemData->new($class_item)
			);
			if ( $class_item == $self->{current_element} ) {
				$selected_item = $class_item_node;
			}
		}

		if ( $class == $self->{current_element} ) {
			$selected_item = $class_node;
		}

		$tree->Expand($class_node);
	}

	$tree->ExpandAll;

	# Select the tree node outside this event to
	# prevent deep recurision
	if ( $should_select_item and defined $selected_item ) {
		Wx::Event::EVT_IDLE(
			$self,
			sub {
				$tree->SelectItem($selected_item);
				Wx::Event::EVT_IDLE( $self, undef );
			}
		);
	}

	return;
}

sub show_inspector {
	my $self      = shift;
	my $element   = shift;
	my $inspector = $self->{inspector};
	my $lock      = $self->lock_update($inspector);

	$inspector->DeleteRows( 0, $inspector->GetNumberRows );
	unless ( defined $element ) {
		return;
	}

	my $type = blessed($element);
	unless ( defined $type and $type =~ /(Class|Role|Attribute|Subtype|Method|Constructor|Destructor)$/ ) {
		$self->error("type: $element is not Class, Role, Attribute, Subtype or Method\n");
		return;
	}

	my $data = $element->get_grid_data;
	$inspector->InsertRows( 0, scalar @$data );
	$inspector->SetGridCursor( 0, 1 );
	foreach my $i ( 0 .. $#$data ) {
		my $row = $data->[$i];
		$inspector->SetCellValue( $i, 0, $row->{name} );
		$inspector->SetReadOnly( $i, 0 );
		if ( defined $row->{is_bool} ) {
			$inspector->SetCellEditor( $i, 1, Wx::GridCellBoolEditor->new );
			$inspector->SetCellValue( $i, 1, 1 );
		} elsif ( defined $row->{choices} ) {
			$inspector->SetCellEditor( $i, 1, Wx::GridCellChoiceEditor->new( $row->{choices}, 1 ) );
		}
	}

	if ( $element->does('Padre::Plugin::Moose::Role::CanHandleInspector') ) {
		$element->write_to_inspector($inspector);
	}

	return;
}

sub on_add_class_button {
	my $self = shift;

	# Add a new class object to program
	require Padre::Plugin::Moose::Class;
	my $class = Padre::Plugin::Moose::Class->new;
	$class->name( "Class" . $self->{class_count}++ );
	$class->immutable(1);
	push @{ $self->{program}->classes }, $class;

	$self->{current_element} = $class;
	$self->show_inspector($class);
	$self->show_code_in_preview(1);

	return;
}

sub on_add_role_button {
	my $self = shift;

	# Add a new role object to program
	require Padre::Plugin::Moose::Role;
	my $role = Padre::Plugin::Moose::Role->new;
	$role->name( "Role" . $self->{role_count}++ );
	push @{ $self->{program}->roles }, $role;

	$self->{current_element} = $role;
	$self->show_inspector($role);
	$self->show_code_in_preview(1);

	return;
}

sub on_add_attribute_button {
	my $self = shift;

	# Only allowed within a class/role element
	unless ( defined $self->{current_element}
		&& defined $self->{current_parent}
		&& $self->{current_parent}->does('Padre::Plugin::Moose::Role::HasClassMembers') )
	{
		$self->error( Wx::gettext('You can only add an attribute to a class or role') );
		$self->{palette}->SetSelection(0);
		return;
	}

	# Add a new attribute object to class
	require Padre::Plugin::Moose::Attribute;
	my $attribute = Padre::Plugin::Moose::Attribute->new;
	$attribute->name( 'attribute' . $self->{attribute_count}++ );
	push @{ $self->{current_parent}->attributes }, $attribute;

	$self->{current_element} = $attribute;
	$self->show_inspector($attribute);
	$self->show_code_in_preview(1);

	return;
}

sub on_add_subtype_button {
	my $self = shift;

	# Only allowed within a class/role element
	unless ( defined $self->{current_element}
		&& defined $self->{current_parent}
		&& $self->{current_parent}->does('Padre::Plugin::Moose::Role::HasClassMembers') )
	{
		$self->error( Wx::gettext('You can only add a subtype to a class or role') );
		$self->{palette}->SetSelection(0);
		return;
	}

	# Add a new subtype object to class
	require Padre::Plugin::Moose::Subtype;
	my $subtype = Padre::Plugin::Moose::Subtype->new;
	$subtype->name( 'Subtype' . $self->{subtype_count}++ );
	push @{ $self->{current_parent}->subtypes }, $subtype;

	$self->{current_element} = $subtype;
	$self->show_inspector($subtype);
	$self->show_code_in_preview(1);

	return;
}

sub on_add_method_button {
	my $self = shift;

	# Only allowed within a class/role element
	unless ( defined $self->{current_element}
		&& defined $self->{current_parent}
		&& $self->{current_parent}->does('Padre::Plugin::Moose::Role::HasClassMembers') )
	{
		$self->error( Wx::gettext('You can only add a method to a class or role') );
		$self->{palette}->SetSelection(0);
		return;
	}

	# Add a new method object to class
	require Padre::Plugin::Moose::Method;
	my $method = Padre::Plugin::Moose::Method->new;
	$method->name( 'method_' . $self->{method_count}++ );
	push @{ $self->{current_parent}->methods }, $method;

	$self->{current_element} = $method;
	$self->show_inspector($method);
	$self->show_code_in_preview(1);

	return;
}

sub on_add_constructor_button {
	my $self = shift;

	# Only allowed within a class/role element
	unless ( defined $self->{current_element}
		&& defined $self->{current_parent}
		&& $self->{current_parent}->does('Padre::Plugin::Moose::Role::HasClassMembers') )
	{
		$self->error( Wx::gettext('You can only add a constructor to a class or role') );
		$self->{palette}->SetSelection(0);
		return;
	}

	# Add a new constructor object to class/role
	require Padre::Plugin::Moose::Constructor;
	my $constructor = Padre::Plugin::Moose::Constructor->new;
	$constructor->name('BUILD');
	push @{ $self->{current_parent}->methods }, $constructor;

	$self->{current_element} = $constructor;
	$self->show_inspector($constructor);
	$self->show_code_in_preview(1);

	return;
}

sub on_add_destructor_button {
	my $self = shift;

	# Only allowed within a class/role element
	unless ( defined $self->{current_element}
		&& defined $self->{current_parent}
		&& $self->{current_parent}->does('Padre::Plugin::Moose::Role::HasClassMembers') )
	{
		$self->error( Wx::gettext('You can only add a destructor to a class or role') );
		$self->{palette}->SetSelection(0);
		return;
	}

	# Add a new destructor object to class/role
	require Padre::Plugin::Moose::Destructor;
	my $destructor = Padre::Plugin::Moose::Destructor->new;
	$destructor->name('DEMOLISH');
	push @{ $self->{current_parent}->methods }, $destructor;

	$self->{current_element} = $destructor;
	$self->show_inspector($destructor);
	$self->show_code_in_preview(1);

	return;
}

sub on_reset_button_clicked {
	my $self = shift;

	if ( $self->yes_no( Wx::gettext('Do you really want to reset?') ) ) {
		$self->restore_defaults;
		$self->show_code_in_preview(1);
	}

	return;
}

sub on_generate_code_button_clicked {
	my $self = shift;

	Wx::Event::EVT_IDLE(
		$self,
		sub {
			$self->main->new_document_from_string(
				$self->{preview}->GetText => 'application/x-perl',
			);
			Wx::Event::EVT_IDLE( $self, undef );
		}
	);

	$self->EndModal(Wx::ID_OK);

	return;
}

sub restore_defaults {
	my $self = shift;

	$self->{class_count}     = 1;
	$self->{role_count}      = 1;
	$self->{attribute_count} = 1;
	$self->{subtype_count}   = 1;
	$self->{method_count}    = 1;

	require Padre::Plugin::Moose::Program;
	$self->{program}         = Padre::Plugin::Moose::Program->new;
	$self->{current_element} = $self->{program};
	$self->{current_parent}  = $self->{program};

	return;
}

# Called when a item context menu is requested.
sub on_tree_item_menu {
	my $self    = shift;
	my $event   = shift;
	my $item    = $event->GetItem;
	my $tree    = $self->{tree};
	my $element = $tree->GetPlData($item) or return;
	return if $element->isa('Padre::Plugin::Moose::Program');

	# Generate the context menu for this element
	my $menu = Wx::Menu->new;

	Wx::Event::EVT_MENU(
		$self,
		$menu->Append( -1, Wx::gettext('Delete') ),
		sub {
			$self->delete_element($element);
		}
	);

	# Pops up the context menu
	$tree->PopupMenu(
		$menu,
		$event->GetPoint->x,
		$event->GetPoint->y,
	);

	return;
}

sub on_tree_key_up {
	my $self  = shift;
	my $event = shift;
	my $mod   = $event->GetModifiers || 0;

	# see Padre::Wx::Main::key_up
	$mod = $mod & ( Wx::MOD_ALT + Wx::MOD_CMD + Wx::MOD_SHIFT );

	my $tree    = $self->{tree};
	my $item_id = $tree->GetSelection;
	my $element = $tree->GetPlData($item_id) or return;

	if ( $event->GetKeyCode == Wx::K_DELETE ) {
		$self->delete_element($element);
	}

	$event->Skip;

	return;
}

sub delete_element {
	my $self = shift;
	my $element = shift or return;

	if ( $self->yes_no( sprintf( Wx::gettext('Do you want to delete %s?'), $element->name ) ) ) {

		#TODO do the actual item deletion
	}

	return;
}

sub on_preferences_button_clicked {
	my $self = shift;

	# Create a new preferences dialog
	require Padre::Plugin::Moose::Preferences;
	my $prefs = Padre::Plugin::Moose::Preferences->new($self);

	# Update plugin variables from plugin's configuration hash
	my $plugin = $self->{plugin};
	my $config = $plugin->{config};
	$prefs->{generated_code_combo}->SetValue( $config->{type} );
	$prefs->{comments_checkbox}->SetValue( $config->{comments} );
	$prefs->{sample_code_checkbox}->SetValue( $config->{sample_code} );
	$prefs->{namespace_autoclean_checkbox}->SetValue( $config->{namespace_autoclean} );

	# Preferences: go modal!
	if ( $prefs->ShowModal == Wx::wxID_OK ) {

		# Update configuration when the user hits the OK button
		my $type = $prefs->{generated_code_combo}->GetValue;
		$config->{type}                = $type;
		$config->{comments}            = $prefs->{comments_checkbox}->IsChecked;
		$config->{sample_code}         = $prefs->{sample_code_checkbox}->IsChecked;
		$config->{namespace_autoclean} = $prefs->{namespace_autoclean_checkbox}->IsChecked;
		$plugin->config_write($config);

		# Update tree and preview editor
		$self->show_code_in_preview(1);

		# Add moose et all keywords highlight to preview editor
		require Padre::Plugin::Moose::Util;
		Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $self->{preview}->{Document}, $type );

		# Add moose et all keywords highlight to current editor
		my $doc = $self->current->document or return;
		if ( $doc->isa('Padre::Plugin::Moose::Document') ) {
			Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $doc, $type );
		}

	}

	return;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
