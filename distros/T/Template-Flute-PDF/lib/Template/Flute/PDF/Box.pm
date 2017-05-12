package Template::Flute::PDF::Box;

use strict;
use warnings;

use Data::Dumper;

use Template::Flute::PDF::Image;
use Template::Flute::PDF::Table;

=head1 NAME

Template::Flute::PDF::Box - PDF boxes class

=head1 CONSTRUCTOR

=head2 new

Creates a Template::Flute:PDF::Box object with the following parameters:

=over 4

=item pdf

Template::Flute::PDF object (required).

=item elt

Corresponding HTML template element for the box (required).

=back

=cut

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);
	my ($elt_class, $elt_id, @p);
	
	$class = ref($proto) || $proto;
	$self = {@args};

	unless ($self->{pdf}) {
		die "Missing PDF object\n";
	}
	
	unless ($self->{elt}) {
		die "Missing Twig element for PDF box\n";
	}

	# Record corresponding GI for box
	$self->{gi} = $self->{elt}->gi();

	# Record corresponding CLASS for box
	$elt_class = $self->{elt}->att('class');

	if (defined $elt_class) {
		$self->{class} = $elt_class;
	}
	else {
		$self->{class} = '';
	}

	# Record corresponding ID for box
	$elt_id = $self->{elt}->att('id');

	if (defined $elt_id) {
		$self->{id} = $elt_id;
	}
	else {
		$self->{id} = '';
	}
	
	# Page for element
	$self->{page} ||= 1;
	
	# Mapping child elements to box objects
	$self->{eltmap} = {};

	# Stack of child elements
	$self->{eltstack} = [];

	# Positions of child elements
	$self->{eltpos} = [];

	# Stripes with child elements
	$self->{stripes} = [];
	
	# Height of these stripes
	$self->{stripe_heights} = [];

	bless ($self, $class);

	# Create selector map
	@p = (id => $self->{id}, class => $self->{class}, parent => $self->{selector_map}, tag => $self->{gi});
	
	$self->{selector_map} = $self->{pdf}->{css}->descendant_properties(@p);
		
	unless ($self->{specs}) {
		$self->setup_specs();
	}

	# Determine our window from bounding box
	%{$self->{window}} = %{$self->{bounding} || $self->{pdf}->bounding};

	if ($self->{specs}->{props}->{width}) {
#		print "Reducing WINDOW width to GI $self->{gi} CLASS $self->{class} to $self->{specs}->{props}->{width}\n";
		$self->{window}->{max_w} = $self->{specs}->{props}->{width};
	}
	if ($self->{specs}->{props}->{height}) {
#		print "Reducing WINDOW height to GI $self->{gi} CLASS $self->{class} to $self->{specs}->{props}->{height}\n";
		$self->{window}->{max_h} = $self->{specs}->{props}->{height};
	}
	
	return $self;
}

=head1 FUNCTIONS

=head2 calculate

Calculates dimensions of the box.

=head3 Images

The width and height of an image is determined according to
the following priority list.

=over 4

=item 1.

From width/height attribute of the <img> HTML tag.

=item 2.

From corresponding CSS width/height property.

=item 3.

From width/height of the image.

=back

=cut

sub calculate {
	my ($self) = @_;
	my ($gi, $class, $text, @parms, $childbox, $dim);
	my ($max_width, $max_height) = (0,0);
    my ($min_width, $min_height);
    
	if ($self->{elt}->is_text()) {
		# simple text box
		$text = $self->{elt}->text();

		# filter text and break into chunks to remove unnecessary whitespace
		$text = $self->{pdf}->text_filter($text, $self->property('text', 'transform'));
		
		# break text first
		my @frags;

		while ($text =~ s/^(.+?)\s+//) {
			push (@frags, $1, ' ');
		}

		if (length($text)) {
			push (@frags, $text);
		}
		
		$self->{box} = $self->{pdf}->calculate($self->{elt}, text => \@frags,
											  specs => $self->{specs});

#		print "Check width $self->{box}->{width}, height $self->{box}->{height}, $self->{box}->{overflow}->{x} vs $self->{window}->{max_w} for $text\n";
		
		if ($self->{box}->{overflow}->{x}) {
			warn "Uh oh, out of bounds for $text: $self->{box}->{overflow}->{x}\n";
		}

		return $self->{box};
	}

    if ($self->{gi} eq 'table') {
        # walk table
        my ($table);
        
        $table = Template::Flute::PDF::Table->new(pdf => $self->{pdf});
        $table->walk($self);
    }
    
	if ($self->{gi} eq 'img') {
		my (@info, $src, $file, %size);

		$src = $self->{elt}->att('src');

		unless ($src) {
		    warn "Missing image: ", $self->_description, "\n";
		    return $self->{box};
		}

		$file = $self->{pdf}->locate_image($src);
		$self->{object} = new Template::Flute::PDF::Image(file => $file, pdf => $self->{pdf});

		for my $extent (qw/width height/) {
			# size from HTML
			if ($size{$extent}= $self->{elt}->att($extent)) {
			    $self->{object}->$extent(Template::Flute::PDF::to_points($size{$extent}));
			    next;
			}

			# size from CSS
			if ($size{$extent} = $self->property($extent)) {
			    $self->{object}->$extent($size{$extent});
			    next;
			}

			# size from image
			$size{$extent} = $self->{object}->$extent();
		}
		$max_width = $size{width};
		$max_height = $size{height};
	}
	
	for my $child ($self->{elt}->children()) {
		# discard elements we won't use anyway
		next if $self->{gi} eq 'style';
		next if $self->{gi} eq 'head';
		
		unless (exists $self->{eltmap}->{$child}) {
			@parms = (elt => $child, pdf => $self->{pdf},
					  parent => $self);

			if ($child->is_text()) {
				# inheriting specifications of parent
				push (@parms, specs => $self->{specs});
			}
			else {
				push (@parms, selector_map => $self->{selector_map});
			}

			push (@parms, bounding => {%{$self->{window}}});

			$childbox = new Template::Flute::PDF::Box(@parms);

			$self->{eltmap}->{$child} = $childbox;
			
			push (@{$self->{eltstack}}, $childbox);
		}
        
        unless (exists $self->{eltmap}->{$child}->{box}) {
            $dim = $self->{eltmap}->{$child}->calculate();
        }
	}

	# processed all childs, now determine my size itself

	my ($vpos, $hpos, $max_stripe_height, $max_stripe_width, $child) = (0,0,0,0,0);
	my ($hpos_next, $vpos_next, @stripes, $stripe_pos, $stripe_base, $clear_after);

	$stripe_base = 0;
	$clear_after = 0;
	$stripe_pos = 0;
	
	for (my $i = 0; $i < @{$self->{eltstack}}; $i++) {
		$child = $self->{eltstack}->[$i];
		$child->{stackpos} = $i;
		
		if ($hpos > 0 && ! $child->{box}->{clear}->{before}
			&& ! $clear_after) {
			# check if item fits horizontally
			$hpos_next = $hpos + $child->{box}->{width};

			if ($self->{specs}->{props}->{width}
				&& $self->{specs}->{props}->{width} < $hpos_next) {
				# doesn't fit in fixed width of this box
#				print "NO HORIZ FIT for GI $child->{gi} CLASS $child->{class} ID $child->{id}: too wide for H $hpos_next\n";
				$hpos = 0;				
				$hpos_next = 0;
			}

			if ($hpos_next > $self->{bounding}->{max_w}) {
				# doesn't fit in bounding box
#				print "NO HORIZ FIT for GI $child->{gi} CLASS $child->{class} ID $child->{id}: H $hpos HN $hpos_next MAX_W  $self->{bounding}->{max_w}\n";
				$hpos = 0;
				$hpos_next = 0;
			}
		}
		else {
			$hpos = 0;
			$hpos_next = 0;
#			print "NO HORIZ FIT for ", $child->_description, ": CLR AFTER $clear_after\n";
		}

		# keep vertical position
		$vpos_next = $vpos;
		
		if ($hpos_next > 0) {
#			print "HORIZ FIT for GI $child->{gi} CLASS $child->{class} ID $child->{id}\n";
			$max_stripe_width = $hpos_next;

			if ($child->property('float') eq 'right'
				&& $self->property('float') ne 'right') {
				# push it to the right border
				
				if ($self->property('width')) {
					$max_width = $self->property('width');
				}
				else {
					$max_width = $self->{bounding}->{max_w};
				}

				$hpos = $max_width - $child->{box}->{width};
				$hpos_next = $max_width;
			}
			elsif ($max_stripe_width > $max_width) {
				# add to current width
				$max_width = $max_stripe_width;
			}

			# check whether we need to extend the height
			my $height_extend = 0;
			
			if ($child->{box}->{height} > $max_stripe_height) {
				$height_extend = $child->{box}->{height} - $max_stripe_height;
			}

			$max_stripe_height += $height_extend;
			$max_height += $height_extend;

			$self->{stripe_heights}->[$stripe_pos] = $max_stripe_height;
		}
		else {
			# starting new stripe now
			$stripe_pos++;
			$max_stripe_height = 0;
			$max_stripe_width = 0;

			# stripe base moves to max_height
			$stripe_base = $max_height;
		
			if ($child->{box}->{width} > $max_width
			    && $child->{gi} ne 'hr') {
				$max_width = $child->{box}->{width};
				$max_stripe_width = $max_width;
			}

			# add to current height
			$max_height += $child->{box}->{height};

			if ($stripe_base) {
				$vpos_next = $stripe_base;
			}
			$vpos = $stripe_base;
		
			# stripe height is simply height of this child
			$max_stripe_height = $child->{box}->{height};

			$self->{stripe_heights}->[$stripe_pos] = $max_stripe_height;

			if ($child->property('float') eq 'right'
				&& $self->property('float') ne 'right') {
				# push it to the right border
				if ($self->property('width')) {
					$max_width = $self->property('width');
				}
				else {
					$max_width = $self->{bounding}->{max_w};
				}

				$hpos = $max_width - $child->{box}->{width};
				$hpos_next = $max_width;
			}
				
#			print "NEW HPOS from GI $child->{gi} CLASS $child->{class}: $child->{box}->{width}, VPOS $vpos\n";
			$hpos_next = $child->{box}->{width};
			$max_stripe_width = $hpos_next;
		}

		$self->{eltpos}->[$i] = {hpos => $hpos, vpos => -$vpos};
		
#		if ($child->{elt}->is_text()) {
#			print "POS (relative) for TEXT '" . $child->{elt}->text() . "': " . Dumper($self->{eltpos}->[$i]);
#		}
#		else {
#			print "POS (relative) for GI $child->{gi} CLASS $child->{class}: " . Dumper($self->{eltpos}->[$i]);
#		}

		# record child within its stripe
		push (@{$self->{stripes}->[$stripe_pos]}, $child);
		
		# advance to new relative position
		$hpos = $hpos_next;
		$vpos = $vpos_next;

		$clear_after = $child->{box}->{clear}->{after};
	}

	# apply fixed dimensions
	if ($self->{specs}->{props}->{width} > $max_width) {
		$max_width = $self->{specs}->{props}->{width};
	}

	if ($self->{specs}->{props}->{height} > $max_height) {
		$max_height = $self->{specs}->{props}->{height};
	}

	# apply minimum for dimensions
    $min_width = Template::Flute::PDF::to_points($self->{specs}->{props}->{min_width}) || 0;
    
    if ($max_width < $min_width) {
        $max_width = $min_width;
    }

    $min_height = Template::Flute::PDF::to_points($self->{specs}->{props}->{min_height}) || 0;
    
    if ($max_height < $min_height) {
        $max_height = $min_height;
    }
    
	# add offsets
	$max_width += $self->{specs}->{offset}->{left} + $self->{specs}->{offset}->{right};
	$max_height += $self->{specs}->{offset}->{top} + $self->{specs}->{offset}->{bottom};

	# set up clear properties
	my $clear = {after => 0, before => 0};

	if ($self->{gi} eq 'hr') {
		$clear->{before} = $clear->{after} = 1;
		$max_width ||= $self->{bounding}->{max_w};
	}
	elsif ($self->{gi} eq 'br') {
		$clear->{before} = 1;
	}
    elsif ($self->{gi} eq 'tr') {
        $clear->{before} = $clear->{after} = 1;
    }
	elsif ($self->{specs}->{props}->{display} eq 'block') {
	    if ($self->property('float') eq 'left') {
		# no change
	    }
	    elsif ($self->property('float') eq 'right') {
		$clear->{before} = 0,
		$clear->{after} = 1;
	    }
	    else {
		$clear->{before} = $clear->{after} = 1;
	    }
	}
	elsif ($self->{gi} eq 'li') {
	    unless ($self->property('float') eq 'left'
		    && $self->property('list_style') eq 'none') {
		# show list elements vertically
		$clear->{before} = $clear->{after} = 1;
	    }
	}

	$self->{box} = {width => $max_width,
					height => $max_height,
					clear => $clear,
					size => $self->{specs}->{size}};

#	print "DIM for ", $self->_description, ": ",  Dumper($self->{box});
 	return $self->{box};
}

=head2 align OFFSET

Aligns boxes (center, left, right).

=cut

sub align {
	my ($self, $offset) = @_;
	my ($avail_width, $avail_width_text, $textprops, $child, $box_pos, $valign, $valign_space);

	$offset ||= 0;
	
	for (my $i = 0; $i < @{$self->{stripes}}; $i++) {
		for my $child (@{$self->{stripes}->[$i]}) {
			# skip over text elements (align only applies to grand children)
			next if $child->{elt}->is_text();
			
			if ($child->property('display') eq 'block') {
			    $valign = $child->property('vertical_align') || 'top';
			}
			else {
			    $valign = $child->property('vertical_align') || 'bottom';
			}

			unless ($valign eq 'top') {
                            # check whether we have space to move 
			    $valign_space =  $self->{stripe_heights}->[$i] - $child->{box}->{height};

			    if ($valign_space > 0) {
				$child->{voff} = $valign_space;
			    }
			}

			if (($textprops = $child->property('text'))
			    || $child->{gi} eq 'center') {
			   
				if ($child->property('width')) {
					$avail_width = $child->property('width');
				}
				elsif (@{$self->{stripes}->[$i]} == 1) {
					# single box in a stripe can take over all the space
					# in the bounding box
					$avail_width = $child->{bounding}->{max_w} - $offset - $self->{specs}->{offset}->{left} - $self->{specs}->{offset}->{right};
#					$avail_width = $self->{box}->{width};
				}
				else {
					$avail_width = $child->{box}->{width};
				}

				if ($child->{gi} eq 'center') {
				    if ($avail_width > $self->{box}->{width}) {
					$child->{hoff} += ($avail_width - $self->{box}->{width}) / 2;
				    }
				    next;
				}

				for (my $cpos = 0; $cpos < @{$child->{eltstack}}; $cpos++) {
					next unless $child->{eltstack}->[$cpos]->{elt}->is_text();

					$avail_width_text = $avail_width - $child->{eltstack}->[$cpos]->{box}->{text_width};

					if ($avail_width_text > 0 && exists $textprops->{align}) {
						if ($textprops->{align} eq 'right') {
							$child->{eltstack}->[$cpos]->{hoff} += $avail_width_text;
						}
						elsif ($textprops->{align} eq 'center') {
							$child->{eltstack}->[$cpos]->{hoff} += $avail_width_text / 2;
						}
					}
				}
			}
		}
	}

	for (my $i = 0; $i < @{$self->{eltstack}}; $i++) {
		$child = $self->{eltstack}->[$i];
		$child->align($offset + $self->{eltpos}->[$i]->{hpos});
	}
}

=head2 partition PAGE_NUM HEIGHT_BASE

Partitions boxes through pages.

=cut

sub partition {
	my ($self, $page_num, $height_base) = @_;
	my (@children, $children_height, $vpos_diff, $page_num_max);

	$children_height = 0;
	$page_num_max = $page_num;

	if ($page_num > $self->{page}) {
		$self->{page} = $page_num;
	}
	
#	print "PART $self->{gi} $self->{class}, PAGE $page_num, BASE $height_base BOX: " . Dumper($self->{box});

	if ($height_base + $self->{box}->{height} > $self->{pdf}->content_height()) {
#		print "SPLIT required due to H " . $self->{pdf}->content_height() . "\n";
				
		@children = @{$self->{eltstack}};

		if (@children > 1) {
			# partition children
#			print "MULTIPLE\n";
			for (my $i = 0; $i < @children; $i++) {
				my $c_info = "GI " . $children[$i]->{gi} . ", CLASS " . $children[$i]->{class};
				
				if ($height_base + $children_height + $children[$i]->{box}->{height} > $self->{pdf}->content_height()) {
#					print "CALL CHILD FROM BASE $height_base WITH CH $children_height, $c_info\n";
					$page_num_max = $children[$i]->partition($page_num_max, $height_base +  $children_height);
					# adjust positions of children
#					print "PAGE NUM GI $self->{gi} CLASS $self->{class}: FROM $page_num TO $page_num_max (CH: $children_height, HB: $height_base)\n";

#					print "OLD ELT POS $c_info: " . Dumper($self->{eltpos}->[$i]) . "\n";

					$vpos_diff = - $self->{eltpos}->[$i]->{vpos};

					unless ($children[$i]->{box}->{height} > $self->{pdf}->content_height()) {
						$self->{eltpos}->[$i]->{vpos} = 0;
						$self->{eltpos}->[$i]->{page} = $page_num_max;
						$children[$i]->adjust_page($page_num_max);
					}
					
#					print "NEW ELT POS: " . Dumper($self->{eltpos}->[$i]) . "\n";

#					if ($page_num_max == $page_num) {
#						# advance page for following element
#						$page_num++;
#					}
					
					# reset heights
					$height_base = 0;
					$children_height = $children[$i]->{box}->{height};
					next;
				}
				elsif ($vpos_diff) {
					$self->{eltpos}->[$i]->{vpos} += $vpos_diff;
					$self->{eltpos}->[$i]->{page} = $page_num_max;

					$children[$i]->adjust_page($page_num_max);
#					print "ADJUST CHILD ON PAGE $page_num_max FROM BASE $height_base WITH CH $children_height, GI " . $children[$i]->{gi} . ", CLASS " . $children[$i]->{class} . " TO: " . Dumper($self->{eltpos}->[$i]) . "\n";
				}
				else {					
#					print "CHILD FIT FROM BASE ON PAGE $page_num_max $height_base WITH CH $children_height, GI " . $children[$i]->{gi} . ", CLASS " . $children[$i]->{class} . "\n";
					$self->{eltpos}->[$i]->{page} = $page_num_max;
				}
				
				$children_height += $children[$i]->{box}->{height};
			}
		}
		elsif (@children) {
#			print "SINGLE\n";

			$children[0]->partition($page_num, $height_base);
			$page_num_max++;
#			$page_num += 1;
#			$self->{page} = $page_num;
		}
		else {
			$page_num_max++;
#			print "Advance page for element without children to $page_num_max\n";
		}
	}

	return $page_num_max;
}

=head2 property NAME NAME ...

Returns property.

=cut

sub property {
	my ($self, @names) = @_;
	my $ptr;

	$ptr = $self->{specs}->{props};
	
	for my $name (@names) {
		if (exists $ptr->{$name}) {
			$ptr = $ptr->{$name};
		}
		else {
			return;
		}
	}
	
	return $ptr;
}

=head2 render PARAMETERS

Renders box.

=cut

sub render {
	my ($self, %parms) = @_;
	my ($child, $pos, $page_before, $page_cur);

	$self->{hoff} ||= 0;
	$self->{voff} ||= 0;

#	print "RENDER ", $self->_description, " on PAGE $self->{page}: " . Dumper(\%parms);

	if (exists $parms{page}
		&& $parms{page} > $self->{page}) {
		$self->{pdf}->select_page($parms{page});
	}
	else {
		$self->{pdf}->select_page($self->{page});
	}

	$page_before = $self->{page};
	
	# loop through our stack
	for (my $i = 0; $i < @{$self->{eltstack}};  $i++) {
		$child = $self->{eltstack}->[$i];
		$pos = $self->{eltpos}->[$i];
		$page_cur = $pos->{page} || $page_before;

		if ($page_cur > $page_before) {
			if ($i > 0) {
				# page turn, adjust position
				my $c_info = "GI " . $child->{gi} . ", CLASS " . $child->{class};
#				print "PAGE TURN FROM $page_before TO $page_cur CLASS $self->{class} GI $self->{gi} FOR $c_info\n";

				$parms{vpos} = $self->{pdf}->{border_top};
				$parms{hpos} = $self->{pdf}->{border_left};
			}
			
			$page_before = $page_cur;
		}
		
		$child->render(hpos => $parms{hpos} + $self->{specs}->{offset}->{left} + $pos->{hpos} + $self->{hoff},
					   vpos => $parms{vpos} - $self->{specs}->{offset}->{top} + $pos->{vpos} - $self->{voff},
					   page => $pos->{page} || $self->{page},
					   );
	}
	
	if ($self->{elt}->is_text()) {
		# render text
		my $chunks = $self->{box}->{chunks};

#		print "Chunks: " . Dumper($chunks) . "\n";
		
		for (my $i = 0; $i < @$chunks; $i++) {
			$self->{pdf}->textbox($self->{elt}, $chunks->[$i],
								  $self->{specs}, {%parms, hpos => $parms{hpos} + ($self->{hoff} || 0), vpos => $parms{vpos} - ($i * $self->{specs}->{size})},
								  noborder => 1);
		}
		return;
	}

	if ($self->{gi} eq 'hr') {
	    # rendering horizontal line

	    $self->{pdf}->hline($self->{specs}, $parms{hpos},
				$parms{vpos} - $self->{specs}->{offset}->{top},
				$self->{box}->{width}, $self->{specs}->{props}->{height});
	    
	    return;
	}

	if ($self->{gi} eq 'img') {
	    # rendering image
	    if ($self->{object}->{type}) {
		$self->{pdf}->image($self->{object},
				    $parms{hpos} + $self->{specs}->{offset}->{left},
				    $parms{vpos} - $self->{object}->height - $self->{specs}->{offset}->{top},
				    $self->{object}->width,
				    $self->{object}->height,
				    $self->{specs});
	    }
	    # fall through to borders
	}

	# render borders
	my ($hpos, $vpos, $width, $height, $margins);
		
	$margins = $self->{specs}->{margins};

	# adjust border dimensions by margins
	$hpos = $parms{hpos} + $margins->{left} + $self->{hoff};
	$vpos = $parms{vpos} - $margins->{top} - $self->{voff};
	$width = $self->{box}->{width} - $margins->{left} - $margins->{right};
	$height = $self->{box}->{height} - $margins->{top} - $margins->{bottom};
		
	$self->{pdf}->borders($hpos, $vpos, $width, $height, $self->{specs});
}

=head2 adjust_page PAGE_NUM

Adjust page number for all descendants to PAGE_NUM.

=cut

sub adjust_page {
	my ($self, $page_num) = @_;
	my (@children);

	@children = @{$self->{eltstack}};
	
	for (my $i = 0; $i < @children; $i++) {
		$self->{eltpos}->[$i]->{page} = $page_num;
		$children[$i]->adjust_page($page_num);
	}
}

=head2 setup_specs

Setup specifications for this box.

=cut
	
sub setup_specs {
	my ($self) = @_;
	my ($inherit, $selector_map);
	
	if ($self->{parent}) {
		$inherit = $self->{parent}->{specs}->{props};
	}
	
	# lookup ourselves in selector map from ancestors
	if ($selector_map = $self->{parent}->{selector_map}) {
		my (@selectors);
		
		if ($self->{class}) {
			push (@selectors, ".$self->{class}");
		}
		if ($self->{id}) {
			push (@selectors, "#$self->{id}");
		}
		if ($self->{gi}) {
			push (@selectors, $self->{gi});
		}

		for my $key (@selectors) {
			if ($selector_map->{$key}) {
				$self->{specs} = $self->{pdf}->setup_text_props($self->{elt},
														 $selector_map->{$key}, $inherit);
			}
		}
	}
			
	$self->{specs} ||= $self->{pdf}->setup_text_props($self->{elt}, undef, $inherit);
	return;
}

sub _description {
    my $self = shift;
    my ($desc, $text, $max_length);

    $max_length = 20;

    $desc = "GI $self->{gi}";

    if ($self->{gi} eq '#PCDATA') {
	$text = $self->{elt}->text();

	if (length $text > $max_length) {
	    $text = substr($text, 0, $max_length - 1) . ' ...';
	}

	$desc .= ", TEXT $text";
	return $desc;
    }
    
    if ($self->{class}) {
	$desc .= ", CLASS $self->{class}";
    }

    if ($self->{id}) {
	$desc .= ", ID $self->{id}";
    }

    if ($self->{gi} eq 'img') {
	$desc .= ', SRC ' . $self->{elt}->att('src');
    }

    return $desc;
};

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
	
1;
