package Padre::Plugin::PerlTidy;

use 5.008002;
use strict;
use warnings;
use File::Spec     ();
use File::Basename ();
use Params::Util 1.04 ();
use Padre::Current ();
use Padre::Wx      ();
use Padre::Plugin 0.92 ();
use FindBin qw($Bin);

our $VERSION = '0.22';
our @ISA     = 'Padre::Plugin';

# This constant is used when storing and restoring the cursor position.
# Keep it small to limit resource use.
use constant SELECTIONSIZE => 40;

sub padre_interfaces {
	return (
		'Padre::Plugin' => '0.92',
		'Padre::Wx::Main' => '0.92',
	);
}

sub plugin_name {
	return Wx::gettext('Perl Tidy');
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext("Tidy the active document\tAlt+Shift+F") => sub {
			$self->tidy_document;
		},
		Wx::gettext("Tidy the selected text\tAlt+Shift+G") => sub {
			$self->tidy_selection;
		},
		'---'                                              => undef,
		Wx::gettext('Export active document to HTML file') => sub {
			$self->export_document;
		},
		Wx::gettext('Export selected text to HTML file') => sub {
			$self->export_selection;
		},
	];
}





######################################################################
# Menu Handlers

sub tidy_document {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $self->current->document;
	my $text     = $document->text_get;

	# Tidy the entire current document
	$self->{over_ride} = 0;
	my $perltidyrc = $self->_which_tidyrc;
	my $tidy = $self->_tidy( $text, $perltidyrc );
	unless ( defined Params::Util::_STRING($tidy) ) {
		return;
	}

	# Overwrite the entire document
	my ( $regex, $start ) = $self->_get_cursor_position;
	$document->text_set($tidy);
	$self->_set_cursor_position( $regex, $start );
}

sub tidy_selection {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $self->current;
	my $text    = $current->text;

	# Tidy the current selected text
	$self->{over_ride} = 0;
	my $perltidyrc = $self->_which_tidyrc;

	my $tidy = $self->_tidy( $text, $perltidyrc );
	unless ( defined Params::Util::_STRING($tidy) ) {
		return;
	}

	# If the selected text does not have a newline at the end,
	# trim off any that Perl::Tidy has added.
	unless ( $text =~ /\n\z/ ) {
		$tidy =~ s{\n\z}{};
	}

	# Overwrite the selected text
	$current->editor->ReplaceSelection($tidy);
}

sub export_selection {
	my $self = shift;
	my $text = $self->current->text or return;
	$self->_export($text);
}

sub export_document {
	my $self = shift;
	my $document = $self->current->document or return;
	$self->_export( $document->text_get );
}





######################################################################
# Support Methods

sub _tidy {
	my $self       = shift;
	my $source     = shift;
	my $perltidyrc = shift;
	my $main       = $self->main;
	my $document   = $self->current->document;

	# Check for problems
	unless ( defined $source ) {
		return;
	}
	unless ( $document->isa('Padre::Document::Perl') ) {
		$main->error( Wx::gettext('Document is not a Perl document') );
		return;
	}

	my $destination = undef;
	my $errorfile   = undef;
	my %tidyargs    = (
		argv        => \'-nse -nst',
		source      => \$source,
		destination => \$destination,
		errorfile   => \$errorfile,
	);
	if ( $self->{over_ride} ) {
		$tidyargs{'perltidyrc'} = $perltidyrc;
	}
	if ( $self->{over_ride} ) {
		$tidyargs{'perltidyrc'} = $perltidyrc;
	}

	my $output;
	if ( $main->config->info_on_statusbar ) {
		$main->info( Wx::gettext("Running Tidy, don't forget to save changes.") );
	} else {

		#Make sure output is visible...
		$main->show_output(1);
		$output = $main->output;
	}

	# TODO: suppress the senseless warning from PerlTidy
	eval {
		require Perl::Tidy;
		Perl::Tidy::perltidy(%tidyargs);
	};

	if ( defined $errorfile ) {
		$main->show_output(1);
		$output = $main->output;
		my $filename =
			  $document->filename
			? $document->filename
			: $document->get_title;
		my $width = length($filename) + 2;
		$output->AppendText( "\n\n" . "-" x $width . "\n" . $filename . "\n" . "-" x $width . "\n" );
		$output->AppendText("$errorfile\n");
	}

	if ($@) {
		$main->error( Wx::gettext("PerlTidy Error") . ":\n" . $@ );
		return;
	}

	if ( defined $errorfile ) {
		$main->show_output(1);
		$output = $main->output;
		my $filename =
			  $document->filename
			? $document->filename
			: $document->get_title;
		my $width = length($filename) + 2;
		$output->AppendText( "\n\n" . "-" x $width . "\n" . $filename . "\n" . "-" x $width . "\n" );
		$output->AppendText("$errorfile\n");
	}

	return $destination;
}

sub _export {
	my $self     = shift;
	my $src      = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	return unless defined $src;

	if ( !$document->isa('Padre::Document::Perl') ) {
		$main->error( Wx::gettext('Document is not a Perl document') );
		return;
	}

	my $filename = $self->_get_filename;
	return unless defined $filename;

	my ( $output, $error );
	my %tidyargs = (
		argv        => \'-html -nnn -nse -nst',
		source      => \$src,
		destination => $filename,
		errorfile   => \$error,
	);

	# Make sure output window is visible...
	$main->show_output(1);
	$output = $main->output;

	if ( my $tidyrc = $document->project->config->config_perltidy ) {
		$tidyargs{perltidyrc} = $tidyrc;
		$output->AppendText("Perl\::Tidy running with project-specific configuration $tidyrc\n");
	} else {
		$output->AppendText("Perl::Tidy running with default or user configuration\n");
	}

	# TODO: suppress the senseless warning from PerlTidy
	eval {
		require Perl::Tidy;
		Perl::Tidy::perltidy(%tidyargs);
	};
	if ($@) {
		$main->error( Wx::gettext("PerlTidy Error") . ":\n" . $@ );
		return;
	}

	if ( defined $error ) {
		my $width = length( $document->filename ) + 2;
		my $main  = Padre::Current->main;

		$output->AppendText( "\n\n" . "-" x $width . "\n" . $document->filename . "\n" . "-" x $width . "\n" );
		$output->AppendText("$error\n");
		$main->show_output(1);
	}

	return;
}

sub _get_filename {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $self->current->document or return;
	my $filename = $document->filename;
	my $dir      = '';

	if ( defined $filename ) {
		$dir = File::Basename::dirname($filename);
	}

	while (1) {
		my $dialog = Wx::FileDialog->new(
			$main,
			Wx::gettext("Save file as..."),
			$dir,
			( $filename or $document->get_title ) . '.html',
			"*.*",
			Wx::wxFD_SAVE,
		);
		if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
			return;
		}
		my $filename = $dialog->GetFilename;
		$dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile( $dir, $filename );
		if ( -e $path ) {
			return $path
				if $main->yes_no(
				Wx::gettext("File already exists. Overwrite it?"),
				Wx::gettext("Exist")
				);
		} else {
			return $path;
		}
	}
}

# parameter: $main, compiled regex
sub _set_cursor_position {
	my $self   = shift;
	my $regex  = shift;
	my $start  = shift;
	my $editor = $self->current->editor or return;
	my $text   = $editor->GetTextRange(
		( $start - SELECTIONSIZE ) > 0 ? $start - SELECTIONSIZE
		: 0,
		( $start + SELECTIONSIZE < $editor->GetLength ) ? $start + SELECTIONSIZE
		: $editor->GetLength
	);
	eval {
		if ( $text =~ /($regex)/ )
		{
			my $pos = $start + length $1;
			$editor->SetCurrentPos($pos);
			$editor->SetSelection( $pos, $pos );
		}
	};
	$editor->goto_line_centerize( $editor->GetCurrentLine );
	return;
}

# parameter: $current
# returns: compiled regex, start position
# compiled regex is /^./ if no valid regex can be reconstructed.
sub _get_cursor_position {
	my $self   = shift;
	my $editor = $self->current->editor or return;
	my $pos    = $editor->GetCurrentPos;

	my $start;
	if ( ( $pos - SELECTIONSIZE ) > 0 ) {
		$start = $pos - SELECTIONSIZE;
	} else {
		$start = 0;
	}

	my $prefix = $editor->GetTextRange( $start, $pos );
	my $regex;
	eval {

		# Escape non-word chars
		$prefix =~ s/(\W)/\\$1/gm;

		# Replace whitespace by regex \s+
		$prefix =~ s/(\\\s+)/(\\s+|\\r*\\n)*/gm;

		$regex = qr{$prefix};
	};
	if ($@) {
		$regex = qw{^.};
		print STDERR @_;
	}
	return ( $regex, $start );
}

# Pick the revelant tidyrc file
sub _which_tidyrc {
	my $self = shift;

	# perl tidy Padre/tools
	if ( $ENV{'PADRE_DEV'} ) {
		my $perltidyrc = eval { File::Spec->catfile( $Bin, '../../tools/perltidyrc' ); };
		if ( -e $perltidyrc ) {
			$self->{over_ride} = 1;
			return $perltidyrc;
		}

		my $main = $self->main;
		Wx::MessageBox(
			Wx::gettext("You need to install from SVN Padre/tools."),
			Wx::gettext("tools/perltidyrc missing"),
			Wx::wxCANCEL,
			$main,
		);
	}

	return;
}

1;

=pod

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 DESCRIPTION

This is a simple plugin to run L<Perl::Tidy> on your source code.

Currently there are no customisable options (since the Padre plugin system
doesn't support that yet) - however Perl::Tidy will use your normal .perltidyrc
file if it exists (see Perl::Tidy documentation).

=head1 METHODS

=head2 padre_interfaces

Indicates our compatibility with Padre.

=head2 plugin_name

A simple accessor for the name of the plugin.

=head2 menu_plugins_simple

Menu items for this plugin.

=head2 tidy_document

Runs Perl::Tidy on the current document.

=head2 export_document

Export the current document as html.

=head2 tidy_selection

Runs Perl::Tidy on the current code selection.

=head2 export_selection

Export the current code selection as html.

=cut
