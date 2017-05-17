use Renard::Curie::Setup;
package Renard::Curie::Component::FileChooser;
# ABSTRACT: Component that implements a file chooser dialog
$Renard::Curie::Component::FileChooser::VERSION = '0.002';
use Moo;
use Renard::Curie::Types qw(InstanceOf);
use Function::Parameters;

has all_filter => (
	is => 'lazy', # _build_all_filter
	isa => InstanceOf['Gtk3::FileFilter'],
);

has pdf_filter => (
	is => 'lazy', # _build_pdf_filter
	isa => InstanceOf['Gtk3::FileFilter'],
);

method _build_all_filter() :ReturnType(InstanceOf['Gtk3::FileFilter']) {
	my $filter = Gtk3::FileFilter->new;
	$filter->set_name("All files");
	$filter->add_pattern("*");

	return $filter;
}

method _build_pdf_filter() :ReturnType(InstanceOf['Gtk3::FileFilter']) {
	my $filter = Gtk3::FileFilter->new;
	$filter->set_name("PDF files");
	$filter->add_mime_type("application/pdf");

	return $filter;
}

method get_open_file_dialog() :ReturnType(InstanceOf['Gtk3::FileChooserDialog']) {
	my $dialog = Gtk3::FileChooserDialog->new(
		"Open File",
		$self->app->window,
		'GTK_FILE_CHOOSER_ACTION_OPEN',
		'gtk-cancel' => 'cancel',
		'gtk-open' => 'accept',
	);

	return $dialog;
}

method get_open_file_dialog_with_filters() :ReturnType(InstanceOf['Gtk3::FileChooserDialog']) {
	my $dialog = $self->get_open_file_dialog;

	$dialog->add_filter( $self->pdf_filter );
	$dialog->add_filter( $self->all_filter );

	return $dialog;
}

with qw(
	Renard::Curie::Component::Role::HasParentApp
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::FileChooser - Component that implements a file chooser dialog

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Component::Role::HasParentApp>

=back

=head1 ATTRIBUTES

=head2 all_filter

A L<Gtk3::FileFilter> that displays all files.

=head2 pdf_filter

A L<Gtk3::FileFilter> that displays only C<application/pdf> files.

=head1 METHODS

=head2 get_open_file_dialog

  method get_open_file_dialog() :ReturnType(InstanceOf['Gtk3::FileChooserDialog'])

Returns an instance of L<Gtk3::FileChooserDialog> for opening files.

=head2 get_open_file_dialog_with_filters

  method get_open_file_dialog_with_filters() :ReturnType(InstanceOf['Gtk3::FileChooserDialog'])

Same as L</get_open_file_dialog> but with the following filters added:

=over 4

=item *

L</pdf_filter>

=item *

L</all_filter>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
