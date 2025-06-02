package PDFio::Architect;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

use PDFio::Architect::File;

require XSLoader;
XSLoader::load("PDFio::Architect", $VERSION);

1;

__END__

=head1 NAME

PDFio::Architect - creating and manipulating PDF files

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use PDFio::Architect;

	my $pdf = PDFio::Architect->new("test.pdf");

	$pdf->load_font("F1", "Courier");

	for (1 .. 10) {
		my $page = $pdf->add_page({
			size => "A4"
		});
		$page->add_text({
			text => "Hello World"
			font => "F1",
			size => 12,
			bounding_box => $pdf->new_rect(0, 0, $page->width, $page->height)
		});
		$page->done();
	}

	$pdf->total_pages; # 10

	$pdf->save();

=head1 NOTE

This module is a work in progress and is not yet fully functional. It is intended to provide a framework for creating and manipulating PDF files, but many features are still under development.

=head1 DESCRIPTION

PDFio::Architect is a Perl module that provides an interface for creating and manipulating PDF files. It allows you to create new PDF files, add pages, load fonts, and perform various operations on the PDF content.

=head1 METHODS

=head2 new

=head2 add_page

=head2 add_font

=head2 save

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pdfio-architect at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDFio-Architect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc PDFio::Architect


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=PDFio-Architect>

=item * Search CPAN

L<https://metacpan.org/release/PDFio-Architect>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of PDFio::Architect
