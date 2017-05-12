package Template::Flute::PDF;

use strict;
use warnings;

use Data::Dumper;

use File::Basename;
use File::Spec;
use Math::Trig;

use PDF::API2;
use PDF::API2::Util;

use Template::Flute::Style::CSS;

use Template::Flute::PDF::Import;
use Template::Flute::PDF::Box;

=head1 NAME

Template::Flute::PDF - PDF generator for HTML templates

=head1 VERSION

Version 0.0042

=cut

our $VERSION = '0.0042';

=head1 SYNOPSIS

  $flute = Template::Flute->new (specification_file => 'invoice.xml',
                                 template_file => 'invoice.html',
                                 values => \%values);
  $flute->process();

  $pdf = Template::Flute::PDF->new (template => $flute->template(),
                                    file => 'invoice.pdf');

  $pdf->process();

=head1 DESCRIPTION

Template::Flute::PDF is a PDF generator based on L<Template::Flute>
and L<PDF::API2>.

=head2 OUTPUT

To obtain the PDF as a string instead of writing it to a file,
please simply leave out the file parameter when creating the Template::Flute::PDF
object:

   $pdf = Template::Flute::PDF->new (template => $flute->template(),
                                     file => 'invoice.pdf');

   $pdf_as_string = $pdf->process();

=head2 UNITS

Template::Flute::PDF uses the pt unit internally.

In addition, the following units are supported and automatically
converted by this module:

=over 4

=item in

An inch converts to 72 pt.

=item cm

A centimeter converts to approximately 28.3 pt.

=item mm

A millimeter converts to approximately 2.8 pt.

=item px

A pixel converts to 1 pt.

=back

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::PDF object with the following parameters:

=over 4

=item template

L<Template::Flute::HTML> object.

=item file

PDF output file.

=item page_size

Page size for the PDF (default: A4).

=item html_base

Base directory for HTML resources like images and stylesheets.

=item import

Import parameters for L<Template::Flute::PDF::Import>.

=back

=head3 Margin parameters

=over 4

=item margin_top

Top margin, defaults to 20.

=item margin_right

Right margin, defaults to 20.

=item margin_bottom

Bottom margin, defaults to 50.

=item margin_left

Left margin, defaults to 20.

=back

=cut

# defaults
use constant FONT_FAMILY => 'Helvetica';
use constant FONT_SIZE => '12';
use constant PAGE_SIZE => 'a4';
use constant MARGINS => (20, 20, 50, 20);

# font map for PDF core fonts (see PDF::API2::Resource::Font::CoreFont)
our %font_map = (Courier => {Bold => 'Courier-Bold',
			     BoldItalic => 'Courier-BoldOblique',
			     Italic => 'Courier-Oblique',
			     Roman => 'Courier',
		 },
		 Georgia => {Bold => 'Georgia,Bold',
			     BoldItalic => 'Georgia,BoldItalic',
			     Italic => 'Georgia,Italic',
			     Roman => 'Georgia',
		 },
		 Helvetica => {Bold => 'Helvetica-Bold',
			       BoldItalic => 'Helvetica-BoldOblique',
			       Italic => 'Helvetica-Oblique',
			       Roman => 'Helvetica',
		 },
		 Symbol => {},
		 Times => {Bold => 'Times-Bold',
			   BoldItalic => 'Times-BoldItalic',
			   Roman => 'Times',
			   Italic => 'Times-Italic'
		 },
		 Verdana => {Bold => 'Verdana,Bold',
			     BoldItalic => 'Verdana,BoldItalic',
			     Italic => 'Verdana,Italic',
			     Roman => 'Verdana',
		 },
		 Webdings => {},
		 Wingdings => {},
		 ZapfDingbats => {},
    );

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};
	bless ($self, $class);
	
	if ($self->{template}) {
		$self->{xml} = $self->{template}->root();
		$self->{css} = new Template::Flute::Style::CSS(template => $self->{template});
	}

	# create PDF::API2 object
	if ($self->{file}) {
		$self->{pdf} = new PDF::API2(-file => $self->{file});
	}
	else {
		$self->{pdf} = new PDF::API2();
	}

	# font cache
	$self->{_font_cache} = {};

	# page size
	if ($self->{page_size}) {
		$self->set_page_size(delete $self->{page_size});
	}
	else {
		$self->set_page_size(PAGE_SIZE);
	}

	# page orientation
	unless ($self->{orientation}) {
	    $self->{orientation} = '';
	}

	# margins
	my @sides = qw(top right bottom left);
	
	for (my $i = 0; $i < @sides; $i++) {
	    $self->{'margin_' . $sides[$i]} ||= (MARGINS)[$i];
	}
	
	bless ($self, $class);
}

=head1 METHODS

=head2 process

Processes HTML template and creates PDF file.

=cut

sub process {
	my $self = shift;
	my ($file, $font);

    if (@_) {
        $file = shift;
    }
    else {
        $file = $self->{file};
    }
    
	$self->{cur_page} = 1;

	$self->{border_left} = to_points($self->{margin_left}, 'pt');
	$self->{border_right} = $self->{page_width} - to_points($self->{margin_right}, 'pt');

	$self->{border_top} = $self->{page_height} - to_points($self->{margin_top}, 'pt');
	$self->{border_bottom} = to_points($self->{margin_bottom}, 'pt');

	$self->{vpos_next} = $self->{border_top};
	
	$self->{hpos} = $self->{border_left};

	if ($self->{verbose}) {
		print "Starting page at X $self->{hpos} Y $self->{y}.\n";
		print "Borders are T $self->{border_top} R $self->{border_right} B $self->{border_bottom} L $self->{border_left}.\n\n";
	}

	my %h = $self->{pdf}->info(
	    'Producer' => "Template::Flute::PDF $VERSION",
	);

	if ($self->{import}) {
		my ($obj, $ret, %import_parms);

		if (ref($self->{import})) {
			%import_parms = %{$self->{import}};
		}
		else {
			%import_parms = (file => $self->{import});
		}

		$import_parms{pdf} = $self->{pdf};
		
		$obj = new Template::Flute::PDF::Import;
		
		unless ($ret = $obj->import(%import_parms)) {
			die "Failed to import file $import_parms{file}.\n";
		}

#		if ($self->{verbose} || 1) {
#			print "Imported PDF $self->{import}: $ret->{pages} pages.\n\n";
#		}

		$self->{page} = $ret->{cur_page};
#		$pdf->saveas();
#		return;
	}

	# Open first page
	$self->{page} ||= $self->{pdf}->page($self->{cur_page});

	$self->{pdf}->preferences(
					  -fullscreen => 0,
					  -singlepage => 1,
					  -afterfullscreenoutlines => 1,
					  -firstpage => [ $self->{page} , -fit => 0],
					  -displaytitle => 1,
					  -fitwindow => 0,
					  -centerwindow => 1,
					  -printscalingnone => 1,
	);
	
	# retrieve default settings for font etc from CSS
	my $css_defaults = $self->{css}->properties(tag => 'body');

	# set font
	if ($css_defaults->{font}->{family}) {
		$self->{fontfamily} = $self->_font_select($css_defaults->{font}->{family});
	}
	else {
		$self->{fontfamily} = FONT_FAMILY;
	}
	
	if ($css_defaults->{font}->{size}) {
		$self->{fontsize} = to_points($css_defaults->{font}->{size});
	}
	else {
		$self->{fontsize} = FONT_SIZE;
	}

	if ($css_defaults->{font}->{weight}) {
		$self->{fontweight} = $css_defaults->{font}->{weight};
	}
	else {
		$self->{fontweight} = '';
	}

	$font = $self->font($self->{fontfamily}, $self->{fontweight});
	
	$self->{page}->text->font($font, $self->{fontsize});

	# move to starting point
	$self->{page}->text->translate($self->{border_left}, $self->{border_top});

	# page orientation
	if ($self->{orientation} eq 'landscape') {
	    $self->{page}->rotate(90);
	}

	# now walk HTML document and add appropriate parts
	my ($root_box, @root_parms);

	@root_parms = (pdf => $self,
				   elt => $self->{xml},
				   bounding => {vpos => $self->{border_top},
								hpos => $self->{border_left},
								max_w => $self->{border_right} - $self->{border_left},
								max_h => $self->{border_top} - $self->{border_bottom}});

	$root_box = new Template::Flute::PDF::Box(@root_parms);

	# calculate sizes
	$root_box->calculate();

	# align
	$root_box->align();
	
	# page partitioning
	$root_box->partition(1, 0);

	# render
	$root_box->render(vpos => $self->{border_top},
					  hpos => $self->{border_left});
	
#	$self->walk_template($self->{xml});

	if ($file) {
	    $self->{pdf}->saveas($file);
	    return 1;
	}

	return $self->{pdf}->stringify;
}

sub template {
	my $self = shift;
	
	return $self->{template};
}

=head2 set_page_size

Sets the page size for the PDF.

=cut

sub set_page_size {
	my ($self, @args) = @_;
	my ($ret, @ps);

	if (ref($args[0]) eq 'ARRAY') {
		@args = @{$args[0]};
	}
	
	if (@args > 1) {
		# passing page size as numbers
		@ps = map {to_points($_, 'pt')} @args;
		($self->{page_width}, $self->{page_height}) = @ps;
	}
	else {
		# resolve page size
		unless ($self->{_paper_sizes}) {
			$self->{_paper_sizes} = {getPaperSizes()};
		}

		if (exists $self->{_paper_sizes}->{lc($args[0])}) {
			($self->{page_width}, $self->{page_height})
				= @{$self->{_paper_sizes}->{lc($args[0])}};
		}
		else {
			die "Invalid paper size $args[0]";
		}
			
		$ps[0] = $args[0];
	}
	
	$self->{_page_size} = \@ps;

	$self->{pdf}->mediabox(@ps);
}

=head2 select_page PAGE_NUM
	
Selects page with the given PAGE_NUM. Creates new page if necessary.

=cut

sub select_page {
	my ($self, $page_num) = @_;
	my ($diff, $cur_page);
	
	if ($page_num > $self->{pdf}->pages()) {
		$diff = $page_num - $self->{pdf}->pages();

		for (my $i = 0; $i < $diff; $i++) {
			$cur_page = $self->{pdf}->page();
		}
	}
	else {
		$cur_page = $self->{pdf}->openpage($page_num);
	}

	$self->{page} = $cur_page;
}

=head2 content_height

Returns the height of the content part of the page.

=cut
	
sub content_height {
	my ($self) = @_;
	my ($height);

	return $self->{page_height};
}

=head2 content_width

Returns the width of the content part of the page.

=cut
	
sub content_width {
	my ($self) = @_;
	my ($width);
	
	$width = $self->{page_width} - to_points($self->{margin_left}, 'pt') 
	    - to_points($self->{margin_right}, 'pt');

	return $width;
}

=head2 bounding

Returns the bounding box for the PDF as a hash reference
with the following key/value pairs:

=over 4

=item vpos

Top vertical position.

=item pos

Left horizonal position.

=item max_w

Maximum width.

=item max_h

Maximum height.

=back

The bounding box defines the available space without
the borders.

=cut

sub bounding {
    my $self = shift;
    
    return {vpos => $self->{border_top},
            hpos => $self->{border_left},
            max_w => $self->{border_right} - $self->{border_left},
            max_h => $self->{border_top} - $self->{border_bottom},
    };
}

=head2 font NAME [weight] [style]

Returns PDF::API2 font object for font NAME, WEIGHT and STYLE are optional.

=cut
	
sub font {
	my ($self, $name, $weight, $style) = @_;
	my ($key, $obj);

    if ($weight eq 'normal') {
        # default font weight
        $weight = '';
    }

	# determine font name from supplied name and optional weight
	if ($weight) {
	    if ($style) {
            $key = "$name-$weight$style";
        }
        else {
            $key = "$name-$weight";
        }
	}
	elsif ($style) {
	    if (exists $font_map{$name}->{$style}) {
            $key = $font_map{$name}->{$style};
	    }
	    else {
            $key = "$name-$style";
	    }
	}
	else {
		$key = $name;
	}
		
	if (exists $self->{_font_cache}->{$key}) {
		# return font object from cache
		return $self->{_font_cache}->{$key};
	}

	# create new font object
	$obj = $self->{pdf}->corefont($key, -encoding => 'latin1');

	$self->{_font_cache}->{$key} = $obj;
	
	return $obj;
}

=head2 text_filter TEXT

Adjusts whitespace in TEXT for output in PDF.

=cut
	
sub text_filter {
	my ($self, $text, $transform) = @_;
	my ($orig);
	
	# fall back to empty string
	unless (defined $text) {
		return '';
	}

	$orig = $text;
	
	# replace newlines with blanks
	$text =~ s/\n/ /gs;

	# collapse blanks
	$text =~ s/\s+/ /g;

	if (length $orig && ! length $text) {
		# reduce not further than a single whitespace
		return ' ';
	}

	# transform text analogous to CSS specification
	if (defined $transform) {
		if ($transform eq 'uppercase') {
			$text = uc($text);
		}
		elsif ($transform eq 'lowercase') {
			$text = lc($text);
		}
		elsif ($transform eq 'capitalize') {
			$text =~ s/\b(\w)/\u$1/g;
		}
		elsif ($transform ne 'none') {
			die "Unknown transformation $transform\n";
		}
	}
	
	return $text;
}

=head2 setup_text_props ELT SELECTOR [INHERIT]

Determines text properties for HTML template element ELT, CSS selector SELECTOR
and INHERIT flag.

=cut

sub setup_text_props {
	my ($self, $elt, $selector, $inherit) = @_;
	my ($props, %borders, %padding, %margins, %offset, $fontsize, $fontfamily,
		$fontweight, $fontstyle, $txeng);

	my $class = $elt->att('class') || '';
	my $id = $elt->att('id') || '';
	my $gi = $elt->gi();

	$selector ||= '';
	
	# get properties from CSS
	$props = $self->{css}->properties(id => $id,
									  class => $elt->att('class'),
									  tag => $elt->gi(),
									  selector => $selector,
									  inherit => $inherit,
									 );
			
	$txeng = $self->{page}->text;

	if ($props->{font}->{size}) {
	    if ($props->{font}->{size} =~ s/^(\d+)(pt)?$/$1/) {
		$fontsize =  $props->{font}->{size};
	    }
	    else {
		$fontsize = to_points($props->{font}->{size});
	    }
	}
	else {
		$fontsize = $self->{fontsize};
	}

	if ($props->{font}->{family}) {
		$fontfamily = $self->_font_select($props->{font}->{family});
	}
	else {
		$fontfamily = $self->{fontfamily};
	}

	if ($props->{font}->{weight}) {
		$fontweight = $props->{font}->{weight};
	}
	else {
		$fontweight = $self->{fontweight};
	}

    if ($props->{font}->{style}) {
        $fontstyle = $props->{font}->{style};
    }
    elsif ($gi eq 'i') {
        $fontstyle = 'Italic';
    }

	$self->{font} = $self->font($fontfamily, $fontweight,
	    $fontstyle);
	
	$txeng->font($self->{font}, $fontsize);

	if ($gi eq 'hr') {
		unless (keys %{$props->{margin}}) {
			# default margins for horizontal rule
			my $margin;

			$margin = 0.5 * $fontsize;

			$props->{margin} = {top => $margin,
								bottom => $margin};
		}
	}
				
	# offsets from border, padding etc.
	for my $s (qw/top right bottom left/) {
		$borders{$s} = to_points($props->{border}->{$s}->{width});
		$margins{$s} = to_points($props->{margin}->{$s});
		$padding{$s} = to_points($props->{padding}->{$s});

		$offset{$s} += $margins{$s} + $borders{$s} + $padding{$s};
	}

	# height and width
	$props->{width} = to_points($props->{width});
	$props->{height} = to_points($props->{height});
	
	return {font => $self->{font}, size => $fontsize, offset => \%offset,
			borders => \%borders, margins => \%margins, padding => \%padding, props => $props,
			# for debugging
			class => $class, selector => $selector
		   };
}

=head2 calculate ELT [PARAMETERS]

Calculates width and height for HTML template element ELT.

=cut	
	
sub calculate {
	my ($self, $elt, %parms) = @_;
	my ($text, $chunk_width, $text_width, $max_width, $avail_width, $height, $specs, $txeng,
		$overflow_x, $overflow_y, $clear_before, $clear_after, @chunks, $buf, $lines);
	
	$txeng = $self->{page}->text();
	$max_width = 0;
	$height = 0;
	$overflow_x = $overflow_y = 0;
	$clear_before = $clear_after = 0;
	$lines = 1;

	if ($parms{specs}) {
		$specs = $parms{specs};
	}
	else {
		$specs = $self->setup_text_props($elt);
	}

	if ($specs->{props}->{width}) {
		$avail_width = $specs->{props}->{width};
	}
	else {
		$avail_width = $self->content_width();
	}

	if (ref($parms{text}) eq 'ARRAY') {
		$buf = '';
		$text_width = 0;
		
		for my $text (@{$parms{text}}) {
			if ($text eq "\n") {
				# force newline
				push (@chunks, $buf . $text);
				$buf = '';
				$text_width = 0;
				$lines++;
			}
			elsif ($text =~ /\S/) {
				$chunk_width = $txeng->advancewidth($text, font => $specs->{font},
												   fontsize => $specs->{size});
			}
			else {
				# whitespace
				$chunk_width = $txeng->advancewidth("\x20", font => $specs->{font},
												   fontsize => $specs->{size});
			}

			if ($avail_width
				&& $text_width + $chunk_width > $avail_width) {
#				print "Line break by long text: $buf + $text\n";

				push (@chunks, $buf);
				$buf = $text;
				$text_width = 0;
				$lines++;
			}
			else {
				$buf .= $text;
			}

			$text_width += $chunk_width;
			
			if ($text_width > $max_width) {
				$max_width = $text_width;
			}
		}

		if (length($buf)) {
			push (@chunks, $buf);
		}
	}

	if ($parms{clear} || $specs->{props}->{clear} eq 'both') {
		$clear_before = $clear_after = 1;
	}
	elsif ($specs->{props}->{clear} eq 'left') {
		$clear_before = 1;		
	}
	elsif ($specs->{props}->{clear} eq 'right') {
		$clear_after = 1;
	}
	
#	print "Before offset: MW $max_width H $height S $specs->{size}, ", Dumper($specs->{offset}) . "\n";
	
#	print "PW $avail_width, PH $specs->{props}->{height}, MW $max_width H $height\n";

	# line height
	if (exists $specs->{props}->{line_height}) {
		$height = $lines * to_points($specs->{props}->{line_height});
	}
	else {
		$height = $lines * $specs->{size};
	}

	# adjust to fixed width
	if ($avail_width) {
		if ($avail_width < $max_width) {
			$overflow_x = $max_width - $avail_width;
			$max_width = $avail_width;
		}
	}

	# adjust to fixed height
	if ($specs->{props}->{height}) {
		if ($specs->{props}->{height} < $height) {
			$overflow_y = $height - $specs->{props}->{height};
			$height = $specs->{props}->{height};
		}
		else {
			$height = $specs->{props}->{height};
		}
	}
	
	return {width => $max_width, height => $height, size => $specs->{size},
			clear => {before => $clear_before, after => $clear_after},
			overflow => {x => $overflow_x, y => $overflow_y},
			text_width => $text_width,
			chunks => \@chunks,
		   };
}

=head2 check_out_of_bounds POS DIM

Check whether we are out of bounds with position POS and dimensions DIM.

=cut

sub check_out_of_bounds {
	my ($self, $pos, $dim) = @_;

	if ($pos->{hpos} == $self->{border_right}) {
		# we are on the left border, so even if the box is out
		# of bounds, we have no better idea :-)
		return;
	}
	
#	print "COB pos: " . Dumper($pos) . "COB dim: " . Dumper($dim);
#	print "NEXT: $self->{vpos_next}.\n";

	if ($pos->{hpos} + $dim->{width} > $self->{border_right}) {
		return {hpos => $self->{border_left}, vpos => $self->{vpos_next}};
	}
	
	return;
}

=head2 textbox ELT TEXT PROPS BOX ATTRIBUTES

Adds textbox for HTML template element ELT to the PDF.

=cut

sub textbox {
	my ($self, $elt, $boxtext, $boxprops, $box, %atts) = @_;
	my ($width_last, $y_top, $y_last, $left_over, $text_width, $text_height, $box_height);
	my (@tb_parms, %parms, $txeng, %offset, %borders, %padding, $props,
		$paragraph, $specs, %text_options, $decoration);

	if ($boxprops) {
		$specs = $boxprops;
	}
	else {
		# get specifications from CSS
		$specs = $self->setup_text_props($elt);
	}

#	unless ($specs->{borders}) {
#		delete $specs->{font};
#		print "Elt: ", $elt->sprint(), "\n";
#		print "Specs for textbox: " . Dumper($specs) . "\n";
#	}
	
	$props = $specs->{props};
	%borders = %{$specs->{borders}};
	%offset = %{$specs->{offset}};
	%padding = %{$specs->{padding}};

	if ($box) {
#		print "Set from box: " . Dumper($box) . " for size $specs->{size}\n";
		$self->{hpos} = $box->{hpos};
		$self->{y} = $box->{vpos};
	}

	$txeng = $self->{page}->text;
	$txeng->font($specs->{font}, $specs->{size});
	
#print "Starting pos: X $self->{hpos} Y $self->{y}\n";
	$txeng->translate($self->{hpos}, $self->{y});
	
	# determine resulting horizontal position
	$text_width = $txeng->advancewidth($boxtext);
#print "Hpos after: " . $text_width . "\n";

	# now draw the background for text box
	if ($props->{background}->{color}) {
#		print "Background for text box: $props->{background}->{color}\n";
		$self->rect($self->{hpos}, $self->{y},
					$self->{hpos} + $text_width, $self->{y} - $padding{top} - $specs->{size} - $padding{bottom},
					$props->{background}->{color});
	}

	# colors
	if ($props->{color}) {
		$txeng->fillcolor($props->{color});		
	}
	
	%parms = (x => $self->{hpos},
			  y => $self->{y} - $specs->{size},
			  w => $self->content_width(),
			  h => to_points(100),
			  lead => $specs->{size},
#			  align => $props->{text}->{align} || 'left',
			  align => 'left',
			 );
		
	@tb_parms = ($txeng,  $boxtext, %parms);

#print "Add textbox (class " . ($elt->att('class') || "''") . ") with content '$boxtext' at $parms{y} x $parms{x}, border $offset{top}\n";

	if ($decoration = $props->{text}->{decoration}) {
	    if ($decoration eq 'underline') {
                $text_options{'-underline'} = 1;
            }
	}

	if (length($boxtext) && $boxtext =~ /\S/) {
	    if ($props->{line_height}) {
		# adjust text position accordingly
		$parms{y} -= (to_points($props->{line_height}) - $specs->{size}) / 2;
	    }
	    # try different approach
	    if (exists $props->{rotate}) {
		$txeng->translate($parms{x}, $parms{y});
		$txeng->transform_rel(-rotate => 360 - $props->{rotate});
	    }
	    else {
		$txeng->translate($parms{x}, $parms{y});
	    }

	    $txeng->text($boxtext, %text_options);
	}
	else {
		$y_last = $parms{y};
	}

	$txeng->fill();
}

=head2 hline SPECS HPOS VPOS LENGTH WIDTH

Add horizontal line to PDF.

=cut
	
sub hline {
	my ($self, $specs, $hpos, $vpos, $width, $height) = @_;
	my ($gfx);

	$gfx = $self->{page}->gfx;

	$self->begin_transform($gfx, $hpos, $vpos - $height / 2, $width, $height || 1, $specs->{props});

	# set line color
	$gfx->strokecolor($specs->{props}->{color});

	# set line width
	$gfx->linewidth($height || 1);

	$gfx->line($width, 0);
	
	# draw line
	$gfx->stroke();

	$self->end_transform($gfx, $hpos, $vpos - $height / 2, $width, $height || 1, $specs->{props});

	return;
}

=head2 borders X_LEFT Y_TOP WIDTH HEIGHT

Adds borders to the PDF.

=cut

sub borders {
	my ($self, $x_left, $y_top, $width, $height, $specs) = @_;
	my ($gfx);
	
	$gfx = $self->{page}->gfx;
	
	if ($specs->{borders}->{top}) {
		$gfx->strokecolor($specs->{props}->{border}->{top}->{color});
		$gfx->linewidth($specs->{borders}->{top});
		$gfx->move($x_left, $y_top - $specs->{borders}->{top} * 0.5);
		$gfx->line($x_left + $width, $y_top - $specs->{borders}->{top} * 0.5);
		$gfx->stroke();
	}

	if ($specs->{borders}->{left}) {
		$gfx->strokecolor($specs->{props}->{border}->{left}->{color});
		$gfx->linewidth($specs->{borders}->{left});
		$gfx->move($x_left + 0.5 * $specs->{borders}->{left}, $y_top);
		$gfx->line($x_left + 0.5 * $specs->{borders}->{left} , $y_top - $height); #- $specs->{borders}->{top});
	    
		$gfx->stroke();
	}
	
	if ($specs->{borders}->{bottom}) {
		$gfx->strokecolor($specs->{props}->{border}->{bottom}->{color});
		$gfx->linewidth($specs->{borders}->{bottom});
		$gfx->move($x_left, $y_top - $height + 0.5 * $specs->{borders}->{bottom} );
		$gfx->line($x_left + $width, $y_top - $height +  0.5 * $specs->{borders}->{bottom} );
		$gfx->stroke();
	}

	if ($specs->{borders}->{right}) {
		$gfx->strokecolor($specs->{props}->{border}->{right}->{color});
		$gfx->linewidth($specs->{borders}->{right});
		$gfx->move($x_left + $width - 0.5 * $specs->{borders}->{right}, $y_top);
		$gfx->line($x_left + $width  - 0.5 * $specs->{borders}->{right}, $y_top - $height);
		$gfx->stroke();
	}
}

=head2 rect X_LEFT Y_TOP X_RIGHT Y_BOTTOM COLOR

Adds rectangle to the PDF.

=cut

# primitives
sub rect {
	my ($self, $x_left, $y_top, $x_right, $y_bottom, $color) = @_;
	my ($gfx);

	$gfx = $self->{page}->gfx;

	if ($color) {
		$gfx->fillcolor($color);
	}

	$gfx->rectxy($x_left, $y_top, $x_right, $y_bottom);

	if ($color) {
		$gfx->fill();
	}
}

=head2 locate_image

Determines location of an image file from the C<src> HTML
attribute.

    $imgfile = $pdf->locate_image('images/cart.png');

The location is based on the current directory, or on
the C<html_base> constructor parameter if the C<src> HTML
attribute contains a single file name only.
 
=cut

sub locate_image {
    my ($self, $src) = @_;
    my ($img_dir, $template_dir, $img_file);

    if ($self->{swap_images}) {
	for my $href (@{$self->{swap_images}}) {
	    if ($href->{src} eq $src) {
		$src = $href->{path};
	    }
	}
    }

    $img_dir = dirname($src);
    $img_file = $src;

    if ($img_dir eq '.') {
	# check whether HTML template is located in another directory
	$template_dir = dirname($self->template()->file());

	if ($template_dir ne '.') {
	    if ($self->{html_base}) {
		$img_file = File::Spec->catfile($self->{html_base},
					   basename($src));
	    }
	    else {
		$img_file = File::Spec->catfile($template_dir,
						basename($src));
	    }
	}
    }

    return $img_file;
}

=head2 image OBJECT HPOS VPOS WIDTH HEIGHT

Add image OBJECT to the PDF.

=cut

sub image {
	my ($self, $object, $x_left, $y_top, $width, $height, $specs) = @_;
	my ($gfx, $method, $image_object);

	$gfx = $self->{page}->gfx;
	
	$method = 'image_' . $object->{type};

	$image_object = $self->{pdf}->$method($object->{file});

	$gfx->image($image_object, $x_left, $y_top, $width, $height);
}

=head2 begin_transform

Starts transformation of current content object.

=cut

sub begin_transform {
    my ($self, $gfx, $hpos, $vpos, $width, $height, $props) = @_;

    $gfx->move(0,0);
 
    if (exists $props->{translate}->{x}) {
	$hpos += to_points($props->{translate}->{x});
    }

    if (exists $props->{translate}->{y}) {
	$vpos -= to_points($props->{translate}->{y});
    }

    $gfx->translate($hpos, $vpos);
    
    if ($props->{rotate}) {
	$gfx->rotate(- $props->{rotate});
    }
}

=head2 end_transform

Ends transformation of current content object.

=cut

sub end_transform {
    my ($self, $gfx, $hpos, $vpos, $width, $height, $props) = @_;
    
    if ($props->{rotate}) {
	$gfx->rotate($props->{rotate});
    }

    if (exists $props->{translate}->{x}) {
	$hpos += to_points($props->{translate}->{x});
    }

    if (exists $props->{translate}->{y}) {
	$vpos -= to_points($props->{translate}->{y});
    }

    $gfx->translate(-$hpos, -$vpos);
}

=head1 FUNCTIONS

=head2 to_points [DEFAULT_UNIT]
	
Converts widths to points, default unit is mm.

=cut
	
sub to_points {
	my ($width, $default_unit) = @_;
	my ($unit, $points, $negative);

	return 0 unless defined $width;

	if ($width =~ s/^(-?)(\d+(\.\d+)?)\s?(in|px|pt|cm|mm)?$/$2/) {
	    $negative = $1;
	    $unit = $4 || $default_unit || 'mm';
	}
	else {
		warn "Invalid width $width\n";
		return;
	}

	if ($unit eq 'in') {
		# 72 points per inch
		$points = 72 * $width;
	}
	elsif ($unit eq 'cm') {
		$points = 72 * $width / 2.54;
	}
	elsif ($unit eq 'mm') {
		$points = 72 * $width / 25.4;
	}
	elsif ($unit eq 'pt') {
		$points = $width;
	}
	elsif ($unit eq 'px') {
		$points = $width;
	}

	if ($negative) {
	    return - $points;
	}

	return $points;
}

# auxiliary methods

# select font from list provided by CSS (currently just the first)

sub _font_select {
	my ($self, $font_string) = @_;
	my (@fonts);

	@fonts = split(/,/, $font_string);

	return $fonts[0];
}

=head1 SUPPORTED HTML/CSS SYNTAX

This is an incomplete list of supported HTML/CSS syntax.

=head2 HTML tags and attributes

<i>

=head3 style

The HTML attribute "style" is not supported.

=head2 CSS properties

=head3 display

The CSS property "display" is not supported.

=head3 font-weight

The values "normal" and "bold" are supported.

=head3 min-height

The CSS property "min-height" is supported.

=head3 min-width

The CSS property "min-width" is supported.
    
=head3 text-transformation

The CSS property "text-transformation" is supported with
the exception of the value "inherit".

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 BUGS

Certainly a lot, as converting from HTML to PDF is quite complicated and challenging.

Please report any unknown bugs or feature requests to C<bug-template-flute-pdf at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Flute-PDF>.

=head2 KNOWN BUGS

=over 4

=item Background color

Using background color hides text.

=item Vertical align

We currently support only aligning to top or bottom of the available space.
This is in contradiction to HTML, where the default vertical align 
is baseline (of the text).

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Flute::PDF

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Flute-PDF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Flute-PDF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Flute-PDF>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Flute-PDF/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
