package Padre::Plugin::FormBuilder;

=pod

=head1 NAME

Padre::Plugin::FormBuilder - Generate Perl for dialogs created in wxFormBuilder

=head1 DESCRIPTION

The Form Builder user interface design tool helps to produce user interface
code relatively quickly. However, it does not natively support the
generation of Perl code.

B<Padre::Plugin::FormBuilder> provides an interface to the
L<Wx::Perl::FormBuilder> module to allow the generation of Padre dialog code
based on wxFormBuilder designs.

=cut

use 5.008005;
use strict;
use warnings;

# Normally we would run-time load most of these,
# but we happen to know Padre uses all of them itself.
use Class::Inspector 1.22 ();
use Params::Util     1.00 ();
use Padre::Plugin         ();

our $VERSION = '0.04';
our @ISA     = 'Padre::Plugin';

# Temporary namespace counter
my $COUNT = 0;





#####################################################################
# Padre::Plugin Methods

sub plugin_name {
	'Padre Form Builder';
}

sub padre_interfaces {
	'Padre::Plugin'         => 0.93,
	'Padre::Util'           => 0.93,
	'Padre::Unload'         => 0.93,
	'Padre::Task'           => 0.93,
	'Padre::Document'       => 0.93,
	'Padre::Project'        => 0.93,
	'Padre::Wx'             => 0.93,
	'Padre::Wx::Role::Main' => 0.93,
	'Padre::Wx::Main'       => 0.93,
	'Padre::Wx::Editor'     => 0.93,
}

# Clean up our classes
sub plugin_disable {
	my $self = shift;

	# Remove the dialog
	$self->clean_dialog;

	# Unload all our child classes
	$self->unload( qw{
		Padre::Plugin::FormBuilder::Dialog
		Padre::Plugin::FormBuilder::FBP
		Padre::Plugin::FormBuilder::Perl
		Padre::Plugin::FormBuilder::Preview
	} );

	return 1;
}

sub menu_plugins {
	my $self = shift;
	my $main = shift;

	# Create a manual menu item
	my $item = Wx::MenuItem->new(
		undef,
		-1,
		$self->plugin_name,
	);
	Wx::Event::EVT_MENU(
		$main,
		$item,
		sub {
			local $@;
			eval {
				$self->menu_dialog($main);
			};
		},
	);

	return $item;
}

sub clean_dialog {
	my $self = shift;

	# Close the formbuilder dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->clear_preview;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}





######################################################################
# Menu Commands

sub menu_dialog {
	my $self = shift;
	my $main = $self->main;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::FormBuilder::Dialog;
	$self->{dialog} = Padre::Plugin::FormBuilder::Dialog->new($main);
	$self->{dialog}->Show;

	return;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-FormBuilder>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Padre>

=head1 COPYRIGHT

Copyright 2010 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
