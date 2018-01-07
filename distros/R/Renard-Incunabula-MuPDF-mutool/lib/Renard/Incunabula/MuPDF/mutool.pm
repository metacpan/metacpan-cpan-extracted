use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::MuPDF::mutool;
# ABSTRACT: Retrieve PDF image and text data via MuPDF's mutool
$Renard::Incunabula::MuPDF::mutool::VERSION = '0.004';
use Capture::Tiny qw(capture);
use XML::Simple;
use Alien::MuPDF 0.007;
use Path::Tiny;

use Log::Any qw($log);
use constant MUPDF_DEFAULT_RESOLUTION => 72; # dpi

use Renard::Incunabula::MuPDF::mutool::ObjectParser;

BEGIN {
	our $MUTOOL_PATH = Alien::MuPDF->mutool_path;
}

fun _call_mutool( @mutool_args ) {
	my @args = ( $Renard::Incunabula::MuPDF::mutool::MUTOOL_PATH, @mutool_args );
	my ($stdout, $exit);

	# Note: The code below is marked as uncoverable because it only applies
	# on Windows and we are currently only automatically checking coverage
	# on Linux via Travis-CI.
	# uncoverable branch true
	if( $^O eq 'MSWin32' ) {
		# Need to redirect to a file for two reasons:
		# - /SUBSYSTEM:WINDOWS closes stdin/stdout <https://github.com/project-renard/curie/issues/128>.
		# - MuPDF does not set the mode on stdout to binary <http://bugs.ghostscript.com/show_bug.cgi?id=694954>.
		my $temp_fh = File::Temp->new;                       # uncoverable statement
		close $temp_fh; # to avoid Windows file locking      # uncoverable statement

		my $output_param = 0;                                # uncoverable statement
		for my $idx (1..@args-2) {                           # uncoverable statement
			# uncoverable branch true
			if( $args[$idx] eq '-o'                      # uncoverable statement
				&& $args[$idx+1] eq '-' ) {
				$args[$idx+1] = $temp_fh->filename;  # uncoverable statement
				$output_param = 1;                   # uncoverable statement
			}
		}

		# uncoverable branch true
		if( not $output_param ) {                            # uncoverable statement
			# redirect into a temp file
			my $cmd = join " ",                          # uncoverable statement
				map { $_ =~ /\s/ ? "\"$_\"" : $_ }   # uncoverable statement
				@args;                               # uncoverable statement
			my $redir = $temp_fh->filename;              # uncoverable statement
			@args = ("$cmd > \"$redir\"");               # uncoverable statement
		}

		$log->infof("running mutool: %s", \@args);           # uncoverable statement
		system( @args );                                     # uncoverable statement
		$stdout = path( $temp_fh->filename )->slurp_raw;     # uncoverable statement
		$exit = $?;                                          # uncoverable statement
	} else {
		($stdout, undef, $exit) = capture {
			$log->infof("running mutool: %s", \@args);
			system( @args );
		};
	}

	die "Unexpected mutool exit: $exit" if $exit;

	return $stdout;
}

fun get_mutool_pdf_page_as_png($pdf_filename, $pdf_page_no, $zoom_level) {
	my $stdout = _call_mutool(
		qw(draw),
		qw( -r ), ($zoom_level * MUPDF_DEFAULT_RESOLUTION), # calculate the resolution
		qw( -F png ),
		qw( -o -),
		$pdf_filename,
		$pdf_page_no,
	);

	return $stdout;
}

fun get_mutool_text_stext_raw($pdf_filename, $pdf_page_no) {
	my $stdout = _call_mutool(
		qw(draw),
		qw(-F stext),
		qw(-o -),
		$pdf_filename,
		$pdf_page_no,
	);

	return $stdout;
}

fun get_mutool_text_stext_xml($pdf_filename, $pdf_page_no) {
	my $stext_xml = get_mutool_text_stext_raw(
		$pdf_filename,
		$pdf_page_no,
	);

	my $stext = XMLin( $stext_xml,
		KeyAttr => [],
		ForceArray => [ qw(page block line font char) ] );

	return $stext;
}

fun get_mutool_page_info_raw($pdf_filename) {
	my $stdout = _call_mutool(
		qw(pages),
		$pdf_filename
	);

	# remove the first line
	$stdout =~ s/^[^\n]*\n//s;

	# wraps the data with a root node
	return "<document>$stdout</document>"
}

fun get_mutool_page_info_xml($pdf_filename) {
	my $page_info_xml = get_mutool_page_info_raw( $pdf_filename );

	my $page_info = XMLin( $page_info_xml,
		KeyAttr => [],
		ForceArray => [ qw(page) ] );

	return $page_info;
}

fun get_mutool_outline_simple($pdf_filename) {
	my $outline_text = _call_mutool(
		qw(show),
		$pdf_filename,
		qw(outline)
	);

	my @outline_items = ();
	open my $outline_fh, '<:encoding(UTF-8):crlf', \$outline_text;
	while( defined( my $line = <$outline_fh> ) ) {
		$line =~ /^(?<indent>\t*)(?<text>.*)\t#(?<page>\d+)(,(?<dx>\d+),(?<dy>\d+))?$/;
		my %copy = %+;
		$copy{level} = length $copy{indent};
		delete $copy{indent};
		# not storing the offsets yet and not every line has offsets
		delete @copy{qw(dx dy)};
		push @outline_items, \%copy;
	}

	return \@outline_items;
}

fun get_mutool_get_trailer_raw($pdf_filename) {
	my $trailer_text = _call_mutool(
		qw(show),
		$pdf_filename,
		qw(trailer)
	);

	open my $trailer_fh, '<:encoding(UTF-8):crlf', \$trailer_text;
	do { local $/ = ''; <$trailer_fh> };
}

fun get_mutool_get_object_raw($pdf_filename, $object_id) {
	my $object_text = _call_mutool(
		qw(show),
		$pdf_filename,
		$object_id,
	);

	open my $object_fh, '<:encoding(UTF-8):crlf', \$object_text;
	do { local $/ = ''; <$object_fh> };
}

fun get_mutool_get_info_object_parsed( $pdf_filename ) {
	my $trailer = Renard::Incunabula::MuPDF::mutool::ObjectParser->new(
		filename => $pdf_filename,
		string => Renard::Incunabula::MuPDF::mutool::get_mutool_get_trailer_raw($pdf_filename),
	);

	my $info = $trailer->resolve_key('Info');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::MuPDF::mutool - Retrieve PDF image and text data via MuPDF's mutool

=head1 VERSION

version 0.004

=head1 FUNCTIONS

=head2 _call_mutool

  _call_mutool( @args )

Helper function which calls C<mutool> with the contents of the C<@args> array.

Returns the captured C<STDOUT> of the call.

This function dies if C<mutool> unsuccessfully exits.

=head2 get_mutool_pdf_page_as_png

  get_mutool_pdf_page_as_png($pdf_filename, $pdf_page_no)

This function returns a PNG stream that renders page number C<$pdf_page_no> of
the PDF file C<$pdf_filename>.

=head2 get_mutool_text_stext_raw

  get_mutool_text_stext_raw($pdf_filename, $pdf_page_no)

This function returns an XML string that contains structured text from page
number C<$pdf_page_no> of the PDF file C<$pdf_filename>.

The XML format is defined by the output of C<mutool> looks like this (for page
23 of the C<pdf_reference_1-7.pdf> file):

  <?xml version="1.0"?>
  <document name="(null)">
    <page height="666" width="531">
      <block bbox="261.18 616.16397 269.77766 625.2532">
        <line bbox="261.18 616.16397 269.77766 625.2532" dir="1 0" wmode="0">
          <font name="MyriadPro-Semibold" size="7.98">
            <char bbox="261.18 616.16397 265.45729 625.2532" c="2" x="261.18" y="623.2582"/>
            <char bbox="265.50038 616.16397 269.77766 625.2532" c="3" x="265.50038" y="623.2582"/>
          </font>
        </line>
      </block>
      <block bbox="225.78 88.20229 305.18159 117.93829">
        <line bbox="225.78 88.20229 305.18159 117.93829" dir="1 0" wmode="0">
          <font name="MyriadPro-Bold" size="24">
            <char bbox="225.78 88.20229 239.724 117.93829" c="P" x="225.78" y="111.93829"/>
            <char bbox="239.5176 88.20229 248.63759 117.93829" c="r" x="239.5176" y="111.93829"/>
            <char bbox="248.4552 88.20229 261.1272 117.93829" c="e" x="248.4552" y="111.93829"/>
            <char bbox="261.1128 88.20229 269.29679 117.93829" c="f" x="261.1128" y="111.93829"/>
          </font>
        </line>
      </block>
    </page>
  </document>

Simplified, the high-level structure looks like:

  <page> -> [list of blocks]
    <block> -> [list of blocks]
      a block is either:
        - stext
            <line> -> [list of lines] (all have same baseline)
              <font> -> [list of fonts] (horizontal spaces over a line)
                <char> -> [list of chars]
        - image
            # TODO document the image data from mutool

=head2 get_mutool_text_stext_xml

  get_mutool_text_stext_xml($pdf_filename, $pdf_page_no)

Returns a HashRef of the structured text from from page
number C<$pdf_page_no> of the PDF file C<$pdf_filename>.

See the function L<get_mutool_text_stext_raw|/get_mutool_text_stext_raw> for
details on the structure of this data.

=head2 get_mutool_page_info_raw

  get_mutool_page_info_raw($pdf_filename)

Returns an XML string of the page bounding boxes of PDF file C<$pdf_filename>.

The data is in the form:

  <document>
    <page pagenum="1">
      <MediaBox l="0" b="0" r="531" t="666" />
      <CropBox l="0" b="0" r="531" t="666" />
      <Rotate v="0" />
    </page>
    <page pagenum="2">
      ...
    </page>
  </document>

=head2 get_mutool_page_info_xml

  get_mutool_page_info_xml($pdf_filename)

Returns a HashRef containing the page bounding boxes of PDF file
C<$pdf_filename>.

See function L<get_mutool_page_info_raw|/get_mutool_page_info_raw> for
information on the structure of the data.

=head2 get_mutool_outline_simple

  fun get_mutool_outline_simple($pdf_filename)

Returns an array of the outline of the PDF file C<$pdf_filename> as an
C<ArrayRef[HashRef]> which corresponds to the C<items> attribute of
L<Renard::Incunabula::Outline>.

=head2 get_mutool_get_trailer_raw

  fun get_mutool_get_trailer_raw($pdf_filename)

Returns the trailer of the PDF file C<$pdf_filename> as a string.

=head2 get_mutool_get_object_raw

  fun get_mutool_get_object_raw($pdf_filename, $object_id)

Returns the object given by the ID C<$object_id> for PDF file C<$pdf_filename>
as a string.

=head2 get_mutool_get_info_object_parsed

  fun get_mutool_get_info_object_parsed( $pdf_filename )

Returns the document information dictionary as a
L<Renard::Incunabula::MuPDF::mutool::ObjectParser> object.

See Table 10.2 on pg. 844 of the I<PDF Reference, version 1.7> to see the
entries that usually used (e.g., Title, Author).

=head1 SEE ALSO

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Renard-Incunabula-MuPDF-mutool/>

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
