package Padre::Plugin::Experimento;

use Modern::Perl;
use Padre::Plugin ();

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Experimento
};

# Called when Padre wants to check what package versions this
# plugin needs
sub padre_interfaces {
	'Padre::Plugin' => 0.94,;
}

# Called when Padre wants a name for the plugin
sub plugin_name {
	Wx::gettext('Experimento');
}

#######
# Called by padre to build the menu in a simple way
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Move Selected Lines Up') . "\tCtrl-Shift-Up"     => sub { $self->move_selected_lines_up },
		Wx::gettext('Move Selected Lines Down') . "\tCtrl-Shift-Down" => sub { $self->move_selected_lines_down },
		'---'                                                         => undef,
		Wx::gettext('Check POD')                                      => sub { $self->check_pod },
		'---'                                                         => undef,
		Wx::gettext('About')                                          => sub { $self->show_about },
	];
}

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('Experimento Plug-in') );
	my $authors     = 'Ahmad M. Zawawi';
	my $description = Wx::gettext( <<'END' );
Experimental features for Padre

Copyright 2012 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

sub move_selected_lines_up {
	my $self = shift;

	my $editor = $self->current->editor or return;

	if ( $editor->can('MoveSelectedLinesUp') ) {
		$editor->MoveSelectedLinesUp;
	} else {
		$self->main->error( Wx::gettext('Error: Wx::Scintilla should be 0.3801 or later') );
	}

	return;
}

sub move_selected_lines_down {
	my $self = shift;

	my $editor = $self->current->editor or return;
	if ( $editor->can('MoveSelectedLinesDown') ) {
		$editor->MoveSelectedLinesDown;
	} else {
		$self->main->error( Wx::gettext('Error: Wx::Scintilla should be 0.3801 or later') );
	}

	return;
}

sub check_pod {
	my $self = shift;
	my $editor = $self->current->editor or return;

	require Pod::Checker;
	require IO::String;

	my $checker = Pod::Checker->new;
	my $output  = '';
	my $out     = IO::String->new($output);
	$checker->parse_from_file( IO::String->new( $editor->GetText ), $out );

	my $num_errors   = $checker->num_errors;
	my $num_warnings = $checker->num_warnings;
	my $results;
	if ( $num_errors == -1 ) {
		$results = Wx::gettext('No POD in current document');
	} elsif ( $num_errors == 0 and $num_warnings == 0 ) {
		$results = Wx::gettext('POD check OK');
	} else {
		$results = sprintf(
			Wx::gettext("Found %s errors and %s warnings"),
			$num_errors, $num_warnings
		);
		for ( split /^/, $output ) {
			if (/^(.+?) at line (\d+) in file \S+$/) {
				my ( $message, $line ) = ( $1, $2 );
				$results .= "\nAt line $line, $message";
			}
		}
	}

	my $main = $self->main;
	$main->output->SetValue($results);
	$main->output->SetSelection( 0, 0 );
	$main->show_output(1);

	return;
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

	#TODO some configuration defaults

	# Write the plugin's configuration
	$self->config_write($config);

	# Update configuration attribute
	$self->{config} = $config;

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

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Experimento - Provides experimental features to Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::Experimento

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you will be to do the following:

=head2 Move selected lines up (Ctrl-Shift-Up)

Move the selected lines up one line, shifting the line above after the
selection. The selection will be automatically extended to the
beginning of the selection's first line and the end of the seletion's
last line. If nothing was selected, the line the cursor is currently at
will be selected.

=head2 Move selected lines down (Ctrl-Shift-Down)

Move the selected lines down one line, shifting the line below before
the selection. The selection will be automatically extended to the
beginning of the selection's first line and the end of the seletion's
last line. If nothing was selected, the line the cursor is currently at
will be selected.

=head2 Check POD

Print the current document's POD errors and warnings in the output panel.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-padre-plugin-Experimento at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Experimento>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Experimento

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Experimento>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Experimento>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Experimento>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Experimento/>

=back

=head1 SEE ALSO

L<Padre>, L<PPI>, L<Pod::Checker>

=head1 AUTHORS

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
