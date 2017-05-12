package Padre::Plugin::DataWalker;
BEGIN {
  $Padre::Plugin::DataWalker::VERSION = '0.04';
}

# ABSTRACT: Simple Perl data structure browser Padre

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();

our @ISA = 'Padre::Plugin';



sub padre_interfaces {
	'Padre::Plugin' => 0.47,;
}

sub plugin_name {
	Wx::gettext('DataWalker');
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About')                          => sub { $self->show_about },
		Wx::gettext('Browse YAML dump file')          => sub { $self->browse_yaml_file },
		Wx::gettext('Browse current document object') => sub { $self->browse_current_document },
		Wx::gettext('Browse Padre IDE object')        => sub { $self->browse_padre },
		Wx::gettext('Browse Padre main symbol table') => sub { $self->browse_padre_stash },
	];
}

sub browse_yaml_file {
	my $self = shift;
	require YAML::XS;
	my $main   = Padre->ide->wx->main;
	my $dialog = Wx::FileDialog->new(
		$main,
		Wx::gettext('Open file'),
		$main->cwd,
		"",
		"*.*",
		Wx::wxFD_OPEN | Wx::wxFD_FILE_MUST_EXIST,
	);
	unless ( Padre::Constant::WIN32() ) {
		$dialog->SetWildcard("*");
	}

	return if $dialog->ShowModal == Wx::wxID_CANCEL;
	my @filenames = $dialog->GetFilenames or return ();
	my $file = File::Spec->catfile( $dialog->GetDirectory(), shift @filenames );

	if ( not( -f $file and -r $file ) ) {
		Wx::MessageBox(
			sprintf( Wx::gettext("Could not find the specified file '%s'"), $file ),
			Wx::gettext('File not found'),
			Wx::wxOK,
			$main,
		);
	}

	my $data = eval { YAML::XS::LoadFile($file) };
	if ( not defined $data or $@ ) {
		Wx::MessageBox(
			sprintf( Wx::gettext( "Could not read the YAML file.%s", ( $@ ? "\n$@" : "" ) ) ),
			Wx::gettext('Invalid YAML file'),
			Wx::wxOK,
			$main,
		);
	}

	$self->_data_walker($data);
	return ();
}

sub browse_padre_stash {
	my $self = shift;
	$self->_data_walker( \%:: );
	return ();
}


sub browse_current_document {
	my $self = shift;
	my $doc  = Padre::Current->document;
	$self->_data_walker($doc);
	return ();
}


sub browse_padre {
	my $self = shift;
	$self->_data_walker( Padre->ide );
	return ();
}

sub _data_walker {
	my $self = shift;
	my $data = shift;
	require Wx::Perl::DataWalker;

	my $dialog = Wx::Perl::DataWalker->new(
		{ data => $data },
		undef,
		-1,
		"DataWalker",
	);
	$dialog->SetSize( 500, 500 );
	$dialog->Show(1);
	return ();
}


sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::DataWalker");
	$about->SetDescription( <<"END_MESSAGE" );
Simple Perl data structure browser for Padre
END_MESSAGE
	$about->SetVersion($Padre::Plugin::DataWalker::VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

__END__
=pod

=head1 NAME

Padre::Plugin::DataWalker - Simple Perl data structure browser Padre

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Use this like any other Padre plugin. To install
Padre::Plugin::DataWalker for your user only, you can
type the following in the extracted F<Padre-Plugin-DataWalker-...>
directory:

  perl Makefile.PL
  make
  make test
  make installplugin

Afterwards, you can enable the plugin from within Padre
via the menu I<Plugins-E<gt>Plugin Manager> and there click
I<enable> for I<DataWalker>.

=head1 DESCRIPTION

This plugin uses the L<Wx::Perl::DataWalker> module to
provide facilities for interactively browsing Perl data structures.

At this time, the plugin offers several menu entries
in Padre's I<Plugins> menu:

=over 2

=item Browse YAML dump file

If you dump (almost) any data structure from a running program into
a YAML file, you can use this to open the dump and browse
it within Padre. Dump a data structure like this:

  use YAML::XS; YAML::XS::Dump(...YourDataStructure...);

This menu entry will show a file-open dialog and let you select the YAML
file to load.

Let me know if you need any other input format (like Storable's nstore).

=item Browse current document object

Opens the data structure browser on the current document object.

Like all following menu entries, this is mostly useful for the Padre developers.

=item Browse Padre IDE object

Opens the Padre main IDE object in the data structure browser. Useful for debugging Padre.

=item Browse Padre main symbol table

Opens the C<%main::> symbol table of Padre in the data structure browser.
Certainly only useful for debugging Padre.

=back

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

