package Padre::Plugin::Snippet;

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Snippet::Role::NeedsSaveAsEvent
	Padre::Plugin::Snippet::Document
	Padre::Plugin::Snippet::Preferences
	Padre::Plugin::Snippet::FBP::Preferences
};

# Store the current configuration object for _plugin_config consumers
my $config;

# Called when Padre wants to check what package versions this
# plugin needs
sub padre_interfaces {
	'Padre::Plugin' => 0.94, 'Padre::Wx::Editor' => 0.94, 'Padre::Wx::Role::Main' => 0.94;
}

# Called when Padre wants a name for the plugin
sub plugin_name {
	Wx::gettext('Snippet');
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

	# Make sure defaults are respected if they are undefined.
	unless ( defined $config->{type} ) {
		$config->{type} = 'Moose';
	}
	unless ( defined $config->{feature_snippets} ) {
		$config->{feature_snippets} = 'Moose';
	}

	# Write the plugin's configuration
	$self->config_write($config);

	# Update configuration attribute
	$self->{config} = $config;

	# Generate missing Padre's events
	# TODO remove once Padre 0.96 is released
	require Padre::Plugin::Snippet::Role::NeedsPluginEvent;
	Padre::Plugin::Snippet::Role::NeedsPluginEvent->meta->apply( $self->main );

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

# # Called when Padre wants to display plugin menu items
# sub menu_plugins {
# my $self      = shift;
# my $main      = $self->main;
# my $menu_item = Wx::MenuItem->new( undef, -1, Wx::gettext('Snippet') . "...\tF9", );

# Wx::Event::EVT_MENU(
# $main,
# $menu_item,
# sub {
# },
# );

# return $menu_item;
# }

sub editor_changed {
	my $self     = shift;
	my $document = $self->current->document or return;
	my $editor   = $self->current->editor or return;

	# Always cleanup current document
	if ( defined $self->{document} ) {
		$self->{document}->cleanup;
		$self->{document} = undef;
	}

	# Only on Perl documents
	return unless $document->isa('Padre::Document::Perl');

	# Create a new snippet document
	require Padre::Plugin::Snippet::Document;
	$self->{document} = Padre::Plugin::Snippet::Document->new(
		editor   => $editor,
		document => $document,
		config   => $self->{config},
	);

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Snippet - TextMate-like snippets for Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::Snippet

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get TextMate-style TAB triggered
snippets for the following:

=item Perl

=item Moose

=item Mouse

=item MooseX::Declare

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-snippet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Snippet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Snippet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Snippet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Snippet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Snippet>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Snippet/>

=back

=head1 SEE ALSO

L<Padre>

=head1 AUTHORS

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 CONTRIBUTORS

Adam Kennedy <adamk@cpan.org>

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
