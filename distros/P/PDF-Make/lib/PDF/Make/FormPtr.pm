package PDF::Make::FormPtr;

use strict;
use warnings;
use PDF::Make ();

our $VERSION = '0.05';

1;

__END__

=head1 NAME

PDF::Make::FormPtr - Low-level XS AcroForm pointer API

=head1 SYNOPSIS

	use PDF::Make;
	use PDF::Make::FormPtr;
	use PDF::Make::FieldPtr;

	my $doc = PDF::Make::Document->new;
	$doc->add_page;

	my $form = PDF::Make::FormPtr::create($doc);
	$form->set_need_appearances(1);

	my $field = PDF::Make::FieldPtr::text($doc, 'name', 72, 700, 240, 20);
	my $page  = $doc->get_page(0);
	$field->add_to_page($page);

	$form->finalize;

=head1 DESCRIPTION

C<PDF::Make::FormPtr> exposes low-level AcroForm operations backed by
C<libpdfmake> through XS.

This module is a namespace loader only; implementation lives in
C<xs/form.xs> and C<src/pdfmake_form.c>.

=head1 METHODS

The following methods are provided by XS:

=over 4

=item * C<get($doc)>

Return the document form pointer if it exists, otherwise C<undef>.

=item * C<create($doc)>

Create a form dictionary in the document and return its pointer.

=item * C<set_need_appearances($bool)>

Set AcroForm C</NeedAppearances> behavior.

=item * C<field_count>

Return number of fields in the form.

=item * C<field_at($idx)>

Return field pointer at index or C<undef>.

=item * C<field_by_name($name)>

Return field pointer by name or C<undef>.

=item * C<fields>

Return all field pointers as a list.

=item * C<finalize>

Finalize form resources before document write.

=item * C<flatten>

Flatten interactive fields into static page content.

=item * C<export_fdf>, C<export_xfdf>

Export form values in FDF/XFDF formats.

=item * C<import_fdf($bytes)>, C<import_xfdf($bytes)>

Import form values from FDF/XFDF payloads.

=back

=head1 SEE ALSO

L<PDF::Make::FieldPtr>, L<PDF::Make::Form>, L<PDF::Make>, L<PDF::Make::Builder>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
