package Padre::Plugin::PDL;

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.05';

our @ISA = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::PDL
	Padre::Plugin::PDL::Document
	Padre::Plugin::PDL::Help
	Padre::Plugin::PDL::Util
};

# Called when Padre wants to check what package versions this
# plugin needs
sub padre_interfaces {
	return
		'Padre::Plugin'         => 0.94,
		'Padre::Document'       => 0.94,
		'Padre::Wx::Main'       => 0.94,
		'Padre::Wx::Role::Main' => 0.94,
		'Padre::Help'           => 0.94,
		;
}

# Called when Padre wants to knows what documents this Plugin supports
sub registered_documents {
	return 'application/x-perl' => 'Padre::Plugin::PDL::Document',;
}

# Called when Padre wants a name for the plugin
sub plugin_name {
	Wx::gettext('PDL');
}

# Called when the plugin is enabled by Padre
sub plugin_enable {
	my $self = shift;

	# Read the plugin configuration, and
	my $config = $self->config_read;
	unless ( defined $config ) {

		# No configuration, let us create it
		$config = {};
	}

	#TODO initialize your configuration here

	# Write the plugin's configuration
	$self->config_write($config);

	# Update configuration attribute
	$self->{config} = $config;

	# Generate missing Padre's events
	# TODO remove once Padre 0.96 is released
	require Padre::Plugin::PDL::Role::NeedsPluginEvent;
	Padre::Plugin::PDL::Role::NeedsPluginEvent->meta->apply( $self->main );

	# Highlight the current editor. This is needed when a plugin is enabled
	# for the first time
	$self->editor_changed;

	return 1;
}

# Called when the plugin is disabled by Padre
sub plugin_disable {
	my $self = shift;

	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}
}

# Called when Padre wants to display plugin menu items
#sub menu_plugins {
#	my $self      = shift;
#	my $main      = $self->main;
#	my $menu_item = Wx::MenuItem->new( undef, -1, Wx::gettext('PDL') );
#
#
#	Wx::Event::EVT_MENU(
#		$main,
#		$menu_item,
#		sub {
#		},
#	);
#
#	return $menu_item;
#}

# Called when an editor is opened
sub editor_enable {
	my $self     = shift;
	my $editor   = shift;
	my $document = shift;

	# Only on Perl documents
	return unless $document->isa('Padre::Document::Perl');

	require Padre::Plugin::PDL::Util;
	Padre::Plugin::PDL::Util::add_pdl_keywords_highlighting( $document, $editor );
}

# Called when an editor is changed
sub editor_changed {
	my $self     = shift;
	my $document = $self->current->document or return;
	my $editor   = $self->current->editor or return;

	# Only on Perl documents
	return unless $document->isa('Padre::Document::Perl');

	require Padre::Plugin::PDL::Util;
	Padre::Plugin::PDL::Util::add_pdl_keywords_highlighting( $document, $editor );
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::PDL - PDL support for Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::PDL

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once enabled, one will automatically get the following features:

=over

=item Context-sensitive help integration

Press F2 to get the help for the current PDL keyword

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-pdl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-PDL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::PDL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-PDL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-PDL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-PDL>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-PDL/>

=back

=head1 SEE ALSO

L<PDL>, L<Padre>

=head1 AUTHORS

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
