use v5.18;
use strict;
use warnings;

package Mxpress::PDF {
	our $VERSION = '0.03';
	use MooX::Pression (
		version	=> '0.03',
		authority => 'cpan:LNATION',
	);
	use Colouring::In;
	use constant mm => 25.4 / 72;
	use constant pt => 1;
	class File (HashRef $args) {
		my @plugins = (qw/font line box circle text title subtitle subsubtitle toc image/, ($args->{plugins} ? @{$args->{plugins}} : ()));
		for my $p (@plugins) {
			my $meth = sprintf('_store_%s', $p);
			has {$meth} (type => Object);
			method {$p} () {
				my $klass = $self->$meth;
				if (!$klass) {
					$klass = $class->FACTORY->$p($self, %{$args->{$p}});
					$self->$meth($klass);
				}
				return $klass;
			}
		}
		has file_name (type => Str, required => 1);
		has pdf (required => 1, type => Object);
		has pages (required => 1, type => ArrayRef);
		has page (type => Object);
		has page_args (type => HashRef);
		has onsave_cbs (type => ArrayRef);
		method add_page (Map %args) {
			my $page = $self->FACTORY->page(
				$self->pdf,
				page_size => 'A4',
				%{ $self->page_args },
				($self->page ? (num => $self->page->num + 1) : ()),
				%args,
			);
			push @{$self->pages}, $page;
			$self->page($page);
			$self->box->add( fill_colour => $page->background ) if $page->background;
			$self->page->set_position($page->parse_position([]));
			$self;
		}
		method save {
			if ($self->onsave_cbs) {
				for my $cb (@{$self->onsave_cbs}) {
					my ($plug, $meth, $args) = @{$cb};
					$self->$plug->$meth(%{$args});
				}
			}
			$self->pdf->saveas();
			$self->pdf->end();
		}
		method onsave (Str $plug, Str $meth, Map %args) {
			my $cbs = $self->onsave_cbs || [];
			push @{$cbs}, [$plug, $meth, \%args];
			$self->onsave_cbs($cbs);
		}
	}
	class Page {
		with Utils;
		has page_size (type => Str, required => 1);
		has background (type => Str);
		has num (type => Num, required => 1);
		has current (type => Object);
		has is_rotated (type => Num);
		has x (type => Num);
		has y (type => Num);
		has w (type => Num);
		has h (type => Num);
		factory page (Object $pdf, Map %args) {
	 		my $page = $args{open} ? $pdf->openpage($args{num}) : $pdf->page($args{num});
			$page->mediabox($args{page_size});
			my ($blx, $bly, $trx, $try) = $page->get_mediabox;
			my $new_page = $class->new(
				current => $page,
				num => $args{num} || 1,
				($args{is_rotated} ? (
					x => 0,
					w => $try,
					h => $trx,
					y => $trx,
				) : (
					x => 0,
					w => $trx,
					h => $try,
					y => $try,
				)),
				padding => 0,
				%args
			);
			return $new_page;
		}
		method rotate {
			my ($h, $w) = ($self->h, $self->w);
			$self->current->mediabox(
				0,
				0,
				$self->w($h),
				$self->h($self->y($w))
			);
			$self->is_rotated(!$self->is_rotated);
			return $self;
		}
	}
	role Utils {
		has padding (type => Num);
		has margin_top (type => Num);
		has margin_bottom (type => Num);
		method add_padding (Num $padding) {
			$self->padding($self->padding + $padding);
		}
		method set_position (Num $x, Num $y, Num $w, Num $h) {
			my $page = $self->can('file') ? $self->file->page : $self;
			$page->x($x);
			$page->y($y);
			$page->w($w);
			$page->h($h);
			return ($x, $y, $w, $h);
		}
		method parse_position (ArrayRef $position, Bool $xy?) {
			my ($x, $y, $w, $h) = map {
				$_ =~ m/[^\d\.]/ ? $_ : $_/mm
			} @{$position};
			my $page = $self->can('file') ? $self->file->page : $self;
			$x //= $page->x + ($self->padding/mm);
			$y //= $page->y - ($self->padding/mm);
			$w //= $page->w - ($self->padding/mm);
			$h //= $y - (($self->padding + $page->padding)/mm);
			return $xy ? ($x, $y) : ($x, $y, $w, $h);
		}
		method set_y (Num $y) {
			$y -= $self->margin_bottom if $self->margin_bottom;
			my $page = $self->can('file') ? $self->file->page : $self;
			return $page->y($y);
		}
		method valid_colour (Str $css) {
			return Colouring::In->new($css)->toHEX(1);
		}
		method _recurse_find {
			my ($self, $check, $recurse, $val, @items) = @_;
			for (@items) {
				if (defined $_->$check && $_->$check =~ $val) {
					return $_;
				} elsif ($_->$recurse && scalar @{$_->$recurse}) {
					my $val = $self->_recurse_find($check, $recurse, $val, @{$_->$recurse});
					return $val if $val;
				}
			}
			return undef;
		}
	}
	class Plugin {
		with Utils;
		has file (type => Object);
		has position (type => ArrayRef);
		method set_attrs (Map %args) {
			$self->can($_) && $self->$_($args{$_}) for keys %args;
		}
		class +Font {
			has colour (type => Str);
			has size (type => Num);
			has family (type => Str);
			has loaded (type => HashRef);
			has line_height ( type => Num);
			factory font (Object $file, Map %args) {
				return $class->new(
					file => $file,
					colour => $file->page->valid_colour($args{colour} || '#000'),
					size => 9,
					line_height => $args{size} || 9,
					family => 'Times',
					%args
				);
			}
			method load () { $self->find($self->family); }
			method find (Str $family, Str $enc?) {
				my $loaded = $self->loaded;
				unless ($loaded->{$family}) {
					$loaded->{$family} = $self->file->pdf->corefont($family, -encoding => $enc || 'latin1');
					$self->loaded($loaded);
				}
				return $loaded->{$family};
			}
		}
		class +Shape {
			has fill_colour ( type => Str );
			has radius ( type => Num );
			method generic_new (Object $file, Map %args) {
				return $class->new(
					file => $file,
					fill_colour => $file->page->valid_colour($args{fill_colour} || '#fff'),
					padding => $args{padding} || 0,
					($args{radius} ? (radius => $args{radius}) : ())
				);
			}
			method add (Map %args) {
				$self->set_attrs(%args);
				my $shape = $self->file->page->current->gfx;
				$self->shape($shape);
				return $self->file;
			}
			class +Line {
				has end_position;
				factory line (Object $file, Map %args) {
					$class->generic_new($file, %args);
				}
				method shape (Object $shape) {
					$shape->strokecolor($self->fill_colour);
					my ($x, $y, $w, $h) = $self->parse_position($self->position || []);
					$shape->move($x, $y);
					($x, $y) = $self->end_position ? $self->parse_position($self->end_position, \1) : ($w, $y);
					$shape->line($x, $y);
					$shape->stroke;
				}
			}
			class +Box {
				factory box (Object $file, Map %args) {
					return $class->generic_new($file, %args);
				}
				method shape (Object $shape) {
					my $box = $shape->rect(
						$self->parse_position(
							$self->position || [0, 0, $self->file->page->w, $self->file->page->h]
						)
					);
					$box->fillcolor($self->fill_colour);
					$box->fill;
				}
			}
			class +Circle {
				factory circle (Object $file, Map %args) {
					$args{radius} ||= 50;
					return $class->generic_new($file, %args);
				}
				method shape (Object $shape) {
					my ($x, $y, $r) = $self->parse_position(
						$self->position || [
							($self->file->page->x*mm) + $self->radius,
							($self->file->page->y*mm) - $self->radius,
							$self->radius
						]
					);
					my $circle = $shape->circle(
						$x, $y, $r
					);
					$circle->fillcolor($self->fill_colour);
					$circle->fill;
				}
			}
		}
		class +Text {
			has font (type => Object);
			has paragraph_space (type => Num);
			has first_line_indent (type => Num);
			has first_paragraph_indent (type => Num);
			has align (type => Str); #enum
			has margin_bottom (type => Num);
			has indent (type => Num);
			has pad (type => Str);
			has pad_end (type => Str);
			has next_page;
			factory text (Object $file, Map %args) {
				$class->generic_new($file, %args);
			}
			method generic_new (Object $file, Map %args) {
				return $class->new({
					file => $file,
					page => $file->page,
					next_page => do { method {
						my $self = shift;
						$file->add_page;
						return $file->page;
					} },
					padding =>  0,
					align => 'left',
					font => $class->FACTORY->font(
						$file,
						%{$args{font}}
					),
					position => $args{position} || [],
					(map {
						$args{$_} ? ( $_ => $args{$_} ) : ()
					} qw/margin_bottom margin_top indent align padding pad pad_end/)
				});
			}
			method add (Str $string, Map %args) {
				$self->set_attrs(%args);
				my ($xpos, $ypos);
				my @paragraphs = split /\n/, $string;
				my $text = $self->file->page->current->text;
				$text->font( $self->font->load, $self->font->size/pt );
				$text->fillcolor( $self->font->colour );
				my ($total_width, $space_width, %width) = $self->_calculate_widths($string, $text);
				my ($l, $x, $y, $w, $h) = (
					$self->font->line_height/pt,
					$self->parse_position($self->position)
				);
				$ypos = $y - $l;
				my ($fl, $fp, @paragraph) = (1, 1, split ( / /, shift(@paragraphs) || '' ));
				# while we have enough height to add a new line
				while ($ypos >= $y - $h) {
					unless (@paragraph) {
						last unless scalar @paragraphs;
						@paragraph = split( / /, shift(@paragraphs) );
						$ypos -= $self->paragraph_space/mm if $self->paragraph_space;
						last unless $ypos >= $y - $h;
						($fl, $fp) = (1, 0);
					}
					my ($xpos, $lw, $line_width, @line) = ($x, $w, 0);
					($xpos, $lw) = $self->_set_indent($xpos, $lw, $fl, $fp);
					while (@paragraph and ($line_width + (scalar(@line) * $space_width) + ($width{$paragraph[0]}||0)) < $lw) {
						$line_width += $width{$paragraph[0]} || 0;
						push @line, shift(@paragraph);
					}
					my ($wordspace, $align);
					if ($self->align eq 'fulljustify' or $self->align eq 'justify' and @paragraph) {
						if (scalar(@line) == 1) {
							@line = split( //, $line[0] );
						}
						$wordspace = ($lw - $line_width) / (scalar(@line) - 1);
						$align = 'justify';
					} else {
						$align = ($self->align eq 'justify') ? 'left' : $self->align;
						$wordspace = $space_width;
					}
					$line_width += $wordspace * (scalar(@line) - 1);
					if ($align eq 'justify') {
						foreach my $word (@line) {
							$text->translate($xpos, $ypos);
							$text->text($word);
							$xpos += ($width{$word} + $wordspace) if (@line);
						}
					} else {
						if ($align eq 'right') {
							$xpos += $lw - $line_width;
						} elsif ($align eq 'center') {
							$xpos += ($lw/2) - ($line_width / 2);
						}
						$text->translate($xpos, $ypos);
						$text->text(join(' ', @line));
					}
					if (@paragraph) {
						$ypos -= $l if @paragraph;
					} elsif ($self->pad) {
						my $pad_end = $self->pad_end;
						$lw -= $self->page->padding/mm;
						my $pad = sprintf ("%s%s",
							$self->pad x int(((
								(((($lw + $wordspace) - $line_width) - $text->advancewidth($self->pad . $pad_end)))
							) / $text->advancewidth($self->pad))),
							$pad_end
						);
						$text->translate($xpos + ( $lw - $text->advancewidth($pad) ), $ypos);
						$text->text($pad);
					}
					$fl = 0;
				}
				unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);
				$ypos -= $self->margin_bottom/mm if $self->margin_bottom;
				$self->set_y($ypos);
				if (scalar @paragraphs && $self->next_page) {
					my $next_page = $self->next_page->($self);
					return $self->add(join("\n", @paragraphs), %args);
				}
				return $self->file;
			}
			method _set_indent (Num $xpos, Num $w, Num $fl, Num $fp) {
	 			if ($fl && $self->first_line_indent) {
					$xpos += $self->first_line_indent/mm;
					$w -= $self->first_line_indent/mm;
				} elsif ($fp && $self->first_paragraph_indent) {
					$xpos += $self->first_paragraph_indent/mm;
					$w -= $self->first_paragraph_indent/mm;
				} elsif ($self->indent) {
					$xpos += $self->indent/mm;
					$w -= $self->indent/mm
				}
				return ($xpos, $w);
			}
			method _calculate_widths (Str $string, Object $text) {
				my @words = split /\s+/, $string;
				# calculate width of space
				my $space_width = $text->advancewidth(' ');
				# calculate the width of each word
				my %width = ();
				my $total_width = 0;
				foreach (@words) {
					next if exists $width{$_};
					$width{$_} = $text->advancewidth($_);
					$total_width += $width{$_} + $space_width;
				}
				return ($total_width, $space_width, %width);
			}
			class +Title {
				factory title (Object $file, Map %args) {
					$args{font}->{size} ||= 50/pt;
					$args{font}->{line_height} ||= 40/pt;
					$class->generic_new($file, %args);
				}
			}
			class +Subtitle {
				factory subtitle (Object $file, Map %args) {
					$args{font}->{size} ||= 25;
					$args{font}->{line_height} ||= 20;
					$class->generic_new($file, %args);
				}
			}
			class +Subsubtitle {
				factory subsubtitle (Object $file, Map %args) {
					$args{font}->{size} ||= 20;
					$args{font}->{line_height} ||= 15;
					$class->generic_new($file, %args);
				}
			}
		}
		class +TOC::Outline {
			extends Plugin::Text;
			has outline (type => Object);
			has x (type => Num);
			has y (type => Num);
			has title (type => Str);
			has page (type => Object);
			has level (type => Num);
			has children (type => ArrayRef);
			factory add_outline (Object $file, Object $outline, Map %args) {
				my ($x, $y) = $file->page->parse_position($args{position} || []);
				$y += $args{jump_lh};
				my $new = $outline->outline()->open()
					->title($args{outline_title})
					->dest($file->page->current, '-xyz' => [$x, $y, 0]);
				return $class->new(
					x => $x,
					y => $y,
					children => [],
					level => $args{level} || 0,
					title => $args{outline_title},
					file => $file,
					page => $file->page,
					outline => $new,
					font => $class->FACTORY->font(
						$file,
						%{$args{font}}
					),
					pad => $args{pad} || '.',
					next_page => $args{next_page} || do { method {
						my $self = shift;
						$file->add_page(open => 1);
						$file->page->set_position($file->toc->parse_position([]));
						return $file->page;
					} },
					padding => $args{padding} || 0,
					align => $args{align} || 'left',
					position => $args{position} || [],
					(map {
						$args{$_} ? ( $_ => $args{$_} ) : ()
					} qw/margin_bottom margin_top indent align pad_end/)
				);
			}
			method render (Map %args) {
				$self->set_attrs(%args);
				$self->pad_end($self->page->num + $args{page_offset});
				$self->add($self->title);
				my ($x, $y, $w) = ($self->file->page->x, $self->file->page->y, $self->file->page->w);
				my $annotation = $self->file->page->current->annotation()->rect(
					$x, $y + 3.5, $w, $y - 3.5
				)->link($self->page->current, -xyz => [$self->x, $self->y, 0]);
				for (@{$self->children}) {
					$_->render(%args);
				}
			}
		}
		class +TOC {
			has count (type => Num);
			has toc_placeholder (type => HashRef);
			has outline (type => Object);
			has outlines (type => ArrayRef);
			has indent (type => Num);
			has levels (type => ArrayRef);
			has toc_line_offset (type => Num);
			has font (type => HashRef);
			factory toc (Object $file, Map %args) {
				return $class->new(
					file => $file,
					outline => $file->pdf->outlines()->outline,
					outlines => [],
					count => 0,
					toc_line_offset => $args{toc_line_offset} || 0,
					padding => $args{padding} || 0,
					levels => [qw/title subtitle subsubtitle/],
					indent => $args{indent} || 5,
					($args{font} ? (font => $args{font}) : ())
				);
			}
			method placeholder (Map %args) {
				$self->set_attrs(%args);
				#$self->file->subtitle->add($args{title} ? @{$args{title}} : 'Table of contents');
				$self->toc_placeholder({
					page => $self->file->page,
					position => [$self->parse_position($args{position} || [])]
				});
				$self->file->onsave('toc', 'render', %args);
				$self->file->add_page;
				return $self->file;
			}
			method add (Map %args) {
				$self->set_attrs(%args);
				$self->count($self->count + 1);
				$args{level} = 0;
				my ($text, %targs, $level);
				for (@{$self->levels}) {
					if (defined $args{$_}) {
						($text, %targs) = ref $args{$_} ? @{$args{$_}} : $args{$_};
						$level = $_;
						$args{outline_title} ||= $text;
						$args{jump_lh} = $self->file->$level->font->line_height;
						last;
					}
					$args{level}++;
				}
				$args{font} ||= $self->font;
				my $outline;
				$outline = $self->_recurse_find('level', 'children', $args{level} - 1, reverse @{$self->outlines}) if $args{level};
				my $add = $self->FACTORY->add_outline($self->file, ($outline ? $outline->outline : $self->outline), %args);
				if ($outline) {
					$add->indent($self->indent * $add->level);
					push @{ $outline->children }, $add;
				} else {
					push @{ $self->outlines }, $add;
				}
				$self->file->$level->add($text, %targs);
				return $self->file;
			}
			method render (Map %args) {
				$self->set_attrs(%args);
				my $placeholder = $self->toc_placeholder;
				my ($x, $y, $w, $h) = $self->set_position(@{$placeholder->{position}});
				# todo better
				$args{page_offset} = 0;
				my $one_toc_link = $self->outlines->[0]->font->size + $self->toc_line_offset/mm;
				my $total_height = ($self->count * $one_toc_link) - $h;
				while ($total_height > 0) {
					$args{page_offset}++;
					$self->file->add_page(num => $placeholder->{page}->num + $args{page_offset});
					$total_height -= $self->file->page->h;
				}
				$self->file->page($placeholder->{page});
				for my $outline (@{$self->outlines}) {
					$outline->render(%args);
				}
			}
		}
		class +Image {
			has width (type => Num);
			has height (type => Num);
			has align (type => Str);
			has valid_mime (type => HashRef);
			factory image (Object $file, Map %args) {
				return $class->new(
					file => $file,
					padding => 0,
					align => 'center',
					valid_mime => {
						jpeg => 'image_jpeg',
						tiff => 'image_tiff',
						pnm => 'image_pnm',
						png => 'image_png',
						gif => 'image_gif'
					},
					%args
				);
			}
			multi method add (FileHandle $image, Str $type, Map %args) {
				$self->set_attrs(%args);
				$type = $self->valid_type->{$type};
				return $self->_add($self->file->pdf->$type($image));
			}
			multi method add (Str $image, Map %args) {
				$self->set_attrs(%args);
				my $type = $self->_identify_type($image);
				return $self->_add($self->file->pdf->$type($image));
			}
			method _add (Object $image) {
				my ($x, $y, $w, $h) = $self->_image_position($image);
				my $photo = $self->file->page->current->gfx;
				$photo->image(
					$image,
					$x, $y, $w, $h
				);
				$self->set_y($y);
				return $self->file;
			}
			method _identify_type (Str $image) {
				my $reg = sprintf '\.(%s)$', join ("|", keys %{$self->valid_mime});
				$image =~ m/$reg/;
				return $self->valid_mime->{$1} || 'image_png';
			}
			method _image_position (Object $image) {
				my ($x, $y, $w, $h) = $self->parse_position($self->position || []);
				my $height = $self->height || $image->height;
				my $width = $self->width || $image->width;
				$width = $w if $width > $w;
				if ($self->align eq 'fill') {
					$height = $h;
					$width = $w;
				} elsif ($self->align eq 'right') {
					$x += ($w - $width);
				} elsif ($self->align eq 'center') {
					$x = ($w - $width) / 2;
				}
				# todo scale
				if ($height <= $h) {
					$y -= $height;
				} else {
					$self->file->add_page;
					($x, $y, $w, $h) = $self->parse_position([]);
					if ($height > $h) {
						$height = $h;
					}
					$y -= $height;
				}
				return ($x, $y, $width, $height);
			}
		}
	}
	class Factory {
		use PDF::API2;
		factory new_pdf (Str $name, Map %args) {
			return $factory->generate_file( \%args )->new(
				file_name => $name,
				pages => [],
				num => 0,
				page_size => 'A4',
				page_args => $args{page} || {},
				pdf => PDF::API2->new( -file => sprintf("%s.pdf", $name)),
			);
		}
	}
}

# probably should dry-run to calculate positions

1;

__END__

=head1 NAME

Mxpress::PDF - PDF

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use Mxpress::PDF;

	my $pdf = Mxpress::PDF->new_pdf('test-pdf',
		page => {
			background => '#000',
			padding => 5
		},
		toc => {
			font => { colour => '#00f' },
		},
		title => {
			font => { colour => '#f00' },
		},
		subtitle => {
			font => { colour => '#0ff' },
		},
		subsubtitle => {
			font => { colour => '#f0f' },
		},
		text => {
			font => { colour => '#fff' },
		},
	)->add_page->title->add(
		'This is a title'
	)->line->add->toc->placeholder->toc->add(
		title => 'This is a title'
	)->text->add(
		'Add some text.'
	)->toc->add(
		subtitle => 'This is a subtitle'
	)->text->add(
		'Add some more text.'
	)->toc->add(
		subsubtitle => 'This is a subsubtitle'
	)->text->add(
		'Add some more text.'
	)->image->add(
		'path/to/file.png'
	)->save;

=head2 Note

experimental.

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mxpress-pdf at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mxpress-PDF>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Mxpress::PDF

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mxpress-PDF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mxpress-PDF>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Mxpress-PDF>

=item * Search CPAN

L<https://metacpan.org/release/Mxpress-PDF>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Mxpress::PDF
