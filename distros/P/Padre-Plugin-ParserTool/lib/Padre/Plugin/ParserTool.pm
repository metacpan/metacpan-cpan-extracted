package Padre::Plugin::ParserTool;

use 5.008005;
use strict;
use warnings;
use Params::Util 1.00  ();
use Padre::Plugin 0.89 ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::ParserTool
	Padre::Plugin::ParserTool::Dialog
	Padre::Plugin::ParserTool::FBP
};

######################################################################
# Configuration Methods

sub plugin_name {
	Wx::gettext('Parser Tool');
}

sub padre_interfaces {
	'Padre::Plugin' => '0.89', 'Padre::Wx' => '0.89', 'Padre::Wx::Role::Dialog' => '0.89',;
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
		$main, $item,
		sub {
			local $@;
			eval { $self->menu_dialog($main); };
		},
	);

	return $item;
}

sub plugin_disable {
	my $self = shift;

	# Clean up the dialog if it is still open
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);
}

######################################################################
# Main Methods

sub menu_dialog {
	my $self = shift;
	my $main = shift;

	# Spawn the dialog
	require Padre::Plugin::ParserTool::Dialog;
	unless ( $self->{dialog} ) {
		$self->{dialog} = Padre::Plugin::ParserTool::Dialog->new($main);
	}
	$self->{dialog}->refresh;
	$self->{dialog}->ShowModal;

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::ParserTool - A realtime interactive parser test tool for Padre

=head1 DESCRIPTION

The B<ParserTool> plugin adds an interactive parser testing tool for L<Padre>.

It provides a two-panel dialog where you can type file contents into a panel
on one side, and see a realtime dump of the resulting parsed structure on the
other side of the dialog.

The dialog is configurable, so it can be used to test both common Perl parsers
and parsers for custom file formats of your own.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-ParserTool>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head2 CONTRIBUTORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 SEE ALSO

L<Padre>, L<PPI>

=head1 COPYRIGHT

Copyright 2011-2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
