use Renard::Incunabula::Common::Setup;
package Renard::Block::Format::PDF::Document;
# ABSTRACT: document that represents a PDF file
$Renard::Block::Format::PDF::Document::VERSION = '0.005';
use Moo;
use Renard::API::MuPDF::mutool;
use Renard::Block::Format::PDF::Page;
use Renard::Incunabula::Outline;
use Renard::Incunabula::Document::Types qw(PageNumber ZoomLevel);
use Renard::Incunabula::Common::Types qw(InstanceOf);

use Math::Trig;
use Math::Polygon;

use String::Tagged;

use Function::Parameters;

extends qw(Renard::Incunabula::Document);

has _raw_bounds => (
	is => 'lazy', # _build_raw_bounds
);

method _build_last_page_number() :ReturnType(PageNumber) {
	my $info = Renard::API::MuPDF::mutool::get_mutool_page_info_xml(
		$self->filename
	);

	return scalar @{ $info->{page} };
}

method get_rendered_page( (PageNumber) :$page_number, (ZoomLevel) :$zoom_level = 1.0 ) {
	return Renard::Block::Format::PDF::Page->new(
		document => $self,
		page_number => $page_number,
		zoom_level => $zoom_level,
	);
}

method _build_outline() {
	my $outline_data = Renard::API::MuPDF::mutool::get_mutool_outline_simple(
		$self->filename
	);

	return Renard::Incunabula::Outline->new( items => $outline_data );
}

method _build__raw_bounds() {
	my $info = Renard::API::MuPDF::mutool::get_mutool_page_info_xml(
		$self->filename
	);
}

method _build_identity_bounds() {
	my $compute_rotate_dim = sub {
		my ($info) = @_;
		my $theta_deg = $info->{rotate} // 0;
		my $theta_rad = $theta_deg * pi / 180;

		my ($x, $y) = ($info->{x}, $info->{y});
		my $poly = Math::Polygon->new(
			points => [
				[0, 0],
				[$x, 0],
				[$x, $y],
				[0, $y],
			],
		);

		my $rotated_poly = $poly->rotate(
			degrees => $theta_deg,
			center => [ $x/2, $y/2 ],
		);

		my ($xmin, $ymin, $xmax, $ymax) = $rotated_poly->bbox;


		return { w => $xmax - $xmin, h => $ymax - $ymin };
	};

	my $bounds = $self->_raw_bounds;
	my @page_xy = map {
		my $p = {
			x => $_->{CropBox}{r}-$_->{CropBox}{l},
			y => $_->{CropBox}{t}-$_->{CropBox}{b},
			rotate => $_->{Rotate}{v} // 0,
			pageno => $_->{pagenum},
		};
		if( exists $p->{rotate} ) {
			$p->{dims} = $compute_rotate_dim->( $p );
		}

		$p;
	} @{ $bounds->{page} };

	return \@page_xy;
}

method get_textual_page( (PageNumber) $page_number )
		:ReturnType(InstanceOf['String::Tagged']) {
	my $page_st = String::Tagged->new;

	my $stext = Renard::API::MuPDF::mutool::get_mutool_text_stext_xml(
		$self->filename,
		$page_number
	);

	my $levels = [ qw(document page block line font char) ];
	_walk_page_data( $page_st, $stext, 0, $levels );

	$page_st;
}

fun _walk_page_data( $tagged, $data, $depth, $levels ) {
	my $level_tagged = String::Tagged->new("");

	if( $depth == @$levels - 1 ) {
		# last level is the character, so we append that to the string
		$level_tagged .= $data->{c};
	} else {
		# empty pages will not have this data
		return unless exists $data->{ $levels->[$depth+1] };

		my @data_next = @{ $data->{ $levels->[$depth+1] } };
		for my $next_data (@data_next) {
			_walk_page_data( $level_tagged, $next_data, $depth+1, $levels );
		}
	}
	$level_tagged->apply_tag(0, $level_tagged->length, $levels->[$depth] => $data );

	$tagged->append_tagged($level_tagged);

	return;
}


with qw(
	Renard::Incunabula::Document::Role::FromFile
	Renard::Incunabula::Document::Role::Pageable
	Renard::Incunabula::Document::Role::Renderable
	Renard::Incunabula::Document::Role::Cacheable
	Renard::Incunabula::Document::Role::Outlineable
	Renard::Incunabula::Document::Role::Boundable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Block::Format::PDF::Document - document that represents a PDF file

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Renard::Incunabula::Document>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Document::Role::Boundable>

=item * L<Renard::Incunabula::Document::Role::Cacheable>

=item * L<Renard::Incunabula::Document::Role::FromFile>

=item * L<Renard::Incunabula::Document::Role::Outlineable>

=item * L<Renard::Incunabula::Document::Role::Pageable>

=item * L<Renard::Incunabula::Document::Role::Renderable>

=back

=head1 METHODS

=head2 get_rendered_page

  method get_rendered_page( (PageNumber) :$page_number )

See L<Renard::Incunabula::Document::Role::Renderable>.

=head2 get_textual_page

  method get_textual_page( (PageNumber) $page_number ) :ReturnType(InstanceOf['String::Tagged'])

Returns a L<String::Tagged> representation of the PDF textual data for a given
page. The return value contains tags that indicate the extent of each level as
defined by L<Renard::API::MuPDF::mutool::get_mutool_text_stext_xml>:

=over 4

=item *

C<page>,

=item *

C<block>,

=item *

C<line>,

=item *

C<span>, and

=item *

C<char>

=back

The values associated with these tags can be used to find the bounding box for
the symbols on the page.

=begin comment

=method _build_last_page_number

Retrieves the last page number of the PDF. Currently implemented through
C<mutool>.


=end comment

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
