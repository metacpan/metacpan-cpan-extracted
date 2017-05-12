package Padre::Plugin::LaTeX;
BEGIN {
  $Padre::Plugin::LaTeX::VERSION = '0.13';
}

# ABSTRACT: LaTeX support for Padre

use warnings;
use strict;

use File::Spec::Functions qw{ catfile };

use base 'Padre::Plugin';
use Padre::Wx ();

sub plugin_name {
	Wx::gettext('LaTeX');
}

sub padre_interfaces {
	'Padre::Plugin'   => 0.89,
	'Padre::Document' => 0.89,
	'Padre::Wx::Main' => 0.89;
}

sub registered_documents {
	'application/x-latex' => 'Padre::Document::LaTeX',
	'application/x-bibtex' => 'Padre::Document::BibTeX',
	;
}

sub plugin_icon {
	my $self = shift;

	# find resource path
	my $iconpath = catfile( $self->plugin_directory_share, 'icons', 'text-x-tex.png' );

	# create and return icon
	return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );

	# TODO: simplify
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Create/Update PDF') => sub { $self->create_pdf },
		Wx::gettext('View PDF')          => sub { $self->view_pdf },
		Wx::gettext('Run BibTeX')        => sub { $self->run_bibtex },
		'---'                            => undef,
		Wx::gettext('Find Symbol/Special Character')
			=> sub { Padre::Wx::launch_browser('http://detexify.kirelabs.org') },
		'---' => undef,
		Wx::gettext('About') => sub { $self->show_about },
	];
}

sub plugin_disable {
	my $self = shift;

	if ( $self->{about_box} ) {
		$self->{about_box}->Destroy;
		$self->{about_box} = undef;
 	}

	#require Class::Unload;
	#Class::Unload->unload('Padre::Document::LaTeX');
	#Class::Unload->unload('Padre::Document::BibTeX');

	return 1;
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $self->{about} = Wx::AboutDialogInfo->new;
	$self->{about}->SetName( Wx::gettext('LaTeX Plug-in') );
	my $authors     = 'Zeno Gantner, Ahmad M. Zawawi';
	my $description = Wx::gettext( <<'END' );
LaTeX support for Padre

For syntax highlighting of BibTeX files install the Kate plugin: Padre::Plugin::Kate

Copyright 2010, 2011 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$self->{about}->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($self->{about});

	return;
}

sub create_pdf {
	my $self = shift;

	my $pdflatex = 'pdflatex -interaction nonstopmode -file-line-error';

	my $main     = $self->main;
	my $doc      = $main->current->document;
	my $tex_dir  = $doc->dirname;
	my $tex_file = $doc->get_title;

	if ( !$doc->isa('Padre::Document::LaTeX') ) {
		$main->message( Wx::gettext('Creating PDF files is only supported for LaTeX documents.') );
		return;
	}

	# TODO autosave or ask or use temporary file

	chdir $tex_dir;
	my $output_text = `$pdflatex $tex_file`;
	$self->_output($output_text);

	return;
}

sub run_bibtex {
	my $self = shift;

	my $bibtex = 'bibtex';

	my $main = $self->main;
	my $doc  = $main->current->document;

	my $tex_dir  = $doc->dirname;
	my $aux_file = $doc->filename;
	$aux_file =~ s/\.tex/.aux/;

	if ( !$doc->isa('Padre::Document::LaTeX') ) {
		$main->message( Wx::gettext('Running BibTeX is only supported for LaTeX documents.') );
		return;
	}

	# TODO autosave (or ask)

	chdir $tex_dir; # TODO does this have side effects?
	my $output_text = `$bibtex $aux_file`;
	$self->_output($output_text);

	return;
}

sub view_pdf {
	my $self = shift;

	my $main = $self->main;
	my $doc  = $main->current->document;

	if ( !$doc->isa('Padre::Document::LaTeX') ) {
		$main->message( Wx::gettext('Viewing PDF files is only supported for LaTeX documents.') );
		return;
	}

	my $pdf_file = $doc->filename;
	$pdf_file =~ s/\.tex$/.pdf/;

	if ( !-f $pdf_file ) {
		main->error( sprintf( Wx::gettext("Could not find file '%s'."), $pdf_file ) );
	}

	$self->launch_pdf_viewer($pdf_file);

	return;
}


sub launch_pdf_viewer {
	my $self     = shift;
	my $pdf_file = shift;

	# TODO find PDF viewer from system settings like Debian alternatives
	# TODO get PDF viewer from configuration

	require File::Which;
	my @pdf_viewers = qw/evince okular xpdf gv acroread/;
	my $pdf_viewer  = '';
	foreach my $program (@pdf_viewers) {
		last if defined( $pdf_viewer = File::Which::which($program) );
	}

	system "$pdf_viewer $pdf_file &";

	return;
}

sub editor_enable {
	my $self     = shift;
	my $editor   = shift;
	my $document = shift;

	if ( $document->isa('Padre::Document::LaTeX') ) {

		# TODO
	}

	return 1;
}

sub _output {
	my ( $self, $text ) = @_;
	my $main = $self->main;

	$main->show_output(1);
	$main->output->clear;
	$main->output->AppendText($text);

	return;
}


1;


=pod

=head1 NAME

Padre::Plugin::LaTeX - LaTeX support for Padre

=head1 VERSION

version 0.13

=head1 DESCRIPTION

LaTeX support for Padre, the Perl Application Development and Refactoring
Environment.

Syntax highlighting for LaTeX is supported by Padre out of the box.
This plug-in adds some more features to deal with LaTeX files.
If you also want syntax highlighting for BibTeX files, install the Kate
plugin.

=head1 AUTHORS

=over 4

=item *

Zeno Gantner <zenog@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Zeno Gantner, Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

