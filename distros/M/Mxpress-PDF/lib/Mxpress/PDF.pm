use v5.18;
use strict;
use warnings;

package Mxpress::PDF {
	our $VERSION = '0.11';
	use Zydeco (
		version	=> '0.11',
		authority => 'cpan:LNATION',
	);
	use Colouring::In;
	use constant mm => 25.4 / 72;
	use constant pt => 1;
	class File (HashRef $args) {
		my @plugins = (qw/font line box circle pie ellipse text title subtitle subsubtitle toc image form field annotation cover/, ($args->{plugins} ? @{$args->{plugins}} : ()));
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
		has page_offset (type => Num);
		method add_page (Map %args) {
			$args{is_rotated} = 0;
			if ($self->page) {
				unless ($args{force_new_page}) {
					$self->page->next_column() && return;
					$self->page->next_row() && return;
				}
				$args{h_offset} = $self->page->h_offset;
				$args{is_rotated} = $self->page->is_rotated;
				$args{columns} = $self->page->columns;
			}
			my @attrs = qw/active padding show_page_num page_num_text onsave_cbs x y w h background columns column rows row row_y/;
			my $page = $self->FACTORY->page(
				$self->pdf,
				page_size => 'A4',
				%{ $self->page_args },
				($self->page ? (
					num => $self->page->num + 1,
					header => $self->page->header->attrs(@attrs),
					footer => $self->page->footer->attrs(@attrs)
				) : ()),
				%args,
			);
			push @{$self->pages}, $page;
			$self->page($page);
			$self->box->add( fill_colour => $page->background, full => \1 ) if $page->background;
			$self->page->set_position($page->parse_position([]));
			$self;
		}
		method save {
			my @pages = @{$self->pages};
			if ($self->cover->active) {
				$self->page(shift @pages);
				$self->page->current($self->pdf->openpage(1));
				$self->cover->run_onsave_cbs($self);
			}
			if ($self->onsave_cbs) {
				for my $cb (@{$self->onsave_cbs}) {
					my ($plug, $meth, $args) = @{$cb};
					$self->$plug->$meth(%{$args});
				}
			}
			for my $page (@pages) {
				$page->num($page->num + ($self->page_offset || 0));
				$page->current($self->pdf->openpage($page->num));
				$self->page($page)->run_onsave_cbs($self);
			}
			$self->pdf->saveas();
			$self->pdf->end();
		}
		method onsave (Str $plug, Str $meth, Map %args) {
			# todo role onsave
			my $cbs = $self->onsave_cbs || [];
			push @{$cbs}, [$plug, $meth, \%args];
			$self->onsave_cbs($cbs);
		}
		method mmp (Num $mm) {
			return $mm/mm
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
		has header (type => HashRef|Object);
		has footer (type => HashRef|Object);
		has x (type => Num);
		has y (type => Num);
		has w (type => Num);
		has h (type => Num);
		has oh (type => Num);
		has ow (type => Num);
		has saving (type => Bool);
		has onsave_cbs (type => ArrayRef);
		factory page (Object $pdf, Map %args) {
			my $page = $args{open} ? $pdf->openpage($args{num}) : $pdf->page($args{num} || 0);
			$page->mediabox($args{page_size});
			my ($blx, $bly, $trx, $try) = $page->get_mediabox;
			@args{qw/x y w h oh ow/} = $args{is_rotated} ? (
				0, $trx, $try, $trx, $trx, $try
			) : (
				0, $try, $trx, $try, $try, $trx
			);
			$args{num} ||= 1;
			my $new_page = $class->new(
				current => $page,
				padding => 0,
				columns => 1,
				column => 1,
				rows => 1,
				row => 1,
				h_offset => 0,
				%args,
			);
			for (qw/header footer/) {
				$new_page->$_($factory->$_(
					parent => $new_page,
					%{$args{$_}}
				));
			}
			return $new_page;
		}
		method onsave (Str $plug, Str $meth, Any @args) {
			my $cbs = $self->onsave_cbs || [];
			push @{$cbs}, [$plug, $meth, @args];
			$self->onsave_cbs($cbs);
		}
		method run_onsave_cbs (Object $file) {
			$self->saving(\1);
			if ($self->onsave_cbs) {
				for my $cb (@{$self->onsave_cbs}) {
					my ($plug, $meth, @args) = @{$cb};
					$file->$plug->$meth(@args);
				}
			}
			$self->header->run_onsave_cbs($file) if $self->header && $self->header->active;
			$self->footer->run_onsave_cbs($file) if $self->footer && $self->footer->active;
			return $file;
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
				my $fh = !!$self->footer->active ? $self->footer->h : 0;
				$self->y($self->row_y ? $self->row_y : ($self->h + (($self->padding*2)/mm) + $fh));
				$self->column($self->column + 1);
				return 1;
			}
			return;
		}
		method next_row {
			if ($self->row < $self->rows) {
				my $fh = $self->footer->active ? $self->header->h : 0;
				my ($blx, $bly, $trx, $try) = $self->current->get_mediabox;
				my $row_height = ($self->h + (($self->padding*2)/mm)) / $self->rows;
				my $offset = int($try - $fh - ($row_height * ($self->row)));
				$self->row_y($self->y($offset));
				$self->column(1);
				$self->row($self->row + 1);
				return 1;
			}
			return;
		}
		method attrs (Any @attrs) {
			return {
				map +($_ => $self->$_), grep { defined $self->$_ } @attrs
			}
		}
		method hf_offset {
			return ($self->header->active ? $self->header->h : 0 ) + ($self->footer->active ? $self->footer->h : 0);
		}
		class +Component {
			has parent (type => Object);
			has show_page_num (type => Str);
			has page_num_text (type => Str);
			has active (type => Bool);
			method add (Map %args) {
				if ($args{cb}) {
					$self->onsave(@{ delete $args{cb} });
				}
				$self->set_attrs(%args);
				if (!$self->active) {
					$self->activate();
				#	$self->parent->h_offset($self->parent->h_offset + $self->h);
				}
				return $self->parent;
			}
			method set_position () {
				my $p = $self->padding/mm;
				$self->parent->set_position(
					($self->x > 100 ? ($self->x - $p) : ($self->x + $p)),
					($self->y > 100 ? ($self->y - $p) : ($self->y + $p)),
					($self->w - $p),
					$self->h
				);
			}
			method process_page_num_text {
				if ($self->page_num_text) {
					(my $text = $self->page_num_text) =~ s/\{(.*)\}/$self->$1/eg;
					return $text;
				}
				return $self->parent->num;
			}
			method activate () {
				$self->active(\1);
				return $self;
			}
			around run_onsave_cbs (Object $file) {
				$self->set_position();
				$file->page->padding($self->padding);
				$file->page->column($self->column || 1);
				$file->page->columns($self->columns || 1);
				$file->page->row($self->row || 1);
				$file->page->rows($self->rows || 1);
				$self->$next($file);
				if ($self->show_page_num) {
					$self->set_position();
					$file->text->add($self->process_page_num_text, align => $self->show_page_num);
				}
			}
			class +Cover {
				has file (type => Object);
				factory cover (Object $file, Map %args) {
					$args{$_} //= $file->page->$_ for qw/x y w h padding oh ow column columns row rows num page_size/;
					return $class->new(
						file => $file,
						parent => $file->page,
						current => $file->page->current,
						%args
					);
				}
				method end {
					$self->file->page($self->parent);
					$self->file->add_page(force_new_page => 1);
					return $self->file;
				}
				around add {
					$self->file->page($self);
					$self->$next(@_);
					return $self->file;
				}
			}
			class +Header {
				factory header (Map %args) {
					$args{$_} //= $args{parent}->$_ for qw/num page_size/;
					$args{x} //= 0;
					$args{w} //= $args{parent}->ow;
					$args{y} //= $args{parent}->h;
					$args{h} //= 10/mm;
					$args{padding} //= 0;
					my $head = $class->new(onsave_cbs => [], %args);
					$head->activate if !!$head->active;
					return $head;
				}
				before activate {
					$self->parent->y($self->parent->y - $self->h);
				}
			}
			class +Footer {
				factory footer (Map %args) {
					$args{$_} //= $args{parent}->$_ for qw/num page_size/;
					$args{x} //= 0;
					$args{w} //= $args{parent}->ow;
					$args{y} //= (5/mm);
					$args{h} //= (10/mm);
					$args{padding} //= 0;
					return $class->new(onsave_cbs => [], %args);
				}
			}
		}
	}
	role Utils {
		has full (type => Bool);
		has padding (type => Num);
		has margin_top (type => Num);
		has margin_bottom (type => Num);
		has h_offset (type => Num);
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
			my $sp = $self->padding/mm;
			my $pp = $page->padding/mm;
			$x //= ($page->x + $sp);
			$y //= ($page->y - $sp);
			$w //= ($page->w - $sp);
			$h //= ($page->oh - ($page->oh - $y) - ($sp + $pp));
			$h = ((!$page->footer || !$page->footer->active) ? $h : $page->footer->saving ? ($h + $sp + $pp) : $h > $page->footer->h ? ($h - $page->footer->h) : 0);
			if ($file) {
				if ($page->columns > 1 && !$self->full) {
					$w = ($page->w / $page->columns);
					$x += ($w * ($page->column - 1));
					$w -= $sp;
				}
				$w -= ($pp + $sp);
				if ($page->rows > 1 && !$self->full) {
					my $hh = $page->header && $page->header->active ? $page->header->h :0;
					my $fh = $page->footer && $page->footer->active ? $page->footer->h : 0;
					$h = ($page->h + ($pp*2)) / $page->rows;
					$h -= ((($page->h + ($pp*3)) - $y) - ($h * ($page->row - 1)));
					$h -= $fh;
					if ($page->row > 1 && $page->y == $page->row_y) {
						$y -= $pp;
						$h -= $pp;
					}
				}
				$h -= $sp;
			}
			return $xy ? ($x, $y) : ($x, $y, $w, $h);
		}
		method set_y (Num $y) {
			$y -= ($self->margin_bottom/mm) if $self->margin_bottom;
			my $page = $self->can('file') ? $self->file->page : $self;
			return $page->y($y);
		}
		method valid_colour (Str $css) {
			return Colouring::In->new($css)->toHEX(1);
		}
		method set_attrs (Map %args) {
			$self->can($_) && $self->$_($args{$_}) for keys %args;
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
			has text (type => Object);
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
					padding => 0,
					align => 'left',
					font => $class->FACTORY->font(
						$file,
						%{$args{font}}
					),
					position => $args{position} || [],
					(map {
						defined $args{$_} ? ( $_ => $args{$_} ) : ()
					} qw/
						align margin_bottom margin_top indent align padding pad pad_end first_line_indent
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
				my $text = $self->text($self->file->page->current->text);
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
				if ($h >= 0 && $y >= 0) {
					while ($ypos + 0 >= ($y - $h)) {
						unless (scalar @paragraph) {
							last unless scalar @paragraphs;
							@paragraph = split( / /, shift(@paragraphs) );
							if ($page_column) {
								$page_column++;
								$x += 50/mm;
								$ypos = $y;
							}
							$ypos -= $l;
							$ypos -= ($self->paragraph_space/mm) if $self->paragraph_space;
							last unless $ypos >= ($y - $h);
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
							my $pad_end = $self->pad_end || '';
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
				}
				unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);
				$self->file->page->y($ypos);
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
						#$file->page->set_position($file->toc->parse_position([]));
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
					position => [$self->file->page->parse_position($args{position} || [])]
				});
				$self->file->onsave('toc', 'render', %args);
				$self->file->add_page(force_new_page => 1);
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
				my $total_height = ($self->count * $one_toc_link) - ($h + ($self->file->page->h * $self->file->page->columns - 1));
				while ($total_height > 0) {
					$args{page_offset}++;
					$self->file->add_page(num => $placeholder->{page}->num + $args{page_offset});
					$total_height -= $self->file->page->h;
				}
				$self->file->page($placeholder->{page});
				$self->file->page->h($self->file->page->h - $self->file->page->hf_offset);
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
		class +Annotation {
			has type (type => Str);
			has w (type => Num);
			has h (type => Num);
			has open (type => Bool);
			has rect (type => ArrayRef);
			has border (type => ArrayRef);
			factory annotation (Object $file, Map %args) {
				return $class->new(
					file => $file,
					padding => 0,
					type => 'text',
					open => 0,
					w => 0,
					h => 0,
					%args
				);
			}
			method add (Str $text, %args) {
				my $annotation = $self->file->page->current->annotation;
				return $self->_add_annotation($self->type, $text, %args);
			}
			method _add_annotation (Str $type, Str $cont, Map %args) {
				$self->set_attrs(%args);
				my $annotation = $self->file->page->current->annotation;
				my @xy = $self->parse_position(($self->position || []), 1);
				$annotation->$type($cont,
					-rect => $self->rect || [@xy, $self->w, $self->h],
					-open => $self->open,
					-border => $self->border || [@xy, $self->w]
				); # :/
				return $self->file;
			}
		}
		class +Form {
			has xo (type => Object);
			factory form (Object $file, Map %args) {
				return $class->new(
					file => $file,
					forms => [],
					padding => $args{padding} || 0,
				);
			}
			method add {
				my $form = $self->xo(
					$self->file->pdf->xo_form()
				);
				$self->position([$self->parse_position([], 1)]);
				return $self->file;
			}
			method end (Map %args) {
				my $position = $self->position;

				return $self->file;
			}
		}
		class +Field {
			extends Plugin::Text;
			factory field (Object $file, Map %args) {
				$args{pad} ||= '_';
				$class->generic_new($file, %args);
				# todo Attempt2 when brain != hangover |--[fillable forms]--|
			}
			around add (Str $text, Map %args) {
				my $file = $self->$next($text, %args);
				return $file;
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
			)->add_page;
		}
	}
}

# probably should dry-run to calculate positions

1;

__END__

=head1 NAME

Mxpress::PDF - PDF

=head1 VERSION

Version 0.11

=cut

=head1 Note

This is experimental and may yet still change.

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
			columns => 3,
		},
		cover => {
			columns => 1
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
			font => { colour => '#fff' },
			margin_bottom => 3,
			align => 'justify'
		},
	);

	$pdf->cover->add->title->add(
		'Add a cover page'
	)->image->add(
		't/hand-cross.png'
	)->cover->add(
		cb => ['text', 'add', q|you're welcome|]
	);

	$pdf->title->add(
		'Table Of Contents'
	)->toc->placeholder;

	$pdf->page->header->add(
		show_page_num => 'right',
		page_num_text => "page {num}",
		cb => ['text', 'add', 'Header of the page', align => 'center', font => Mxpress::PDF->font($pdf, colour => '#f00') ],
		h => $pdf->mmp(10),
		padding => 5
	);

	$pdf->page->footer->add(
		show_page_num => 'left',
		cb => ['text', 'add', 'Footer of the page', align => 'center', font => Mxpress::PDF->font($pdf, colour => '#f00') ],
		h => $pdf->mmp(10),
		padding => 5
	);

	for (0 .. 100) {
		$pdf->toc->add(
			[qw/title subtitle subsubtitle/]->[int(rand(3))] => $gen_text->(4)
		)->text->add( $gen_text->(1000) );
	}

	$pdf->save();

=head1 Description

This module currently allows you to easily create a PDF. Why? For fun.

=head1 Factory

Mxpress::PDF is a factory package and the entry point for Mxpress::PDF::* objects.

=head2 new_pdf

Returns a new Mxpress::PDF::File object. This is the MAIN object for working on the PDF file.

	my $file = Mxpress::PDF->new_pdf($filename, %page_args);

=cut

=head2 page

Returns a new Mxpress::PDF::Page Object. This object is for managing an individual PDF page.

	my $page = Mxpress::PDF->page(%page_args);

=head2 cover

Returns a new Mxpress::PDF::Page::Component::Cover Object. This object is for managing the PDF cover page.

	my $cover = Mxpress::PDF->cover(%cover_args);

=head2 header

Returns a new Mxpress::PDF::Page::Component::Header Object. This object is for managing an individual PDF page header.

	my $header = Mxpress::PDF->header(%header_args);

=head2 footer

Returns a new Mxpress::PDF::Page::Component::Footer Object. This object is for managing an individual PDF page footer.

	my $footer = Mxpress::PDF->footer(%footer_args);

=head2 font

Returns a new Mxpress::PDF::Plugin::Font Object. This object is for loading a PDFs text font.

	my $font = Mxpress::PDF->font($file, %font_args);

=head2 line

Returns a new Mxpress::PDF::Plugin::Shape::Line Object. This object is for drawing lines.

	my $line = Mxpress::PDF->line($file, %line_args);

=head2 box

Returns a new Mxpress::PDF::Plugin::Shape::Box Object. This object is for drawing box shapes.

	my $box = Mxpress::PDF->box($file, %box_args);

=head2 circle

Returns a new Mxpress::PDF::Plugin::Shape::Circle Object. This object is for drawing circle shapes.

	my $box = Mxpress::PDF->box($file, %circle_args);

=head2 pie

Returns a new Mxpress::PDF::Plugin::Shape::Pie Object. This object is for drawing pie shapes.

	my $pie = Mxpress::PDF->pie($file, %pie_args);

=head2 ellipse

Returns a new Mxpress::PDF::Plugin::Shape::Ellipse Object. This object is for drawing ellipse shapes.

	my $ellipse = Mxpress::PDF->ellipse($file, %ellise_args);

=head2 text

Returns a new Mxpress::PDF::Plugin::Text Object. This object aids with writing text to a pdf page.

	my $text = Mxpress::PDF->text($file, %text_args);

=head2 title

Returns a new Mxpress::PDF::Plugin::Text::Title Object. This object aids with writing 'title' text to a pdf page.

	my $title = Mxpress::PDF->title($file, %title_args);

=head2 subtitle

Returns a new Mxpress::PDF::Plugin::Text::Title Object. This object aids with writing 'subtitle' text to a pdf page.

	my $subtitle = Mxpress::PDF->subtitle($file, %subtitle_args);

=head2 subsubtitle

Returns a new Mxpress::PDF::Plugin::Text::Subsubtitle Object. This object aids with writing 'subsubtitle' text to a pdf page.

	my $subsubtitle = Mxpress::PDF->subsubtitle($file, %subsubtitle_args);

=head2 toc

Returns a new Mxpress::PDF::Plugin::TOC Object. This object is for managing a table of contents.

	my $toc = Mxpress::PDF->toc($file, %toc_args);

=head2 add_outline

Returns a new Mxpress::PDF::Plugin::TOC::Outline Object. This object is for managing an indivual outline for the table of contents.

	my $outline = Mxpress::PDF->add_outline($file, %ouline_args);

=head2 image

Returns a new Mxpress::PDF::Plugin::Image Object. This object aids with adding images to a pdf page.

	my $image = Mxpress::PDF->image($file, %image_args);

=head2 annotation

Returns a new Mxpress::PDF::Plugin::Annotation Object. This object aids with adding annotations to a pdf page.

	my $annotation = Mxpress::PDF->annotation($file, %image_args);

=head1 File

Mxpress::PDF::File is the main object that you will use when creating a pdf using this library. To instantiate call add_file
with a file name and any plugin attributes.

	my $file = Mxpress::PDF->add_file($filename,
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
	);

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::File, they are all optional.

	$file->$attr

=head3 file_name (type => Str);

The file name of the pdf

	$file->file_name;

=head3 pdf (type => Object);

A PDF::API2 Object.

	$file->pdf;

=head3 pages (type => ArrayRef);

A list of Mxpress::PDF::Page objects.

	$file->pages;

=head3 page (type => Object);

An open Mxpress::PDF::Page object.

	$file->page;

=head3 onsave_cbs (type => ArrayRef);

An array of arrays that define cbs, triggered when $file->save() is called.

	[
		[$plugin, $method_name, @%args]
	]

=head3 font (type => Object)

A Mxpress:PDF::Plugin::Font Object.

	$file->font->load;

=head3 line (type => Object)

A Mxpress::PDF::Plugin::Shape::Line Object.

	$file->line->add;

=head3 box (type => Object)

A Mxpress::PDF::Plugin::Shape::Box Object.

	$file->box->add;

=head3 circle

A Mxpress::PDF::Plugin::Shape::Circle Object.

	$file->circle->add;

=head3 pie

A Mxpress::PDF::Plugin::Shape::Pie Object.

	$file->pie->add;

=head3 ellipse

A Mxpress::PDF::Plugin::Shape::Ellipse Object.

	$file->ellipse->add;

=head3 toc

A Mxpress::PDF::Plugin::TOC Object.

	$file->toc->placeholder->toc->add(
		title => 'A title'
	);

=head3 title

A Mxpress::PDF::Plugin::Title Object.

	$file->title->add;

=head3 subtitle

A Mxpress::PDF::Plugin::Subtitle Object.

	$file->title->add;

=head3 subsubtitle

A Mxpress::PDF::Plugin::Subsubtitle Object

	$file->subsubtitle->add;

=head3 text

A Mxpress::PDF::Plugin::Text Object

	$file->text->add;

=head2 Methods

The following methods can be called from a Mxpress::PDF::File Object.

=head3 add_page

This will add a new Mxpress::PDF::Page to the file. You can pass any page attributes defined in
the documentation below.

	$file->add_page(%page_attrs)

=head3 save

This will save the pdf file. Note call only once you are finished generating the pdf file.

	$file->save();

=head3 onsave

Add a onsave callback to the file. The callbacks will be triggered when you call $file->save();.

	$file->onsave($plugin, $cb, \%plugin_args);

=head3 mmp

Convert mm to pt.

	my $pt = $file->mmp(10);

=head1 Page

An open Mxpress::PDF::Page object.
Mxpress::PDF::Page is for managing an individual PDF page. To access the current open page call the attribute on the file object.

	my $page = $file->page;

To add a new page to the pdf call add_page on the file object.

	my $new_page = $file->add_page(%page_attributes)->page;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::File, they are all optional.

	$page->$attr

=head3 page_size (type => Str);

The page size of the pdf, default is A4.

	$page->page_size('A4');

=head3 background (type => Str);

The background colour of the page.

	$page->background('#000');

=head3 num (type => Num, required => 1);

The page number.

	$page->num;

=head3 current (type => Object);

The current PDF::API2::Page Object.

	$page->current;

=head3 columns (type => Num);

The number of columns configured for the page, default is 1.

	$page->columns(5);

=head3 column (type => Num);

The current column that is being generated, default is 1.

	$page->column(2);

=head3 rows (type => Num);

The number of rows configured for the page, default is 1.

	$page->rows(5);

=head3 row (type => Num);

The number of rows configured for the page, default is 1.

	$page->row(2);

=head3 is_rotated (type => Num);

Is the page rotated (portrait/landscape).

	$page->is_rotated;

=head3 x (type => Num);

The current x coordinate.

	$page->x($x);

=head3 y (type => Num);

The current y coordinate.

	$page->y($y);

=head3 w (type => Num);

The available page width.

	$page->w($w);

=head3 h (type => Num);

The available page height.

	$page->h($h);

=head3 full (type => Bool);

Disable any column/row configuration and render full width/height.

	$page->full(\1);

=head3 padding (type => Num);

Add padding to the page (mm).

	$page->padding($mm);

=head3 margin_top (type => Num);

Add margin to the top of the page (mm).

	$page->margin_top($mm);

=head3 margin_bottom (type => Num);

Add margin to the bottom of the page (mm).

	$page->margin_bottom($mm);

=head3 onsave_cbs (type => ArrayRef);

Callbacks that will be triggered when $file->save is called.

	$page->onsave_cbs([
		[$plugin, $method_name, @%args]
	]);

=head3 header (type => HashRef|Object);

A Mxpress::PDF::Page::Component::Header Object.

	$page->header;

=head3 footer (type => HashRef|Object);

A Mxpress::PDF::Page::Component::Footer Object.

	$page->footer;

=head2 Methods

The following methods can be called from a Mxpress::PDF::Page Object.

=head3 rotate

Rotate the current page.

	$page->rotate();

=head3 next_column

Find the next column of the page.

	$page->next_column();

=head3 next_row

Find the next row of the page.

	$page->next_row();

=head2 onsave

Add a onsave callback to the page. The callbacks will be triggered when you call $file->save();.

	$page->onsave($plugin, $cb, @%plugin_args);

=head2 attrs

Return attributes for the page.

	my $attrs = $page->attrs(@attrs);

=head1 Component


=head1 Cover

Mxpress::PDF::Page::Component::Cover extends Mxpress::PDF::Page::Component and is for managing an the PDF cover page.

You can pass default attributes when instantiating the page object.

	$file->add_page(
		cover => { %cover_atts }
	);

or when calling the objects add method.

	$page->cover->add(
		%cover_attrs
	);

=head2 Attributes

The following additional attributes can be configured for a Mxpress::PDF::Page::Component::Cover, they are all optional.

	$page->cover->$attr

=head3 show_page_num (type => Str);

Alignment for the page number

	show_page_num => 'right'

=head3 page_num_text (type => Str);

Text to display around the page number.

	page_num_text => 'Page {num}'

=head3 active (type => Bool);

Control whether to display the cover, default is false however it is set to true if ->cover->add() is called.

	active => true

=head2 Methods

The following methods can be called from a Mxpress::PDF::Page::Component Object.

=head3 add

Add content to the cover. You can pass any attribute for the header along with a cb function which will be added to
the onsave_cbs.

	$page->coverr->add(
		cb => [...],
		%cover_atts
	);

=head3 set_position

Set the position of the header.

	$page->header->position($x, $y, $w, $h);

=head3 process_page_num_text

Process the page_num_text into printable form.

	$self->header->processs_page_num_text();

=head3 activate

Activate the header.

	$page->activate()

=head3 end

Move to page 2.

	$page->end;

=head1 Header

Mxpress::PDF::Page::Component::Header extends Mxpress::PDF::Page::Component and is for managing an individual PDF page header.

You can pass default attributes when instantiating the page object.

	$file->add_page(
		header => { %header_atts }
	);

or when calling the objects add method.

	$page->header->add(
		%header_attrs
	);

=head2 Attributes

The following additional attributes can be configured for a Mxpress::PDF::Page::Component::Header, they are all optional.

	$page->header->$attr

=head3 show_page_num (type => Str);

Alignment for the page number

	show_page_num => 'right'

=head3 page_num_text (type => Str);

Text to display around the page number.

	page_num_text => 'Page {num}'

=head3 active (type => Bool);

Control whether to display the header, default is false however it is set to true if ->header->add() is called.

	active => true

=head2 Methods

The following methods can be called from a Mxpress::PDF::Page::Header Object.

=head3 add

Add content to the header. You can pass any attribute for the header along with a cb function which will be added to
the onsave_cbs.

	$page->header->add(
		cb => [...],
		%header_atts
	);

=head3 set_position

Set the position of the header.

	$page->header->position($x, $y, $w, $h);

=head3 process_page_num_text

Process the page_num_text into printable form.

	$self->header->processs_page_num_text();

=head3 activate

Activate the header.

	$page->activate()

=head1 Footer

Mxpress::PDF::Page::Component::Footer extends Mxpress::PDF::Page and is for managing an individual PDF page footer.

You can pass default attributes when instantiating the page object.

	$file->add_page(
		footer => { %footer_atts }
	);

or when calling the objects add method.

	$page->footer->add(
		%footer_attrs
	);

=head2 Attributes

The following additional attributes can be configured for a Mxpress::PDF::Page::Component::Footer, they are all optional.

	$page->footer->$attr

=head3 show_page_num (type => Str);

Alignment for the page number

	show_page_num => 'right'

=head3 page_num_text (type => Str);

Text to display around the page number.

	page_num_text => 'Page {num}'

=head3 active (type => Bool);

Control whether to display the header, default is false however it is set to true if ->footer->add() is called.

	active => true

=head2 Methods

The following methods can be called from a Mxpress::PDF::Page::Footer Object.

=head3 add

Add content to the footer. You can pass any attribute for the footer along with a cb function which will be added to
the onsave_cbs.

	$page->footer->add(
		cb => [...],
		%footer_atts
	);

=head3 set_position

Set the position of the footer.

	$page->footer->position($x, $y, $w, $h);

=head3 process_page_num_text

Process the page_num_text into printable form.

	$self->header->processs_page_num_text();

=head3 activate

Activate the header.

	$page->activate()

=head1 Plugin

Mxpress::PDF::Plugin is a base class for plugins, it includes Mxpress::PDF::Utils.

=head1 Font

Mxpress::PDF::Plugin::Font extends Mxpress::PDF::Plugin and is for managing pdf fonts.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		font => { %font_atts },
		text => {
			font => { %font_attrs }
		}
	);

or when calling some objects add methods like Mxpress::PDF::Plugin::Text->add.

	$file->text->add(
		font => { %font_attrs },
	);

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Font object, they are all optional.

	$font->$attr();

=head3 colour (type => Str);

The font colour.

=head3 size (type => Num);

The font size.

=head3 family (type => Str);

The font family.

=head3 loaded (type => HashRef);

Loaded hashref of PDF::API2 fonts.

=head3 line_height ( type => Num);

Line height of the font.

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Font Object.

=head3 load

Load the PDF::API2 font object.

	$font->load()

=head3 find

Find a PDF::API2 font object.

	$font->find($famild, $enc?)

=head1 Shape

Mxpress::PDF::Plugin::Shape extends Mxpress::PDF::Plugin and is the base class for all shape plugins.

=head1 Line

Mxpress::PDF::Plugin::Shape::Line extends Mxpress::PDF::Plugin::Shape and is for aiding with drawing lines on a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		line => { %line_attrs },
	);

or when calling the objects add method.

	$file->line->add(
		%line_attrs
	);

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Line object, they are all optional.

	$line->$attr();

=head3 fill_colour (type => Str);

The colour of the line.

	$line->fill_colour('#000');

=head3 position (type => ArrayRef);

The position of the line

	$line->position([$x, $y]);

=head3 end_position (type => ArrayRef);

	$line->end_position([$x, $y]);

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Shape::Line Object.

=head3 add

Add a new line to the current Mxpress::PDF::Page.

	$line->add(%line_args);

=head1 Box

Mxpress::PDF::Plugin::Shape::Box extends Mxpress::PDF::Plugin::Shape and is for aiding with drawing boxes on a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		box => { %box_attrs },
	);

or when calling the objects add method.

	$file->box->add(
		%box_attrs
	);

	my $box = $file->box;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Box object, they are all optional.

	$box->$attr();

=head3 fill_colour (type => Str);

The background colour of the box.

	$box->fill('#000');

=head3 position (type => ArrayRef);

The position of the box.

	$box->position([$x, $y, $w, $h]);

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Shape::Box Object.

=head3 add

Add a new box to the current Mxpress::PDF::Page.

	$box->add(%box_attrs);

=head1 Circle

Mxpress::PDF::Plugin::Shape::Circle extends Mxpress::PDF::Plugin::Shape and is for aiding with drawing circles on a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		circle => { %circle_attrs },
	);

or when calling the objects add method.

	$file->box->add(
		%circle_attrs
	);

	my $circle = $file->circle;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Shape::Circle object, they are all optional.

	$circle->$attr();

=head3 fill_colour (type => Str);

The background colour of the circle.

	$circle->fill_colour('#000');

=head3 radius (type => Num);

The radius of the circle. (mm)

	$circle->radius($num);

=head3 position (type => ArrayRef);

The position of the circle. (pt)

	$circle->position([$x, $y, $w, $h]);

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Shape::Circle Object.

=head3 add

Add a new circle shape to the current Mxpress::PDF::Page.

	$circle->add(%line_args);

=head1 Pie

Mxpress::PDF::Plugin::Shape::Pie extends Mxpress::PDF::Plugin::Shape and is for aiding with drawing pies on a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		pie => { %pie_attrs },
	);

or when calling the objects add method.

	$file->pie->add(
		%pie_attrs
	);

	my $pie = $file->pie;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Shape::Pie object, they are all optional.

	$pie->$attr();

=head3 fill_colour (type => Str);

The background colour of the pie.

	$pie->fill_colour('#000');

=head3 radius (type => Num);

The radius of the pie.

	$pie->radius($num);

=head3 start (type => Num);

Start percent of the pie.

	$pie->start(180)

=head3 end (type => Num);

End percent of the pie.

	$pie->end(90);

=head3 position (type => ArrayRef);

The position of the pie (pt)

	$pie->position([$x, $y, $w, $h]);

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Shape::Pie Object.

=head3 add

Add a new pie shape to the current Mxpress::PDF::Page.

	$pie->add(%pie_attrs);

=head1 Ellipse

Mxpress::PDF::Plugin::Shape::Ellipse extends Mxpress::PDF::Plugin::Shape and is for aiding with drawing ellipses on a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		ellipse => { %ellise_attrs },
	);

or when calling the objects add method.

	$file->ellipse->add(
		%pie_attrs
	);

	my $pie = $file->ellipse;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Shape::Ellipse object, they are all optional.

	$ellipse->$attr();

=head2 Attributes

=head3 fill_colour (type => Str);

The background colour of the ellipse.

	$ellipse->fill_colour('#000');

=head3 radius (type => Num);

The radius of the ellispe.

	$ellispse->radius($r);

=head3 start (type => Num);

Start percent of the ellipse

	$ellipse->start($p)

=head3 end (type => Num);

End percent of the ellipse.

	$ellipse->end($p);

=head3 position (type => ArrayRef);

The position of the ellipse (pt)

	$pie->position([$x, $y, $w, $h]);

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Shape::Ellipse Object.

=head3 add

Add a new ellipse shape to the current Mxpress::PDF::Page.

	$ellipse->add(%ellipse_attrs);

=head1 Text

Mxpress::PDF::Plugin::Text extends Mxpress::PDF::Plugin and is for aiding with writing text to a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		text => { %text_attrs },
	);

or when calling the objects add method.

	$file->text->add(
		%text_attrs
	);

	my $text = $file->text;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Text object, they are all optional.

	$text->$attrs();

=head3 font (type => Object);

An Mxpress::PDF::Plugin::Font object.

	$text->font(Mxpress::PDF->font($file, %font_args));

=head3 paragraph_space (type => Num);

Configure the spacing between paragraphs.

	$text->paragraph_space($mm);

=head3 paragraphs_to_columns (type => Bool);

If true then paragraphs within the passed text string will be split into individual columns.

	$text->paragraphs_to_columns(\1);

=head3 first_line_indent (type => Num);

Indent the first line when rendering given text.

	$text->first_line_indent($mm);

=head3 first_paragraph_indent (type => Num);

Indent the first line when rendering given text.

	$text->first_paragraph_indent($mm);

=head3 align (type => Str); #enum

Align the text on each line. (left|justify|center|right)

	$text->align('justify');

=head3 margin_bottom (type => Num);

Set a bottom margin to be added after text has been rendered.

	$text->margin($mm);

=head3 indent (type => Num);

Set an indent for the block of text.

	$text->indent($mm);

=head3 pad (type => Str);

Pad the passed text to fit the available space, default is undefined.

	$text->pad('.');

=head3 pad_end (type => Str);

Append a string to the padded text.

	$text->pad_end('!');

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Text Object.

=head2 add

Add a text to the current Mxpress::PDF::Page.

	$text->add($string_of_text, %text_args);

=head1 Title

Mxpress::PDF::Plugin::Title extends Mxpress::PDF::Plugin::Text and is for aiding with adding titles to a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		title => { %title_attrs },
	);

or when calling the objects add method.

	$file->title->add(
		%title_attrs
	);

=head1 Subtitle

Mxpress::PDF::Plugin::Subtitle extends Mxpress::PDF::Plugin::Text and is for aiding with adding subtitles to a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		subtitle => { %subtitle_attrs },
	);

or when calling the objects add method.

	$file->subtitle->add(
		%subtitle_attrs
	);

=head1 Subsubtitle

Mxpress::PDF::Plugin::Subsubtitle extends Mxpress::PDF::Plugin::Text and is for aiding with adding subsubtitles to a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		subsubtitle => { %subsubtitle_attrs },
	);

or when calling the objects add method.

	$file->subsubtitle->add(
		%subsubtitle_attrs
	);

=head1 TOC

Mxpress::PDF::Plugin::TOC extends Mxpress::PDF::Plugin and is for managing a table of contents.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		toc => { %toc_attrs },
	);

or when calling the objects add method.

	$file->toc->add(
		%toc_attrs
	);

	my $toc = $file->toc;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::TOC object, they are all optional.

	$toc->$attr();

=head3 count (type => Num);

The current count of toc links

	$file->toc->count;

=head3 indent (type => Num);

The indent used for each level, default is 5.

	$file->toc->indent(0);

=head3 levels (type => ArrayRef);

The levels that can be used for TOC. For now we just have title|subtitle|subsubtitle but this is where you could extend.

	$file->toc->levels;

=head3 toc_line_offset (type => Num);

The line height offset when rendering the table of contents.

	$file->toc_line_offset($mm);

=head3 font (type => HashRef);

Attributes to be used for building the font class for TOC outlines

	$toc->font(\%font_attrs);

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::TOC Object.

=head3 placeholder

The placeholder position where the table of contents will be rendered.

	$toc->placeholder(%placeholder_attrs);

=head3 add

Add to the table of contents

	$toc->add(
		title => $title,
		%toc_attrs
	)

	$toc->add(
		subtitle => [$subtitle, %subtitle_attrs]
	);

=head1 TOC Outline

Mxpress::PDF::Plugin::TOC::Outline extends Mxpress::PDF::Plugin and is for managing a table of content outline.

	my $outline = $file->FACTORY->add_outline()

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::TOC::Object object.

	$outline->$attrs();

=head3 outline (type => Object);

The PDF::API2 Outline object.

	$outline->outline;

=head3 x (type => Num);

The x coordinates of the outline.

	$outline->x($x);

=head3 y (type => Num);

The y coordinates of the outline.

	$outline->y($y);

=head3 title (type => Str);

The title text used to render in the table of contents.

	$outline->title($text);

=head3 page (type => Object);

The linked Mxpress::PDF::Page object.

	$ouline->page();

=head3 level (type => Num);

The level of the outline.

	$ouline->level(1);

=head3 children (type => ArrayRef);

An arrarref of linked Mxpress::PDF::Plugin::TOC::Outline objects.

	$ouline->children

=head1 Image

Mxpress::PDF::Plugin::Image extends Mxpress::PDF::Plugin and is for adding images to a Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		image => { %image_attrs },
	);

or when calling the objects add method.

	$file->image->add(
		%image_attrs
	);

	my $image = $file->image;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Image object, they are all optional.

	$img->$attrs();

=head3 width (type => Num);

The width of the image.

	$img->width($pt);

=head3 height (type => Num);

The height of the image.

	$img->height($pt);

=head3 align (type => Str);

Align the image - left|center|right

	$img->align('right');

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Image Object.

=head3 add

Add an image to the current Mxpress::PDF::Page.

	$img->add($image_fh, $type, %image_attrs)

or

	$img->add($image_file_path, %image_attrs)

=head1 Annotation

Mxpress::PDF::Plugin::Annotation extends Mxpress::PDF::Plugin and is for adding annotations to a
Mxpress::PDF::Page.

You can pass default attributes when instantiating the file object.

	Mxpress::PDF->add_file($filename,
		annotation => { %annotation_attrs },
	);

or when calling the objects add method.

	$file->annotation->add(
		%annotation_attrs
	);

	my $annotation = $annotation->annotation;

=head2 Attributes

The following attributes can be configured for a Mxpress::PDF::Plugin::Annotation object, they are all optional.

	$annotation->$attrs();

=head3 type (type => Num)

The type of annotation text|file|.

	$annotation->type;

=head3 w (type => Num)

The width of the annotation.

	$annotation->w;

=head3 h (type => Num)

The hieght of the annotation.

	$annotation->h;

=head2 open (type => Bool)

Toggle whether annotation is open.

	$annotation->open;

=head2 Methods

The following methods can be called from a Mxpress::PDF::Plugin::Annotation Object.

=head3 add

Add an annotation to the current Mxpress::PDF::Page.

	$annotation->add('add some text', %annotation_attrs)

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
