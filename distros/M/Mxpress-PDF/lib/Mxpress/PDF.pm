use v5.18;
use strict;
use warnings;

package Mxpress::PDF {
	our $VERSION = '0.04';
	use MooX::Pression (
		version	=> '0.04',
		authority => 'cpan:LNATION',
	);
	use Colouring::In;
	use constant mm => 25.4 / 72;
	use constant pt => 1;
	class File (HashRef $args) {
		my @plugins = (qw/font line box circle pie ellipse text title subtitle subsubtitle toc image/, ($args->{plugins} ? @{$args->{plugins}} : ()));
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
			$args{is_rotated} = 0;
			if ($self->page) {
				$self->page->next_column() && return;
				$self->page->next_row() && return;
				$args{is_rotated} = $self->page->is_rotated;
				$args{columns} = $self->page->columns;
			}
			my $page = $self->FACTORY->page(
				$self->pdf,
				page_size => 'A4',
				%{ $self->page_args },
				($self->page ? (num => $self->page->num + 1) : ()),
				%args,
			);
			push @{$self->pages}, $page;
			$self->page($page);
			$self->box->add( fill_colour => $page->background, full => \1 ) if $page->background;
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
		has columns (type => Num);
		has column (type => Num);
		has rows (type => Num);
		has row (type => Num);
		has row_y (type => Num);
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
				columns => 1,
				column => 1,
				rows => 1,
				row => 1,
				%args
			);
			return $new_page;
		}
		method rotate {
			my ($blx, $bly, $trx, $try) = $self->current->get_mediabox;
			$self->current->mediabox(
				$self->x(0),
				0,
				$self->w($try),
				$self->h($self->y($trx)),
			);
			$self->set_position($self->parse_position([]));
			$self->is_rotated(!$self->is_rotated);
			return $self;
		}
		method next_column {
			if ($self->column < $self->columns) {
				my ($blx, $bly, $trx, $try) = $self->current->get_mediabox;
				$self->y($self->row_y || $try - ($self->padding/mm));
				$self->column($self->column + 1);
				return 1;
			}
			return;	
		}
		method next_row {
			if ($self->row < $self->rows) {
				my ($blx, $bly, $trx, $try) = $self->current->get_mediabox;
				my $row_height = ($self->h + (($self->padding*2)/mm)) / $self->rows;
				my $offset = int($try - ($row_height * ($self->row)));
				$self->row_y($self->y($offset));
				$self->column(1);
				$self->row($self->row + 1);
				return 1;
			}
			return;
		}
	}
	role Utils {
		has full (type => Bool);
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
			my $file = $self->can('file');
			my $page = $file ? $self->file->page : $self;
			$x //= $page->x + ($self->padding/mm);
			$y //= $page->y - ($self->padding/mm);
			$w //= $page->w - ($self->padding/mm);
			$h //= $y - (($self->padding + $page->padding)/mm);
			if ($file && $page->columns > 1 && !$self->full) {
				$w = ($w / $page->columns);
				$x += ($w * ($page->column - 1));
				$w -= $page->padding/mm;
			}
			if ($file && $page->rows > 1 && !$self->full) {
				$h = ($page->h + (($page->padding*2)/mm)) / $page->rows;
				$h -= ((($page->h + (($page->padding*3)/mm)) - $y) - ($h * ($page->row - 1)));
				if ($page->row > 1) {
					$y -= $page->padding/mm;
					$h -= $page->padding/mm;
				}
			}
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
			has start (type => Num);
			has end (type => Num);
			method generic_new (Object $file, Map %args) {
				return $class->new(
					padding => $args{padding} || 0,	
					%args,
					file => $file,
					fill_colour => $file->page->valid_colour($args{fill_colour} || '#fff'),
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
			class +Pie {
				factory pie (Object $file, Map %args) {
					$args{radius} ||= 50;
					$args{start} ||= 180;
					$args{end} ||= 135;
					return $class->generic_new($file, %args);
				}
				method shape (Object $shape) {
					my ($x, $y, $r) = $self->parse_position($self->position || [
						($self->file->page->x*mm) + $self->radius,
						($self->file->page->y*mm) - $self->radius,
						$self->radius,
					]);
					my $pie = $shape->pie($x, $y, $r, $r, $self->start, $self->end);
					$pie->fillcolor($self->fill_colour);
					$pie->fill;
				}
			}
			class +Ellipse {
				factory ellipse (Object $file, Map %args) {
					$args{start} ||= 50;
					$args{end} ||= 100;
					return $class->generic_new($file, %args);
				}
				method shape (Object $shape) {
					my ($x, $y) = $self->parse_position($self->position || [
						($self->file->page->x*mm) + $self->start,
						($self->file->page->y*mm) - ($self->end / 2),
					]);
					my $ellipse = $shape->ellipse($x, $y, $self->start, $self->end);
					$ellipse->fillcolor($self->fill_colour);
					$ellipse->fill;
				}
			}
		}
		class +Text {
			has font (type => Object);
			has paragraph_space (type => Num);
			has paragraphs_to_columns (type => Bool);
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
						defined $args{$_} ? ( $_ => $args{$_} ) : ()
					} qw/
						margin_bottom margin_top indent align padding pad pad_end first_line_indent 
						first_paragraph_indent paragrah_space paragraphs_to_columns
					/)
				});
			}
			method add (Str $string, Map %args) {
				$self->set_attrs(%args);
				my ($xpos, $ypos);
				my @paragraphs = split /\n/, $string;
				my $columns = $self->file->page->columns;
				my $page_column;
				if ($columns == 1 && $self->paragraphs_to_columns) {
					@paragraphs = grep { $_ =~ m/\w/ } @paragraphs;
					$self->file->page->columns(scalar grep { ($_ =~ m/\w/) } @paragraphs);
					$page_column = 1;
				}
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
						if ($page_column) {
							$page_column++;
							$x += 50/mm;
							$ypos = $y;
						}
						$ypos -= $l;
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
				$self->file->page->columns($columns);
				if (scalar @paragraphs && $self->next_page) {
					my $next_page = $self->next_page->($self);
					return $self->add(join("\n", @paragraphs), %args);
				}
				$self->set_y($ypos);
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

Version 0.04

=cut

=head1 SYNOPSIS
	
	use Mxpress::PDF;

	my @data = qw/
		Brian
		Dougal
		Dylan
		Ermintrude
		Florence
		Zebedee
	/;

	my $gen_text = sub { join( ' ', map { $data[int(rand(scalar @data))] } 0 .. int(rand(shift))) };

	my $pdf = Mxpress::PDF->new_pdf('test',
		page => {
			background => '#000',
			padding => 15,
		},
		toc => {
			font => { colour => '#00f' },
		},
		title => {
			font => { 
				colour => '#f00',
			},
			margin_bottom => 3,
		},
		subtitle => {
			font => { 
				colour => '#0ff', 
			},
			margin_bottom => 3
		},
		subsubtitle => {
			font => { 
				colour => '#f0f',
			},
			margin_bottom => 3
		},
		text => {
			font => { align => 'justify', colour => '#fff' },
			margin_bottom => 3
		},
	)->add_page->title->add(
		$gen_text->(5)
	)->toc->placeholder;

	$pdf->page->columns(2);

	for (0 .. 100) {
		$pdf->toc->add( 
			[qw/title subtitle subsubtitle/]->[int(rand(3))] => $gen_text->(4) 
		)->text->add( $gen_text->(1000) );
	}

=head1 Factory

=new new_pdf 

Start a new pdf.

	my $file = Mxpress->new_pdf(
		page => {},
		toc => {},
		title => {},
		subtitle => {},
		subsubtitle => {},
		text => {},
		toc => {},
		box => {},
		line => {},
		circle => {},
		pie => {},
		ellipse => {}
	)

=cut

=head page

	Mxpress::Page->page(%page_args);

...

=head1 File

=head2 Attributes

	$file->$attr

=head3 file_name (type => Str, required => 1);

=head3 pdf (required => 1, type => Object);

=head3 pages (required => 1, type => ArrayRef);

=head3 page (type => Object);

=head3 page_args (type => HashRef);

=head3 onsave_cbs (type => ArrayRef);

=head2 Plugins

	$file->$plugin->$thing()

=head3 font

=head3 line

=head3 box

=head3 circle

=head3 pie

=head3 toc

=head3 title 

=head3 subtitle 

=head3 subsubtitle 

=head3 text 

=head3 toc 

=head3 box 

=head3 line 

=head3 circle 

=head3 pie 

=head3 ellipse 

=head2 Methods

=head3 add_page

	$file->add_page(%page_attrs)

=head3 save

	$file->save();

=head3 onsave

	$file->onsave($plugin, $cb, \%plugin_args)

=head1 Page

	my $page = $file->page;

=head2 Attributes

	$page->$attr	

=head3 page_size (type => Str);

=head3 background (type => Str);

=head3 num (type => Num, required => 1);

=head3 current (type => Object);

=head3 columns (type => Num);

=head3 column (type => Num);

=head3 rows (type => Num);

=head3 row (type => Num);

=head3 row_y (type => Num);

=head3 is_rotated (type => Num);

=head3 x (type => Num);

=head3 y (type => Num);

=head3 w (type => Num);

=head3 h (type => Num);

=head3 full (type => Bool);

=head3 padding (type => Num);

=head3 margin_top (type => Num);

=head3 margin_bottom (type => Num);

=head2 Methods

=head3 rotate

	$page->rotate();

=head3 next_column

	$page->next_column();

=head3 next_row

	$page->next_row();

=head1 Font

	my $font = $file->font;

=head2 Attributes

	$font->$attr();

=head3 colour (type => Str);

=head3 size (type => Num);

=head3 family (type => Str);

=head3 loaded (type => HashRef);

=head3 line_height ( type => Num);

=head2 Methods

=head3 load

	$font->load()

=head3 find

	$font->find($famild, $enc?)

=head1 Line

	my $line = $file->line;

=head2 Attributes

	$line->$attr();

=head3 fill_colour (type => Str);

=head3 position (type => ArrayRef);

=head3 end_position (type => ArrayRef);

=head2 Methods

=head3 add

	$line->add(%line_args);

=head3 shape

	$line->shape($shape);

=head1 Box

	my $box = $file->box;

=head2 Attributes

	$box->$attr();

=head3 fill_colour (type => Str);

=head3 position (type => ArrayRef);

=head2 Methods

=head3 add

	$box->add(%line_args);

=head3 shape

	$box->shape($shape);

=head1 Circle

	my $circle = $file->circle;

=head2 Attributes

	$circle->$attr();

=head3 fill_colour (type => Str);

=head3 radius (type => Num);

=head3 position (type => ArrayRef);

=head2 Methods

=head3 add

	$circle->add(%line_args);

=head3 shape

	$circle->shape($shape);

=head1 Pie

	my $pie = $file->pie;

=head2 Attributes

	$pie->$attr();

=head3 fill_colour (type => Str);

=head3 radius (type => Num);

=head3 start (type => Num);

=head3 end (type => Num);

=head3 position (type => ArrayRef);

=head2 Methods

=head3 add

	$pie->add(%pie_attrs);

=head3 shape

	$pie->shape($shape);

=head1 Ellipse

	my $ellipse = $file->ellipse;

=head2 Attributes

	$ellipse->$attr();

=head2 Attributes

=head3 fill_colour (type => Str);

=head3 radius (type => Num);

=head3 start (type => Num);

=head3 end (type => Num);

=head3 position (type => ArrayRef);

=head2 Methods

=head3 add

	$ellipse->add(%ellipse_attrs);

=head3 shape

	$ellipse->shape($shape);

=head1 Text

	my $text = $file->text;

=head2 Attributes

	$text->$attrs();

=head3 font (type => Object);

=head3 paragraph_space (type => Num);

=head3 paragraphs_to_columns (type => Bool);

=head3 first_line_indent (type => Num);

=head3 first_paragraph_indent (type => Num);

=head3 align (type => Str); #enum

=head3 margin_bottom (type => Num);

=head3 indent (type => Num);

=head3 pad (type => Str);

=head3 pad_end (type => Str);

=head3 next_page;

=head2 Methods

=head2 add

	$text->add($string_of_text, %text_args);

=head1 Title

	my $title = $file->title;

=head2 Attributes

	$title->$attrs();

=head3 font (type => Object);

=head3 paragraph_space (type => Num);

=head3 paragraphs_to_columns (type => Bool);

=head3 first_line_indent (type => Num);

=head3 first_paragraph_indent (type => Num);

=head3 align (type => Str); #enum

=head3 margin_bottom (type => Num);

=head3 indent (type => Num);

=head3 pad (type => Str);

=head3 pad_end (type => Str);

=head3 next_page;

=head2 Methods

=head2 add

	$title->add($string_of_text, %text_args);

=head1 Subtitle

	my $st = $file->subtitle;

=head2 Attributes

	$st->$attrs();

=head3 font (type => Object);

=head3 paragraph_space (type => Num);

=head3 paragraphs_to_columns (type => Bool);

=head3 first_line_indent (type => Num);

=head3 first_paragraph_indent (type => Num);

=head3 align (type => Str); #enum

=head3 margin_bottom (type => Num);

=head3 indent (type => Num);

=head3 pad (type => Str);

=head3 pad_end (type => Str);

=head3 next_page;

=head2 Methods

=head2 add

	$st->add($string_of_text, %text_args);

=head1 Subsubtitle

	my $sst = $file->subsubtitle;

=head2 Attributes

	$sst->$attrs();

=head3 font (type => Object);

=head3 paragraph_space (type => Num);

=head3 paragraphs_to_columns (type => Bool);

=head3 first_line_indent (type => Num);

=head3 first_paragraph_indent (type => Num);

=head3 align (type => Str); #enum

=head3 margin_bottom (type => Num);

=head3 indent (type => Num);

=head3 pad (type => Str);

=head3 pad_end (type => Str);

=head3 next_page;

=head2 Methods

=head2 add

	$sst->add($string_of_text, %text_args);

=head1 TOC

	my $toc = $file->toc;

=head2 Attributes

=head3 count (type => Num);

=head3 toc_placeholder (type => HashRef);

=head3 outline (type => Object);

=head3 outlines (type => ArrayRef);

=head3 indent (type => Num);

=head3 levels (type => ArrayRef);

=head3 toc_line_offset (type => Num);

=head3 font (type => HashRef);

=head2 Methods

=head3 placeholder

The placeholder position where the table of contents will be rendered.
	
	$toc->placeholder(%placeholder_attrs);

=head3 add

Add to the table of contents

	$toc->add(%placeholders_attrs)

=head1 TOC Outline

	my $outline = $file->FACTORY->add_outline()
	
=head2 Attributes

	$outline->$attrs();

=head3 outline (type => Object);

=head3 x (type => Num);

=head3 y (type => Num);

=head3 title (type => Str);

=head3 page (type => Object);

=head3 level (type => Num);

=head3 children (type => ArrayRef);

=head2 Methods

=head3 render

	$outline->render(%outline_attrs)

=head1 Image

	my $img = $file->image;

=head2 Attributes

	$img->$attrs();

=head3 width (type => Num);

=head3 height (type => Num);

=head3 align (type => Str);

=head3 valid_mime (type => HashRef);

=head2 Methods

=head3 add

	$img->add($image_fh, $type, %image_attrs)

or

	$img->add($image_file_path, %image_attrs)

=cut

=head1 Factory

=cut

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
