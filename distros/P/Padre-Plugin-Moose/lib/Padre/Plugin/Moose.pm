package Padre::Plugin::Moose;

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.21';
our @ISA     = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Moose
	Padre::Plugin::Moose::Role::CanGenerateCode
	Padre::Plugin::Moose::Role::CanHandleInspector
	Padre::Plugin::Moose::Role::CanProvideHelp
	Padre::Plugin::Moose::Role::HasClassMembers
	Padre::Plugin::Moose::Role::NeedsPluginEvent
	Padre::Plugin::Moose::Attribute
	Padre::Plugin::Moose::Class
	Padre::Plugin::Moose::ClassMember
	Padre::Plugin::Moose::Constructor
	Padre::Plugin::Moose::Destructor
	Padre::Plugin::Moose::Method
	Padre::Plugin::Moose::Program
	Padre::Plugin::Moose::Role
	Padre::Plugin::Moose::Subtype
	Padre::Plugin::Moose::Util
	Padre::Plugin::Moose::Assistant
	Padre::Plugin::Moose::Preferences
	Padre::Plugin::Moose::FBP::Assistant
	Padre::Plugin::Moose::FBP::Preferences
};

# Called when Padre wants to check what package versions this
# plugin needs
sub padre_interfaces {
	'Padre::Plugin'               => 0.94,
		'Padre::Document'         => 0.94,
		'Padre::Wx::Main'         => 0.94,
		'Padre::Wx::Theme'        => 0.94,
		'Padre::Wx::Editor'       => 0.94,
		'Padre::Wx::Role::Main'   => 0.94,
		'Padre::Wx::Role::Dialog' => 0.94,
		;
}

# Called when Padre wants a name for the plugin
sub plugin_name {
	Wx::gettext('Moose');
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
	unless ( defined $config->{namespace_autoclean} ) {
		$config->{namespace_autoclean} = 0;
	}
	unless ( defined $config->{comments} ) {
		$config->{comments} = 1;
	}
	unless ( defined $config->{sample_code} ) {
		$config->{sample_code} = 1;
	}

	# Write the plugin's configuration
	$self->config_write($config);

	# Update configuration attribute
	$self->{config} = $config;

	# Generate missing Padre's events
	# TODO remove once Padre 0.96 is released
	require Padre::Plugin::Moose::Role::NeedsPluginEvent;
	Padre::Plugin::Moose::Role::NeedsPluginEvent->meta->apply( $self->main );

	# Highlight the current editor. This is needed when a plugin is enabled
	# for the first time
	$self->editor_changed;

	return 1;
}

# Called when the plugin is disabled by Padre
sub plugin_disable {
	my $self = shift;

	# Destroy resident dialog
	if ( defined $self->{assistant} ) {
		$self->{assistant}->Destroy;
		$self->{assistant} = undef;
	}

	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}
}

# Called when Padre wants to display plugin menu items
sub menu_plugins {
	my $self      = shift;
	my $main      = $self->main;
	my $menu_item = Wx::MenuItem->new( undef, -1, Wx::gettext('Moose Assistant') . "...\tF8", );

	Wx::Event::EVT_MENU(
		$main,
		$menu_item,
		sub {
			$self->show_assistant;
		},
	);

	return $menu_item;
}

# Shows the Moose assistant dialog. Creates it only once if needed
sub show_assistant {
	my $self = shift;

	eval {
		unless ( defined $self->{assistant} )
		{
			require Padre::Plugin::Moose::Assistant;
			$self->{assistant} = Padre::Plugin::Moose::Assistant->new($self);
		}
	};
	if ($@) {
		$self->main->error( sprintf( Wx::gettext('Error: %s'), $@ ) );
	} else {
		$self->{assistant}->run;
	}

	return;
}

# Called when an editor is opened
sub editor_enable {
	my $self     = shift;
	my $editor   = shift;
	my $document = shift;

	# Only on Perl documents
	return unless $document->isa('Padre::Document::Perl');

	require Padre::Plugin::Moose::Util;
	Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $self->{config}->{type}, $document, $editor );
}

# Called when an editor is changed
sub editor_changed {
	my $self     = shift;
	my $current  = $self->current or return;
	my $document = $current->document or return;
	my $editor   = $current->editor or return;

	# Only on Perl documents
	return unless $document->isa('Padre::Document::Perl');

	require Padre::Plugin::Moose::Util;
	Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $self->{config}->{type}, $document, $editor );
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose - Moose, Mouse and MooseX::Declare support for Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::Moose

Then use it via L<Padre>, The Perl IDE. Press F8.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the
following options:

=head2 Moose Assistant

Opens up a user-friendly dialog where you can add classes, roles and their
members. The dialog contains a tree view of created class and role elements and
a preview of the generated Perl code. It also contains links to Moose online
references.

=head2 Moose Preferences

Provides the ability to change the operation type (Moose, Mouse or 
MooseX::Declare) and toggle the usage of namespace::clean, comments and sample 
usage code generation.

=head2 Keyword Syntax Highlighting

Moose/Mouse and MooseX::Declare keywords are highlighted automatically in any
Perl document. The operation type determines what to highlight.

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-moose at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Moose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Moose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Moose>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Moose/>

=back

=head1 SEE ALSO

L<Moose>, L<Padre>

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
