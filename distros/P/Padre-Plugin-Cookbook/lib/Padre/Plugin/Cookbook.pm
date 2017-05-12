package Padre::Plugin::Cookbook;

use 5.010001;
use strict;
use warnings;

use Padre::Plugin;
use Padre::Util;
use Padre::Wx;

our $VERSION = '0.24';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Cookbook::Recipe01::Main
	Padre::Plugin::Cookbook::Recipe01::FBP::MainFB
	Padre::Plugin::Cookbook::Recipe02::Main
	Padre::Plugin::Cookbook::Recipe02::FBP::MainFB
	Padre::Plugin::Cookbook::Recipe03::Main
	Padre::Plugin::Cookbook::Recipe03::FBP::MainFB
	Padre::Plugin::Cookbook::Recipe03::About
	Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB
	Padre::Plugin::Cookbook::Recipe04::Main
	Padre::Plugin::Cookbook::Recipe04::FBP::MainFB
	Padre::Plugin::Cookbook::Recipe04::About
	Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB
};

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (

		# Default, required
		'Padre::Plugin' => '0.96',

		# used by Main, About and by Padre::Plugin::FormBuilder
		'Padre::Wx'             => '0.96',
		'Padre::Wx::Main'       => '0.96',
		'Padre::Wx::Role::Main' => '0.96',
		'Padre::DB'             => '0.96',
		'Padre::Logger'         => '0.96',
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Plugin Cookbook');
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('01 - Hello World') => sub {
			$self->load_dialog_recipe01_main;
		},
		Wx::gettext('02 - Fun with widgets...') => sub {
			$self->load_dialog_recipe02_main;
		},
		Wx::gettext('03 - About dialogs...') => sub {
			$self->load_dialog_recipe03_main;
		},
		Wx::gettext('04 - ConfigDB...') => sub {
			$self->load_dialog_recipe04_main;
		},
	];
}


#######
# Add icon to Plugin
#######
sub plugin_icon {
	my $class = shift;
	my $share = $class->plugin_directory_share or return;
	my $file  = File::Spec->catfile( $share, 'icons', '16x16', 'cookbook.png' );
	return unless -f $file;
	return unless -r $file;
	return Wx::Bitmap->new( $file, Wx::wxBITMAP_TYPE_PNG );
}

#######
# Clean up dialog Main, Padre::Plugin,
# POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;

}

########
# Composed Method,
# Load Recipe-01 Main Dialog, only once
#######
sub load_dialog_recipe01_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe01::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe01::Main->new($main);
	$self->{dialog}->Show;

	return;
}

########
# Composed Method,
# Load Recipe-02 Main Dialog, only once
#######
sub load_dialog_recipe02_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe02::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe02::Main->new($main);
	$self->{dialog}->Show;

	return;
}

########
# Composed Method,
# Load Recipe-03 Main Dialog, only once
#######
sub load_dialog_recipe03_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe03::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe03::Main->new($main);
	$self->{dialog}->Show;

	return;
}

########
# Composed Method,
# Load Recipe-04 Main Dialog, only once
#######
sub load_dialog_recipe04_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe04::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe04::Main->new($main);
	$self->{dialog}->Show;
	$self->{dialog}->set_up;

	return;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Cookbook

Cookbook contains recipes to assist you in making your own Plug-ins for Padre, The Perl IDE.

=head1 VERSION

version: 0.24
  
=head1 DESCRIPTION

Cookbook is just an example Padre::Plugin using a WxDialog, showing minimal requirements. It consists of a series of Recipes.

=over 4

=item * Recipe 01, Hello World what else could it be.

=item * Recipe 02, Fun with widgets and a Dialogue (method modifiers and event handlers).

=item * Recipe 03, Every Plug-in needs an About Dialogue or Multiple Dialogues.

=item * Recipe 04, ListCtrl or ConfigDB.

=back

=head2 Example

You will find more info in the companion L<wiki|http://padre.perlide.org/trac/wiki/PadrePluginDialog/> pages.

=head1 METHODS

=over 4

=item padre_interfaces

Required method with minimum requirements

	sub padre_interfaces {
	return (
		# Default, required
		'Padre::Plugin'         => 0.84,
		
        # used by Main, About and by Padre::Plugin::FormBuilder
        'Padre::Wx' => 0.84,
        'Padre::Wx::Main' => '0.86',
        'Padre::Wx::Role::Main' => 0.84,
        'Padre::Logger' => '0.84',
		);
	}

Called by Padre::Wx::Dialog::PluginManager

	my @needs = $plugin->padre_interfaces;

=item plugin_name

Required method with minimum requirements

	sub plugin_name {
		return 'Plugin Cookbook';
	}

Called by Padre::Wx::Dialog::PluginManager

	# Updating plug-in name in right pane
	$self->{label}->SetLabel( $plugin->plugin_name );


=item menu_plugins_simple

This is where you defined your plugin menu name, note hyphen for clarity.

	return $self->plugin_name => [
		'01 - Hello World' => sub {
			$self->load_dialog_recipe01_main;
		},
		'02 - Fun with widgets' => sub {
			$self->load_dialog_recipe02_main;
		},
		'03 - About dialogs' => sub {
			$self->load_dialog_recipe03_main;
		},
		'04 - ConfigDB RC1' => sub {
			$self->load_dialog_recipe04_main;
		},
	];

=item plugin_disable

Required method with minimum requirements

	$self->unload('Padre::Plugin::Cookbook::Recipe01::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe01::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe02::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');
	
=item plugin_icon

overloads plugin_icon from Padre::Plugin

=item load_dialog_recipe01_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe01::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe01::Main->new($main);

=item load_dialog_recipe02_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe02::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe02::Main->new($main);

=item load_dialog_recipe03_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe03::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe03::Main->new($main);

=item load_dialog_recipe04_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe04::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe04::Main->new($main);
    $self->{dialog}->Show;

=item clean_dialog

=back


=head1 BUGS AND LIMITATIONS 

=over

=item * No bugs have been reported.

=back

=head1 DEPENDENCIES

	Padre::Plugin, 
	Padre::Plugin::Cookbook, 
	Padre::Plugin::Cookbook::Recipe01::FBP::Main, Padre::Plugin::Cookbook::Recipe01::FBP::MainFB, 
	Padre::Plugin::Cookbook::Recipe02::FBP::Main, Padre::Plugin::Cookbook::Recipe02::FBP::MainFB, 
	Padre::Plugin::Cookbook::Recipe03::FBP::Main, Padre::Plugin::Cookbook::Recipe03::FBP::MainFB, 
	Padre::Plugin::Cookbook::Recipe03::About, Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB, 
	Padre::Plugin::Cookbook::Recipe04::FBP::Main, Padre::Plugin::Cookbook::Recipe04::FBP::MainFB, 
	Padre::Plugin::Cookbook::Recipe04::About, Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB, 
	Moose, namespace::autoclean, Data::Printer, POSIX,

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2013 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
