package PDF::Make::FieldPtr;

use strict;
use warnings;
use PDF::Make ();

our $VERSION = '0.04';

1;

__END__

=head1 NAME

PDF::Make::FieldPtr - Low-level XS form field pointer API

=head1 SYNOPSIS

	use PDF::Make;
	use PDF::Make::FieldPtr;

	my $doc = PDF::Make::Document->new;
	$doc->add_page;

	# Create a text field (returns native field pointer object)
	my $field = PDF::Make::FieldPtr::text(
		$doc,
		'email',
		72, 700, 240, 20,
	);

	$field->set_value('user@example.com');

	# Attach to page
	my $page = $doc->get_page(0);
	$field->add_to_page($page);

=head1 DESCRIPTION

C<PDF::Make::FieldPtr> exposes low-level field construction and mutation
APIs backed by C<libpdfmake> through XS.

This module is a namespace loader only; implementation lives in
C<xs/form.xs> and C<src/pdfmake_form.c>.

=head1 METHODS

The following constructor-style methods are provided by XS:

=over 4

=item * C<text($doc, $name, $x, $y, $width, $height)>

=item * C<checkbox($doc, $name, $x, $y, $width, $height, $on_value = "Yes")>

=item * C<radio_group($doc, $name)>

=item * C<add_radio_option($group, $x, $y, $width, $height, $value)>

=item * C<choice($doc, $name, $x, $y, $width, $height, $combo = 0)>

=item * C<combo($doc, $name, $x, $y, $width, $height)>

=item * C<listbox($doc, $name, $x, $y, $width, $height)>

=item * C<button($doc, $name, $x, $y, $width, $height, $caption)>

=item * C<signature($doc, $name, $x, $y, $width, $height)> (if enabled)

=back

Accessor and mutator methods are also provided on returned field pointer
objects (for example C<set_value>, C<readonly>, C<required>,
C<add_to_page>, and related methods).

=head1 SEE ALSO

L<PDF::Make::FormPtr>, L<PDF::Make::Form>, L<PDF::Make>, L<PDF::Make::Builder>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
