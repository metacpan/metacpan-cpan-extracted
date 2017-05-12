package Padre::Plugin::HTMLExport;
BEGIN {
  $Padre::Plugin::HTMLExport::VERSION = '0.09';
}

# ABSTRACT: Export highlighted HTML in Padre

use 5.008005;
use warnings;
use strict;

use File::Basename ();

use base 'Padre::Plugin';
use Padre::Wx ();
use Wx::Locale qw(:default);

our %KATE_ALL = (
	'text/x-adasrc'      => 'Ada',
	'text/asm'           => 'Asm6502',
	'text/x-c++src'      => 'Cplusplus',
	'text/css'           => 'CSS',
	'text/x-patch'       => 'Diff',
	'text/eiffel'        => 'Eiffel',
	'text/x-fortran'     => 'Fortran',
	'text/html'          => 'HTML',
	'text/ecmascript'    => 'JavaScript',
	'text/latex'         => 'LaTeX',
	'text/lisp'          => 'Common_Lisp',
	'text/lua'           => 'Lua',
	'text/x-makefile'    => 'Makefile',
	'text/matlab'        => 'Matlab',
	'text/x-pascal'      => 'Pascal',
	'application/x-perl' => 'Perl',
	'text/x-python'      => 'Python',
	'application/x-php'  => 'PHP_PHP',
	'application/x-ruby' => 'Ruby',
	'text/x-sql'         => 'SQL',
	'text/x-tcl'         => 'Tcl_Tk',
	'text/vbscript'      => 'JavaScript',
	'text/xml'           => 'XML',
);

sub padre_interfaces {
	'Padre::Plugin' => '0.47',;
}

sub menu_plugins_simple {
	my $self = shift;
	return (
		Wx::gettext('Export Colorful HTML') => [
			Wx::gettext('Export HTML...'),  sub { $self->export_html },
			Wx::gettext('Configure Color'), sub { $self->plugin_preferences },
		]
	);
}

sub export_html {
	my ($self) = @_;
	my $main = $self->main;

	my $doc = $main->current->document or return;
	my $current = $doc->filename;
	my $default_dir;
	if ( defined $current ) {
		$default_dir = File::Basename::dirname($current);
	}

	# ask where to save
	my $save_to_file;
	while (1) {
		my $dialog = Wx::FileDialog->new(
			$main,
			Wx::gettext('Save as HTML...'),
			$default_dir,
			'',
			'*.html',
			Wx::wxFD_SAVE,
		);
		if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
			return 0;
		}
		my $filename = $dialog->GetFilename;
		$default_dir = $dialog->GetDirectory;
		my $path = File::Spec->catfile( $default_dir, $filename );
		if ( -e $path ) {
			my $res = Wx::MessageBox(
				Wx::gettext('File already exists. Overwrite it?'),
				Wx::gettext('Exist'),
				Wx::wxYES_NO,
				$main,
			);
			if ( $res == Wx::wxYES ) {
				$save_to_file = $path;
				last;
			}
		} else {
			$save_to_file = $path;
			last;
		}
	}

	# highlight
	my $mimetype = $doc->mimetype;
	unless ( exists $KATE_ALL{$mimetype} ) {
		$main->error( sprintf( gettext('%s is not supported'), $mimetype ) );
		return;
	}
	my $language = $KATE_ALL{$mimetype};

	require Syntax::Highlight::Engine::Kate;
	my $hl = Syntax::Highlight::Engine::Kate->new(
		language      => $language,
		substitutions => {
			"<"  => "&lt;",
			">"  => "&gt;",
			"&"  => "&amp;",
			" "  => "&nbsp;",
			"\t" => "&nbsp;&nbsp;&nbsp;",
			"\n" => "<BR>\n",
		},
		format_table => {
			Alert        => [ "<font color=\"#0000ff\">",       "</font>" ],
			BaseN        => [ "<font color=\"#007f00\">",       "</font>" ],
			BString      => [ "<font color=\"#c9a7ff\">",       "</font>" ],
			Char         => [ "<font color=\"#ff00ff\">",       "</font>" ],
			Comment      => [ "<font color=\"#7f7f7f\"><i>",    "</i></font>" ],
			DataType     => [ "<font color=\"#0000ff\">",       "</font>" ],
			DecVal       => [ "<font color=\"#00007f\">",       "</font>" ],
			Error        => [ "<font color=\"#ff0000\"><b><i>", "</i></b></font>" ],
			Float        => [ "<font color=\"#00007f\">",       "</font>" ],
			Function     => [ "<font color=\"#007f00\">",       "</font>" ],
			IString      => [ "<font color=\"#ff0000\">",       "" ],
			Keyword      => [ "<b>",                            "</b>" ],
			Normal       => [ "",                               "" ],
			Operator     => [ "<font color=\"#ffa500\">",       "</font>" ],
			Others       => [ "<font color=\"#b03060\">",       "</font>" ],
			RegionMarker => [ "<font color=\"#96b9ff\"><i>",    "</i></font>" ],
			Reserved     => [ "<font color=\"#9b30ff\"><b>",    "</b></font>" ],
			String       => [ "<font color=\"#ff0000\">",       "</font>" ],
			Variable     => [ "<font color=\"#0000ff\"><b>",    "</b></font>" ],
			Warning      => [ "<font color=\"#0000ff\"><b><i>", "</b></i></font>" ],
		},
	);

	my $title  = 'Highlight ' . $doc->filename . ' By Padre::Plugin::HTML::Export';
	my $code   = $doc->text_get;
	my $output = "<html>\n<head>\n<title>$title</title>\n</head>\n<body>\n";
	$output .= $hl->highlightText($code);
	$output .= "</body>\n</html>\n";

	open( my $fh, '>', $save_to_file );
	print $fh $output;
	close($fh);

	my $ret = Wx::MessageBox(
		sprintf( Wx::gettext('Saved to %s. Do you want to open it now?'), $save_to_file ),
		Wx::gettext('Done'),
		Wx::wxYES_NO | Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		Wx::LaunchDefaultBrowser($save_to_file);
	}
}

sub plugin_preferences {
	my ($self) = @_;
	my $main = $self->main;

	$main->error( Wx::gettext('Not implemented, TODO') );
}

1;


=pod

=head1 NAME

Padre::Plugin::HTMLExport - Export highlighted HTML in Padre

=head1 VERSION

version 0.09

=head1 SYNOPSIS

	$>padre
	Plugins -> Export Colorful HTML ->
						  Export HTML
						  Configure Color

=head1 DESCRIPTION

Export a HTML page by using L<Syntax::Highlight::Engine::Kate>

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

