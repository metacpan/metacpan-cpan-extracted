package Padre::Plugin::Swarm::Wx::Resources;

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Current ();
use Padre::Plugin::Swarm::Wx::Resources::TreeCtrl ();
use Padre::Logger;
use Params::Util qw( _INSTANCE ) ;

our $VERSION = '0.2';
our @ISA     = 'Wx::Panel';

use Class::XSAccessor {
	getters => {
		tree   => 'tree',
		search => 'search',
	},
	accessors => {
		mode                  => 'mode',
		project_dir           => 'project_dir',
		previous_dir          => 'previous_dir',
		project_dir_original  => 'project_dir_original',
		previous_dir_original => 'previous_dir_original',
		label => 'label',
		universe => 'universe',
	},
};

=pod

=head1 NAME

Padre::Plugin::Swarm::Wx::Resources - Tree view panel of swarm resources

=head1 DESCRIPTION

As swarmers open and close documents in their editor this control updates
a tree view of each swarmers open documents.

=cut


sub plugin { Padre::Plugin::Swarm->instance }

# Creates the Directory Left Panel with a Search field
# and the Directory Browser
sub new {
	my $class = shift;
	my $main  = Padre::Current->main;
	my %args = @_;
	my $self = $class->SUPER::new(
		$main->directory_panel,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);
	$self->label($args{label});
	
	$self->universe($args{universe});
	
	
	$self->{tree}   = 
		Padre::Plugin::Swarm::Wx::Resources::TreeCtrl->new( $self,
				universe => $args{universe} # ERK
		
		);

	# Fill the panel
	my $sizerv = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $sizerh = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizerv->Add( $self->tree,   1, Wx::wxALL | Wx::wxEXPAND, 0 );
	$sizerh->Add( $sizerv,   1, Wx::wxALL | Wx::wxEXPAND, 0 );
	
	# Fits panel layout
	$self->SetSizerAndFit($sizerh);
	$sizerh->SetSizeHints($self);
	$self->Hide;
	TRACE( "Resource tree Ready - ", $self->tree ) if DEBUG;
	$self->universe->reg_cb( 'enable' , sub {  $self->enable(@_) } );
	$self->universe->reg_cb( 'disable' , sub {$self->disable(@_) } );
	$self->universe->reg_cb( 'recv' , sub { shift; $self->on_recv(@_) } );
	
	return $self;
	
}


sub enable {
	my $self = shift;
	TRACE( "Enable" ) if DEBUG;
	my $left = $self->main->directory_panel;
	
	$left->show($self);
	
	
	# TODO - use wx event to catch messages. 
	$self->refresh;

	return $self;
}

sub disable {
	my $self = shift;
	TRACE( "Disabled" ) if DEBUG;
	my $left = $self->main->directory_panel;
	my $pos = $left->GetPageIndex($self);
	$self->Hide;
	$left->RemovePage($pos);
	# Bad idea ?
	#$self->Destroy;
	
}

# The parent panel
sub panel {
	$_[0]->GetParent;
}

# Returns the main object reference
sub main {
	$_[0]->GetGrandParent;
}

sub current {
	Padre::Current->new( main => $_[0]->main );
}

# Returns the window label
sub view_label {
	my $self = shift;
	return $self->label;
}

*gettext_label = \&view_label;

sub view_icon {
	my $icon = Padre::Plugin::Swarm->plugin_icon;
}

sub view_panel  { 'left' }

# Updates the gui, so each compoment can update itself
# according to the new state
sub clear {
	$_[0]->refresh;
	return;
}


use Carp 'croak';
sub on_recv {
	my $self = shift;
	#my $universe = shift;
	my $message = shift;
	
	
	my $handler = 'accept_' . $message->type;
	if ( $self->can( $handler ) ) {
            eval {
                $self->$handler($message);
            };
            TRACE( $handler . ' failed with ' . $@ ) if $@; #DEBUG && $@;
            
        }
	
}


## TODO Perform less revolting redraw when things change
sub accept_promote {
	my ($self,$message) = @_;
	if ( $message->{resource} ) {
		$self->refresh;
	}
}

sub accept_destroy {
	my ($self,$message) = @_;
	if ( $message->{resource} ) {
		$self->refresh;
	}
}

sub accept_disco {
	my ($self,$message) = @_;
	
}

sub accept_leave {
	my ($self,$message) = @_;
	$self->refresh;
	
}


# Perform a full redraw :(

sub refresh {
	my $self     = shift;
	TRACE( "Refresh" ) if DEBUG;
	my $current  = $self->current;
	my $document = $current->document;



	$self->tree->refresh;
	# Update the panel label
	$self->panel->refresh;

	return 1;
}

# When a project folder is changed
sub _change_project_dir {
	my $self   = shift;
	my $dialog = Wx::DirDialog->new(
		undef,
		Wx::gettext('Choose a directory'),
		$self->project_dir,
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	$self->{projects_dirs}->{ $self->project_dir_original } = $dialog->GetPath;
	$self->refresh;
}

# What side of the application are we on
sub side {
	my $self  = shift;
	my $panel = $self->GetParent;
	if ( $panel->isa('Padre::Wx::Left') ) {
		return 'left';
	}
	if ( $panel->isa('Padre::Wx::Right') ) {
		return 'right';
	}
	die "Bad parent panel";
}

# Moves the panel to the other side
sub move {
	my $self   = shift;
	my $config = $self->main->config;
	my $side   = $config->main_directory_panel;
	if ( $side eq 'left' ) {
		$config->apply( main_directory_panel => 'right' );
	} elsif ( $side eq 'right' ) {
		$config->apply( main_directory_panel => 'left' );
	} else {
		die "Bad main_directory_panel setting '$side'";
	}
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
