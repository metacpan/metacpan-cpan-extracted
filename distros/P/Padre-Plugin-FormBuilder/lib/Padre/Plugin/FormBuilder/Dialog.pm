package Padre::Plugin::FormBuilder::Dialog;

use 5.008;
use strict;
use warnings;
use Class::Inspector                    ();
use Padre::Unload                       ();
use Padre::Plugin::FormBuilder::FBP     ();
use Padre::Plugin::FormBuilder::Preview ();

our $VERSION = '0.04';
our @ISA     = 'Padre::Plugin::FormBuilder::FBP';

# Temporary namespace counter
my $COUNT = 0;

use constant OPTIONS => qw{
	translate
	encapsulation
	version
	padre
};

use constant SINGLE => qw{
	select
	preview
	translate
	encapsulation
	version
	associate
	generate
};

use constant COMPLETE => qw{
	complete_fbp
	complete_shim
};

use constant FRAME => qw{
	complete_app
	complete_script
};





######################################################################
# Customisation

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);
	$self->disable( OPTIONS, SINGLE, COMPLETE, FRAME );
	$self->CenterOnParent;

	# If we don't have a current project, disable the checkbox
	my $project = $main->current->project;
	unless ( $project and $project->isa('Padre::Project::Perl') ) {
		$self->associate->Disable;
	}

	return $self;
}

sub path {
	$_[0]->browse->GetPath;
}

sub selected {
	$_[0]->select->GetStringSelection;
}

sub padre_code {
	!! $_[0]->padre->IsChecked;
}

sub i18n {
	$_[0]->translate->GetSelection > 0;
}

sub i18n_trim {
	$_[0]->translate->GetSelection > 1;
}

sub encapsulate {
	$_[0]->encapsulation->GetSelection == 1;
}

sub project {
	my $self = shift;
	my $path = $self->path or return;
	$self->ide->project_manager->from_file($path);
}





######################################################################
# Event Handlers

sub browse_changed {
	my $self = shift;
	my $path = $self->path;

	# Flush any existing state
	$self->{xml} = undef;
	SCOPE: {
		my $lock = $self->lock_update;
		$self->select->Clear;
		$self->disable( OPTIONS, SINGLE, COMPLETE, FRAME );
	}

	# Attempt to load the file and parse out the dialog list
	local $@;
	eval {
		# Load the file
		require FBP;
		$self->{xml} = FBP->new;
		my $ok = $self->{xml}->parse_file($path);
		die "Failed to load the file" unless $ok;

		# Extract the dialog list
		my $list = [
			sort
			grep { defined $_ and length $_ }
			map  { $_->name }
			$self->{xml}->project->forms
		];
		die "No dialogs found" unless @$list;

		# Find the project for the fbp file
		my $project = $self->project;
		if ( $project->isa('Padre::Project::Perl') ) {
			my $version = $project->version;
			$self->version->SetValue($version) if $version;
		}

		# Populate the dialog list
		my $lock = $self->lock_update;
		$self->select->Append($list);
		$self->select->SetSelection(0);

		# If any of the dialogs are under Padre:: default the
		# Padre-compatible code generation to true.
		if ( grep { /^Padre::/ } @$list ) {
			$self->padre->SetValue(1);
			$self->encapsulation->SetSelection(0);
			$self->translate->SetSelection(1);
		} else {
			$self->padre->SetValue(0);
			$self->encapsulation->SetSelection(0);
			$self->translate->SetSelection(0);
		}

		# Enable the dialog list and buttons
		$self->enable( OPTIONS, SINGLE, COMPLETE );

		# We need at least one frame to build a complete application
		if ( $self->{xml}->project->find_first( isa => 'FBP::Frame' ) ) {
			$self->enable( FRAME );
		} else {
			$self->disable( FRAME );
		}

		# Indicate the FBP file is ok
		if ( $self->browse->HasTextCtrl ) {
			my $ctrl = $self->browse->GetTextCtrl;
			$ctrl->SetBackgroundColour(
				Wx::Colour->new('#CCFFCC')
			);
		}
	};
	if ( $@ ) {
		# Indicate the FBP file is not ok
		if ( $self->browse->HasTextCtrl ) {
			$self->browse->GetTextCtrl->SetBackgroundColour(
				Wx::Colour->new('#FFCCCC')
			);
		}

		# Inform the user directly
		$self->error("Missing, invalid or empty file '$path': $@");
	}

	return;
}

sub generate_clicked {
	my $self   = shift;
	my $dialog = $self->selected or return;
	my $fbp    = $self->{xml}    or return;
	my $form   = $fbp->form($dialog);
	unless ( $form ) {
		$self->error("Failed to find form $dialog");
		return;
	}

	# Generate the dialog code
	my $code = $self->generate_form(
		fbp       => $fbp,
		form      => $form,
		package   => $dialog,
		padre     => $self->padre_code,
		version   => $self->version->GetValue || '0.01',
		i18n      => $self->i18n,
		i18n_trim => $self->i18n_trim,
	) or return;

	# Open the generated code as a new file
	$self->show($code);

	return;
}

sub preview_clicked {
	my $self   = shift;
	my $dialog = $self->selected or return;
	my $fbp    = $self->{xml}    or return;
	my $form   = $fbp->form($dialog);
	unless ( $form ) {
		$self->error("Failed to find form $dialog");
		return;
	}

	# Close any previous frame
	$self->clear_preview;

	# Generate the dialog code
	my $name = "Padre::Plugin::FormBuilder::Temp::Dialog" . ++$COUNT;
	SCOPE: {
		local $@ = '';
		my $code = eval {
			$self->generate_form(
				fbp       => $fbp,
				form      => $form,
				package   => $name,
				padre     => $self->padre_code,
				version   => $self->version->GetValue || '0.01',
				i18n      => 0,
				i18n_trim => 0,
			)
		};
		if ( $@ or not $code ) {
			$self->error("Error generating dialog: $@");
			$self->unload($name);
			return;
		}

		# Load the dialog
		eval "$code";
		if ( $@ ) {
			$self->error("Error loading dialog: $@");
			$self->unload($name);
			return;
		}
	}

	# Create the form
	local $@;
	my $preview = eval {
		$form->isa('FBP::FormPanel')
			? Padre::Plugin::FormBuilder::Preview->new( $self->main, $name )
			: $name->new( $self->main )
	};
	if ( $@ ) {
		$self->error("Error constructing dialog: $@");
		$self->unload($name);
		return;
	}

	# Handle the ones we can show modally
	if ( $preview->can('ShowModal') ) {
		# Show the dialog
		my $rv = eval {
			$preview->ShowModal;
		};
		$preview->Destroy;
		if ( $@ ) {
			$self->error("Dialog crashed while in use: $@");
		}
		$self->unload($name);
		return;
	}

	# Show the long way
	$preview->Show;
	$self->{frame} = $preview->GetId;

	return 1;
}

sub clear_preview {
	my $self = shift;
	if ( $self->{frame} ) {
		my $old = Wx::Window::FindWindowById( delete $self->{frame} );
		$old->Destroy if $old;
	}
	return 1;
}

sub complete_refresh {
	my $self = shift;

	# Show the complete button if any box is ticked
	foreach my $name ( COMPLETE ) {
		my $checkbox = $self->$name();
		next unless $checkbox->IsEnabled;
		next unless $checkbox->IsChecked;
		return $self->enable('complete');
	}

	# None of the tick boxes are enabled
	return $self->disable('complete');
}

sub complete_clicked {
	my $self = shift;
	my $fbp  = $self->{xml} or return;

	# This could change lots of files, so lets wrap some
	# relatively course locking to prevent background task
	# storms and unneeded database operations.
	# Also ensure all notebook titles are updated when we are done.
	my $lock = $self->main->lock('DB', 'REFRESH', 'refresh_notebook');

	# Prepare the common generation options
	my @files  = ();
	my %common = (
		fbp       => $fbp,
		padre     => $self->padre_code,
		version   => $self->version->GetValue || '0.01',
		i18n      => $self->i18n,
		i18n_trim => $self->i18n_trim,
		shim      => $self->complete_shim->IsChecked ? 1 : 0,
	);

	# Generate the launch script for the app
	if ( $self->complete_script->IsChecked ) {
		my $code = $self->generate_script(%common) or return;

		# Make a guess at a sensible default name for the script
		my $file = lc $self->generator(%common)->app_package;
		$file =~ s/:://g;

		push @files, $self->show(
			code => $code,
			file => File::Spec->catfile( 'script', $file ),
		);
	}

	# Generate the Wx::App root class
	if ( $self->complete_app->IsChecked ) {
		my $code = $self->generate_app(%common) or return;
		push @files, $self->show($code);
	}

	# Generate all of the shim dialogs
	if ( $self->complete_shim->IsChecked ) {
		foreach my $form ( $fbp->project->forms ) {
			my $name = $form->name or next;

			# Generate the class
			my $code = $self->generate_shim(
				form => $form,
				name => $name,
				%common,
			) or next;

			# Open the generated code as a new file
			push @files, $self->show($code);
		}
	}

	# Generate all of the FBP dialogs
	if ( $self->complete_fbp->IsChecked ) {
		foreach my $form ( $fbp->project->forms ) {
			my $name = $form->name or next;

			# Generate the class
			my $code = $self->generate_form(
				form => $form,
				name => $name,
				%common,
			) or next;

			# Open the generated code as a new file
			push @files, $self->show($code);
		}
	}

	# Focus on the first document we touched
	@files = grep { !! $_ } @files;
	if ( @files ) {
		my $editor   = $files[0]->editor or return;
		my $notebook = $editor->notebook or return;
		my $id       = $notebook->GetPageIndex($editor);
		$notebook->SetSelection($id);
	}	

	return;
}





######################################################################
# Code Generation Methods

# Generate a launch script
sub generate_script {
	my $self = shift;
	my $perl = $self->generator(@_);

	# Generate the script code
	local $@;
	my $string = eval {
		$perl->flatten(
			$perl->script_app
		);
	};
	if ( $@ ) {
		$self->error("Code Generator Error: $@");
		return;
	}

	return $string;
}

# Generate the root Wx app class
sub generate_app {
	my $self = shift;
	my $perl = $self->generator(@_);

	# Generate the app code
	local $@;
	my $string = eval {
		$perl->flatten(
			$perl->app_class
		);
	};
	if ( $@ ) {
		$self->error("Code Generator Error: $@");
		return;
	}

	return $string;
}

# Generate the class code
sub generate_form {
	my $self  = shift;
	my $perl  = $self->generator(@_);
	my %param = @_;

	# Generate the class code
	local $@;
	my $string = eval {
		$perl->flatten(
			$perl->form_class( $param{form} )
		);
	};
	if ( $@ ) {
		$self->error("Code Generator Error: $@");
		return;
	}

	# Customise the package name if requested
	if ( $param{package} ) {
		$string =~ s/^package [\w:]+/package $param{package}/;
	}

	return $string;
}

# Generate the shim code
sub generate_shim {
	my $self  = shift;
	my $perl  = $self->generator(@_);
	my %param = @_;

	# Generate the class code
	local $@;
	my $string = eval {
		$perl->flatten(
			$perl->shim_class($param{form})
		);
	};
	if ( $@ ) {
		$self->error("Code Generator Error: $@");
		return;
	}

	return $string;
}

# NOTE: Not in use yet, intended for arbitrary class entry later
sub dialog_class {
	my $self = shift;
	my $name = shift || '';
	my $main = $self->main;

	# What class name?
	my $dialog = Wx::TextEntryDialog->new(
		$main,
		Wx::gettext("Enter Class Name"),
		$self->plugin_name,
		$name,
	);
	while ( $dialog->ShowModal != Wx::wxID_CANCEL ) {
		my $package = $dialog->GetValue;
		unless ( defined $package and length $package ) {
			$self->error("Did not provide a class name");
			next;
		}
		unless ( Params::Util::_CLASS($package) ) {
			$self->error("Not a valid class name");
			next;
		}

		return $package;
	}

	return;
}





######################################################################
# Support Methods

# Display a generated document
sub show {
	my $self    = shift;
	my %param   = (@_ == 1) ? ( code => shift ) : @_;
	my $code    = $param{code};
	my $file    = $param{file};
	my $main    = $self->main;
	my $project = $self->project;

	# Auto-detect the file name if we can
	unless ( defined Params::Util::_STRING($file) ) {
		# Is this a module?
		if ( $code =~ /^package\s+([\w:]+)/ ) {
			# Where should the module be on the filesystem
			my $module = $1;
			$file = File::Spec->catfile(
				'lib',
				split( /::/, $1 )
			) . '.pm';
		}
	}

	# If we have a file name and it exists, overwrite the
	# content in an existing editor rather than making a new
	# document.
	if ( defined Params::Util::_STRING($file) ) {
		my $path = File::Spec->catfile( $project->root, $file );

		# Do we have the module open
		my $id = $main->editor_of_file($path);
		unless ( defined $id ) {
			# Open the file if it exists on disk
			if ( -f $path and -r $path ) {
				# Always use the plural "setup_editors" as
				# it clears the unused current document and
				# does update and refresh locking.
				$main->setup_editors($path);
				$id = $main->editor_of_file($path);
				unless ( defined $id ) {
					warn "Failed to open '$path'";
					return;
				}
			}
		}
		if ( defined $id ) {
			# Apply to the existing file by delta
			my $editor   = $main->notebook->GetPage($id);
			my $document = $editor->{Document} or return;
			$document->text_replace($code);
			return $document;
		}
	}

	# Not open, does not exist, or no special handling
	my $lock     = $main->lock('REFRESH');
	my $document = $main->new_document_from_string(
		$code => 'application/x-perl',
	);

	# If we have a file name for the new file, set it early.
	if ( defined Params::Util::_STRING($file) ) {
		$document->set_filename(
			File::Spec->catfile( $project->root, $file )
		);
	}

	return $document;
}

sub generator {
	my $self  = shift;
	my %param = @_;

	# Use the version tweaked for Padre?
	if ( $param{padre} ) {
		require Padre::Plugin::FormBuilder::Perl;
		return Padre::Plugin::FormBuilder::Perl->new(
			project     => $param{fbp}->project,
			version     => $param{version},
			encapsulate => $self->encapsulate,
			prefix      => 2,
			nocritic    => 1,
			i18n        => $param{i18n},
			i18n_trim   => $param{i18n_trim},
			shim        => $param{shim},
			shim_deep   => $param{shim},
		);
	}

	# Just use the normal version
	require FBP::Perl;
	return FBP::Perl->new(
		project   => $param{fbp}->project,
		version   => $param{version},
		nocritic  => 1,
		i18n      => $param{i18n},
		i18n_trim => $param{i18n_trim},
		shim      => $param{shim},
		shim_deep => $param{shim},
	);
}

# Enable a set of controls
sub enable {
	my $self = shift;
	foreach my $name ( @_ ) {
		$self->$name()->Enable(1);
	}
	return;
}

# Disable a set of controls
sub disable {
	my $self = shift;
	foreach my $name ( @_ ) {
		$self->$name()->Disable;
	}
	return;
}

# Convenience integration with Class::Unload
sub unload {
	my $either = shift;
	foreach my $package (@_) {
		Padre::Unload::unload($package);
	}
	return 1;
}

# Convenience
sub error {
	shift->main->error(@_);
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
